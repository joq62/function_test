%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(console).      
 
-export([start/0]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(AllHosts,["c200","c201"]).
-define(WantedState,[{"test_appl","c200"},{"divi","c201"}]).

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
   
    ok=setup(),
    ok=check_orchestrate(na),
      
    
    io:format("Test OK !!! ~p~n",[?MODULE]),
 %   timer:sleep(2000),
 %   init:stop(),
    ok.

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
check_orchestrate(PreviousState)->
  %  io:format("Start ~p~n",[{PreviousState,?MODULE,?FUNCTION_NAME}]),

  %  [{"production",WantedState}]=db_deployment_spec:read_all(),
    CurrentState=orchestrate:is_wanted_state(),
    if
	PreviousState/=CurrentState->
	    io:format("is_wanted_state  ~p~n",[{CurrentState,time(),?MODULE,?FUNCTION_NAME,?LINE}]);
	true->
	    ok
    end,
    
    timer:sleep(20*1000),
    check_orchestrate(CurrentState),
    
    ok.

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------



%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------


setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok=application:start(dbetcd_appl),
    pong=dbetcd:ping(),
    pong=common:ping(),
    pong=sd:ping(),

    ok=application:start(function_test),
    pong=ft:ping(),
    
    pong=log:ping(),
     
    pong=sd:call(dbetcd_appl,dbetcd,ping,[],4000),
    
    ok.
