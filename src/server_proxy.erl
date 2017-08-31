%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(server_proxy).

%% ====================================================================
%% API functions
%% ====================================================================
-export([run/3]).

%% ====================================================================
%% Internal functions
%% ====================================================================

run(MM,ArgC,ArgS) ->
	io:format("server proxy:run starting~n ArgC=~p ArgS=~p~n",[ArgC,ArgS]),
	S = self(),
	Worker = spawn(fun() -> server_worker:start(fun(Socket) -> loop(Socket,S) end,100) end),
	proxy_loop(MM,Worker).

proxy_loop(MM,Worker) ->
	receive
		{chan,MM,Bin} ->
			io:format("server proxy received client message ~p~n", [Bin]),
			Worker ! {client,Bin},
		    proxy_loop(MM,Worker);
		{chan_closed,MM} ->
			io:format("server proxy stopping~n"),
			exit(normal);
		{worker,Bin} ->
			io:format("server proxy received worker message ~p~n", [Bin]),
			MM ! {send,Bin},
			proxy_loop(MM,Worker);
		Any ->
			io:format("server proxy received:~p~n",[Any])
	end.	

loop(Socket,Master) ->
	receive
		{tcp,Socket,Bin} ->
			io:format("worker received server message ~p~n", [Bin]),
			Master ! {worker,Bin},
			loop(Socket,Master);
		{client,Bin} ->
			io:format("worker send client message ~p~n", [Bin]),
			gen_tcp:send(Socket, Bin),
			loop(Socket,Master);
		{tcp_closed,Socket} ->
			io:format("socket closed~n");
		Any ->
			io:format("server worker received:~p~n",[Any])
	end.
	