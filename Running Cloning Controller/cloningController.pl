% Title: RAW version - Cloning Controller for Tartarus
% Author: Tushar Semwal 
% Date: 26-Oct-15
% Notes: This version is NOT thread safe. Needs "mutex" here and there! 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Declarations                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:-style_check(-singleton). %%hide warnings due to singleton variables

:-dynamic set_to_move/1.
:-dynamic q_port/1.
:-dynamic dq_port/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.
:-dynamic agent_resource/2.

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

%Harsh added..
:-dynamic platform_port/1.

:-dynamic agent_max_resource/2.
agent_max_resource(100).

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
              create_static_agent(q_manager,(localhost,P),q_manager_handle,[30]),
              assert(q_port(P)),
              write('=====Q-Manager====='),
              write('started at port': P),!.

q_manager(P):- write('q_manager failed'),!.

:- dynamic q_manager_handle/3.

q_manager_handle(guid,(IP,P),recv_agent(X)):-
                                            writeln('Request received for the arrival of agent':X),
                                            writeln('Arrival of agent from Port ':P),
                                             intranode_queue(Li), length(Li,Q_Len),queue_length(Len),
                                             ack_q(ACK_Q),length(ACK_Q,ACK_Len),
                                             L is ACK_Len + Q_Len, 
                                             writeln(Len), writeln(Q_Len), writeln(ACK_Len), writeln(L),
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
                                                                   %writeln('Q-Port ':QP),
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
                 writeln('\n'),
                 writeln('Migrating agent to the Intranode queue':GUID),
                 intranode_queue(I),
                 (member(GUID,I)->
                 (dequeue(GUID,I,In),enqueue(GUID,In,Inew));
                 enqueue(GUID,I,Inew)
                 ),

                 update_intranode_queue(Inew),
                 writeln('Agent added to the queue':Inew),

                 %writeln('After updating the intranode queue'),
                 %intranode_queue(Itwo),
                 %writeln(Itwo),

                 ack_q(ACK_Q),
                (
                        member(GUID,ACK_Q)->
                                        (
                                                delete(ACK_Q,GUID,NwACK_Q),
                                                update_ack_queue(NwACK_Q)
                                        );(nothing)
                ),
                writeln('ACK Q updated'),

                writeln('ACK Q is ':ACK_Q),

                %writeln('Going to Call Leave Queue..'),
                
                !.

migrate_typhlet(GUID):- writeln('Migrate Typhlet in Q-Manager Failed for':GUID),!.

% update_internode_queue/1 updates the internode_queue with the new queue list
:- dynamic update_intranode_queue/1.
update_intranode_queue(Inew):-

                        %writeln('Here in update function, Agent added to the queue':Inew),
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
                                
                                leaving_queue(GUID,IP,Port),
                                
                                neighbour(NP,NEP),

                                writeln('\n'),
                                writeln('Leaving Queue':GUID:IP:Port),
                                writeln('To ':NP),

                                %catch(agent_move(GUID,(localhost,NP)),Err,writeln(Err)), 
                                %catch(retractall(nak_record(GUID,_)),ERr,write(ERr)),
                                %retract(set_to_move(GUID)), writeln('here bro'),
                                intranode_queue(I),
                                %dequeue(GUID,I,Inew),
                                
                                %update_intranode_queue(Inew),

                                writeln('initiate_migration Successful!!!, updated intranode queue:':I),
                                !.
initiate_migration(GUID):- writeln('initiate_migration Failed'),!.

% clone_if_necessary/1 makes clones if the agent at the top of the intranode queue as per the equations
% given in the paper and add those clone to the queue.
:-dynamic clone_if_necessary/1.
clone_if_necessary(GUID):-
              no_of_clone(GUID,N), %writeln(N),
                ( (N = 0)->(writeln('No Clones will be created':GUID));(writeln('Creating Clones':N), deduct_clonal_resource(GUID,N))),
                !.

clone_if_necessary(GUID):- writeln('clone_if_necessary/1 Failed'),!.

