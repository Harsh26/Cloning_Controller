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
:-dynamic agent_type/2.
:-dynamic need/1.
:-dynamic agent_inherit/2.

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

:-dynamic child/1.
child('C').

%Harsh added..
:-dynamic platform_port/1.

:-dynamic agent_max_resource/1.
agent_max_resource(100).

:-dynamic agent_min_resource/1.
agent_min_resource(10).

:-dynamic global_mutex/1.
:-dynamic posted_lock/1.
:-dynamic posted_lock_dq/1.

:-dynamic satisfied_need/1.


%---------------------Declarations End----------------------------------------%


start_clonning_controller(P):-

                mutex_create(GMID),
                assert(global_mutex(GMID)),

                
                mutex_create(GPOST),
                assert(posted_lock(GPOST)),
                
                
                mutex_create(GPOSTT),
                assert(posted_lock_dq(GPOSTT)),

                set_log_server(localhost, 6666),

                q_manager(P),
                dq_manager(P),

                thread_create(timer_release(ID, 0),ID,[detached(false)]),
                !.


start_queue_manager(P):- write('start_queue_manager Failed'),!.

init_need(N):-
        retractall(need(_)),
        assert(need(N)),
        !.

q_manager(P):-
              write('=====Q-Manager====='),
              write('started at port': P),!.

q_manager(P):- write('q_manager failed'),!.


:- dynamic q_manager_handle_thread/3.

q_manager_handle_thread(ID,(IP,NP),X):-
                
                writeln('Atleast till qmht'),

                posted_lock(GPOST),
                mutex_lock(GPOST),

                writeln('Request received for the arrival of agent':X),
                writeln('Arrival of agent from Port ':NP),
                
                intranode_queue(Li), 
                length(Li,Q_Len),
                
                queue_length(Len),
                
                ack_q(ACK_Q),
                length(ACK_Q,ACK_Len),
                
                platform_port(QP),
                
                L is Q_Len, 
                writeln(Len), writeln(Q_Len), writeln(ACK_Len), writeln(L),
                (
                        (L<Len)->
                        (                       
                                ack_q(Ack_Q),
                                append([X],Ack_Q,Nw_Ack_Q),
                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),ack(X)]),
                                writeln('Space is available in the queue. ACK sent.'),
                                writeln('Ack Queue':Nw_Ack_Q),
                                update_ack_queue(Nw_Ack_Q),
                                movedagent(_,(localhost, NP), X)

                                ,
                                platform_port(Q),
                                Str1 = X, Str2 = ' arrived at Platform ', Str3 = Q, 
                                atom_concat(Str1, Str2, W1),
                                atom_concat(W1, Str3, W2),
                                send_log(_, W2)
                        )
                        ;
                        (
                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),nack(X)]),
                                writeln('No space is available in queue. NAK sent...'),
                                Strr1 = X, Strr2 = ' requested for arrival at Platform ', Strr3 = QP, Strr4 = ' which has no space.',
                                atom_concat(Strr1, Strr2, Wr1),
                                atom_concat(Wr1, Strr3, Wr2),
                                atom_concat(Wr2, Strr4, Wr3),
                                send_log(_, Wr3)
                        )
                ),
                
                mutex_unlock(GPOST),
                !.

q_manager_handle_thread(ID,(IP,NP),X):-
                writeln('Q_maanger_handle_thread failed !!'), !.

:- dynamic q_manager_handle/3.

q_manager_handle(_,(IP,NP),recv_agent(X)):-

                writeln('Arrived q_manager_handle atleast'),
                thread_create(q_manager_handle_thread(ID, (IP, NP), X),ID,[detached(true)]),
                
                !.
                
q_manager_handle(guid,(IP,P),recv_agent(X)):- write('Q-manager handler failed!!'),!.

