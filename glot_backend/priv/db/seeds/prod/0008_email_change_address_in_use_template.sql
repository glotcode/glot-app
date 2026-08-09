INSERT INTO email_templates (
  name, subject_template, text_body_template, html_body_template, updated_at
) VALUES (
  'email_change_address_in_use',
  'Email address already in use',
  'This email address is already associated with a glot account, so the requested email change was not completed. Please choose a different email address.',
  NULL,
  NOW()
)
ON CONFLICT (name) DO UPDATE SET
  subject_template = EXCLUDED.subject_template,
  text_body_template = EXCLUDED.text_body_template,
  html_body_template = EXCLUDED.html_body_template,
  updated_at = EXCLUDED.updated_at;
