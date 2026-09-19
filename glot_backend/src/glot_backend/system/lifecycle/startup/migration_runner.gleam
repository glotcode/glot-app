import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glot_backend/system/database as db_helpers
import glot_backend/system/file_system
import glot_backend/system/lifecycle/startup/sql_file
import glot_backend/system/lifecycle/startup/startup_transaction
import parrot/dev
import pog

const bootstrap_version = "0000"

const migration_statement_timeout_ms = 300_000

type Migration {
  Migration(version: String, name: String, filename: String, sql: String)
}

pub fn run_pending(
  db: pog.Connection,
  migrations_dir: String,
) -> Result(List(String), String) {
  use migrations <- result.try(load_migrations(migrations_dir))
  use _ <- result.try(ensure_bootstrap_migration_present(migrations))
  use _ <- result.try(bootstrap_schema_migrations_if_needed(db, migrations))
  use applied_versions <- result.try(list_applied_versions(db))

  migrations
  |> pending_migrations(applied_versions)
  |> apply_migrations(db, [])
  |> result.map(list.reverse)
}

pub fn run_pending_seeds(
  db: pog.Connection,
  seeds_dir: String,
) -> Result(List(String), String) {
  case file_system.is_dir(seeds_dir) {
    False -> Ok([])
    True -> {
      use seeds <- result.try(load_seeds(seeds_dir))
      use applied_versions <- result.try(list_applied_seed_versions(db))

      seeds
      |> pending_migrations(applied_versions)
      |> apply_seeds(db, [])
      |> result.map(list.reverse)
    }
  }
}

fn load_migrations(migrations_dir: String) -> Result(List(Migration), String) {
  use filenames <- result.try(list_sql_filenames(migrations_dir))
  use files <- result.try(sql_file.validate_migrations(filenames))
  decode_sql_files(migrations_dir, files, [])
}

fn load_seeds(seeds_dir: String) -> Result(List(Migration), String) {
  use filenames <- result.try(list_sql_filenames(seeds_dir))
  use files <- result.try(sql_file.validate_seeds(filenames))
  decode_sql_files(seeds_dir, files, [])
}

fn decode_sql_files(
  directory: String,
  files: List(sql_file.SqlFile),
  acc: List(Migration),
) -> Result(List(Migration), String) {
  case files {
    [] -> Ok(list.reverse(acc))
    [file, ..rest] -> {
      use sql <- result.try(
        file_system.read_file(migration_path(directory, file.filename)),
      )

      decode_sql_files(directory, rest, [
        Migration(
          version: file.version,
          name: file.name,
          filename: file.filename,
          sql: sql,
        ),
        ..acc
      ])
    }
  }
}

fn ensure_bootstrap_migration_present(
  migrations: List(Migration),
) -> Result(Nil, String) {
  case
    list.find(migrations, fn(migration) {
      migration.version == bootstrap_version
    })
  {
    Ok(_) -> Ok(Nil)
    Error(Nil) ->
      Error("Missing required migration: " <> bootstrap_version <> ".sql")
  }
}

fn bootstrap_schema_migrations_if_needed(
  db: pog.Connection,
  migrations: List(Migration),
) -> Result(Nil, String) {
  use has_schema_migrations <- result.try(schema_migrations_exists(db))

  case has_schema_migrations {
    True -> Ok(Nil)
    False ->
      case
        list.find(migrations, fn(migration) {
          migration.version == bootstrap_version
        })
      {
        Ok(migration) -> apply_migration(db, migration)
        Error(Nil) ->
          Error("Missing required migration: " <> bootstrap_version <> ".sql")
      }
  }
}

fn schema_migrations_exists(db: pog.Connection) -> Result(Bool, String) {
  db_helpers.query(
    db_helpers.new(db),
    #(
      "SELECT to_regclass('public.schema_migrations') IS NOT NULL",
      [],
      bool_decoder(),
    ),
    stringify_query_error,
  )
  |> result.map(fn(returned) {
    case returned.rows {
      [has_table, ..] -> has_table
      [] -> False
    }
  })
}

fn list_applied_versions(db: pog.Connection) -> Result(List(String), String) {
  db_helpers.query(
    db_helpers.new(db),
    #(
      "SELECT version FROM schema_migrations ORDER BY version",
      [],
      version_decoder(),
    ),
    stringify_query_error,
  )
  |> result.map(fn(returned) { returned.rows })
}

fn list_applied_seed_versions(
  db: pog.Connection,
) -> Result(List(String), String) {
  db_helpers.query(
    db_helpers.new(db),
    #(
      "SELECT version FROM schema_seeds ORDER BY version",
      [],
      version_decoder(),
    ),
    stringify_query_error,
  )
  |> result.map(fn(returned) { returned.rows })
}

fn pending_migrations(
  migrations: List(Migration),
  applied_versions: List(String),
) -> List(Migration) {
  list.filter(migrations, fn(migration) {
    !list.contains(applied_versions, migration.version)
  })
}

