-module(startup_transaction_ffi).

-export([run/2]).

%% Runs Callback inside a pgo transaction whose pool checkout never expires.
%%
%% pog:transaction/2 checks its connection out with pgo's default 5 second
%% hold deadline. When that fires the pool disconnects the socket, the running
%% statement fails client-side with `closed' (reported as QueryTimeout) while
%% Postgres keeps executing it, and the startup retry then queues a second copy
%% behind the first. Startup SQL instead uses pgo's own transaction with an
%% unlimited checkout; pog queries issued on the pool connection inside the
%% callback are routed to the transaction's connection by pgo.
run({pool, PoolName}, Callback) ->
    Fun = fun() ->
        case Callback() of
            {ok, Value} -> {ok, Value};
            {error, Reason} -> throw({startup_transaction_rollback, Reason})
        end
    end,
    try pgo:transaction(PoolName, Fun, #{pool_options => [{timeout, infinity}]}) of
        {ok, Value} -> {ok, Value};
        {error, Reason} -> {error, format("checkout failed: ~p", [Reason])}
    catch
        throw:{startup_transaction_rollback, Reason} -> {error, Reason};
        Class:Reason:Stack -> {error, format("~p: ~p at ~p", [Class, Reason, lists:sublist(Stack, 4)])}
    end;
run(Other, _Callback) ->
    {error, format("startup transactions need a pooled connection, got ~p", [Other])}.

format(Format, Args) ->
    unicode:characters_to_binary(io_lib:format(Format, Args)).
