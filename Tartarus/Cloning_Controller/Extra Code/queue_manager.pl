% Author:
% Date: 26-Oct-15

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Declarations                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:-style_check(-singleton). %%hide warnings due to singleton variables

:-dynamic set_to_move/1.

:-dynamic intranode_queue/1.
intranode_queue([]).

:-dynamic ack_q/1.
ack_q([]).

:-dynamic transit_req/1.
transit_req(0).

:-dynamic queue_length/1.
queue_length(5).

:-dynamic clone_lifetime/1.
clone_lifetime(10).

:-dynamic clone_resource/1.
clone_resource(10).

:-dynamic queue_threshold/1.
queue_threshold(5).

:-dynamic q_monitor_steptime/1.
q_monitor_steptime(1003).

:-dynamic ack_q_timeout/1.
ack_q_timeout(4).

:-dynamic transit_req_timeout/1.
transit_req_timeout(8).

:-dynamic lifetime_decrement/1.
lifetime_decrement(1).

:-dynamic service_reward/1.
service_reward(1).

:-dynamic tau_c/1.
tau_c(0.1).

:-dynamic tau_r/1.
tau_r(100).

:-dynamic sigma/1.
sigma(7).

%---------------------Declarations End----------------------------------------%


start_clonning_controller(EP,DP):-
                                %enqueue_port(EP),
                                %dequeue_port(DP),
                                q_manager(EP),
                                dq_manager(DP),
                                thread_create(timer_release,_,[detached(false)]),

                                !.


start_queue_manager(EP,DP):- write('start_queue_manager Failed'),!.



q_manager(P):-
              create_static_agent(q_manager,(localhost,P),q_manager_handle),
              assert(q_port(P)),
              write('=====Q-Manager====='),
              write('started at port': P),!.

q_manager(P):- write('q_manager failed'),!.

:- dynamic q_manager_handle/3.

q_manager_handle(guid,(IP,P),recv_agent(X)):-
                                            writeln('request received for the arrival of agent':X),
                                             intranode_queue(Li), length(Li,Q_Len),queue_length(Len),
                                             ack_q(ACK_Q),length(ACK_Q,ACK_Len),
                                             L is ACK_Len + Q_Len,
                                             ((L<Len)->
                                             (
                                                       ack_q(Ack_QQ),
                                                       (
                                                         (member([X,_],Ack_QQ))->
                                                                 (
                                                                   nothing,writeln('Request ignored for receive.. already sent ealier.')

                                                                 );
                                                                 (

                                                                   ack_q(Ack_Q),
                                                                   q_port(QP),
                                                                   append([X],Ack_Q,Nw_Ack_Q) ,
                                                                   agent_post(platform,(IP,P),[dq_manager_handle,dq_manager,(localhost,QP),ack(X)]),
                                                                   writeln('Space is available in the queue. ACK sent.'),
                                                                   writeln('Ack Queue':Nw_Ack_Q),
                                                                   update_ack_queue(Nw_Ack_Q)

                                                                  )
                                                        )

                                             );
                                             (
                                              intranode_queue(Lii),length(Lii,Lh),queue_length(Lenn),
                                              agent_post(platform,(IP,P),[dq_manager_handle,dq_manager,(localhost,QP),nack(X)]),
                                              writeln('No space is available in queue. NAK sent...')

                                              )
                                              ),
                !.
                
q_manager_handle(guid,(IP,P),recv_agent(X)):- write('handler failed!!'),!.

%%=============================== Q-Manager handler ends=======================================



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%===Inserting into own queue===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic migrate_typhlet/1.
migrate_typhlet(GUID):-
                 writeln('Migrating agent to the Intranode queue':GUID),
                 intranode_queue(I),
                 (member(GUID,I)->
                 (dequeue(GUID,I,In),enqueue(GUID,In,Inew));
                 enqueue(GUID,I,Inew)
                 ),

                 update_intranode_queue(Inew),
                 writeln('Agent added to the queue':Inew),

                 ack_q(ACK_Q),
                (
                        member(GUID,ACK_Q)->
                                        (
                                                delete(ACK_Q,GUID,NwACK_Q),
                                                update_ack_queue(NwACK_Q)
                                        );(nothing)
                ),
                writeln('ACK Q updated') ,
                !.