fn apply_migrations(
  migrations: List(Migration),
  db: pog.Connection,
  acc: List(String),
) -> Result(List(String), String) {
  case migrations {
    [] -> Ok(acc)
    [migration, ..rest] -> {
      use _ <- result.try(apply_migration(db, migration))
      apply_migrations(rest, db, [migration.version, ..acc])
    }
  }
}

fn apply_migration(
  db: pog.Connection,
  migration: Migration,
) -> Result(Nil, String) {
  startup_transaction.run(db, fn() { run_migration(db, migration) })
  |> result.map_error(fn(err) {
    "Migration transaction failed for " <> migration.filename <> ": " <> err
  })
}

fn run_migration(
  db: pog.Connection,
  migration: Migration,
) -> Result(Nil, String) {
  let tx_db = db_helpers.new(db)
  let statements = statements_from_sql(migration.sql)

  use _ <- result.try(
    result.map_error(configure_statement_timeout(db), fn(err) {
      "Failed to configure statement timeout for "
      <> migration.filename
      <> ": "
      <> string.inspect(err)
    }),
  )
  use _ <- result.try(execute_statements(tx_db, migration.filename, statements))
  db_helpers.execute(
    tx_db,
    #("INSERT INTO schema_migrations (version, name) VALUES ($1, $2)", [
      dev.ParamString(migration.version),
      dev.ParamString(migration.name),
    ]),
    fn(err) {
      "Failed to record applied migration "
      <> migration.version
      <> "_"
      <> migration.name
      <> ": "
      <> string.inspect(err)
    },
  )
  |> result.map(fn(_) { Nil })
}

fn apply_seeds(
  seeds: List(Migration),
  db: pog.Connection,
  acc: List(String),
) -> Result(List(String), String) {
  case seeds {
    [] -> Ok(acc)
    [seed, ..rest] -> {
      use _ <- result.try(apply_seed(db, seed))
      apply_seeds(rest, db, [seed.version, ..acc])
    }
  }
}

fn apply_seed(db: pog.Connection, seed: Migration) -> Result(Nil, String) {
  startup_transaction.run(db, fn() { run_seed(db, seed) })
  |> result.map_error(fn(err) {
    "Seed transaction failed for " <> seed.filename <> ": " <> err
  })
}

fn run_seed(db: pog.Connection, seed: Migration) -> Result(Nil, String) {
  let tx_db = db_helpers.new(db)
  let statements = statements_from_sql(seed.sql)

  use _ <- result.try(
    result.map_error(configure_statement_timeout(db), fn(err) {
      "Failed to configure statement timeout for seed "
      <> seed.filename
      <> ": "
      <> string.inspect(err)
    }),
  )
  use _ <- result.try(execute_statements(tx_db, seed.filename, statements))
  db_helpers.execute(
    tx_db,
    #("INSERT INTO schema_seeds (version, name) VALUES ($1, $2)", [
      dev.ParamString(seed.version),
      dev.ParamString(seed.name),
    ]),
    fn(err) {
      "Failed to record applied seed "
      <> seed.version
      <> "_"
      <> seed.name
      <> ": "
      <> string.inspect(err)
    },
  )
  |> result.map(fn(_) { Nil })
}

fn execute_statements(
  db: db_helpers.Db,
  filename: String,
  statements: List(String),
) -> Result(Nil, String) {
  case statements {
    [] -> Ok(Nil)
    [statement, ..rest] -> {
      use _ <- result.try(
        db_helpers.execute(db, #(statement, []), fn(err) {
          "Failed to execute " <> filename <> ": " <> string.inspect(err)
        })
        |> result.map(fn(_) { Nil }),
      )
      execute_statements(db, filename, rest)
    }
  }
}

fn configure_statement_timeout(
  tx: pog.Connection,
) -> Result(Nil, pog.QueryError) {
  pog.query(
    "set local statement_timeout = "
    <> int.to_string(migration_statement_timeout_ms),
  )
  |> pog.execute(tx)
  |> result.map(fn(_) { Nil })
}

fn bool_decoder() -> decode.Decoder(Bool) {
  use value <- decode.field(0, decode.bool)
  decode.success(value)
}

fn version_decoder() -> decode.Decoder(String) {
  use value <- decode.field(0, decode.string)
  decode.success(value)
}

fn stringify_query_error(err: pog.QueryError) -> String {
  string.inspect(err)
}

fn statements_from_sql(sql: String) -> List(String) {
  sql
  |> remove_comment_only_lines()
  |> string.split(";")
  |> list.map(string.trim)
  |> list.filter(fn(statement) { statement != "" })
}

fn remove_comment_only_lines(sql: String) -> String {
  sql
  |> string.split("\n")
  |> list.filter(fn(line) {
    let trimmed = string.trim(line)
    trimmed == "" || !string.starts_with(trimmed, "--")
  })
  |> string.join(with: "\n")
}

fn list_sql_filenames(directory: String) -> Result(List(String), String) {
  file_system.list_dir(directory)
  |> result.map(fn(filenames) {
    filenames
    |> list.filter(fn(filename) { string.ends_with(filename, ".sql") })
    |> list.sort(by: fn(left, right) { string.compare(left, right) })
  })
}

fn migration_path(migrations_dir: String, filename: String) -> String {
  migrations_dir <> "/" <> filename
}
