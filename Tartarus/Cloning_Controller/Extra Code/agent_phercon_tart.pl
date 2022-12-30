

%========================================================================
%               Pheromone-Conscientous Mobile Agent     
%               ---------------------------------------
%Author: Shashi Shekhar Jha {special8688@gmail.com}
%Date : 08-Oct-2012
%Description: This mobile agent checks for pheromones on a node, if it finds a 
%                       a pheromone that it can service, it starts following the pheromone
%                       trail otherwise it goes for a conscientious move.
%                       [please follow agent_conscientious.pl to know anout conscientious move]
%
%
%=========================================================================

:-ensure_loaded(system(chimera)).

:- dynamic task_info/3. 		% task_info must be added as a payload which carries the information
                                % about the tasks for which the agent can provide solution.
                                % task_info contains three parameters viz. guid, list of task ids
                                % for which agent has the solution, and list of lists of 
                                % solution predicates strictly following the order of their task ids
                                % in the previous parameter.
                                % e.g. if agent is carrying solution for tasks 1 & 2 and predicates
                                % (t1_sol1,2),(t1_sol2,4) are for task 1 and  (t2_sol1,0),(t2_sol2,5)
                                % are for task 2 then the payload struture would be:
                                % task_info(guid,[1,2],[[(t1_sol1,2),(t1_sol2,4)],[(t2_sol1,0),(t2_sol2,5)]]) 
                                % NOTE: Always add some dummy task payload if agent is not carrying any task.

:- dynamic visited_nodes/2. 	% This predicate keeps a list of visited nodes by the agent.


%%
%       Create PherCon Agent 
%%
:- dynamic (create_phercon_agent/2).
create_phercon_agent(GUID,P):-
        agent_create(GUID,(localhost,P),phercon_handler),
        add_payload(GUID,[(visited_nodes,2),(cons_move,1),(select_move,1),(agent_type,2),(agent_kind,2),(agent_parent,2),(agent_max_resource,2),(agent_lifetime,2),(agent_resource,2)]). 
        
%------------------------------- Create Agent End ------------------------

%%
%       Conscientious Agent Migration
%%
:- dynamic (migrate_phercon_agent/1).
migrate_phercon_agent(GUID):-
        agent_GUID(GUID,Handler,P),agent_execute(GUID,(localhost,P),Handler). 
        
%------------------------------- Agent Migration End ------------------------

%%
%       Phercon Agent Handler
%%

% phercon_handler/3 matches the solution carried by the mobile agent with the nodes required
% task, and if a match occurs,agents copies the solution to the node
:- dynamic (phercon_handler/3).
phercon_handler(guid,(localhost,P),main):-
                %write(`Inside Handler`),
                (task_info(guid,Tasks,Sols),
                        task_db(T_ID,negative,_),
                        member(T_ID,Tasks)
                        )->             
                        (
                                member(T_ID,Tasks,Pos),
                                member(Solution,Sols,Pos),
                                copy_payload(guid,Solution),
                                write(`~M Solution for Task `:T_ID:` is deployed on this node~M`),
                                node_info(NodeNm,_,_),
                                (write(NodeNm),write(','),
                                write(`Solution Provided,`),
                                write(T_ID)
                                )~>D,send_log(D),
                                (write(NodeNm),write(`-`),write(999),write(`-`),write([T_ID,0]),write(`-`),write(guid))~>Data,
                                send_logger(Data),
                                catch(Err,payload_retract),
                                execute_sol(Solution),
                                beep(300,400),
                                retractall(task_db(T_ID,_,_)),
                                assert(task_db(T_ID,positive,Solution)),
                                clear_nearby_pheromone(T_ID),
                                confer_reward(guid),                                    %% Providing rewards to the agent for servicing the node
                                %write(`~M~J..Mode 1 Strategy selection..`),
                                migrate_typhlet(guid)
                        );
                        (
                                nothing,
                                %write(`~M~J..Mode 2 Strategy selection..`:guid),
                                migrate_typhlet(guid)
                        ),
                !.
                        
% This handler specifies the migration strategy of the agent. It needs to be included in all the
% agents in the system.
phercon_handler(guid,Link,move(GUID,P)):-
                                (neighbors(X,_,_,_,_)->select_move(guid);migrate_typhlet(guid),release_agent),!.


                        
%------------------------------- Agent Handler End ------------------------

%%
%       Phercon Agent Payload
%%

% select_move/1 selects whether the agent will follow a pheromone trail or 
% will go for a conscientious move.

