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
	server_worker:start(fun(Socket) -> loop(Socket,S) end),
	proxy_loop(MM).

proxy_loop(MM) ->
	receive
		{chan,MM,Bin} ->			
			case Bin of
				{Socket,Msg} ->
					io:format("server proxy received client message ~p~n", [Msg]),
					gen_tcp:send(Socket, Msg)					
			end,
			proxy_loop(MM);
		{chan_closed,MM} ->
			io:format("server proxy stopping~n"),
			exit(normal);
		{worker,Socket,Bin} ->
			io:format("server proxy received worker message ~p~n", [Bin]),
			MM ! {send,{Socket,Bin}},
			proxy_loop(MM);
		Any ->
			io:format("server proxy received:~p~n",[Any])
	end.	

loop(Socket,Master) ->
	receive
		{tcp,Socket,Bin} ->
			io:format("worker received server message ~p~n", [Bin]),			
			Master ! {worker,Socket,Bin},
			loop(Socket,Master);
		{tcp_closed,Socket} ->
			io:format("socket closed~n");
		Any ->
			io:format("server worker received:~p~n",[Any])
	end.
	