%%=============================== Q-Manager handler ends=======================================



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%===Inserting into own queue===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic migrate_typhlet/1.
migrate_typhlet(GUID):-
                writeln('\n'),
                 writeln('Migrating agent to the Intranode queue':GUID),
                 intranode_queue(I),
                 
                 (member(GUID,I)->
                 (dequeue(GUID,I,In),enqueue(GUID,In,Inew));
                 (enqueue(GUID,I,Inew), platform_port(QP)
                 ,Str1 = GUID, Str2 = ' started at ' , atom_number(Str, QP) , atom_concat(Str1, Str2, W1), atom_concat(W1, Str, W2),send_log(_, W2)
                 )
                 ),

                 update_intranode_queue(Inew),
                 writeln('Agent added to the queue':Inew),
                 
                 Str3 = 'Intranode Queue Looks like this: ',
                 atomic_list_concat(Inew, ', ', Str4),
                 atom_concat(Str3, Str4, W3),
                 send_log(_, W3),

                 ack_q(ACK_Q),
                (
                        member(GUID,ACK_Q)->
                                        (
                                                delete(ACK_Q,GUID,NwACK_Q),
                                                update_ack_queue(NwACK_Q)
                                        );(nothing)
                ),
                writeln('ACK Q updated'),
                
                !.

migrate_typhlet(GUID):- writeln('Migrate Typhlet in Q-Manager Failed for':GUID),!.

% update_intranode_queue/1 updates the intranode_queue with the new queue list
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
initiate_migration(GUID, NP):-
                
                writeln('\n'),
                write('Leaving Queue':GUID),
                writeln(' To ':NP),

                platform_port(Q),

                Str1 = GUID, Str2 = ' leaving platform ', Str3 = Q, Str4 = ' to platform ', Str5 = NP,  
                atom_concat(Str1, Str2, W1),
                atom_concat(W1, Str3, W2),
                atom_concat(W2, Str4, W3),
                atom_concat(W3, Str5, W4),
                send_log(_, W4),

                
                intranode_queue(I),
                writeln('Initiate_migration Successful!!!, updated intranode queue:':I),

                send_log(_, 'Initiate_migration Successful!!!'),
        
        !.

initiate_migration(GUID):- writeln('initiate_migration Failed'),!.

% Assigns the clone same type as that of parent.
:-dynamic assign_type/2.
assign_type(G, X):-
                %writeln('chk this four ':G),
                %writeln('Value of New type X ':X),!.
                retractall(agent_type(G,_)),
                assert(agent_type(G, X)), 
                retractall(agent_inherit(G,_)),
                assert(agent_inherit(G, 'C')),
                !.

assign_type(GUID, X):- write('Assigning type Failed!!'), !.

% clone_if_necessary/1 makes clones if the agent at the top of the intranode queue as per the equations
% given in the paper and add those clone to the queue.

:-dynamic clone_if_necessary/1.
clone_if_necessary(GUID):-

        global_mutex(GMID),
        mutex_lock(GMID),

        platform_port(QP),

        no_of_clone(GUID,N),

        agent_resource(GUID, Rav),
        agent_min_resource(Rmin),

        NR is Rav - N * Rmin, 

        (
                (N = 0 ; NR < Rmin)->
                (
                        writeln('No Clones will be created':GUID)
                )
                ;
                (
                        writeln('Original Resource ':Rav), 
                        writeln('Creating Clones':N), 
                        
                        deduct_clonal_resource(GUID,N),

                        agent_resource(GUID, Rafter), 
                        writeln('Left Resource ':Rafter), 
        
                        Str1 = N, Str2 = ' number of clones made at platform ', Str3 = QP, Str4 = ' of ', Str5 = GUID,
                        atom_concat(Str1, Str2, W1),
                        atom_concat(W1, Str3, W2),
                        atom_concat(W2, Str4, W3),
                        atom_concat(W3, Str5, W4),
                        send_log(_, W4)

                )
        ),

        
        mutex_unlock(GMID),
        

        !.

clone_if_necessary(GUID):- writeln('clone_if_necessary/1 Failed'),!.

% no_of_clone/2 gives the no of clones that will be created for the agent GUID.

