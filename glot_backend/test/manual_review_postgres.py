"""Spam review acceptance checks against actual repository SQL in a disposable schema.
Run: python3 test/manual_review_postgres.py
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
SCHEMA = "review_test_" + uuid.uuid4().hex
REVISION = "2026-01-01 00:00:00+00"
QUERIES = {}
for path in (ROOT / "src/glot_backend/snippet/sql").glob("*.sql"):
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

def queue(**filters):
    defaults = dict(decision="flagged", reason=None, confidence_min=None, confidence_max=None,
                    manual="unreviewed", username=None, language=None, cursor=None,
                    backwards=False, inclusive=False, focus=None, page_limit=2)
    return rows("ListSpamReview", {**defaults, **filters})


def slugs(**filters):
    return [row["slug"] for row in queue(**filters)]


def save(slug="f", verdict="spam", version=0, revision=REVISION, reviewer=1000):
    return query("SaveManualReview", [slug, verdict, identifier(reviewer), REVISION, version, revision])


try:
    run(f"CREATE SCHEMA {SCHEMA}")
    for migration in sorted((ROOT / "priv/db/migrations").glob("*.sql")):
        if not migration.name.startswith("0010_"):
            run(migration.read_text())
    run(f"""
      INSERT INTO accounts VALUES ('{identifier(1000)}','active',NULL,'free',NULL,NOW(),NOW());
      INSERT INTO users VALUES ('{identifier(1000)}','{identifier(1000)}','fixture@example.test','fixture','admin',NOW(),NOW(),NOW());
      INSERT INTO snippets(id,slug,user_id,language,title,visibility,stdin,files,created_at,updated_at,spam_decision,spam_confidence,spam_reason_code)
      SELECT ('00000000-0000-0000-0000-' || lpad(to_hex(n),12,'0'))::uuid,
        chr(96+n), '{identifier(1000)}', CASE n WHEN 5 THEN 'javascript' ELSE 'python' END,
        'Review fixture', CASE n%3 WHEN 0 THEN 'secret' WHEN 1 THEN 'public' ELSE 'unlisted' END,
        'stdin', '[{{"name":"one.py","content":"<script>alert(1)</script>"}},{{"name":"two.py","content":"print(2)"}}]',
        '{REVISION}', '{REVISION}', CASE n WHEN 1 THEN NULL WHEN 2 THEN 'allow' WHEN 3 THEN 'review' ELSE 'block' END,
        CASE n WHEN 1 THEN NULL WHEN 2 THEN 0 WHEN 3 THEN 50 WHEN 4 THEN 100 WHEN 5 THEN NULL ELSE 75 END,
        CASE n WHEN 1 THEN NULL WHEN 3 THEN 'ambiguous' ELSE 'link_spam' END
      FROM generate_series(1,6) n
    """)
    run((ROOT / "priv/db/migrations/0010_snippet_manual_review.sql").read_text())
    assert run("SELECT count(*) FROM snippets WHERE manual_verdict IS NULL AND manual_review_version=0 AND manual_reviewer_id IS NULL AND manual_reviewed_at IS NULL") == "6"
    assert slugs() == ["f", "e"]
    assert slugs(cursor="f") == ["e", "d"]
    assert slugs(cursor="c", backwards=True) == ["d", "e"]  # Adapter reverses before pagination.
    assert slugs(decision="all", cursor="a", backwards=True, inclusive=True, page_limit=1) == ["a"]
    assert slugs(decision="all", page_limit=10) == list("fedcba")
    assert slugs(decision="unclassified") == ["a"]
    assert slugs(decision="review") == ["c"]
    assert slugs(decision="allow", confidence_min=0, confidence_max=0) == ["b"]
    assert slugs(confidence_min=100, confidence_max=100) == ["d"]
    assert slugs(confidence_min=0, page_limit=10) == ["f", "d", "c"]
    assert slugs(confidence_max=100, page_limit=10) == ["f", "d", "c"]
    assert slugs(reason="link_spam", confidence_min=75, confidence_max=100, username="fixture", language="python") == ["f", "d"]
    assert slugs(username="fixt") == []
    assert slugs(language="javascript") == ["e"]
    assert slugs(reason="ambiguous") == ["c"]
    assert slugs(focus="c") == ["c"]
    before = run("SELECT visibility || ':' || spam_decision || ':' || spam_confidence FROM snippets WHERE slug='f'")
    assert run(save()).endswith("|1")
    assert slugs() == ["e", "d"]
    assert slugs(manual="spam") == ["f"]
    assert run(save()) == ""  # Duplicate/concurrent reviewer version.
    assert run(save(version=1, revision="2025-01-01 00:00:00+00")) == ""
    assert run(save(verdict="not_spam", version=1, reviewer=2000)).endswith("|2")
    assert slugs(manual="not_spam") == ["f"]
    assert run(save(verdict=None, version=2)).endswith("|3")
    assert slugs() == ["f", "e"]
    # Undo restores the previous verdict with the undoing admin and a fresh version.
    assert run(save(verdict="not_spam", version=3, reviewer=2000)).endswith("|4")
    assert run("SELECT manual_reviewer_id FROM snippets WHERE slug='f'") == identifier(2000)
    assert run("SELECT visibility || ':' || spam_decision || ':' || spam_confidence FROM snippets WHERE slug='f'") == before
    assert run("SELECT manual_reviewed_at IS NOT NULL FROM snippets WHERE slug='f'") == "t"
    run(query("UpdateSnippet", ["f", identifier(1000), "python", "Edited", "secret", "changed", None, '[{"name":"changed.py","content":"print(3)"}]', REVISION, "2026-01-02 00:00:00+00", identifier(6)]))
    assert run("SELECT manual_verdict || ':' || manual_review_version FROM snippets WHERE slug='f'") == "not_spam:4"
    # Actual automated reclassification query preserves the independent manual verdict.
    run(query("UpdateSpamClassification", ["allow", 10, "none", REVISION, identifier(6), "2026-01-02 00:00:00+00", None]))
    assert run("SELECT manual_verdict || ':' || manual_review_version FROM snippets WHERE slug='f'") == "not_spam:4"
    run("UPDATE snippets SET spam_decision=NULL WHERE slug='f'")
    run(query("StoreSpamClassification", ["block", 90, "link_spam", REVISION, identifier(6), "2026-01-02 00:00:00+00", None]))
    assert run("SELECT manual_verdict || ':' || manual_review_version || ':' || spam_decision FROM snippets WHERE slug='f'") == "not_spam:4:block"
    # A blocked writer rechecks both guards after the competing transaction commits.
    concurrency_check(save(slug="c"), "", "UPDATE snippets SET manual_review_version=manual_review_version+1 WHERE slug='c'")
    concurrency_check(save(slug="d"), "", "UPDATE snippets SET updated_at=updated_at+interval '1 second' WHERE slug='d'")
    print("Manual review PostgreSQL checks passed: filters, cursors, save/clear/undo, visibility, edit/reclassification persistence, concurrent review and edit guards.")
finally:
    run(f"DROP SCHEMA IF EXISTS {SCHEMA} CASCADE")
