-module(http_pool_ffi).

-export([start/3, configure/3, request/5]).

start(Pool, MaxSessions, KeepAliveTimeoutMs) ->
    Profile = profile(Pool),
    case inets:start(httpc, [{profile, Profile}], inets) of
        {ok, _Pid} ->
            configure_profile(Profile, MaxSessions, KeepAliveTimeoutMs);
        {error, {already_started, _Pid}} ->
            configure_profile(Profile, MaxSessions, KeepAliveTimeoutMs);
        {error, Reason} ->
            {error, format_error(Reason)}
    end.

configure(Pool, MaxSessions, KeepAliveTimeoutMs) ->
    configure_profile(
        profile(Pool),
        MaxSessions,
        KeepAliveTimeoutMs
    ).

request(Method, Request, HttpOptions, Options, Pool) ->
    httpc:request(
        Method,
        Request,
        HttpOptions,
        Options,
        profile(Pool)
    ).

configure_profile(Profile, MaxSessions, KeepAliveTimeoutMs) ->
    Options = [
        {max_sessions, MaxSessions},
        {keep_alive_timeout, KeepAliveTimeoutMs}
    ],
    case httpc:set_options(Options, Profile) of
        ok ->
            {ok, nil};
        {error, Reason} ->
            {error, format_error(Reason)}
    end.

format_error(Reason) ->
    unicode:characters_to_binary(io_lib:format("~tp", [Reason])).

profile({pool, docker_run}) ->
    glot_docker_run_http;
profile({pool, cloudflare_email}) ->
    glot_cloudflare_email_http;
profile({pool, spam_classifier}) ->
    glot_spam_classifier_http.