:-dynamic no_of_clone/2.
no_of_clone(GUID,N):-

                cloning_pressure(Ps),
                agent_resource(GUID,Rc),
                agent_max_resource(Rmax),
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

                ((P > 0)->(Ps is P);(Ps is 0)),
                
                !.

cloning_pressure(Ps):- writeln('cloning_pressure Failed'),!.

% deduct_clonal_resource/2 deducts from the Agent the amount of resource used for making clone.
:-dynamic deduct_clonal_resource/2.
deduct_clonal_resource(GUID,NC):-

        clone_resource(Rmin),
        agent_resource(GUID,Rav),
        
        Rav_next is Rav - (NC*Rmin),

        (
                (Rav_next<0)->
                (
                        nothing
                )
                ;
                (
                        set_resource(GUID,Rav_next),
                        create_clones(GUID,NC)
                )
        ),
                
                
        !.

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
                writeln('Clone ID ': Clone_ID),

                intranode_queue(Q),
                
                set_clone_parameter(Clone_ID),
                agent_type(GUID, Typ),
                assign_type(Clone_ID, Typ),
                intranode_queue(I),

                
                enqueue(Clone_ID,I,Inew),
                update_intranode_queue(Inew),

                writeln('Lets check queue ': Inew),
                        
        !.


create_clones(GUID,N):- writeln('create_clones Failed'),!.

% set_clone_parameter/1 sets the parameters viz. resource, lifetime etc. for the new formed clone.
:-dynamic set_clone_parameter/1.
set_clone_parameter(GUID):-
                clone_lifetime(L),
                clone_resource(R),
                service_reward(S),
                
                retractall(agent_lifetime(GUID,_)),
                assert(agent_lifetime(GUID,L)),

                retractall(agent_resource(GUID,_)),
                assert(agent_resource(GUID,R)),
                
                retractall(my_service_reward(GUID,_)),
                assert(my_service_reward(GUID, S)), !.

set_clone_parameter(GUID):- write('set_clone_parameter Failed'),!.


:-dynamic give_reward/2.
give_reward(GUID, X):-
                retractall(my_service_reward(GUID,_)),
                assert(my_service_reward(GUID, X)).

give_reward(GUID, X):- write('Give Rewards Failed!!'), !.

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

:-dynamic movedagent/3.
movedagent(_,(IP,NP), X):-    	

                
        writeln('Agent arrived for insertion to queue ':X),
        writeln('Agent arrived from ':NP),
        platform_port(Thisport),

        Str1 = X, Str2 = ' arrived at Platform ', Str3 = Thisport, Str4 = ' from port ', Str5 = NP, 
        atom_concat(Str1, Str2, W1),
        atom_concat(W1, Str3, W2),
        atom_concat(W2, Str4, W3),
        atom_concat(W3, Str5, W4),
        send_log(_, W4),

        writeln('This executed..'),
        intranode_queue(I),
        writeln('This also executed..'),
        
        enqueue(X,I,Inew),
        

        writeln('This did execute'),
        update_intranode_queue(Inew),
        writeln('Agent added to the queue':Inew),

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
        
        Str1 = GUID, Str2 = ' lifetime is increased to ', Str3 = X, 
        atom_concat(Str1, Str2, W1),
        atom_concat(W1, Str3, W2),
        send_log(_, W2),
        !.

update_lifetime(GUID):- writeln('Update lifetime failed!!'),!.

        

