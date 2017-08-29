%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(sproxy).

%% ====================================================================
%% API functions
%% ====================================================================
-export([run/3]).

%% ====================================================================
%% Internal functions
%% ====================================================================

run(MM,ArgC,ArgS) ->
	io:format("sproxy:run starting~n ArgC=~p ArgS=~p~n",[ArgC,ArgS]),
	S = self(),
	proxy_loop(MM,S).

proxy_loop(MM,S) ->
	receive
		{chan,MM,{reg,client}} ->
    	  spawn(fun() -> worker:start(fun(Socket) -> loop(Socket,S) end,100) end),
		  proxy_loop(MM,S);
		{chan_closed,MM} ->
			io:format("sproxy stopping~n"),
			exit(normal);
		{worker,Bin} ->
			io:format("sproxy received message ~p~n", [Bin]),
			MM ! {send,Bin},
			proxy_loop(MM,S);
		Any ->
			io:format("proxy received:~p~n",[Any])
	end.	

loop(Socket,S) ->
	receive
		{tcp,Socket,Bin} ->
			S ! {worker,Bin},
			loop(Socket,S);
		{tcp_closed,Socket} ->
			io:format("socket closed~n");
		Any ->
			io:format("server worker received:~p~n",[Any])
	end.
	