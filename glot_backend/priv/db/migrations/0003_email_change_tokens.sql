CREATE TABLE email_change_tokens (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  old_email TEXT NOT NULL,
  new_email TEXT NOT NULL,
  token TEXT NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ NULL
);

CREATE INDEX idx_email_change_tokens_user_id
  ON email_change_tokens(user_id);

CREATE INDEX idx_email_change_tokens_used_at
  ON email_change_tokens(used_at);