:- dynamic update_resource/1.
update_resource(GUID):-
        %writeln('here'),
        agent_resource(GUID, Rav),
        writeln('Agents original resource ' :Rav),
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
        
        ((P = 0)->(Z is 1 - 1/0.001);(Z is 1 - 1/P)),
        
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
            ((Rav >= 1), (P =< 1)) -> (Rn is Rav + Mul11 + Mul12) ;
            ((Rav < 1), (P < 1)) -> (Rn is Rav + Tc + Mul21) ;
            ((P > 1)) -> (Rn is Rav +  Mul31 + Mul32)
        ),

        (Rn > Rmax->Rf is Rmax ; Rf is Rn),

        set_resource(GUID, Rf),
        agent_resource(GUID, X),
        writeln('Value of new resource ': X),

        Str1 = GUID, Str2 = ' resource is increased to ', Str3 = X, 
        atom_concat(Str1, Str2, W1),
        atom_concat(W1, Str3, W2),
        send_log(_, W2),

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
                write('=========== DQ-MANAGER =========='),
                write('=DQ-Manager started at Port':P),!.

dq_manager(P):- writeln('dq_manager Failed'),!.

% DQ-Manager handler to handle request and response to transfer an agent
% at the top of the intranode queue onto the next node.


:-dynamic dq_manager_thread_ack/3.
dq_manager_thread_ack(ID, (IP, P), X):-

                posted_lock_dq(GPOSTT),
                mutex_lock(GPOSTT),

                writeln('ACK by the receiver':P:X),
                initiate_migration(X, P),
                dq_manager_handler(_,(IP,P),X),
        
                mutex_unlock(GPOSTT),
                !.

dq_manager_thread_ack(ID, (IP, P), X):-
                writeln('Dq_manager_thread_ack failed !!'), !.


:-dynamic dq_manager_thread_nak/3.
dq_manager_thread_nak(ID, (IP, P), X):-

                posted_lock_dq(GPOSTT),
                mutex_lock(GPOSTT),

                writeln('Migration Denied (NAK) by the receiver'),
                
                Str1 = X, Str2 = ' cannot enter the other platform', 
                atom_concat(Str1, Str2, W1),
                send_log(_, W1),

                migrate_typhlet(X),

                mutex_unlock(GPOSTT),

                !.

dq_manager_thread_nak(ID, (IP, P), X):-
                writeln('Dq_manager_thread_nak failed !!'), !.


:- dynamic dq_manager_handle/3.
% To tranfer an agent to the destination after an ACK is received.
dq_manager_handle(_,(IP,P),ack(X)):- 

                writeln('Arrived dq_manager_handle_ack atleast'),
                thread_create(dq_manager_thread_ack(ID, (IP, P), X),ID,[detached(true)]),
                !.

dq_manager_handle(_,(IP,P),ack(X)):- writeln('dq_manager_handle ACK Failed'),!.

% If the received response from the destination is an NAK.
dq_manager_handle(_,(IP,P),nack(X)):-

                writeln('Arrived dq_manager_handle_nak atleast'),
                thread_create(dq_manager_thread_nak(ID, (IP, P), X),ID,[detached(true)]),
                !.

dq_manager_handle(_,(IP,P),nack(X)):- writeln('dq_manager_handle NAK Failed'),!.



:-dynamic dq_manager_handler/3.
% To release agent from the intranode queue.
dq_manager_handler(_,(IP,NP),Agent):-

                writeln('Removing agent from the Queue':Agent),

                intranode_queue(Ihere),
                writeln('Agents currently in queue ':Ihere),

                platform_port(PP),
                
                my_service_reward(Agent, S),
                Snew is S+1,
                writeln('New Reward is ':Snew),
                give_reward(Agent, Snew),
                
                move_agent(Agent,(localhost,NP)),

                dequeue(Agent,Ihere,In),

                update_intranode_queue(In),
                intranode_queue(Ifinal),
                writeln('Agents now in queue ':Ifinal), 

                Str1 = 'Queue is: ', atomic_list_concat(Ifinal, ', ', Str2), Str3 = ' at platform ', Str4 = PP, 
                
                atom_concat(Str1, Str2, W1),
                atom_concat(W1, Str3, W2),
                atom_concat(W2, Str4, W3),
                send_log(_, W3),

        !.

dq_manager_handler(_,(IP,NP),Agent):-
        writeln('Dq_manager_handler failed !!'), !.

%leave_queue/3 contacts the destination of the agent whether it can move there or not.

