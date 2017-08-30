%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(client_proxy).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).

%% ====================================================================
%% Internal functions
%% ====================================================================

start() ->
	io:format("client proxy starting~n"),
	{ok,MM} = lib_chan:connect("127.0.0.1", 2233, ts, "qwerty", {yes,go}),
	S = self(),
	Worker = client_worker:start(fun(Socket) -> loop(Socket,S) end),
	proxy_loop(MM,Worker).	

proxy_loop(MM,Worker) ->
	receive
		{chan,MM,Bin} ->
    	   io:format("client proxy received message:~p~n", [Bin]),
		   Worker ! {proxy,Bin},
		   proxy_loop(MM,Worker);		
	    {worker,Bin} ->
		   MM ! {send, Bin},
		   proxy_loop(MM,Worker);	
		Any ->
		  io:format("client proxy received:~p~n",[Any])
	end.

loop(Socket,Master) ->
	receive
	  {tcp,Socket,Bin} ->
		 Master ! {worker,Bin},
		 loop(Socket,Master);
	  {proxy,Bin} ->
		 io:format("client worker received message:~p~n",[Bin])	,
		 gen_tcp:send(Socket,Bin),
		 loop(Socket,Master);
	  {tcp_closed,Socket} ->
		 io:format("client worker socket disconnected~n")	
	end.