% no_of_clone/2 gives the no of clones that will be created for the agent GUID.
:-dynamic no_of_clone/2.
no_of_clone(GUID,N):-
                cloning_pressure(Ps),
                writeln('chk failure 8'),
                writeln('Guid came ': GUID),
                agent_resource(GUID,Rc),
                writeln('Guid gone ': GUID),
                writeln('Rc ': Rc),
                agent_max_resource(Rmax), %(GUID,Rmax),
                writeln('chk failure 9'),
                R is Rc/Rmax,
                writeln('chk failure 10'),
                N is round(Ps*R),
                
                %writeln(N),
                !.

no_of_clone(GUID,N):- writeln('no_of_clone/2 Failed'),!.

% cloning_pressure/1 returns the current cloning pressure at the node.
:-dynamic cloning_pressure/1.
cloning_pressure(Ps):-
                queue_threshold(Qth),
                intranode_queue(I),

                writeln('Inside Cloning Pressure':I),
                length(I,Qn),
                writeln('Length of queue':Qn),
                writeln('Queue threshold':Qth),

                P is Qth - Qn,
                ((P > 0)->(Ps is P);(Ps is 0)),
                
                !.

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
                         N1 is N-1,deduct_clonal_resource(GUID, N1),
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

                        intranode_queue(I),
                        (member(Clone_ID,I)->
                        (dequeue(Clone_ID,I,In),enqueue(Clone_ID,In,Inew));
                        enqueue(Clone_ID,I,Inew)
                        ),
                        
                        update_intranode_queue(Inew),

                        %retractall(agent_kind(Clone_ID,_)),
                        %assert(agent_kind(Clone_ID,clone)),
                        %retractall(agent_parent(Clone_ID,_)),
                        %assert(agent_parent(Clone_ID,GUID)),

                        platform_port(P),write('Executing':Clone_ID:P), !.


create_clones(GUID,N):- writeln('create_clones Failed'),!.

% set_clone_parameter/1 sets the parameters viz. resource, lifetime etc. for the new formed clone.
:-dynamic set_clone_parameter/1.
set_clone_parameter(GUID):-
                clone_lifetime(L),
                clone_resource(R),
                service_reward(S),
                %set_lifetime(GUID,L),
                %set_resource(GUID,R),
                %set_reward(GUID, S),
                
                retractall(agent_lifetime(GUID,_)),
                assert(agent_lifetime(GUID,L)),
                retractall(agent_resource(GUID,_)),
                assert(agent_resource(GUID,R)),
                retractall(my_service_reward(GUID,_)),
                assert(my_service_reward(GUID, S)).

                %add_payload(GUID, [(agent_resource,2), (agent_lifetime, 2), (my_service_reward, 2)]).

set_clone_parameter(GUID):- write('set_clone_parameter Failed'),!.

% set_lifettime/2 sets the lifetimes of the clone/agent.
%:-dynamic set_lifetime/2.
%set_lifetime(GUID,X):-

                %send_log(D),
                
%set_lifetime(GUID,X):- write('set_lifetime Failed'),!.

:-dynamic give_reward/2.
give_reward(GUID, X):-
                %writeln('Value of New X ':X),
                retractall(my_service_reward(GUID,_)),
                assert(my_service_reward(GUID, X)).

give_reward(GUID, X):- write('Give Rewards Failed!!'), !.

%:-dynamic set_reward/2.
%set_reward(GUID,X):-

                %send_log(D),
                %retractall(my_service_reward(GUID,_)),
                %assert(my_service_reward(GUID,X)).

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

% Harsh added...

:-dynamic moveagent/3.
moveagent(_,(IP,P), recv_agent(X)):-    			
	writeln('Agent arrived for insertion to queue ':X),
        writeln('Agent arrived from ':P),

        intranode_queue(I),
        (member(X,I)->
                 (dequeue(X,I,In),enqueue(X,In,Inew));
                 enqueue(X,I,Inew)
        ),

        update_intranode_queue(Inew),
        writeln('Agent added to the queue':Inew),

        update_resource(X),
        update_lifetime(X),
        !.
                
