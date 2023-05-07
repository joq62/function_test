%%%-------------------------------------------------------------------
%% @doc dbetcd_appl public API
%% @end
%%%-------------------------------------------------------------------

-module(dbetcd_appl_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    dbetcd_appl_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
