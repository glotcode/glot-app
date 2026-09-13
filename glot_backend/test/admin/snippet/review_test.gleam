import gleam/dict
import gleam/option
import glot_backend/admin/domain/snippet/review
import glot_backend/auth/error as auth_error
import glot_backend/snippet/ports/store
import glot_backend/system/effect/database_ports
import glot_backend/system/effect/error
import glot_backend/system/effect/error/resource_error
import glot_backend/system/effect/service_ports
import glot_backend/system/request/context
import glot_backend/system/request/hydrated_context
import glot_core/admin/spam_review_dto
import glot_core/auth/user_model
import glot_core/pagination_model
import glot_core/snippet/manual_review
import glot_core/snippet/spam_review_filter
import support/integration/adapter/snippet as snippet_adapter
import support/integration/adapter/transaction
import support/integration/fixture
import support/integration/model
import support/integration/profile/snippet as profile
import support/integration/runner
import support/integration/store/common

pub fn regular_users_cannot_list_or_review_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let ctx = hydrated_context.new(fixture.ctx, fixture.state.dynamic_config)
  let #(result, state) =
    profile.run_test_program(
      review.list(ctx, list_request()),
      fixture.ctx,
      fixture.state,
    )
  assert result == Error(error.auth(auth_error.AdminRequired))
  assert state.user_action_count == 0
  let #(result, state) =
    profile.run_test_program(
      review.save(ctx, save_request(fixture)),
      fixture.ctx,
      fixture.state,
    )
  assert result == Error(error.auth(auth_error.AdminRequired))
  assert state.user_action_count == 0
}

pub fn admin_save_returns_metadata_and_audits_in_the_transaction_test() {
  let fixture = admin_fixture()
  let request = save_request(fixture)
  let #(result, state) =
    runner.run_test_program_with(
      review.save(
        hydrated_context.new(fixture.ctx, fixture.state.dynamic_config),
        request,
      ),
      fixture.ctx,
      fixture.state,
      fn(test_state) {
        let services = profile.service_ports(test_state)
        let database =
          database_ports.with_snippet(
            services.database,
            store.Store(
              ..snippet_adapter.defaults(),
              save_manual_review: fn(received, reviewer, now) {
                assert received == request
                assert reviewer == fixture.user.id
                assert now == fixture.state.system_time
                Ok(
                  option.Some(manual_review.ManualReview(
                    request.verdict,
                    option.Some(reviewer),
                    option.Some(now),
                    1,
                  )),
                )
              },
            ),
          )
        service_ports.ServicePorts(
          ..services,
          database:,
          transaction: transaction.new(test_state, database),
        )
      },
    )
  let assert Ok(metadata) = result
  assert metadata.version == 1
  assert metadata.verdict == request.verdict
  assert state.user_action_count == 1
  assert state.snippets == fixture.state.snippets
}

pub fn failed_guard_rolls_back_without_a_review_audit_test() {
  let fixture = admin_fixture()
  let #(result, state) =
    runner.run_test_program_with(
      review.save(
        hydrated_context.new(fixture.ctx, fixture.state.dynamic_config),
        save_request(fixture),
      ),
      fixture.ctx,
      fixture.state,
      fn(test_state) {
        let services = profile.service_ports(test_state)
        let database =
          database_ports.with_snippet(
            services.database,
            store.Store(
              ..snippet_adapter.defaults(),
              save_manual_review: fn(_, _, _) { Ok(option.None) },
            ),
          )
        service_ports.ServicePorts(
          ..services,
          database:,
          transaction: transaction.new(test_state, database),
        )
      },
    )
  assert result == Error(error.resource(resource_error.SnippetReviewStale))
  assert state.user_action_count == 0
}

pub fn queue_requests_one_item_with_a_cursor_lookahead_test() {
  let fixture = admin_fixture()
  let #(result, state) =
    runner.run_test_program_with(
      review.list(
        hydrated_context.new(fixture.ctx, fixture.state.dynamic_config),
        list_request(),
      ),
      fixture.ctx,
      fixture.state,
      fn(test_state) {
        let services = profile.service_ports(test_state)
        let database =
          database_ports.with_snippet(
            services.database,
            store.Store(
              ..snippet_adapter.defaults(),
              list_spam_review: fn(request: spam_review_dto.ListRequest) {
                assert request.pagination == pagination_model.InitialPage(2)
                assert request.filter == spam_review_filter.default()
                Ok([])
              },
            ),
          )
        service_ports.ServicePorts(
          ..services,
          database:,
          transaction: transaction.new(test_state, database),
        )
      },
    )
  assert result == Ok(pagination_model.InitialCursorPage([], option.None))
  assert state.user_action_count == 1
}

fn admin_fixture() {
  let fixture =
    fixture.integration_fixture(
      [fixture.must_uuid("00000000-0000-0000-0000-000000000699")],
      [],
      option.None,
    )
  let user = user_model.User(..fixture.user, role: user_model.AdminUser)
  model.TestFixture(
    ..fixture,
    user:,
    state: model.TestState(
      ..fixture.state,
      users: dict.insert(fixture.state.users, common.uuid_key(user.id), user),
    ),
  )
}

fn list_request() {
  spam_review_dto.ListRequest(
    pagination_model.InitialPage(1),
    spam_review_filter.default(),
    option.None,
    False,
  )
}

fn save_request(fixture: model.TestFixture) {
  spam_review_dto.SaveRequest(
    fixture.snippet.slug,
    option.Some(manual_review.Spam),
    0,
    fixture.snippet.updated_at,
  )
}

pub fn anonymous_users_cannot_list_or_save_reviews_test() {
  let fixture = fixture.integration_fixture([], [], option.None)
  let context =
    context.Context(
      ..fixture.ctx,
      client_info: context.ClientInfo(
        ..fixture.ctx.client_info,
        session_token: option.None,
      ),
    )
  let ctx = hydrated_context.new(context, fixture.state.dynamic_config)
  let #(result, state) =
    profile.run_test_program(
      review.list(ctx, list_request()),
      context,
      fixture.state,
    )
  assert result == Error(error.auth(auth_error.MissingSessionToken))
  assert state.user_action_count == 0
  let #(result, state) =
    profile.run_test_program(
      review.save(ctx, save_request(fixture)),
      context,
      fixture.state,
    )
  assert result == Error(error.auth(auth_error.MissingSessionToken))
  assert state.user_action_count == 0
}