moveagent(_,(IP,P),recv_agent(X)):- writeln('moveagent in cloning controller failed!!'),!.

:- dynamic update_lifetime/1.
update_lifetime(GUID):-
        sigma(S),
        agent_lifetime(GUID, O),
        N is O + S * 1,
        retractall(agent_lifetime(GUID, _)),
        assert(agent_lifetime(GUID, N)),
        agent_lifetime(GUID, X),
        writeln('Updated lifetime':X),
        !.

update_lifetime(GUID):- writeln('Update lifetime failed!!'),!.

        

:- dynamic update_resource/1.
update_resource(GUID):-
        %writeln('here'),
        agent_resource(GUID, Rav),
        %writeln('Agents original resource ' :Rav),
        agent_max_resource(Rmax),
        %writeln('Agents Max resource ' :Rmax),
        cloning_pressure(P),
        %writeln('Agents Cloning Pressure ' :P),
        tau_c(Tc),
        %writeln('Tau c ' :Tc),
        tau_r(Tr),
        %writeln('Tau r' :Tr),

        Y is -1/Rav,
        %writeln('Y is ': Y),
        
        ((P = 0)->(Z is 1 - 1/0.1);(Z is 1 - 1/P)),
        
        %writeln('Z is ':Z),

        Pow1 is 2.71**Y,
        %writeln('Pow1 is ':Pow1),
        Pow2 is 2.71**Z,
        %writeln('Pow2 is ' :Pow2),

        Mul11 is Tc * Pow1,
        %writeln('Mul11 is ':Mul11),
        Mul12 is Tr * 1,   
        %writeln('Mul12 is ':Mul12),

        Mul21 is Tr * 1,
        %writeln('Mul21 is ':Mul21),
        Mul31 is Tc * Pow2,
        %writeln('Mul31 is ':Mul31),
        Mul32 is Tr * 1,
        %writeln('Mul32 is ':Mul32),

        %((Rav >= 1) -> ((P < 4) -> writeln('hihi') ; writeln('byby');nothing)),

        (
            ((Rav >= 3), (P =< 1)) -> (Rn is Rav + Mul11 + Mul12) ;
            ((Rav < 1), (P < 1)) -> (Rn is Rav + Tc + Mul21) ;
            ((P > 1)) -> (Rn is Rav +  Mul31 + Mul32)
        ),

        (Rn > Rmax->Rf is Rmax ; Rf is Rn),

        set_resource(GUID, Rf),
        agent_resource(GUID, X),
        writeln('Value of new resource ': X),
        !.

update_resource(GUID):- writeln('Update resource Failed!!'), !.




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
                create_static_agent(dq_manager,(localhost,P),dq_manager_handle,[30]),
                assert(dq_port(P)),
                write('=========== DQ-MANAGER =========='),
                write('=DQ-Manager started at Port':P),!.

dq_manager(P):- writeln('dq_manager Failed'),!.

% DQ-Manager handler to handle request and response to transfer an agent
% at the top of the intranode queue onto the next node.
:- dynamic dq_manager_handle/3.
% To tranfer an agent to the destination after an ACK is received.
dq_manager_handle(guid,(IP,P),ack(X)):- writeln('Entered'),
                                       (transit_req(X)->
                                       retractall(transit_req(_)),
                                       assert(transit_req(0)),
                                       writeln('ACK by the receiver':P:X),
                                       initiate_migration(X);nothing),
                                       dq_port(DP),
                                       agent_post(platform,(localhost,DP),[dq_manager_handle,dq_manager,(_,_),release(X)]),
                                       %release_agent,

                !.

dq_manager_handle(guid,(IP,P),ack(X)):- writeln('dq_manager_handle ACK Failed'),!.

% If the received response from the destination is an NAK.
dq_manager_handle(guid,(IP,P),nack(X)):-

                (transit_req(X)->
                                       retractall(transit_req(X)),
                                       assert(transit_req(0)),
                writeln('=Migration Denied (NAK) by the receiver'),

                agent_list_new(Aglist),

                (member(X, Aglist)->(migrate_typhlet(X));(nothing))
                ;
                (nothing)
                ),

                !.

