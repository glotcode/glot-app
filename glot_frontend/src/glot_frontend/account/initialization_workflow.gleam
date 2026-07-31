import gleam/option
import glot_core/loadable
import glot_frontend/account/command
import glot_frontend/account/message.{
  type Msg, AccountLoaded, AccountLoadingDelayElapsed, AccountPasskeysLoaded,
  AccountSessionsLoaded, PasskeysLoadingDelayElapsed, RuntimeLoaded,
  SessionLoaded, SessionsLoadingDelayElapsed,
}
import glot_frontend/account/model.{
  type Model, Idle, IdlePasskeys, LoadingPasskeys, Model,
}
import glot_frontend/api/response as api_response
import glot_frontend/app/event as app_event
import glot_frontend/request_generation
import glot_frontend/ui/delayed_loading

pub fn update(
  model: Model,
  msg: Msg,
) -> #(Model, command.Command(Msg), app_event.AppEvent) {
  case msg {
    RuntimeLoaded(passkey_supported) -> initialize(model, passkey_supported)

    AccountLoaded(result) ->
      case result {
        api_response.Success(account) -> {
          #(
            Model(
              ..model,
              account: loadable.Loaded(account),
              username: account.username,
              status: Idle,
              account_loading_indicator: delayed_loading.finish(
                model.account_loading_indicator,
              ),
            ),
            command.none(),
            app_event.NoAppEvent,
          )
        }

        api_response.ApiFailure(error) -> #(
          Model(
            ..model,
            account: loadable.LoadError(api_response.error_message(error)),
            account_loading_indicator: delayed_loading.finish(
              model.account_loading_indicator,
            ),
          ),
          command.none(),
          app_event.NoAppEvent,
        )

        api_response.HttpFailure(_) -> #(
          Model(
            ..model,
            account: loadable.LoadError("Could not load account."),
            account_loading_indicator: delayed_loading.finish(
              model.account_loading_indicator,
            ),
          ),
          command.none(),
          app_event.NoAppEvent,
        )
      }

    AccountLoadingDelayElapsed(generation) -> #(
      Model(
        ..model,
        account_loading_indicator: delayed_loading.reveal(
          model.account_loading_indicator,
          generation,
        ),
      ),
      command.none(),
      app_event.NoAppEvent,
    )

    SessionLoaded(result) ->
      case result {
        api_response.Success(option.Some(session)) -> #(
          Model(..model, current_session_id: option.Some(session.id)),
          command.none(),
          app_event.NoAppEvent,
        )

        api_response.Success(option.None) -> #(
          Model(..model, current_session_id: option.None),
          command.none(),
          app_event.NoAppEvent,
        )

        api_response.ApiFailure(_) | api_response.HttpFailure(_) -> #(
          model,
          command.none(),
          app_event.NoAppEvent,
        )
      }
    _ -> #(model, command.none(), app_event.NoAppEvent)
  }
}

fn initialize(
  model: Model,
  passkey_supported: Bool,
) -> #(Model, command.Command(Msg), app_event.AppEvent) {
  let #(account_loading_indicator, account_generation) =
    delayed_loading.begin(model.account_loading_indicator)
  let #(sessions_loading_indicator, sessions_generation) =
    delayed_loading.begin(model.sessions_loading_indicator)
  let #(passkeys_loading_indicator, passkeys_generation) = case
    passkey_supported
  {
    True -> delayed_loading.begin(model.passkeys_loading_indicator)
    False -> #(model.passkeys_loading_indicator, request_generation.initial())
  }
  let passkey_commands = case passkey_supported {
    True -> [
      command.ListPasskeys(AccountPasskeysLoaded),
      command.Schedule(
        delayed_loading.delay(),
        PasskeysLoadingDelayElapsed(passkeys_generation),
      ),
    ]
    False -> []
  }
  #(
    Model(
      ..model,
      passkey_supported: passkey_supported,
      account_loading_indicator: account_loading_indicator,
      sessions_loading_indicator: sessions_loading_indicator,
      passkeys_loading_indicator: passkeys_loading_indicator,
      passkeys_status: case passkey_supported {
        True -> LoadingPasskeys
        False -> IdlePasskeys
      },
    ),
    command.batch([
      command.GetAccount(AccountLoaded),
      command.GetSession(SessionLoaded),
      command.ListSessions(AccountSessionsLoaded),
      command.Schedule(
        delayed_loading.delay(),
        AccountLoadingDelayElapsed(account_generation),
      ),
      command.Schedule(
        delayed_loading.delay(),
        SessionsLoadingDelayElapsed(sessions_generation),
      ),
      ..passkey_commands
    ]),
    app_event.NoAppEvent,
  )
}
