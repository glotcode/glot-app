WITH policy_classes(class, value) AS (
  VALUES
    (
      'default',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 60 },
              { "unit": "day", "max_requests": 2000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 120 },
              { "unit": "day", "max_requests": 5000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 240 },
              { "unit": "day", "max_requests": 10000 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'pageview',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 1000 },
              { "unit": "day", "max_requests": 100000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 2000 },
              { "unit": "day", "max_requests": 250000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 5000 },
              { "unit": "day", "max_requests": 1000000 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'run',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 5 },
              { "unit": "day", "max_requests": 100 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 20 },
              { "unit": "day", "max_requests": 500 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 60 },
              { "unit": "day", "max_requests": 2000 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'create_snippet',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 2 },
              { "unit": "day", "max_requests": 5 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 5 },
              { "unit": "day", "max_requests": 20 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 10 },
              { "unit": "day", "max_requests": 100 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'get_snippet',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 300 },
              { "unit": "day", "max_requests": 50000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 600 },
              { "unit": "day", "max_requests": 100000 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 1200 },
              { "unit": "day", "max_requests": 250000 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'authentication',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 10 },
              { "unit": "day", "max_requests": 100 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 20 },
              { "unit": "day", "max_requests": 200 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 20 },
              { "unit": "day", "max_requests": 200 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'login_email',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "minute", "max_requests": 3 },
              { "unit": "hour", "max_requests": 10 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 3 },
              { "unit": "hour", "max_requests": 10 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "minute", "max_requests": 3 },
              { "unit": "hour", "max_requests": 10 }
            ]
          }
        ]
      }'::JSONB
    ),
    (
      'contact_email',
      '{
        "rules": [
          {
            "match": { "actor": "anonymous" },
            "limits": [
              { "unit": "hour", "max_requests": 2 },
              { "unit": "day", "max_requests": 5 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free"]
            },
            "limits": [
              { "unit": "hour", "max_requests": 5 },
              { "unit": "day", "max_requests": 10 }
            ]
          },
          {
            "match": {
              "actor": "authenticated",
              "account_tiers": ["free_plus"]
            },
            "limits": [
              { "unit": "hour", "max_requests": 5 },
              { "unit": "day", "max_requests": 10 }
            ]
          }
        ]
      }'::JSONB
    )
),
action_policies(key, class) AS (
  VALUES
    ('track_pageview', 'pageview'),
    ('run', 'run'),
    ('get_language_version', 'default'),
    ('get_session', 'default'),
    ('refresh_session', 'default'),
    ('logout', 'default'),
    ('get_account', 'default'),
    ('list_account_sessions', 'default'),
    ('list_account_passkeys', 'default'),
    ('update_account', 'default'),
    ('delete_account_session', 'default'),
    ('delete_account_passkey', 'default'),
    ('schedule_delete_account', 'default'),
    ('cancel_delete_account', 'default'),
    ('get_snippet', 'get_snippet'),
    ('list_public_snippets', 'default'),
    ('list_session_snippets', 'default'),
    ('create_snippet', 'create_snippet'),
    ('update_snippet', 'default'),
    ('delete_snippet', 'default'),
    ('submit_contact', 'contact_email'),
    ('send_login_token', 'login_email'),
    ('login', 'authentication'),
    ('begin_passkey_registration', 'default'),
    ('finish_passkey_registration', 'default'),
    ('begin_passkey_login', 'authentication'),
    ('finish_passkey_login', 'authentication')
)
INSERT INTO app_config (
  namespace,
  key,
  value,
  updated_at
)
SELECT
  'rate_limit',
  action_policies.key,
  policy_classes.value,
  NOW()
FROM action_policies
JOIN policy_classes USING (class)
ON CONFLICT (namespace, key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = EXCLUDED.updated_at;