migrate_typhlet(GUID):- writeln('Migrate Typhlet in Q-Manager Failed for':GUID),!.

% update_internode_queue/1 updates the internode_queue with the new queue list
:- dynamic update_intranode_queue/1.
update_intranode_queue(Inew):-
		
                        retractall(intranode_queue(_)),
                        asserta(intranode_queue(Inew)),


                        !.
update_intranode_queue(Inew):- write('update_intranode_queue Failed'),!.

% update_ack_queue/1 updates the ack_queue with the new list
:- dynamic update_ack_queue/1.
update_ack_queue(X):-
                        %node_info(NodeNm,_,_),
                %(write(NodeNm),write(','),write('Ack Queue updated'),write(X))~>D,send_log(D),
                        retractall(ack_q(_)),
                        asserta(ack_q(X)),
                        !.

update_ack_queue(X):- write('update_ack_queue Failed'),!.


:- dynamic initiate_migration/1.
initiate_migration(GUID):-
                                clone_if_necessary(GUID),
                                leaving_queue(GUID,IP,Port),
                                writeln('Leaving Queue':GUID:IP:Port),
                                neighbour(NP,NEP),
                                catch(agent_move(GUID,(localhost,NP)),Err,writeln(Err)),
                                catch(retractall(nak_record(GUID,_)),ERr,write(ERr)),
                                retract(set_to_move(GUID)),
                                writeln('TUSHAR!!!!!') ,
                                intranode_queue(I),
                                dequeue(GUID,I,Inew),

                                update_intranode_queue(Inew),
                                !.
initiate_migration(GUID):- writeln('initiate_migration Failed'),!.

% clone_if_necessary/1 makes clones if the agent at the top of the intranode queue as per the equations
% given in the paper and add those clone to the queue.
:-dynamic clone_if_necessary/1.
clone_if_necessary(GUID):-
              no_of_clone(GUID,N),
                (
                        (N = 0)->writeln('No Clones will be created':GUID);

                                (
                                   writeln('Creating Clones':N),
                                   deduct_clonal_resource(GUID,N)
                                )
                ),
                !.

clone_if_necessary(GUID):- writeln('clone_if_necessary/1 Failed'),!.

% no_of_clone/2 gives the no of clones that will be created for the agent GUID.
:-dynamic no_of_clone/2.
no_of_clone(GUID,N):-
                cloning_pressure(Ps),
                agent_resource(GUID,Rc),
                agent_max_resource(GUID,Rmax),
                R is Rc/Rmax,
                N is round(Ps*R),

                !.

no_of_clone(GUID,N):- writeln('no_of_clone/2 Failed'),!.

% cloning_pressure/1 returns the current cloning pressure at the node.
:-dynamic cloning_pressure/1.
cloning_pressure(Ps):-
                queue_threshold(Qth),
                intranode_queue(I),
                length(I,Qn),
                P is Qth - Qn,
                ((P > 0)->
                        Ps = P; Ps = 0
                ).

cloning_pressure(Ps):- writeln('cloning_pressure Failed'),!.

% deduct_clonal_resource/2 deducts from the Agent the amount of resource used for making clone.
:-dynamic deduct_clonal_resource/2.
deduct_clonal_resource(GUID,NC):-
                clone_resource(Rmin),
                agent_resource(GUID,Rav),
                NR is Rav/Rmin,
                (
                        (NR=<NC)-> N = NR; N = NC

                ),
                Rav_next is Rav - (N*Rmin),

                ((Rav_next<0)->
                        (
                         %N1 is N-1,deduct_clonal_resource(GUID, N1)
                                nothing
                        );

                        (
                                
                                set_resource(GUID,Rav_next),
                                create_clones(GUID,N)
                        )
                ),!.

