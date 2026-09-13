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
for path in [ROOT / "src/glot_backend/spam_classifier/sql/fingerprints.sql", ROOT / "src/glot_backend/snippet/sql/snippets.sql"]:
    for name, body in re.findall(r"-- name: (\w+) :\w+\n(.*?)(?=\n-- name:|\Z)", path.read_text(), re.S):
        QUERIES[name] = body.strip().rstrip(";")


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


def candidates(exclude=999):
    return rows("FindClassifierNeighbors", dict(algorithm_version=VERSION,
        bands=[f"{n}:same" for n in range(16)], snippet_id=identifier(exclude)))


def concurrency_check(sql, expected):
    """Ensure the tested write waits for a real concurrent snippet edit."""
    holder = subprocess.Popen(["psql", DATABASE, "-XAtq", "-v", "ON_ERROR_STOP=1"],
                              stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    waiter = None
    try:
        holder.stdin.write(f"SET search_path TO {SCHEMA},pg_catalog; BEGIN; UPDATE snippets SET updated_at=updated_at+interval '1 second' WHERE id='{identifier(1)}';\n\\echo locked\n")
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
    assert run("SELECT count(*) FROM snippets WHERE spam_decision='block' AND spam_confidence=75 AND spam_explanation IS NULL") == "205"

    # Durable resume: each completed fingerprint disappears from the next batch.
    first = rows("ListClassifierIndexBatch", {"algorithm_version": VERSION})
    assert len(first) == 100
    for n in range(1, 38):
        assert run(fingerprint(n)) == "t"
    resumed = rows("ListClassifierIndexBatch", {"algorithm_version": VERSION})
    assert resumed[0]["id"] == identifier(38)
    for n in range(38, 206):
        assert run(fingerprint(n)) == "t"
    assert rows("ListClassifierIndexBatch", {"algorithm_version": VERSION}) == []
    assert run("SELECT count(*) FROM snippets WHERE spam_decision='block' AND spam_confidence=75 AND spam_explanation IS NULL") == "205"
    assert run("SELECT count(*) FROM spam_classifier_bands") == str(205 * 16)
    found = candidates(205)
    assert len(found) == 200
    assert found[0]["snippet_id"] == identifier(204)
    assert identifier(205) not in [row["snippet_id"] for row in found]
    assert {row["visibility"] for row in first} == {"public", "unlisted", "secret"}

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
    assert rows("ListClassifierIndexBatch", {"algorithm_version": VERSION})[0]["id"] == identifier(1)
    assert run(fingerprint(1, "2026-01-01 00:00:01+00")) == "t"
    assert candidates()[0]["snippet_id"] == identifier(1)

    # Concurrent edits invalidate both fingerprint and classification writes.
    concurrency_check(fingerprint(1, "2026-01-01 00:00:01+00"), "f")
    assert identifier(1) not in [row["snippet_id"] for row in candidates()]
    update = query("UpdateSpamClassification", ["allow", 99, "none", REVISION, identifier(1), "2026-01-01 00:00:02+00", '{"provider":"local"}'])
    concurrency_check(update + " RETURNING id", "")
    assert run(f"SELECT spam_decision FROM snippets WHERE id='{identifier(1)}'") == "block"

    # Metadata writes preserve revision/visibility and persist explanation separately.
    explanation = json.dumps(dict(provider="local", version="local-v1", score=75, signals=["promotional_url"], neighbors=[]))
    run(query("UpdateSpamClassification", ["block", 55, "promotional_content", REVISION, identifier(2), REVISION, explanation]))
    assert json.loads(run(f"SELECT spam_explanation FROM snippets WHERE id='{identifier(2)}'"))["score"] == 75
    assert run(f"SELECT visibility FROM snippets WHERE id='{identifier(2)}'") == "unlisted"
    assert run(f"SELECT updated_at='{REVISION}' FROM snippets WHERE id='{identifier(2)}'") == "t"
    run(f"DELETE FROM snippets WHERE id='{identifier(2)}'")
    assert run(f"SELECT count(*) FROM spam_classifier_fingerprints WHERE snippet_id='{identifier(2)}'") == "0"
    assert run(f"SELECT count(*) FROM spam_classifier_bands WHERE snippet_id='{identifier(2)}'") == "0"
    print("PostgreSQL acceptance passed: upgrade, resume, visibility coverage, 200-candidate bound, ordering, self exclusion, edits, concurrent stale writes, explanations, cascade deletion")
finally:
    run(f"DROP SCHEMA IF EXISTS {SCHEMA} CASCADE")
