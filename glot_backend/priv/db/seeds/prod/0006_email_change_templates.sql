INSERT INTO email_templates (
  name, subject_template, text_body_template, html_body_template, updated_at
) VALUES
  (
    'email_change_verification',
    'Verify your new email address',
    'Your email change verification code is: {{token}}',
    NULL,
    NOW()
  ),
  (
    'email_changed',
    'Your email address was changed',
  'Your glot account email address was changed to {{new_email}}.',
    NULL,
    NOW()
  )
ON CONFLICT (name) DO UPDATE SET
  subject_template = EXCLUDED.subject_template,
  text_body_template = EXCLUDED.text_body_template,
  html_body_template = EXCLUDED.html_body_template,
  updated_at = EXCLUDED.updated_at;