dq_manager_handle(guid,(IP,P),nack(X)):- writeln('dq_manager_handle NAK Failed'),!.




% To release agent from the intranode queue.
dq_manager_handle(guid,(IP,P),release(Q)):-
                        intranode_queue(Queue),
                        length(Queue,Len),
                        Len > 0,                % If queue is empty keep checking.
                        intranode_queue([Agent|Tail]),  % select the agent at the top of the queue
                        writeln('Releasing agent ':Agent),
                        %agent_list_new(Aglist),writeln('agent list ': Aglist),
                        writeln('Agent list ': Queue),
                        (member(Agent,Aglist)->
                        writeln('Removing agent from the Queue':Agent),
                        intranode_queue(Ihere),
                        writeln('Agents currently in queue ':Ihere),
                        platform_port(PP),neighbour(NP,NEP),
                        %assert(set_to_move(Agent)),
                        %agent_GUID(Agent,Handler,(AIP,AP)),
                        %agent_execute(Agent,(AIP,AP),Handler,move(localhost,P_tomove)),writeln(' SEMWAL!!!')

                        my_service_reward(Agent, S),
                        Snew is S+1,
                        writeln('New Reward is ':Snew),
                        give_reward(Agent, Snew),
                        
                        move_agent(Agent,(localhost,NP)),
                        post_agent(platform,(localhost,NP),[moveagent,_,(localhost,PP), recv_agent(Agent)]),

                        dequeue(Agent,Ihere,In),
                        update_intranode_queue(In),
                        writeln('Bye'),
                        intranode_queue(Ifinal),
                        writeln('Agents currently in queue ':Ifinal),
                        writeln('Printing decremented lifetimes...')
        
                        ;

                        agent_execute(Agent,(AIP,AP),Handler),
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
leave_queue(Agent,NIP,NPort):-      %NIP - neighbour IP
                
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

%:-dynamic do_release/1.

%do_release([[]]):-
%        decrement_lifetime,
%        showlifetime.


%do_release([H|T]):-
        
        
%       do_release([T]),
%        !.

%:-dynamic my_length/2.

%my_length([], 0).
%my_length([A | B], N):-
%        my_length(B, N1),
%        N is N1 + 1.

:- dynamic release_agent/0.
release_agent:-
                        writeln('Release Agent called...'),
                        node_neighbours(X),

                        %do_release(X),

                        %my_length(X,L),
                        %writeln('Length of list of list ':L),
                        length(X, L),

                        writeln('chk failure 1'),

                        ((L > 0)->(node_neighbours([H | T]), nth0(0, H, Elem), nth0(1, H, Elem1), writeln('Elem ':Elem), writeln('Elem1':Elem1), NP is Elem, NEP is Elem1, writeln('chk failure 2'),
                                
                                retractall(neighbour(_,_)), assert(neighbour(NP, NEP)), writeln('chk failure 3'),
                                intranode_queue(I), length(I,Len), writeln('chk failure 4'),
                                
                                ((Len > 0)->(intranode_queue([Agent|Tail]), writeln('Length test ':Len), writeln('Agent test ':Agent), clone_if_necessary(Agent), sleep(3), writeln('chk failure 11'),decrement_lifetime, sleep(3), writeln('chk failure 12'),showlifetime, writeln('chk failure 13'), leave_queue(Agent, localhost, NP), writeln('chk failure 14'),enqueue(H, T, Tn), writeln('chk failure 5'),retractall(node_neighbours(_)), assert(node_neighbours(Tn)));(sleep(3), decrement_lifetime, sleep(3), showlifetime)))
                                
                                ;

                                (intranode_queue(I), length(I,Len), writeln('chk failure 6'),
                                (Len > 0)->(intranode_queue([Agent|Tail]), writeln('Length test ':Len), writeln('Agent test ':Agent), clone_if_necessary(Agent), sleep(3), writeln('chk failure 7'), decrement_lifetime, showlifetime)
                                ;(decrement_lifetime, showlifetime))),

                        !.
release_agent:-
                writeln('Release Agent Failed !'),!.

                        %dq_port(DP), 

                        %write('on ':DP),
                        %writeln('\n'),
                        
                        %writeln('Leave Queue called on.. ':NP),
                        %leave_queue(agent1, localhost, NP),

                        %agent_post(platform,(localhost,DP),[dq_manager_handle,dq_manager,(_,_),release(agent1)]).



%%=============================== DQ-Manager ends==============================================

%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%|| Q-manager Utilities ||%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%


:- dynamic set_transfer/3.
set_transfer(Agent,IP,Port):-
        retractall(leaving_queue(Agent,_,_)),
        assert(leaving_queue(Agent,IP,Port)).

set_transfer(Agent,IP,Port):- writeln('set_transfer Failed'),!.

:-dynamic show_lf/1.

show_lf([]).

show_lf([H|T]):-
        %process(H),

        agent_lifetime(H, L),
        write('Agent ':H),
        write(' has lifetime' :L),
        writeln('\n'),

        show_lf(T),
        
        !.

showlifetime:-
        intranode_queue(I),
        show_lf(I),

        !.

:-dynamic tmp_q/1.
tmp_q([]).

:-dynamic del_zero_lifetime/1.

del_zero_lifetime([]).

del_zero_lifetime([H|T]):-
        agent_lifetime(H, L),
        tmp_q(Q),
        ((L =< 0)->(writeln('Agent Purged ':H), purge_agent(H));(enqueue(H, Q, Qn), retractall(tmp_q(_)), assert(tmp_q(Qn)))),
        del_zero_lifetime(T),
        !.

:-dynamic do_decr/1.

do_decr([]).

do_decr([H|T]):-
        writeln('do_decr_start'),
        writeln('H ':H),

        agent_lifetime(H, O),
        writeln('O ': O),
        N is O - 1,
        writeln('do_decr mid'),
        retractall(agent_lifetime(H, _)),assert(agent_lifetime(H, N)),
        writeln('do_decr end'),
        do_decr(T),
        
        !.

        %((N =< 0)-> (dequeue(H,I,In), purge_agent(H), update_intranode_queue(In), writeln('Agent removed from the queue, updated one ':In), do_decr(In)) 
        %  ; (retractall(agent_lifetime(H, _)),assert(agent_lifetime(H, N)), do_decr(T) )),%dequeue(H,I,In), enqueue(H, In, Inn), update_intranode_queue(Inn), do_decr(Inn))),
        %(retractall(agent_lifetime(H, _)),assert(agent_lifetime(H, N)), dequeue(H,I,In), enqueue(H, In, Inn), update_intranode_queue(Inn) )),
         

