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
-module(all).      
 
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

    {ok,ControllerNode,DbEtcdNode,KubeNode}=init_test(),
   
%    ok=start_orchestrate(ControllerNode,DbEtcdNode,KubeNode),
    ok=check_orchestrate(ControllerNode,DbEtcdNode,KubeNode),
      
    
    io:format("Test OK !!! ~p~n",[?MODULE]),
 %   timer:sleep(2000),
 %   init:stop(),
    ok.

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
check_orchestrate(ControllerNode,DbEtcdNode,KubeNode)->
    io:format("Start ~p~n",[{ControllerNode,DbEtcdNode,KubeNode,?MODULE,?FUNCTION_NAME}]),

    [{"production",WantedState}]=db_deployment_spec:read_all(),
    
    io:format("nodes c200 ~p~n",[{rpc:call(ControllerNode,erlang,nodes,[],5000),?MODULE,?FUNCTION_NAME,?LINE}]),
    io:format("nodes c201 ~p~n",[{rpc:call(host_controller@c201,erlang,nodes,[],5000),?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(20*1000),
    check_orchestrate(ControllerNode,DbEtcdNode,KubeNode),
    
    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start_orchestrate(ControllerNode,DbEtcdNode,KubeNode)->
    io:format("Start ~p~n",[{ControllerNode,DbEtcdNode,KubeNode,?MODULE,?FUNCTION_NAME}]),

    [{"production",WantedState}]=db_deployment_spec:read_all(),
    
    io:format("WantedState ~p~n",[{WantedState,?MODULE,?FUNCTION_NAME,?LINE}]),
      
 %   ok=kube:start_orchestrate(?WantedState),
    ok=rpc:call(KubeNode,kube,start_orchestrate,[WantedState],5000),

    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
init_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    {ok,ControllerNode}=start_controller("c200"),
    {ok,DbEtcdNode,DbETcdApp}=start_provider("dbetcd_appl","c200"),
    {ok,KubeNode,KubeApp}=start_provider("kube_appl","c200"),
    ['dbetcd_appl@c200','kube_appl@c200']=lists:sort(rpc:call(ControllerNode,erlang,nodes,[],5000)),
    ['host_controller@c200','kube_appl@c200']=lists:sort(rpc:call(DbEtcdNode,erlang,nodes,[],5000)),
    ['dbetcd_appl@c200','host_controller@c200']=lists:sort(rpc:call(KubeNode,erlang,nodes,[],5000)),
 
    {ok,ControllerNode,DbEtcdNode,KubeNode}.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start_provider(ProviderSpec,HostSpec)->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
 
    false=lib_provider:is_started(ProviderSpec,HostSpec),
    {ok,ProviderSpec,HostSpec,ApplNode, App}=lib_provider:load(ProviderSpec,HostSpec),
    ok=lib_provider:start(ProviderSpec,HostSpec),
    true=lib_provider:is_started(ProviderSpec,HostSpec),
    {ok,ControllerNode}=db_host_spec:read(connect_node,HostSpec),
    Nodes=rpc:call(ControllerNode,erlang,nodes,[],5000),
    io:format("Nodes ~p~n",[{Nodes,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    Ping=[{rpc:call(N1,net_adm,ping,[N2],5000),N1,N2}||N1<-[ControllerNode|Nodes],
						       N2<-[ControllerNode|Nodes]],
  %  io:format("Ping ~p~n",[{Ping,?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("ApplNode,App, which_applications ~p~n",[{ApplNode,App,rpc:call(ApplNode,application,which_applications,[],5000),?MODULE,?FUNCTION_NAME,?LINE}]),
    case App of
	kube_appl->
	    pong=rpc:call(ApplNode,kube,ping,[],5000);
	_ ->
	    pong=rpc:call(ApplNode,App,ping,[],5000)
    end,
    
    {ok,ApplNode,App}.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
 start_controller(HostSpec)->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    {"c200","c200","192.168.1.200",22,"ubuntu","festum01",[],
     "host_controller",host_controller@c200}=db_host_spec:read(HostSpec),
    
    {ok,ControllerNode}=db_host_spec:read(connect_node,HostSpec),
    pang=net_adm:ping(ControllerNode),
    ok=lib_host:start_controller(HostSpec),
    pong=net_adm:ping(ControllerNode),

    {ok,ControllerNode}.
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
 %   pong=kube:ping(),
    
    pong=sd:call(dbetcd_appl,dbetcd,ping,[],4000),
    
        

    %% Ensure that all controllers are stopped
    [lib_host:stop_controller(HostSpec)||HostSpec<-?AllHosts],
    [false,false]=[lib_host:is_controller_started(HostSpec)||HostSpec<-?AllHosts],


    %%
    ok.