deduct_clonal_resource(GUID,NC):- write('deduct_clonal_resource Failed'),!.

% create_clones/2 creates the number of clones as specified in the input.
:-dynamic create_clones/2.

create_clones(GUID,0):- nl, writeln('Cloning Commencing>>>>>'),!.

create_clones(GUID,N):-
                        Nx is N-1,
                        create_clones(GUID,Nx),
                        writeln('Cloning no-->':N),
                        platform_port(P),
                        agent_clone(GUID,(localhost,P),Clone_ID),
                        set_clone_parameter(Clone_ID),
                        retractall(agent_kind(Clone_ID,_)),
                        assert(agent_kind(Clone_ID,clone)),
                        retractall(agent_parent(Clone_ID,_)),
                        assert(agent_parent(Clone_ID,GUID)),

                        platform_port(P),write('executing':Clone_ID:P).


create_clones(GUID,N):- writeln('create_clones Failed'),!.

% set_clone_parameter/1 sets the parameters viz. resource, lifetime etc. for the new formed clone.
:-dynamic set_clone_parameter/1.
set_clone_parameter(GUID):-
                clone_lifetime(L),
                clone_resource(R),
                set_lifetime(GUID,L),
                set_resource(GUID,R).

set_clone_parameter(GUID):- write('set_clone_parameter Failed'),!.

% set_lifettime/2 sets the lifetimes of the clone/agent.
:-dynamic set_lifetime/2.
set_lifetime(GUID,X):-

                %send_log(D),
                retractall(agent_lifetime(GUID,_)),
                assert(agent_lifetime(GUID,X)).

set_lifetime(GUID,X):- write('set_lifetime Failed'),!.

% set_resource/2 sets the resouce of the clone/agent.
:-dynamic set_resource/2.
set_resource(GUID,X):-

                retractall(agent_resource(GUID,_)),
                assert(agent_resource(GUID,X)).

set_resource(GUID,X):- write('set_resource Failed'),!.

%% get_sublist/3 gives a sublist till a position given as input for the list.
:-dynamic get_sublist/3.

get_sublist(Pos,List,List):- length(List,L),L=<Pos,!.

get_sublist(0,_,[]).

get_sublist(Pos,[H|T],[H|Tnew]):-
                        Pos1 is Pos -1,
                        %nl,write(Pos1),
                        get_sublist(Pos1,T,Tnew),!.


get_sublist(Pos,List,List2):- write('get_sublist Failed'),!.


%%=============================== Q-Manager Utilities ends=======================================


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Inserting into own ends%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%===Queue-Function===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=============================================================================
%                                       Queue
%                               ----------------------
%       Description: Queue implements a simple FIFO queue with basic enqueue()
%                        & dequeue() operations.
%
%=============================================================================



empty_queue([]).

enqueue(E, [], [E]).

enqueue(E, [H | T], [H | Tnew]) :-enqueue(E, T, Tnew).

dequeue(E, [E | T], T).

dequeue(E, [E | _], _).

member_queue(Element, Queue) :-member(Element, Queue).

