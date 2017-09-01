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
	Worker = spawn(fun() -> client_worker:start(fun(Socket) -> loop(Socket,S) end) end) ,
	proxy_loop(MM,Worker).	

proxy_loop(MM,Worker) ->
	receive
		{chan,MM,Bin} ->
		   case Bin of
            {Socket,Msg} ->
				put(Worker,Socket),
				io:format("client proxy received server message:~p~n", [Msg]),
			    Worker ! {proxy,Msg}
		   end,		  
		   proxy_loop(MM,Worker);		
	    {worker,Bin} ->
		   io:format("client proxy received worker message:~p~n", [Bin]),
		   Socket = get(Worker),	
		   MM ! {send, {Socket,Bin}},
		   proxy_loop(MM,Worker);	
		Any ->
		  io:format("client proxy received:~p~n",[Any])
	end.

loop(Socket,Master) ->
	receive
	  {tcp,Socket,Bin} ->
		 io:format("client worker received server message:~p~n",[Bin]),
		 Master ! {worker,Bin},
		 loop(Socket,Master);
	  {proxy,Bin} ->
		 io:format("client worker received proxy message:~p~n",[Bin]),
		 gen_tcp:send(Socket,Bin),
		 loop(Socket,Master);
	  {tcp_closed,Socket} ->
		 io:format("client worker socket disconnected~n")	
	end.