%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(cproxy).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).

%% ====================================================================
%% Internal functions
%% ====================================================================

start() ->
	io:format("client proxy starting~n"),
	{ok,MM} = lib_chan:connect("localhost", 2233, ts, "qwerty", {yes,go}),
	MM ! {send, {reg,client}},
	proxy_loop(MM).

proxy_loop(MM) ->
	receive
		{chan,MM,Reply} ->
    	  io:format("cproxy received message:~p~n", [Reply]),
		  proxy_loop(MM);
		Any ->
		  io:format("client proxy received:~p~n",[Any])
	end.