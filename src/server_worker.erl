%% @author bigdat
%% @doc @todo Add description to mod_math.


-module(server_worker).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/2]).

%% ====================================================================
%% Internal functions
%% ====================================================================

start(Fun,Max) ->
  case gen_tcp:listen(53389, [binary,{packet,0},{reuseaddr,true},{active,true}]) of
	 {ok,Listen} ->
		New = start_accept(Listen,Fun),
		socket_loop(Listen,New,[],Fun,Max);	
	 Error ->
		Error
  end.

socket_loop(Listen,New,Active,Fun,Max) ->
	receive
		{isstarted,New} ->
			Active1 = [New|Active],
			possibly_start_another(false,Listen,Active1,Fun,Max);
		{'EXIT',New,_Why} ->
			possibly_start_another(false,Listen,Active,Fun,Max);
		{'EXIT',Pid,_Why} ->
			Active1 = lists:delete(Pid, Active),
			possibly_start_another(New,Listen,Active1,Fun,Max);
		{children,From} ->
			From ! {session_server,Active},
			socket_loop(Listen,New,Active,Fun,Max);
		_Other ->
			socket_loop(Listen,New,Active,Fun,Max)
	end.

possibly_start_another(New,Listen,Active,Fun,Max)
	when pid(New) ->
		socket_loop(Listen,New,Active,Fun,Max);

possibly_start_another(false,Listen,Active,Fun,Max) ->
	case length(Active) of
		N when N < Max ->
			New = start_accept(Listen,Fun),
			socket_loop(Listen,New,Active,Fun,Max);
		_ ->
			socket_loop(Listen,false,Active,Fun,Max)
	end.
  
start_accept(Listen,Fun) ->
	S = self(),
	spawn_link(fun() -> start_child(S,Listen,Fun) end).

start_child(Parent,Listen,Fun) ->
	case gen_tcp:accept(Listen) of
		{ok,Socket} ->
			Parent ! {isstarted,self()},
			inet:setopts(Socket, [binary,{nodelay,true},{packet,0},{reuseaddr,true},{active,true}]),
			process_flag(trap_exit,true),
			io:format("running the child:~p Fun=~p~n",[Socket,Fun]),
			case (catch Fun(Socket)) of
				{'EXIT',normal} -> true;
				{'EXIT',Why} ->
					io:format("Port process dies with exit:~p~n",[Why]),
					true;
				_ 	->  true
			end	
	end.