:- dynamic leave_queue/3.
leave_queue(Agent,NIP,NPort):-
                
                global_mutex(GMID),
                mutex_lock(GMID),

                platform_port(From_P),
                neighbour(NP),
                agent_post(platform,(localhost,NP),[q_manager_handle,_,(localhost,From_P),recv_agent(Agent)]),
                writeln('Transit request sent':Agent:NP),

                mutex_unlock(GMID),

                !.

leave_queue(Agent,IP,Port):- writeln('leave_queue Failed'),!.



:- dynamic release_agent/0.
release_agent:-
                        writeln('Release Agent called...'),
                        need(N),
                        node_neighbours(X),
                        length(X, L),

                        (
                        (L > 0)-> 
                        (
                                node_neighbours([H | T]),
                                NP is H,
                                retractall(neighbour(_)), assert(neighbour(NP)),

                                intranode_queue(I), length(I,Len), 
                                
                                (
                                        (Len > 0)->
                                        (
                                                intranode_queue([Agent|Tail]), 
                                                clone_if_necessary(Agent), 

                                                global_mutex(GMID),
                                                mutex_lock(GMID),
                                                
                                                decrement_lifetime, 
                                                showlifetime, 
                                                
                                                mutex_unlock(GMID),

                                                intranode_queue(Ileave), 
                                                length(Ileave,Lenleave),

                                                (
                                                        (Lenleave > 0)->
                                                        (
                                                                intranode_queue([Newagent|Newtail]),
                                                                leave_queue(Newagent, localhost, NP)
                                                        );
                                                        (
                                                                nothing
                                                        )
                                                ),

                                                enqueue(H, T, Tn), 
                                                
                                                retractall(node_neighbours(_)), 
                                                assert(node_neighbours(Tn))
                                        )
                                                
                                        ;
                                                
                                        (
                                                nothing
                                        )
                                )
                        )
                                
                        ;

                        (
                                intranode_queue(I), 
                                length(I,Len), 
                        
                                (
                                        (Len > 0)->
                                        (
                                                intranode_queue([Agent|Tail]),  
                                                clone_if_necessary(Agent),

                                                global_mutex(GMID),
                                                mutex_lock(GMID),
                                                
                                                decrement_lifetime, 
                                                showlifetime,
                                        
                                                mutex_unlock(GMID)
                                        )

                                        ;
                                        (
                                                nothing
                                        )
                                )
                        )
                ),

                !.
release_agent:-
                writeln('Release Agent Failed !'),!.


%%=============================== DQ-Manager ends==============================================

%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%|| Q-manager Utilities ||%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%                                                                         %%%%%%%%%%%%%%%%%%%%%%%

:-dynamic show_lf/1.

show_lf([]).

show_lf([H|T]):-
        %process(H),

        agent_lifetime(H, L),
        agent_type(H, Typ),
        write('Agent ':H),
        write(' has lifetime' :L),
        write(' whose type is ':Typ),
        writeln('\n'),

        Str1 = 'Lifetime of agent ', Str2 = H, Str3 = ' is: ', Str4 = L, 
        atom_concat(Str1, Str2, W1),
        atom_concat(W1, Str3, W2),
        atom_concat(W2, Str4, W3),
        send_log(_, W3),

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
        agent_inherit(H, Inherit),
        parent(Par),
        %writeln('In ':Inherit),
        %writeln('Par ':Par),

        ((Inherit = Par, L =< 0)->(retractall(agent_lifetime(H, _)), assert(agent_lifetime(H, 1)));(writeln(''))),

        agent_lifetime(H, Li),

        ((Li =< 0)->(writeln('Agent Purged ':H),purge_agent(H), Str1 = H, Str2 = ' is purged..', atom_concat(Str1, Str2, W1),
        
        send_log(_, W1));(enqueue(H, Q, Qn), retractall(tmp_q(_)), assert(tmp_q(Qn)))),

        del_zero_lifetime(T),


        !.

