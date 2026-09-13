"""Real PostgreSQL acceptance checks in a disposable schema.

Run: python3 test/spam_classifier_postgres.py
Uses the repository SQL sources and migrations, never production table data.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
DATABASE = os.environ.get("GLOT_TEST_DATABASE_URL", "postgresql://glot:glot@localhost:5432/glot")
SCHEMA = "spam_test_" + uuid.uuid4().hex
VERSION = "local-v1"
REVISION = "2026-01-01 00:00:00+00"
QUERIES = {}
for path in [ROOT / "src/glot_backend/spam_classifier/sql/fingerprints.sql", ROOT / "src/glot_backend/snippet/sql/snippets.sql", ROOT / "src/glot_backend/analytics/sql/analytics_metrics.sql"]:
    for name, body in re.findall(r"-- name: (\w+) :\w+\n(.*?)(?=\n-- name:|\Z)", path.read_text(), re.S):
        QUERIES[name] = body.strip().rstrip(";")


# Verify regenerated bindings preserve the statements exercised below.
generated = (ROOT / "src/glot_backend/sql.gleam").read_text()
for query_name, function_name in [
    ("GetClassifierIndexCursor", "get_classifier_index_cursor"),
    ("ListClassifierIndexBatch", "list_classifier_index_batch"),
    ("CommitClassifierIndexBatch", "commit_classifier_index_batch"),
]:
    parameters = {}
    def parameter(match):
        name = match[1]
        return "$" + str(parameters.setdefault(name, len(parameters) + 1))
    expected = re.sub(r"sqlc.n?arg\((\w+)\)", parameter, QUERIES[query_name])
    actual = re.search(r"pub fn " + function_name + r"\([\s\S]*?let sql =\s*\"([\s\S]*?)\"\s*#", generated)[1]
    assert " ".join(expected.split()) == " ".join(actual.split()), query_name


def literal(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "ARRAY[" + ",".join(map(literal, value)) + "]"
    return "'" + str(value).replace("'", "''") + "'"


def query(name, args):
    sql = QUERIES[name]
    if name == "ListClassifierIndexBatch":
        args = {"after_snippet_id": None, **args}
    if isinstance(args, dict):
        return re.sub(r"sqlc.n?arg\((\w+)\)", lambda m: literal(args[m[1]]), sql)
    return re.sub(r"\$(\d+)", lambda m: literal(args[int(m[1]) - 1]), sql)


def run(sql):
    result = subprocess.run(["psql", DATABASE, "-XAtq", "-v", "ON_ERROR_STOP=1"],
                            input=f"SET search_path TO {SCHEMA},pg_catalog;\n{sql};\n",
                            text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def rows(name, args):
    return json.loads(run("SELECT coalesce(json_agg(q), '[]'::json) FROM (" + query(name, args) + ") q"))


def identifier(number):
    return str(uuid.UUID(int=number))


def fingerprint(number, revision=REVISION, bands=16):
    return query("StoreClassifierFingerprint", dict(
        snippet_id=identifier(number), content_revision=revision, algorithm_version=VERSION,
        token_count=25, trigram_hashes=[1, 2, 3], signature=[1] * 64,
        independently_suspicious=True, urls='["example.com"]',
        bands=[f"{n}:same" if n < bands else f"{n}:different" for n in range(16)]))


def cursor(version=VERSION):
    output = run(query("GetClassifierIndexCursor", dict(algorithm_version=version)))
    after_id, generation = output.split("|")
    return dict(after_snippet_id=after_id or None, generation=int(generation))


def index_metrics(version=VERSION):
    return rows("GetFingerprintIndexMetrics", dict(algorithm_version=version))[0]


def index_batch(version=VERSION):
    state = cursor(version)
    return state, rows("ListClassifierIndexBatch", dict(
        algorithm_version=version, after_snippet_id=state["after_snippet_id"]))


def batch_entry(row):
    return dict(snippet_id=row["id"], content_revision=row["updated_at"],
        token_count=25, trigram_hashes=[1, 2, 3], signature=[1] * 64,
        independently_suspicious=True, urls=["example.com"],
        bands=[f"{n}:same" for n in range(16)])


def batch_commit_sql(state, batch, version=VERSION, entries=None):
    return query("CommitClassifierIndexBatch", dict(
        algorithm_version=version, expected_generation=state["generation"],
        after_snippet_id=batch[-1]["id"] if len(batch) == 100 else None,
        fingerprints=json.dumps(entries if entries is not None else list(map(batch_entry, batch)))))


def candidates(exclude=999):
    return rows("FindClassifierNeighbors", dict(algorithm_version=VERSION,
        bands=[f"{n}:same" for n in range(16)], snippet_id=identifier(exclude)))


def concurrency_check(sql, expected, lock_sql=None):
    """Ensure the tested write waits for a concurrent edit or cursor change."""
    lock_sql = lock_sql or f"UPDATE snippets SET updated_at=updated_at+interval '1 second' WHERE id='{identifier(1)}'"
    holder = subprocess.Popen(["psql", DATABASE, "-XAtq", "-v", "ON_ERROR_STOP=1"],
                              stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    waiter = None
    try:
        holder.stdin.write(f"SET search_path TO {SCHEMA},pg_catalog; BEGIN; {lock_sql};\n\\echo locked\n")
        holder.stdin.flush()
        assert holder.stdout.readline().strip() == "locked"
        env = dict(os.environ, PGAPPNAME=SCHEMA + "_waiter")
        waiter = subprocess.Popen(["psql", DATABASE, "-XAtq", "-v", "ON_ERROR_STOP=1", "-c",
            f"SET search_path TO {SCHEMA},pg_catalog; {sql};"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            waiting = run(f"SELECT count(*) FROM pg_stat_activity WHERE application_name='{SCHEMA}_waiter' AND wait_event_type='Lock'")
            if waiting == "1":
                break
            assert waiter.poll() is None, "write finished before waiting for the edit"
            time.sleep(0.02)
        else:
            raise AssertionError("write did not wait for the held revision lock")
        holder.stdin.write("COMMIT;\n\\q\n")
        holder.stdin.flush()
        holder.communicate(timeout=5)
        stdout, stderr = waiter.communicate(timeout=5)
        assert waiter.returncode == 0, stderr
        assert stdout.strip() == expected, stdout
    finally:
        for process in [holder, waiter]:
            if process is not None and process.poll() is None:
                process.kill()
                process.communicate()


try:
    run(f"CREATE SCHEMA {SCHEMA}")
    migrations = sorted((ROOT / "priv/db/migrations").glob("*.sql"))
    for migration in migrations:
        if migration.name.startswith("0008_"):
            break
        run(migration.read_text())
    run(f"""
      INSERT INTO accounts VALUES ('{identifier(1000)}','active',NULL,'free',NULL,NOW(),NOW());
      INSERT INTO users VALUES ('{identifier(1000)}','{identifier(1000)}','fixture@example.test','fixture','user',NOW(),NOW(),NOW());
      INSERT INTO snippets(id,slug,user_id,language,title,visibility,stdin,files,created_at,updated_at,spam_decision,spam_confidence,spam_reason_code,spam_classified_at,is_runnable)
      SELECT ('00000000-0000-0000-0000-' || lpad(to_hex(n),12,'0'))::uuid,
        'fixture-'||n, '{identifier(1000)}', 'python', 'Buy now contact me https://example.com',
        CASE n%3 WHEN 0 THEN 'secret' WHEN 1 THEN 'public' ELSE 'unlisted' END,
        '', '[{{"name":"main.py","content":"print(1)"}}]', '{REVISION}', '{REVISION}', 'block',75,'promotional_content','{REVISION}',true
      FROM generate_series(1,205) n
    """)
    run((ROOT / "priv/db/migrations/0008_local_spam_classifier.sql").read_text())
    run((ROOT / "priv/db/migrations/0009_spam_classifier_index_cursor.sql").read_text())
    assert run("SELECT count(*) FROM snippets WHERE spam_decision='block' AND spam_confidence=75 AND spam_explanation IS NULL") == "205"

    assert index_metrics() == dict(total=205, indexed=0)

    # Reading/computing without committing cannot skip any snippets after restart.
    state, first = index_batch()
    assert len(first) == 100
    assert index_batch() == (state, first)
    # A failed batch rolls back both all fingerprint writes and the cursor.
    invalid = list(map(batch_entry, first))
    invalid[-1]["signature"] = [1]
    try:
        run(batch_commit_sql(state, first, entries=invalid))
        raise AssertionError("invalid batch unexpectedly committed")
    except RuntimeError as err:
        assert "check constraint" in str(err)
    assert cursor() == state
    assert run("SELECT count(*) FROM spam_classifier_fingerprints") == "0"
    assert run(batch_commit_sql(state, first)) == "t|100"
    assert index_metrics() == dict(total=205, indexed=100)
    resumed_state, resumed = index_batch()
    assert resumed_state["generation"] == state["generation"] + 1
    assert resumed[0]["id"] == identifier(101)
    # Replaying a completed generation neither rewrites fingerprints nor rewinds.
    assert run(batch_commit_sql(state, first)) == "f|0"
    assert cursor() == resumed_state
    assert run(batch_commit_sql(resumed_state, resumed)) == "t|100"
    final_state, final = index_batch()
    assert len(final) == 5
    assert run(batch_commit_sql(final_state, final)) == "t|5"
    assert cursor()["after_snippet_id"] is None
    assert index_metrics() == dict(total=205, indexed=205)
    assert index_metrics("unbuilt-version") == dict(total=205, indexed=0)
    empty_state, empty = index_batch()
    assert empty == []
    assert run(batch_commit_sql(empty_state, empty)) == "t|0"
    # A separate algorithm starts its own scan independently.
    other_state, other = index_batch("test-next-version")
    assert other_state == dict(after_snippet_id=None, generation=0)
    assert len(other) == 100
    assert run("SELECT count(*) FROM snippets WHERE spam_decision='block' AND spam_confidence=75 AND spam_explanation IS NULL") == "205"
    assert run("SELECT count(*) FROM spam_classifier_bands") == str(205 * 16)
    found = candidates(205)
    assert len(found) == 200
    assert found[0]["snippet_id"] == identifier(204)
    assert identifier(205) not in [row["snippet_id"] for row in found]
    assert {row["visibility"] for row in first} == {"public", "unlisted", "secret"}

    # Edit behind a saved cursor: skip it during this pass, then reconcile it.
    run(f"UPDATE spam_classifier_index_progress SET after_snippet_id='{identifier(100)}' WHERE algorithm_version='{VERSION}'")
    run(f"DELETE FROM spam_classifier_bands WHERE snippet_id='{identifier(3)}'")
    run(f"DELETE FROM spam_classifier_fingerprints WHERE snippet_id='{identifier(3)}'")
    tail_state, tail = index_batch()
    assert tail == []
    assert run(batch_commit_sql(tail_state, tail)) == "t|0"
    repair_state, repair = index_batch()
    assert [row["id"] for row in repair] == [identifier(3)]
    assert run(batch_commit_sql(repair_state, repair)) == "t|1"

    # The actual public SQL still returns eligible Likely-spam snippets and
    # does not expose explanation/fingerprint metadata.
    run("UPDATE users SET created_at='2025-01-01'")
    visible = rows("ListSnippetsAfter", dict(visibilities=["public"], usernames=[], languages=[], user_ids=[], skip_user_ids=[], account_states=["active"], user_created_before="2026-01-01", excluded_titles=["untitled", "hello world"], excluded_languages=["plaintext"], is_runnable=True, after_slug=None, page_limit=300))
    assert len(visible) == 69
    assert all(row["visibility"] == "public" and "spam_explanation" not in row for row in visible)
    assert rows("GetSnippetBySlug", ["fixture-1"])[0]["title"].startswith("Buy now")

    # Band count outranks recency; ties then use revision and ID.
    assert run(fingerprint(205, bands=1)) == "t"
    assert candidates()[0]["snippet_id"] == identifier(204)
    run(f"UPDATE snippets SET updated_at=updated_at+interval '1 second' WHERE id='{identifier(1)}'")
    assert run(fingerprint(1)) == "f"
    assert index_metrics() == dict(total=205, indexed=204)
    assert rows("ListClassifierIndexBatch", {"algorithm_version": VERSION})[0]["id"] == identifier(1)
    assert run(fingerprint(1, "2026-01-01 00:00:01+00")) == "t"
    assert index_metrics() == dict(total=205, indexed=205)
    assert candidates()[0]["snippet_id"] == identifier(1)

    # Concurrent edits invalidate both fingerprint and classification writes.
    concurrency_check(fingerprint(1, "2026-01-01 00:00:01+00"), "f")
    assert identifier(1) not in [row["snippet_id"] for row in candidates()]
    update = query("UpdateSpamClassification", ["allow", 99, "none", REVISION, identifier(1), "2026-01-01 00:00:02+00", '{"provider":"local"}'])
    concurrency_check(update + " RETURNING id", "")
    assert run(f"SELECT spam_decision FROM snippets WHERE id='{identifier(1)}'") == "block"

    # Concurrent snippet edits reject stale entries in an otherwise atomic batch.
    batch_state, batch = index_batch()
    assert [row["id"] for row in batch] == [identifier(1)]
    concurrency_check(batch_commit_sql(batch_state, batch), "t|0")
    assert identifier(1) not in [row["snippet_id"] for row in candidates()]
    retry_state, retry = index_batch()
    assert [row["id"] for row in retry] == [identifier(1)]
    assert run(batch_commit_sql(retry_state, retry)) == "t|1"

    # Metadata writes preserve revision/visibility and persist explanation separately.
    explanation = json.dumps(dict(provider="local", version="local-v1", score=75, signals=["promotional_url"], neighbors=[]))
    run(query("UpdateSpamClassification", ["block", 55, "promotional_content", REVISION, identifier(2), REVISION, explanation]))
    assert json.loads(run(f"SELECT spam_explanation FROM snippets WHERE id='{identifier(2)}'"))["score"] == 75
    assert run(f"SELECT visibility FROM snippets WHERE id='{identifier(2)}'") == "unlisted"
    assert run(f"SELECT updated_at='{REVISION}' FROM snippets WHERE id='{identifier(2)}'") == "t"
    run(f"DELETE FROM snippets WHERE id='{identifier(2)}'")
    assert run(f"SELECT count(*) FROM spam_classifier_fingerprints WHERE snippet_id='{identifier(2)}'") == "0"
    assert run(f"SELECT count(*) FROM spam_classifier_bands WHERE snippet_id='{identifier(2)}'") == "0"
    assert index_metrics() == dict(total=204, indexed=204)

    # Mixed current/stale entries commit the other 99 fingerprints and bands.
    race_version = "batch-race-test"
    race_state, race_batch = index_batch(race_version)
    assert len(race_batch) == 100
    concurrency_check(batch_commit_sql(race_state, race_batch, race_version), "t|99")
    assert run(f"SELECT count(*) FROM spam_classifier_fingerprints WHERE algorithm_version='{race_version}'") == "99"
    assert run(f"SELECT count(*) FROM spam_classifier_bands WHERE algorithm_version='{race_version}'") == str(99 * 16)
    assert cursor(race_version)["after_snippet_id"] == race_batch[-1]["id"]
    # Deletion of the cursor snippet preserves the scan position.
    saved_position = race_batch[-1]["id"]
    run(f"DELETE FROM snippets WHERE id='{saved_position}'")
    race_next_state, race_next = index_batch(race_version)
    assert race_next_state["after_snippet_id"] == saved_position
    assert all(row["id"] > saved_position for row in race_next)
    # A competing commit changes generation while this writer waits.
    concurrency_check(batch_commit_sql(race_next_state, race_next, race_version), "f|0",
        f"UPDATE spam_classifier_index_progress SET generation=generation+1 WHERE algorithm_version='{race_version}'")
    assert run(f"SELECT count(*) FROM spam_classifier_fingerprints WHERE algorithm_version='{race_version}'") == "98"
    assert cursor(race_version)["after_snippet_id"] == saved_position
    retry_state, retry = index_batch(race_version)
    assert run(batch_commit_sql(retry_state, retry, race_version)) == f"t|{len(retry)}"
    # Runnability metrics distinguish completed negative results from failures,
    # retries and untouched candidates, across all existing visibility categories.
    run(f"UPDATE snippets SET is_runnable=true, runnability_checked_at='{REVISION}', runnability_check_attempts=1, runnability_check_failed_at=NULL")
    run(f"UPDATE snippets SET is_runnable=false WHERE id IN ('{identifier(1)}','{identifier(6)}')")
    run(f"UPDATE snippets SET is_runnable=NULL, runnability_checked_at=NULL, runnability_check_attempts=2 WHERE id='{identifier(3)}'")
    run(f"UPDATE snippets SET is_runnable=NULL, runnability_checked_at=NULL, runnability_check_attempts=3, runnability_check_failed_at='{REVISION}' WHERE id='{identifier(4)}'")
    run(f"UPDATE snippets SET is_runnable=NULL, runnability_checked_at=NULL, runnability_check_attempts=0 WHERE id='{identifier(5)}'")
    total = int(run("SELECT count(*) FROM snippets"))
    metrics = rows("GetRunnabilityOperationalMetrics", {})[0]
    assert {key: metrics[key] for key in ["total", "checked", "runnable", "not_runnable", "backlog", "failed", "attempts", "attempted_backlog"]} == dict(total=total, checked=total-3, runnable=total-5, not_runnable=2, backlog=2, failed=1, attempts=total+2, attempted_backlog=1)
    assert metrics["latest_checked_at"] is not None and metrics["latest_failed_at"] is not None
    assert metrics["oldest_unchecked_at_seconds"] > 0
    assert not metrics["scheduled"] and not metrics["enabled"]
    run(f"INSERT INTO periodic_jobs(id,job_type,interval_seconds,enabled,next_run_at,created_at,updated_at) VALUES ('{identifier(2000)}','check_snippet_runnability',60,false,NOW(),NOW(),NOW())")
    for number, job_type, status in [(2001, "check_snippet_runnability", "running"), (2002, "check_snippet_runnability", "pending"), (2003, "classify_snippet", "running")]:
        run(f"INSERT INTO jobs(id,job_type,status,max_attempts,timeout_seconds,base_backoff_seconds,max_backoff_seconds,run_at,created_at,updated_at,queue_name) VALUES ('{identifier(number)}','{job_type}','{status}',10,600,30,900,NOW(),NOW(),NOW(),'snippet_runnability')")
    metrics = rows("GetRunnabilityOperationalMetrics", {})[0]
    assert metrics["scheduled"] and not metrics["enabled"]
    assert metrics["pending_jobs"] == 1 and metrics["running_jobs"] == 1
    run("UPDATE periodic_jobs SET enabled=true WHERE job_type='check_snippet_runnability'")
    assert rows("GetRunnabilityOperationalMetrics", {})[0]["enabled"]
    run("DELETE FROM snippets")
    empty_metrics = rows("GetRunnabilityOperationalMetrics", {})[0]
    assert empty_metrics["total"] == 0 and empty_metrics["checked"] == 0 and empty_metrics["attempts"] == 0
    assert empty_metrics["latest_checked_at"] is None and empty_metrics["latest_failed_at"] is None
    assert empty_metrics["oldest_unchecked_at_seconds"] == 0
    print("PostgreSQL acceptance passed: upgrade, cursor resume/wraparound, atomic batch rollback, generation replay guard, version isolation, visibility coverage, candidate bounds/order, edits, concurrent stale batch/classification writes, explanations, cascade deletion")
finally:
    run(f"DROP SCHEMA IF EXISTS {SCHEMA} CASCADE")