:- dynamic (select_move/1).
select_move(guid):-
        %write(`~M~JSelect Move ...`),
        node_info(Nodenm,_,_),
                write(`~M~JNode name`:Nodenm),
                visited_nodes(guid,VL),
                (member(Nodenm,VL)->
                        (
                                remove(Nodenm,VL,RL),
                                append(RL,[Nodenm],NL), 
                                %nl,write(NL),
                                retractall(visited_nodes(guid,_)),
                                assert(visited_nodes(guid,NL))

                        );
                        (
                                node_info(Ndnm,_,_),
                                visited_nodes(guid,VLs),
                                append(VLs,[Ndnm],NLs),
                                %nl,write(NL-Ndnm),
                                retractall(visited_nodes(guid,_)),
                                assert(visited_nodes(guid,NLs))
                        )
                ),
                agent_type(guid,T),
                node_info(Myname,_,_),
                visited_nodes(guid,VList),
                task_info(guid,Task,_),
                (
                        write(Nodenm),write(','),
                        write(guid),
                        write(` ,|Type,`),write(T),
                        write(`,|Service`),write(Task),
                        write(` ,|Current node,`),write(Myname),
                        write(` ,|visited nodes,`),write(VList)
                )~> S,
                nl,write(S),
                send_log(S),
                %write(`~M~JSend Log done`),
        task_info(guid,T_List,_),
                %write(`~M~JTask Info`:T_List),
        list_pheromones(P_List),
                %write(`~M~JList pheromones`:P_List),
        find_service_pheromones(P_List,T_List,Pheros),
                %write(`~M~JServiceble pheromones`:Pheros),

        (
                not(Pheros = [ ])->
                        (
                                %write(`~M~JPheromone based move`),
                                max_con_phero(Pheros,Max_pheromone),
                                member(Conc,Max_pheromone,1),
                                member(PID,Max_pheromone,2),
                                pheromone(PID,S_ID,Conc,Timeout,Node),
                                %write(`~M~JPheromone values`:PID:Conc:Node),
                                neighbors(Node,IP,Port,_,_)->(                  % since agents can be at source node 
                                        (
                                                write(Nodenm),
                                                write(`,|Pheromnes Found`),write(Pheros),
                                                write(`,|Choosen pheromone`),write(PID-Conc),
                                                write(`,| Next node`),write(Node-IP)
        
                                        )~> Log,
                                        nl,write(Log),
                                        send_log(Log),
                                        leave_queue(guid,IP,Port)
                                );cons_move(guid)

                        );
                        (
                                cons_move(guid)
                        )
        ),!.

% cons_move/2 makes the Mobile to move with conscientious strategy in the network.

:- dynamic (cons_move/1).
cons_move(guid):-
                %write(`~M~JGoing for Cons Move`),
                node_info(Nodenm,_,_),
                neighbour_list(NList),
                visited_nodes(guid,VList),
                (
                        nak_record(guid,NAKNode)->
                             (
                                        findall(NAKs,nak_record(guid,NAKs),NAKList),
                                        remove_list(NAKList,VList,RList0),
                                        append(RList0,NAKList,NwList),
                                        (
                                                write(Nodenm),
                                                write(`,`),write(guid),
                                                write(`,NAK Set,`),write(NAKNode),
                                                write(`,NwList,`),write(NwList)
        
                                        )~> Log,
                                        send_log(Log)

                                );
                                (
                                        NwList = VList
                                )
                ),  
                
                %write(`~M~J Log Sent`),
                (is_sub_list(NwList,NList,N)->
                        (
                                        %write(`~M~JNormal Migration mode`),
                                        %append(VList,[N],NewList),
                                        %retractall(visited_nodes(guid,_)),
                                        %assert(visited_nodes(guid,NewList)),
                                        neighbors(N,IP,Port,_,_),
                                        nl,write(IP:Port),
                                        %connect(IP,Port,Link),
                                        %nl,write(`Link`:Link),
                                        %move_typhlet(guid,Link),
                                        %nl,write(`Link`:Link)
                                        leave_queue(guid,IP,Port)

                        );
                        (
                                        write(`~M~JRepeated Migration mode`),
                                        neighbour_list(NList),
                                        visited_nodes(guid,VList),
                                        write(NList:VList),
                                        (
                                                nak_record(guid,NAKNode1)->
                                                 (
                                                        findall(NAKs,nak_record(guid,NAKs),NAKList),
                                                        write(NAKList),
                                                        remove_list(NAKList,VList,RList1),
                                                        append(RList1,NAKList,NNwList),
                                                        write(NAKList:NNwList)
                                                );
                                                (
                                                        NNwList = VList,
                                                        write(NNwList = VList)
                                                )
                                        ),
                                        find_least_node(NNwList,NList,X),
                                        write(`~M~JFind Least`:X),
                                        %remove(X,VList1,RList),
                                        %append(RList,[X],NewList),
                                        agent_type(guid,T),
                                        node_info(Myname,_,_),

                                        (
                                                write(Myname),write(','),
                                                write(guid),
                                                write(` ,|Type,`),write(T),
                                                write(` ,|Current node,`),write(Myname),
                                                write(` ,|NewList,`),write(NewList)
                                        )~> Ss,
                                        %write(Ss),
                                        %send_log(Ss),
                                        %retractall(visited_nodes(guid,_)),
                                        %assert(visited_nodes(guid,NewList)),
                                        neighbors(X,IP,Port,_,_),
                                        leave_queue(guid,IP,Port)
                        )
                ),
                !.      
                        

:- dynamic (visited_nodes/2).    
visited_nodes(guid,[]).

:- dynamic (task_info/3).    
task_info(guid,ghy00,oiyu89).

:- dynamic (nothing/0).
nothing.

:- dynamic (agent_type/2).
agent_type(guid,phercon).


:- dynamic (agent_kind/2).
agent_kind(guid,parent). 

:- dynamic (agent_parent/2).
agent_parent(guid,none). 

:- dynamic (agent_resource/2).
agent_resource(guid,100).

:- dynamic (agent_lifetime/2).
agent_lifetime(guid,100).

:- dynamic (agent_max_resource/2).
agent_max_resource(guid,100). 
%------------------------------- Agent Payload End -------------------------------------