:-dynamic do_decr/1.

do_decr([]).

do_decr([H|T]):-
        
        %writeln('do_decr_start'),
        %writeln('H ':H),
        
        agent_lifetime(H, O),
        

        %(Inherit = Par)->(writeln('came here'),do_decr(T));(nothing),
        
        N is O - 1, 
        %writeln('do_decr mid'),
        retractall(agent_lifetime(H, _)),assert(agent_lifetime(H, N)),
        %writeln('do_decr end'),
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
        %writeln('Aglist ': Aglist),
        member_check(I),
        tmp_q(Q),
        %writeln('Q here ' :Q),
        update_intranode_queue(Q),
        retractall(tmp_q(_)),
        assert(tmp_q([])),
        %writeln('Decrement lifetime of ': I),
        do_decr(I),
        intranode_queue(Ii),
        %writeln('Decrement cycle Done ! now lifetimes ':Ii),

        del_zero_lifetime(Ii),
        
        writeln('Ii here ' :Ii),
        tmp_q(R),
        writeln('Q here ' :R),
        update_intranode_queue(R),
        intranode_queue(Iii),
        %writeln('New Iii here ' :Iii),
        retractall(tmp_q(_)),
        assert(tmp_q([])),
        
        agent_list_new(AGV),
        writeln('Aglist ': AGV),
        !.

:-dynamic need_a_member/2.

need_a_member(Need, []).
need_a_member(Need, [H|T]) :- 
        
        agent_type(H, Typ),
        writeln('Check integrity ':H),
        writeln('Check integrity ':Typ),
        writeln('Check integrity ':Need),

        satisfied_need(SN),

        ((Typ = Need, SN =:= 0)->(retractall(satisfied_need(_)), assert(satisfied_need(1)), update_resource(H), update_lifetime(H));(nothing)), 

        need_a_member(Need, T), 
        
        !.

:-dynamic see_if_satisfy/1.

see_if_satisfy(Needsat):-

        writeln('See if satisfy called..':Needsat),

        intranode_queue(I),
        writeln('See_if_satisfy queue':I),

        agent_list_new(AGV),
        writeln('See_if_satisfy Aglist ': AGV),

        length(I, Len),
        satisfied_need(SSN),
        writeln('This is SSN ':SSN),

        (
                (Len > 0)->
                        
                        (
                                need_a_member(Needsat, I),
                                satisfied_need(SN),        
                                writeln('This is SN ':SN),                        
                                ((SN =:= 1)->(writeln("Need of platform satisfied.. It needed ":Needsat));(nothing))
                                
                        )
                        ;
                        (nothing)
        ),

        writeln('See if satisfy ended..'),
        !.

see_if_satisfy(Needsat):-
        writeln("see_if_satisfy fails.."), !.


:-dynamic timer_release/2.

timer_release(ID, N):-

        ((N =:= 0)->(sleep(60));(nothing)),
        
        writeln('timer_release called..'),
        
        
        posted_lock(GPOST),
        posted_lock_dq(GPOSTT),

        mutex_lock(GPOST),
        mutex_lock(GPOSTT),

        writeln('Thread ID ':ID),

        satisfied_need(SN), 
        need(Need),
                
        ((Need =:= 0 ; SN =:= 1)->(

                need_train([H|T]),

                writeln('***************************************************************************'),
                writeln('Platform NEEDS the service of Agent ':H),
                writeln('***************************************************************************'),

                retractall(need(_)),
                assert(need(H)),

                enqueue(H, T, Tn),                 
                retractall(need_train(_)), 
                assert(need_train(Tn)),

                retractall(satisfied_need(_)),
                assert(satisfied_need(0))

        );(nothing)),
        
        need(Needsat),
        see_if_satisfy(Needsat),
        
        release_agent,

        mutex_unlock(GPOSTT),
        sleep(5),
        mutex_unlock(GPOST),
        sleep(5),

        N1 is N + 1,
        timer_release(ID, N1),
        
        !.