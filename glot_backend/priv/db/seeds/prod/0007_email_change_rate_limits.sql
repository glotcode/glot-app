INSERT INTO app_config (namespace, key, value, updated_at)
SELECT namespace, 'begin_email_change', value, NOW()
FROM app_config
WHERE namespace = 'rate_limit' AND key = 'send_login_token'
UNION ALL
SELECT namespace, 'confirm_email_change', value, NOW()
FROM app_config
WHERE namespace = 'rate_limit' AND key = 'login'
ON CONFLICT (namespace, key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = EXCLUDED.updated_at;
