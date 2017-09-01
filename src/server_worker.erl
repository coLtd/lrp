%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(server_worker).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/1]).

%% ====================================================================
%% Internal functions
%% ====================================================================

start(Fun) ->
	{ok,Listen} = gen_tcp:listen(53389, [binary,{packet,0},{reuseaddr,true},{active,true}]),
	spawn(fun() -> par_connect(Listen, Fun) end).
	
par_connect(Listen, Fun) ->
	{ok,Socket} = gen_tcp:accept(Listen),
	spawn(fun() -> par_connect(Listen, Fun) end),
	Fun(Socket).