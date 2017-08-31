%% @author bigdat
%% @doc @todo Add description to cworker.


-module(client_worker).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/1]).

%% ====================================================================
%% Internal functions
%% ====================================================================

start(Fun) ->
	{ok,Socket} = gen_tcp:connect("10.88.20.63", 4389, [binary, {packet,0}]),
	Fun(Socket).