:-dynamic member_check/1.

member_check([]).

member_check([H|T]):-
        agent_list_new(Aglist),
        (member(H, Aglist)->    (
                                        tmp_q(Q),
                                        enqueue(H, Q, Qn), 
                                        retractall(tmp_q(_)),
                                        assert(tmp_q(Qn)),
                                        member_check(T)
                                )
                                ;
                                (
                                        member_check(T)
                                )
        ),

        !.
        
        

:- dynamic decrement_lifetime/0.

decrement_lifetime:-
        intranode_queue(I),
        agent_list_new(Aglist),
        writeln('Aglist ': Aglist),
        member_check(I),
        tmp_q(Q),
        writeln('Q here ' :Q),
        update_intranode_queue(Q),
        retractall(tmp_q(_)),
        assert(tmp_q([])),
        sleep(3),
        writeln('Decrement lifetime of ': I),
        do_decr(I),
        intranode_queue(Ii),
        writeln('Decrement cycle Done ! now lifetimes ':Ii),

        del_zero_lifetime(Ii),
        writeln('Ii here ' :Ii),
        tmp_q(R),
        writeln('Q here ' :R),
        update_intranode_queue(R),
        intranode_queue(Iii),
        writeln('New Iii here ' :Iii),
        retractall(tmp_q(_)),
        assert(tmp_q([])),
        !.


:-dynamic timer_release/0.

timer_release:-
        sleep(10),release_agent,
        timer_release,

        !.