add_list_to_queue(List, Queue, Newqueue) :-append(Queue, List, Newqueue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%===Queue-Function End===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                       ||||| DQ-Manager |||||
%                                               ==========
% Description: It performs the dequeuing function for the agent from the queue.
%                       It always checks the top of the queue and makes request to the next
%                       node whether the agent can be transferred or not and if yes then
%                       migrates the agent to the next node.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DQ-Manager : This agent takes care of transfering an agent to the next node.
:- dynamic dq_manager/1.
dq_manager(P):-
                create_static_agent(dq_manager,(localhost,P),dq_manager_handle),
                assert(dq_port(P)),
                write('=========== DQ-MANAGER =========='),
                write('=DQ-Manager started at Port':P),!.

dq_manager(P):- writeln('dq_manager Failed'),!.

% DQ-Manager handler to handle request and response to transfer an agent
% at the top of the intranode queue onto the next node.
:- dynamic dq_manager_handle/3.
% To tranfer an agent to the destination after an ACK is received.
dq_manager_handle(guid,(IP,P),ack(X)):-
                                       (transit_req(X)->
                                       retractall(transit_req(_)),
                                       assert(transit_req(0)),
                                       writeln('ACK by the receiver':P:X),
                                       initiate_migration(X);nothing),
                                       %release_agent,

                !.

dq_manager_handle(guid,(IP,P),ack(X)):- writeln('dq_manager_handle ACK Failed'),!.

% If the received response from the destination is an NAK.
dq_manager_handle(guid,(IP,P),nack(X)):-

                (transit_req(X)->
                                       retractall(transit_req(X)),
                                       assert(transit_req(0)),
                writeln('=Migration Denied (NAK) by the receiver'),

                 migrate_typhlet(X);nothing),



                !.

dq_manager_handle(guid,(IP,P),nack(X)):- writeln('dq_manager_handle NAK Failed'),!.

% To release agent from the intranode queue.
dq_manager_handle(Name,(IP,P),release(Q)):-
                        intranode_queue(Queue),
                        length(Queue,Len),
                        Len > 0,                % If queue is empty keep checking.
                        writeln('Releasing agent'),
                        intranode_queue([Agent|Tail]),  % select the agent at the top of the queue
                        agent_list_new(Aglist),writeln('agent list ': Aglist),
                        (member(Agent,Aglist)->
                        writeln('Removing agent from the Queue':Agent),
                        platform_port(PP),neighbour(NP,NEP),
                        assert(set_to_move(Agent)),
                        agent_GUID(Agent,Handler,(AIP,AP)),
                        agent_execute(Agent,(AIP,AP),Handler,move(localhost,P_tomove)),writeln(' SEMWAL!!!');
                        writeln('QUEUE PROBLEM RA.'),delete(Aglist,q_manager,Aglist1),
                        delete(Aglist1,dq_manager,Aglist2),
                        update_intranode_queue(Aglist2)),!.

dq_manager_handle(guid,(IP,P),release(Q)):-
                                                        intranode_queue(Queue),
                                                        length(Queue,Len),
                                                        Len = 0,
                                                        writeln('Dude queue is empty!!'),!.
                                                        
dq_manager_handle(guid,(IP,P),release(Q)):- writeln('DQ Mananger release() Failed due to some reason...'),!.

%leave_queue/3 contacts the destination of the agent whether it can move there or not.
:- dynamic leave_queue/3.
leave_queue(Agent,NIP,NPort):-

                platform_port(From_P),
                neighbour(NP,NEP),
                dq_port(DP),
                transit_req_timeout(Tout),
                retractall(transit_req(_,_)),
                assert(transit_req(Agent)),
                agent_post(platform,(localhost,NEP),[q_manager_handle,q_manager,(localhost,DP),recv_agent(Agent)]),
                writeln('Transit request sent':Agent:NP),
                set_transfer(Agent,localhost,NP),!.

leave_queue(Agent,IP,Port):- writeln('leave_queue Failed'),!.

% release_agent/0 selects the agent at the top of the Queue and posts the move() handler
% to start its migration procedure.
:- dynamic release_agent/0.
release_agent:-
                        dq_port(DP),agent_post(platform,(localhost,DP),[dq_manager_handle,dq_manager,(_,_),release(agent)]).

release_agent:- writeln('release_agent/0 failed due to some reason'),!.


%%=============================== DQ-Manager ends==============================================

%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%|| Q-manager Utilities ||%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%


:- dynamic set_transfer/3.
set_transfer(Agent,IP,Port):-
        retractall(leaving_queue(Agent,_,_)),
        assert(leaving_queue(Agent,IP,Port)).

set_transfer(Agent,IP,Port):- writeln('set_transfer Failed'),!.



:-dynamic timer_release/0.

timer_release:-
               sleep(0.5),release_agent,timer_release,!.

