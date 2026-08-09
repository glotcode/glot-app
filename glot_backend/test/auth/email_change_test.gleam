import gleam/dict
import gleam/list
import gleam/option
import gleam/regexp
import glot_backend/auth/domain/email_change/begin
import glot_backend/auth/domain/email_change/confirm
import glot_backend/auth/error as auth_error
import glot_backend/system/effect/error
import glot_backend/system/request/hydrated_context as request_context
import glot_core/auth/email_change_dto
import glot_core/auth/email_change_token_model
import glot_core/auth/login_token_model
import glot_core/auth/user_model
import glot_core/email/email_address_model
import support/integration/fixture
import support/integration/model
import support/integration/profile/auth as runner
import support/integration/store/common
import youid/uuid

pub fn verified_email_change_updates_identity_and_invalidates_login_tokens_test() {
  let email_change_token_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000702")
  let begin_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000701")
  let verification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000703")
  let notification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000705")
  let confirm_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000704")
  let base =
    fixture.integration_fixture(
      next_uuids: [
        begin_action_id,
        email_change_token_id,
        verification_job_id,
        confirm_action_id,
        notification_job_id,
      ],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let new_email = email("new@example.com")
  let old_token = login_token(base.user.email, "old-token")
  let new_token = login_token(new_email, "new-token")
  let state =
    model.TestState(
      ..base.state,
      login_tokens: dict.from_list([
        #(common.uuid_key(old_token.id), old_token),
        #(common.uuid_key(new_token.id), new_token),
      ]),
    )
  let ctx = base.ctx
  let request_ctx = request_context.new(ctx, state.dynamic_config)

  let #(begin_result, begun_state) =
    runner.run_test_program(
      begin.begin_email_change(
        request_ctx,
        email_change_dto.BeginEmailChangeRequest(email: new_email),
      ),
      ctx,
      state,
    )
  assert begin_result == Ok(Nil)

  let #(confirm_result, changed_state) =
    runner.run_test_program(
      confirm.confirm_email_change(
        request_context.new(ctx, begun_state.dynamic_config),
        email_change_dto.ConfirmEmailChangeRequest(token: "random"),
      ),
      ctx,
      begun_state,
    )
  let assert Ok(account) = confirm_result
  assert account.email == new_email
  let assert Ok(updated_user) =
    dict.get(changed_state.users, common.uuid_key(base.user.id))
  assert updated_user.email == new_email
  let assert Ok(updated_old_token) =
    dict.get(changed_state.login_tokens, common.uuid_key(old_token.id))
  let assert Ok(updated_new_token) =
    dict.get(changed_state.login_tokens, common.uuid_key(new_token.id))
  assert updated_old_token.used_at == option.Some(ctx.timestamp)
  assert updated_new_token.used_at == option.Some(ctx.timestamp)
  assert dict.size(changed_state.jobs) == 2
}

pub fn invalid_email_change_code_is_counted_without_changing_email_test() {
  let email_change_token_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000712")
  let begin_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000711")
  let verification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000713")
  let notification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000715")
  let confirm_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000714")
  let base =
    fixture.integration_fixture(
      next_uuids: [
        begin_action_id,
        email_change_token_id,
        verification_job_id,
        confirm_action_id,
        notification_job_id,
      ],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let new_email = email("new@example.com")
  let #(begin_result, begun_state) =
    runner.run_test_program(
      begin.begin_email_change(
        request_context.new(base.ctx, base.state.dynamic_config),
        email_change_dto.BeginEmailChangeRequest(email: new_email),
      ),
      base.ctx,
      base.state,
    )
  assert begin_result == Ok(Nil)
  let #(confirm_result, attempted_state) =
    runner.run_test_program(
      confirm.confirm_email_change(
        request_context.new(base.ctx, begun_state.dynamic_config),
        email_change_dto.ConfirmEmailChangeRequest(token: "wrong"),
      ),
      base.ctx,
      begun_state,
    )
  assert confirm_result == Error(error.auth(auth_error.InvalidEmailChangeToken))
  let assert Ok(email_change_token) =
    dict.get(
      attempted_state.email_change_tokens,
      common.uuid_key(email_change_token_id),
    )
  assert email_change_token.attempt_count == 1
  assert email_change_token.token == "random"
  let assert Ok(user) =
    dict.get(attempted_state.users, common.uuid_key(base.user.id))
  assert user.email == base.user.email
  assert dict.size(attempted_state.jobs) == 1
}

pub fn registered_target_email_returns_success_and_sends_guidance_test() {
  let action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000716")
  let unused_token_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000717")
  let notification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000718")
  let base =
    fixture.integration_fixture(
      next_uuids: [action_id, unused_token_id, notification_job_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let registered_email = email("registered@example.com")
  let registered_user =
    user_model.User(
      ..base.user,
      id: fixture.must_uuid("00000000-0000-0000-0000-000000000719"),
      email: registered_email,
    )
  let state =
    model.TestState(
      ..base.state,
      users: dict.insert(
        base.state.users,
        common.uuid_key(registered_user.id),
        registered_user,
      ),
    )

  let #(result, updated_state) =
    runner.run_test_program(
      begin.begin_email_change(
        request_context.new(base.ctx, state.dynamic_config),
        email_change_dto.BeginEmailChangeRequest(email: registered_email),
      ),
      base.ctx,
      state,
    )

  assert result == Ok(Nil)
  assert dict.is_empty(updated_state.email_change_tokens)
  assert dict.size(updated_state.jobs) == 1
  let assert Ok(notification_job) =
    dict.get(updated_state.jobs, common.uuid_key(notification_job_id))
  let assert option.Some(payload) = notification_job.payload
  assert payload
    == "{\"from\":{\"address\":\"sender@example.com\",\"name\":\"Sender\"},\"to\":\"registered@example.com\",\"subject\":\"Email address already in use\",\"text_body\":\"This email address is already associated with a glot account, so the requested email change was not completed. Please choose a different email address.\",\"html_body\":null}"
  assert updated_state.user_action_count == 1
}

pub fn second_newest_email_change_token_is_accepted_test() {
  let action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000721")
  let notification_job_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000722")
  let base =
    fixture.integration_fixture(
      next_uuids: [action_id, notification_job_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let oldest =
    email_change_token(
      "00000000-0000-0000-0000-000000000723",
      base.user.id,
      base.user.email,
      email("oldest@example.com"),
      "oldest-token",
      base.ctx.timestamp,
    )
  let second_newest =
    email_change_token(
      "00000000-0000-0000-0000-000000000724",
      base.user.id,
      base.user.email,
      email("second@example.com"),
      "second-token",
      base.ctx.timestamp,
    )
  let newest =
    email_change_token(
      "00000000-0000-0000-0000-000000000725",
      base.user.id,
      base.user.email,
      email("newest@example.com"),
      "newest-token",
      base.ctx.timestamp,
    )
  let state =
    model.TestState(
      ..base.state,
      email_change_tokens: email_change_tokens([oldest, second_newest, newest]),
    )

  let #(result, changed_state) =
    runner.run_test_program(
      confirm.confirm_email_change(
        request_context.new(base.ctx, state.dynamic_config),
        email_change_dto.ConfirmEmailChangeRequest(token: "second-token"),
      ),
      base.ctx,
      state,
    )

  let assert Ok(account) = result
  assert account.email == second_newest.new_email
  let assert Ok(updated_oldest) =
    dict.get(changed_state.email_change_tokens, common.uuid_key(oldest.id))
  let assert Ok(updated_second) =
    dict.get(
      changed_state.email_change_tokens,
      common.uuid_key(second_newest.id),
    )
  let assert Ok(updated_newest) =
    dict.get(changed_state.email_change_tokens, common.uuid_key(newest.id))
  assert updated_oldest.attempt_count == 0
  assert updated_second.attempt_count == 1
  assert updated_second.used_at == option.Some(base.ctx.timestamp)
  assert updated_newest.attempt_count == 1
  assert updated_newest.used_at == option.None
}

pub fn third_newest_email_change_token_is_rejected_test() {
  let action_id = fixture.must_uuid("00000000-0000-0000-0000-000000000731")
  let base =
    fixture.integration_fixture(
      next_uuids: [action_id],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let oldest =
    email_change_token(
      "00000000-0000-0000-0000-000000000732",
      base.user.id,
      base.user.email,
      email("oldest@example.com"),
      "oldest-token",
      base.ctx.timestamp,
    )
  let second_newest =
    email_change_token(
      "00000000-0000-0000-0000-000000000733",
      base.user.id,
      base.user.email,
      email("second@example.com"),
      "second-token",
      base.ctx.timestamp,
    )
  let newest =
    email_change_token(
      "00000000-0000-0000-0000-000000000734",
      base.user.id,
      base.user.email,
      email("newest@example.com"),
      "newest-token",
      base.ctx.timestamp,
    )
  let state =
    model.TestState(
      ..base.state,
      email_change_tokens: email_change_tokens([oldest, second_newest, newest]),
    )

  let #(result, attempted_state) =
    runner.run_test_program(
      confirm.confirm_email_change(
        request_context.new(base.ctx, state.dynamic_config),
        email_change_dto.ConfirmEmailChangeRequest(token: "oldest-token"),
      ),
      base.ctx,
      state,
    )

  assert result == Error(error.auth(auth_error.InvalidEmailChangeToken))
  let assert Ok(updated_oldest) =
    dict.get(attempted_state.email_change_tokens, common.uuid_key(oldest.id))
  let assert Ok(updated_second) =
    dict.get(
      attempted_state.email_change_tokens,
      common.uuid_key(second_newest.id),
    )
  let assert Ok(updated_newest) =
    dict.get(attempted_state.email_change_tokens, common.uuid_key(newest.id))
  assert updated_oldest.attempt_count == 0
  assert updated_second.attempt_count == 1
  assert updated_newest.attempt_count == 1
}

pub fn resent_email_change_token_inherits_shared_attempt_count_test() {
  let first_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000741")
  let first_token_id = fixture.must_uuid("00000000-0000-0000-0000-000000000742")
  let first_job_id = fixture.must_uuid("00000000-0000-0000-0000-000000000743")
  let confirm_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000744")
  let second_action_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000745")
  let second_token_id =
    fixture.must_uuid("00000000-0000-0000-0000-000000000746")
  let second_job_id = fixture.must_uuid("00000000-0000-0000-0000-000000000747")
  let base =
    fixture.integration_fixture(
      next_uuids: [
        first_action_id,
        first_token_id,
        first_job_id,
        confirm_action_id,
        second_action_id,
        second_token_id,
        second_job_id,
      ],
      jobs: [],
      account_delete_job_id: option.None,
    )
  let new_email = email("new@example.com")
  let request = email_change_dto.BeginEmailChangeRequest(email: new_email)
  let #(first_result, first_state) =
    runner.run_test_program(
      begin.begin_email_change(
        request_context.new(base.ctx, base.state.dynamic_config),
        request,
      ),
      base.ctx,
      base.state,
    )
  assert first_result == Ok(Nil)
  let #(confirm_result, attempted_state) =
    runner.run_test_program(
      confirm.confirm_email_change(
        request_context.new(base.ctx, first_state.dynamic_config),
        email_change_dto.ConfirmEmailChangeRequest(token: "wrong"),
      ),
      base.ctx,
      first_state,
    )
  assert confirm_result == Error(error.auth(auth_error.InvalidEmailChangeToken))
  let #(second_result, resent_state) =
    runner.run_test_program(
      begin.begin_email_change(
        request_context.new(base.ctx, attempted_state.dynamic_config),
        request,
      ),
      base.ctx,
      attempted_state,
    )
  assert second_result == Ok(Nil)
  let assert Ok(first_token) =
    dict.get(resent_state.email_change_tokens, common.uuid_key(first_token_id))
  let assert Ok(second_token) =
    dict.get(resent_state.email_change_tokens, common.uuid_key(second_token_id))
  assert first_token.attempt_count == 1
  assert second_token.attempt_count == 1
  assert dict.size(resent_state.email_change_tokens) == 2
}

fn email(value: String) -> email_address_model.EmailAddress {
  let assert Ok(pattern) = regexp.from_string(email_address_model.pattern)
  let assert option.Some(address) =
    email_address_model.from_string(pattern, value)
  address
}

fn login_token(email, token) -> login_token_model.LoginToken {
  login_token_model.LoginToken(
    id: uuid.v7(),
    email:,
    token:,
    attempt_count: 0,
    created_at: fixture.test_timestamp(),
    used_at: option.None,
  )
}

fn email_change_token(id, user_id, old_email, new_email, token, created_at) {
  email_change_token_model.EmailChangeToken(
    id: fixture.must_uuid(id),
    user_id:,
    old_email:,
    new_email:,
    token:,
    attempt_count: 0,
    created_at:,
    used_at: option.None,
  )
}

fn email_change_tokens(
  tokens: List(email_change_token_model.EmailChangeToken),
) {
  tokens
  |> list.map(fn(token) { #(common.uuid_key(token.id), token) })
  |> dict.from_list
}
