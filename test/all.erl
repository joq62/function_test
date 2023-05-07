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

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
   
    ok=setup(),
        
    {ok,ControllerNode}=start_controller("c200"),
    {ok,DbEtcdNode,DbETcdApp}=start_provider("dbetcd_appl","c200"),
    {ok,KubeNode,KubeApp}=start_provider("kube_appl","c200"),
    ['dbetcd_appl@c200','kube_appl@c200']=lists:sort(rpc:call(ControllerNode,erlang,nodes,[],5000)),
    ['host_controller@c200','kube_appl@c200']=lists:sort(rpc:call(DbEtcdNode,erlang,nodes,[],5000)),
    ['dbetcd_appl@c200','host_controller@c200']=lists:sort(rpc:call(KubeNode,erlang,nodes,[],5000)),

    
    io:format("Test OK !!! ~p~n",[?MODULE]),
    timer:sleep(2000),
    init:stop(),
    ok.
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start_provider(ProviderSpec,HostSpec)->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
 
    false=kube:is_provider_started(ProviderSpec,HostSpec),
    {ok,ProviderSpec,HostSpec,ApplNode, App}=kube:load_provider(ProviderSpec,HostSpec),
    ok=kube:start_provider(ProviderSpec,HostSpec),
    true=kube:is_provider_started(ProviderSpec,HostSpec),
  
    {ok,ControllerNode}=db_host_spec:read(connect_node,HostSpec),
    pong=rpc:call(ApplNode,App,ping,[],5000),
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
    ok=kube:start_controller(HostSpec),
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
    pong=kube:ping(),
        

    %% Ensure that all controllers are stopped
    [kube:stop_controller(HostSpec)||HostSpec<-?AllHosts],
    [false,false]=[kube:is_controller_started(HostSpec)||HostSpec<-?AllHosts],


    %%
    ok.
