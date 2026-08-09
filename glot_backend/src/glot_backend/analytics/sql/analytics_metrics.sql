-- name: GetMaxCompletedMetricsDay :one
SELECT day
FROM metrics_completed_day
ORDER BY day DESC
LIMIT 1;

-- name: GetFirstMetricsSourceDay :one
SELECT day
FROM (
  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', pageview_log.created_at AT TIME ZONE 'UTC')::date AS day
    FROM pageview_log
    WHERE DATE_TRUNC('day', pageview_log.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS pageview_source_day

  UNION ALL

  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', sessions.created_at AT TIME ZONE 'UTC')::date AS day
    FROM sessions
    WHERE DATE_TRUNC('day', sessions.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS sessions_source_day

  UNION ALL

  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', snippets.created_at AT TIME ZONE 'UTC')::date AS day
    FROM snippets
    WHERE DATE_TRUNC('day', snippets.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS snippets_source_day

  UNION ALL

  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', page_log.created_at AT TIME ZONE 'UTC')::date AS day
    FROM page_log
    WHERE DATE_TRUNC('day', page_log.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS page_log_source_day

  UNION ALL

  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', run_log.created_at AT TIME ZONE 'UTC')::date AS day
    FROM run_log
    WHERE DATE_TRUNC('day', run_log.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS run_log_source_day

  UNION ALL

  SELECT day
  FROM (
    SELECT DATE_TRUNC('day', api_log.created_at AT TIME ZONE 'UTC')::date AS day
    FROM api_log
    WHERE DATE_TRUNC('day', api_log.created_at AT TIME ZONE 'UTC')::date < @before_day::date
    ORDER BY day ASC
    LIMIT 1
  ) AS api_log_source_day
) AS source_days
ORDER BY day ASC
LIMIT 1;

-- name: ListMetricsPageviews :many
SELECT day, route, path, views, unique_sessions, unique_users
FROM metrics_pageview_daily
WHERE day >= @start_day::date AND day < @end_day::date
ORDER BY day DESC, views DESC, route ASC, path ASC;

-- name: ListMetricsProductEvents :many
SELECT day, event_name, event_count, unique_sessions, unique_users
FROM metrics_product_event_daily
WHERE day >= @start_day::date AND day < @end_day::date
ORDER BY day DESC, event_count DESC, event_name ASC;

-- name: ListMetricsRuns :many
SELECT
  day,
  language,
  successful_runs,
  failed_runs,
  unique_sessions,
  unique_users
FROM metrics_run_daily
WHERE day >= @start_day::date AND day < @end_day::date
ORDER BY day DESC, successful_runs + failed_runs DESC, language ASC;

-- name: ListMetricsReliability :many
SELECT
  day,
  surface,
  name,
  request_count,
  error_count,
  avg_duration_ns
FROM metrics_reliability_daily
WHERE day >= @start_day::date AND day < @end_day::date
ORDER BY day DESC, request_count DESC, surface ASC, name ASC;

-- name: InsertMetricsPageviewDay :exec
INSERT INTO metrics_pageview_daily (
  day,
  route,
  path,
  views,
  unique_sessions,
  unique_users
)
SELECT
  @day::date AS day,
  route,
  path,
  COUNT(*),
  COUNT(DISTINCT session_id),
  COUNT(DISTINCT user_id)
FROM pageview_log
WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
GROUP BY route, path
ON CONFLICT (day, route, path) DO NOTHING;

-- name: InsertMetricsProductEventDay :exec
INSERT INTO metrics_product_event_daily (
  day,
  event_name,
  event_count,
  unique_sessions,
  unique_users
)
SELECT
  day,
  event_name,
  event_count,
  unique_sessions,
  unique_users
FROM (
  SELECT
    @day::date AS day,
    'login_succeeded' AS event_name,
    COUNT(*) AS event_count,
    COUNT(DISTINCT id) AS unique_sessions,
    COUNT(DISTINCT user_id) AS unique_users
  FROM sessions
  WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
  GROUP BY 1

  UNION ALL

  SELECT
    @day::date AS day,
    'snippet_created' AS event_name,
    COUNT(*) AS event_count,
    0 AS unique_sessions,
    COUNT(DISTINCT user_id) AS unique_users
  FROM snippets
  WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
  GROUP BY 1
) AS derived_events
ON CONFLICT (day, event_name) DO NOTHING;

-- name: InsertMetricsRunDay :exec
INSERT INTO metrics_run_daily (
  day,
  language,
  successful_runs,
  failed_runs,
  unique_sessions,
  unique_users
)
SELECT
  @day::date AS day,
  COALESCE(language, 'unknown'),
  COUNT(*) FILTER (WHERE outcome = 'succeeded'),
  COUNT(*) FILTER (WHERE outcome = 'failed'),
  COUNT(DISTINCT session_id),
  COUNT(DISTINCT user_id)
FROM run_log
WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
GROUP BY COALESCE(language, 'unknown')
ON CONFLICT (day, language) DO NOTHING;

-- name: InsertMetricsReliabilityPageDay :exec
INSERT INTO metrics_reliability_daily (
  day,
  surface,
  name,
  request_count,
  error_count,
  avg_duration_ns
)
SELECT
  @day::date AS day,
  'page',
  route,
  COUNT(*),
  COUNT(*) FILTER (WHERE status_code >= 400),
  COALESCE(AVG(duration_ns)::BIGINT, 0)
FROM page_log
WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
GROUP BY route
ON CONFLICT (day, surface, name) DO NOTHING;

-- name: InsertMetricsReliabilityApiDay :exec
INSERT INTO metrics_reliability_daily (
  day,
  surface,
  name,
  request_count,
  error_count,
  avg_duration_ns
)
SELECT
  @day::date AS day,
  'api',
  action,
  COUNT(*),
  COUNT(*) FILTER (WHERE error IS NOT NULL),
  COALESCE(AVG(duration_ns)::BIGINT, 0)
FROM api_log
WHERE DATE_TRUNC('day', created_at AT TIME ZONE 'UTC')::date = @day::date
GROUP BY action
ON CONFLICT (day, surface, name) DO NOTHING;

-- name: InsertMetricsCompletedDay :exec
INSERT INTO metrics_completed_day (day)
VALUES (@day::date)
ON CONFLICT (day) DO NOTHING;
