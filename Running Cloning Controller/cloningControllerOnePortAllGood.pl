% Title: RAW version - Cloning Controller for Tartarus
% Author: Tushar Semwal 
% Date: 26-Oct-15

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Declarations                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:-style_check(-singleton). %%hide warnings due to singleton variables
:- use_module(library(assoc)).
:- use_module(library(lists)).

:-dynamic set_to_move/1.
:-dynamic q_port/1.
:-dynamic dq_port/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.
:-dynamic agent_resource/2.
:-dynamic agent_type/2.

:-dynamic need/1.                       % need = -1 means It will not require any need, now or in future. need = -2 means
                                        % it wont require anything now but will require in future. need = -3 means need
                                        % has already been satisfied. 

:-dynamic agent_inherit/2.
:-dynamic agent_visit/2.

:-dynamic intranode_queue/1.
intranode_queue([]).

:-dynamic ack_q/1.
ack_q([]).

:-dynamic transit_req/1.
transit_req(0).

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
tau_r(5).

:-dynamic sigma/1.
sigma(2).

:-dynamic child/1.
child('C').

:-dynamic agent_max_resource/1.
agent_max_resource(100).

:-dynamic agent_min_resource/1.
agent_min_resource(10).

:-dynamic type_of_agents/1.
type_of_agents(3).

:-dynamic global_mutex/1.
:-dynamic posted_lock/1.
:-dynamic posted_lock_dq/1.
:-dynamic platform_number/1.
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

                thread_create(timer_release(ID, 1),ID,[detached(false)]),
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

q_manager_handle_thread(ID,(IP,NP),X, Tokens):-
                
                writeln('Atleast till qmht'),

                posted_lock(GPOST),
                mutex_lock(GPOST),

                writeln('Request received for the arrival of agent':X),
                writeln('Arrival of agent from Port ':NP),
                
                intranode_queue(Li), 
                length(Li,Q_Len),
                
                queue_threshold(Len),
                
                ack_q(ACK_Q),
                length(ACK_Q,ACK_Len),
                
                platform_port(QP),
                
                L is Q_Len, 
                writeln(Len), writeln(Q_Len), writeln(ACK_Len), writeln(L), platform_token(Ptoken),
                (
                        (L<Len, member(Ptoken, Tokens))->
                        (                       
                                ack_q(Ack_Q),
                                append([X],Ack_Q,Nw_Ack_Q),
                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),ack(X)]),
                                writeln('Space is available in the queue. ACK sent.'),
                                %writeln('Ack Queue':Nw_Ack_Q),
                                update_ack_queue(Nw_Ack_Q),
                                movedagent(_,(localhost, NP), X)
                        )
                        ;
                        (
                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),nack(X)]),
                                writeln('No space is available in queue or Tokens do not match. NAK sent...')
                        )
                ),
                
                mutex_unlock(GPOST),
                !.

q_manager_handle_thread(ID,(IP,NP),X, _):-
                writeln('Q_maanger_handle_thread failed !!'), !.

:- dynamic q_manager_handle/3.

q_manager_handle(_,(IP,NP),recv_agent(X, Token)):-

                writeln('Arrived q_manager_handle atleast'),
                thread_create(q_manager_handle_thread(ID, (IP, NP), X, Token),ID,[detached(false)]),
                
                !.
                
q_manager_handle(guid,(IP,P),recv_agent(X, _)):- write('Q-manager handler failed!!'),!.

%%=============================== Q-Manager handler ends=======================================



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%===Inserting into own queue===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic migrate_typhlet/1.
migrate_typhlet(GUID):-
                writeln('\n'),
                writeln('Migrating agent to the Intranode queue':GUID),
                intranode_queue(I),
                 
                (member(GUID,I)->
                        (dequeue(GUID,I,In),enqueue(GUID,In,Inew))
                        ;
                        (enqueue(GUID,I,Inew), platform_port(QP))
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
                        retractall(ack_q(_)),
                        asserta(ack_q(X)),
                        !.

update_ack_queue(X):- write('update_ack_queue Failed'),!.


:- dynamic initiate_migration/1.
initiate_migration(GUID, NP):-
                
                agent_list_new(Aglist),
                (member(GUID, Aglist)->
                
                        writeln('\n'),
                        write('Leaving Queue':GUID),
                        writeln(' To ':NP),

                        platform_port(Q),
                
                        intranode_queue(I),
                        writeln('Initiate_migration Successful!!!, updated intranode queue:':I)

                        ;
                        nothing
                ),
        
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
                        writeln('Left Resource ':Rafter)

                )
        ),
        

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
                
                agent_clone(GUID,(localhost,P),Clone_ID), sleep(1),
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
                assert(my_service_reward(GUID, S)), 
                
                platform_port(P),

                retractall(agent_visit(GUID, _)),
                assert(agent_visit(GUID, [P])),

                !.

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

        %writeln('Rav':Rav),
        %writeln('P':P),

        %((Rav >= 1) -> ((P < 4) -> writeln('hihi') ; writeln('byby');nothing)),
        
        (
            ((Rav >= 1), (P =< 1)) -> (Rn is Rav + Mul11 + Mul12) ;
            ((Rav < 1), (P < 1)) -> (Rn is Rav + Tc + Mul21) ;
            ((P > 1)) -> (Rn is Rav +  Mul31 + Mul32);(Rn is Rav)
        ),

        %writeln('After updating the resource'),
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

                agent_list_new(Aglist),
                (member(X, Aglist)->
                        writeln('ACK by the receiver':P:X),
                        initiate_migration(X, P),
                        dq_manager_handler(_,(IP,P),X)

                        ;

                        nothing
                ),

                
        
                mutex_unlock(GPOSTT),
                !.

dq_manager_thread_ack(ID, (IP, P), X):-
                writeln('Dq_manager_thread_ack failed !!'), !.


:-dynamic dq_manager_thread_nak/3.
dq_manager_thread_nak(ID, (IP, P), X):-

                posted_lock_dq(GPOSTT),
                mutex_lock(GPOSTT),
                
                intranode_queue(I),
                length(I, Len),

                (Len > 0 -> 
                        intranode_queue([H|T]), agent_list_new(Aglist),
                        ((member(X, Aglist), H = X)->
                                writeln('Migration Denied (NAK) by the receiver'),
                                migrate_typhlet(X)
                                ;
                                nothing
                        )
                        ;
                        nothing
                ),
                
                mutex_unlock(GPOSTT),

                !.

dq_manager_thread_nak(ID, (IP, P), X):-
                writeln('Dq_manager_thread_nak failed !!'), !.


:- dynamic dq_manager_handle/3.
% To tranfer an agent to the destination after an ACK is received.
dq_manager_handle(_,(IP,P),ack(X)):- 

                writeln('Arrived dq_manager_handle_ack atleast'),
                thread_create(dq_manager_thread_ack(ID, (IP, P), X),ID,[detached(false)]),
                !.

dq_manager_handle(_,(IP,P),ack(X)):- writeln('dq_manager_handle ACK Failed'),!.

% If the received response from the destination is an NAK.
dq_manager_handle(_,(IP,P),nack(X)):-

                writeln('Arrived dq_manager_handle_nak atleast'),
                thread_create(dq_manager_thread_nak(ID, (IP, P), X),ID,[detached(false)]),
                !.

dq_manager_handle(_,(IP,P),nack(X)):- writeln('dq_manager_handle NAK Failed'),!.



:-dynamic dq_manager_handler/3.
% To release agent from the intranode queue.
dq_manager_handler(_,(IP,NP),Agent):-

                agent_list_new(Aglist),
                (member(Agent, Aglist)->
                
                        writeln('Removing agent from the Queue':Agent),

                        intranode_queue(Ihere),
                        writeln('Agents currently in queue ':Ihere),

                        agent_list_new(Tochk),
                        writeln('Agents in Aglist ':Tochk),

                        platform_port(PP),
                        
                        my_service_reward(Agent, S),
                        Snew is S+1,
                        writeln('New Reward is ':Snew),
                        give_reward(Agent, Snew),
                        
                        agent_visit(Agent, Vis),
                        enqueue(PP, Vis, Visnew),

                        retractall(agent_visit(Agent, _)), assert(agent_visit(Agent, Visnew)),

                        move_agent(Agent,(localhost,NP)),

                        dequeue(Agent,Ihere,In),

                        update_intranode_queue(In),
                        intranode_queue(Ifinal),
                        writeln('Agents now in queue ':Ifinal)
                        ;
                        nothing
                ),
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
                
                agent_token(Agent, Token),

                agent_post(platform,(localhost,NP),[q_manager_handle,_,(localhost,From_P),recv_agent(Agent, Token)]),
                writeln('Transit request sent':Agent:NP),

                mutex_unlock(GMID),

                !.

leave_queue(Agent,IP,Port):- writeln('leave_queue Failed'),!.


:-dynamic pher/2.
pher(H, NP):-
        find_highest_concentration_pheromone(H, PherName, NxtNode), writeln('Nxt Node ':NxtNode),
        NP = NxtNode,
        !.
pher(_, _):-
        writeln('Pher predicate failed !!'),
        !.


:-dynamic cons/2.
cons(H, NP):-
        nn_minus_vis(H, Nxtnode), writeln('Nxt node ':Nxtnode),
        NP = Nxtnode,
        !.
cons(_, _):-
        writeln('Cons predicate failed !!'),
        !.

delete_first([_|T], T).

:-dynamic phercon_decider/2.
phercon_decider(Agent, Decider):-
        
        agent_type(Agent, AgentType),
        pheromones_db(Pheromones),

        % Check if any pheromone has the same agent type
        (member([_, _, _, _, _, _, AgentType], Pheromones) ->
                Decider = 'P'
                ;
                Decider = 'C'
        ),

        !.

phercon_decider(_, _):-
        writeln('phercon_decider failed !!'),
        !.


% Define a predicate to find the pheromone with the highest concentration for a given agent type
find_highest_concentration_pheromone(Agent, PheromoneName, Nxt) :-
        
        agent_type(Agent, AgentType),
        
        % Get the list of pheromones
        pheromones_db(Pheromones),

        writeln('Pheromones list for reference ': Pheromones),

        % Initialize the maximum concentration and index of the pheromone with the highest concentration
        MaxConc = -2147483648,

        writeln('find_highest check 1..'),
        % Loop through the list of pheromones
        findall(I, (nth0(I, Pheromones, [_, Conc, _, _, _, _, AgentType]), Conc > MaxConc), Is),

        writeln('find_highest check 2..'),
        % If there are pheromones with the given agent type
        \+ Is = [],

        writeln('find_highest check 3..'),
        % Get the index of the pheromone with the highest concentration
        max_list(Is, MaxIdx),

        writeln('find_highest check 4..'),
        % Get the name of the pheromone with the highest concentration
        nth0(MaxIdx, Pheromones, [PheromoneName, _, _, Nxt, _, _, _]).



nn_minus_vis(Agent, NxtNode):-
        node_neighbours(NN),
        agent_visit(Agent, Vis),

        subtract(NN, Vis, Result),

        writeln('NN ':NN),
        writeln('Vis ':Vis),
        writeln('Result ':Result),

        length(Result, Len),

        (Len = 0 -> random_member(NxtNode, NN) ; random_member(NxtNode, Result)).

:-dynamic phercon_neighbour/1.
phercon_neighbour(NP):-
        
        writeln('Phercon neighbour check 1..'),

        intranode_queue([H|T]),
        writeln('Phercon neighbour check 2..':H),
        agent_visit(H, Vis),
        writeln('Phercon neighbour check 3..':H),
        writeln('Since queue is not empty, the topmost agents vis list is ':Vis),
        length(Vis, Vislen),
        (Vislen > 5 -> delete_first(Vis, RVis), retractall(agent_visit(H, _)), assert(agent_visit(H, RVis)) ; nothing),
        agent_visit(H, Nvis),
        writeln('New Visit ': Nvis),

        phercon_decider(H, Decider),

        writeln('Decider ':Decider),

        %(Decider = 'P' -> find_highest_concentration_pheromone(H, PherName, NxtNode), writeln('Nxt Node ':NxtNode); nn_minus_vis(H, Nxtnode), writeln('Nxt node ':Nxtnode)),

        (        
                Decider = 'P'->
                        pher(H, NP)
                        ;
                        cons(H, NP)
        ),

        !.

phercon_neighbour(_):-
        wrietln('Phercon neighbour failed !!'),
        !.




:- dynamic release_agent/0.
release_agent:-
                        global_mutex(GMID),
                        mutex_lock(GMID),
                                                
                        writeln('Release Agent called...'),
                        need(N),
                        node_neighbours(X),
                        length(X, L),

                        (
                        (L > 0)-> 
                        (
                                intranode_queue(I), length(I,Len), 
                                
                                (
                                        (Len > 0)->
                                        (
                                                node_neighbours([H | T]), % Shuffling..
                                                %NP is H,
                                                phercon_neighbour(NP),
                                                writeln('Decided NP ':NP),


                                                retractall(neighbour(_)), assert(neighbour(NP)),

                                                intranode_queue([Agent|Tail]), 

                                                clone_if_necessary(Agent), 

                                                
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

                                                enqueue(H, T, Tn), % Shuffling..
                                                
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

        ((Li =< 0)->(writeln('Agent Purged ':H),purge_agent(H),sleep(1) );(enqueue(H, Q, Qn), retractall(tmp_q(_)), assert(tmp_q(Qn)))),

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
        

:- dynamic decrement_lifetime/0.

decrement_lifetime:-

        intranode_queue(I),
        %agent_list_new(Aglist),
        %writeln('Aglist ': Aglist),
        %tmp_q(Q),
        %writeln('Q here ' :Q),
        %update_intranode_queue(Q),
        %retractall(tmp_q(_)),
        %assert(tmp_q([])),
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

        
        list_agents(Res),
        writeln('Agents truly here ':Res),
        !.

:-dynamic need_a_member/2.

need_a_member(Need, []).
need_a_member(Need, [H|T]) :- 
        
        agent_type(H, Typ),
        writeln('Check integrity ':H),
        writeln('Check integrity ':Typ),
        writeln('Check integrity ':Need),
        platform_port(P),
        satisfied_need(SN),

        ((Typ = Need, SN =:= 0)->(retractall(satisfied_need(_)), assert(satisfied_need(1)), agent_GUID(H,Handler,(localhost,P)),agent_execute(H,(localhost, P),Handler), update_resource(H), update_lifetime(H));(nothing)), 

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
        writeln("see_if_satisfy fails.."), 
        !.

% -------------------------- Pheromone Predicates Start ----------------------------------------

:-dynamic cmax/1.                                                       % Max Concentration..
cmax(1000).

:-dynamic lmax/1.
lmax(20).                                                               % Max Lifetime..

:-dynamic pheromones_db/1.
pheromones_db([]).                                                      % All pheromones at this Node..


:-dynamic pheromone_now/1.                                              % Pheromone present Now..
:-dynamic pheromone_time/1.

:-dynamic pheromone_timeout/1.
pheromone_timeout(20).


% Define a predicate to insert a pheromone into the list
insert_pheromone(Pheromone, List, NewList) :-
    % Check if the pheromone is already present in the list

        nth0(0, Pheromone, Name),
        nth0(1, Pheromone, Concentration),

    (member([Name, OldConcentration, _, _, _, _, _], List) ->
        % If the pheromone is already present, compare the concentrations
        (Concentration > OldConcentration ->
        % If the new pheromone has higher concentration, remove the old one
        remove_element([Name, OldConcentration, _, _, _, _, _], List, TempList),
        % Insert the new pheromone into the list
        insert_pheromone(Pheromone, TempList, NewList)
        ;
        % If the old pheromone has higher concentration, do not insert the new one
        NewList = List
        )
    ;
        % If the pheromone is not already present, insert it into the list
        enqueue(Pheromone, List, NewList)
    ).


% Define a predicate to update the list
update_list([Name, Power, Lifetime, X, Y, I, J], [Name, Power, Lifetime, X, [NewValue|Y], I, J], NewValue).

:-dynamic add_me_thread/2.
add_me_thread(_, X):-


    pheromones_db(DB),
    platform_port(PP),

    % update vis and then add in DB..
    update_list(X, NewX, PP),

    insert_pheromone(NewX, DB, DBnew),

    retractall(pheromones_db(_)),
    assert(pheromones_db(DBnew)),

    writeln('New Addition to Pheromone DB, Elements ':DBnew),
    !.

add_me_thread(_, _):-
    writeln('add_me_thread failed !!'),
    !.


:-dynamic add_me/2.
add_me(_,add(X)):-

    %thread_create(add_me_thread(_, X), _, [detached(false)]),
    add_me_thread(_, X),
    writeln('Add me ended..'),
    !.

add_me(_,_):-
    writeln('Add me failed !!'),
    !.


:-dynamic release_pheromones_to_nodes_init/2.                           % Release Pheromones to neighbours
release_pheromones_to_nodes_init([], _, _).

release_pheromones_to_nodes_init([NP|Rest], Need, N):-                              
    
    cmax(Cmax),
    lmax(Lmax),
    platform_port(PP),
    platform_number(Pnum),
    
    Name1 = 'Pheromone',
    atom_concat(Name1, Pnum, Name2),
    atom_concat(Name2, '_', Name3),
    atom_concat(Name3, N, ID),
    
    retractall(pheromone_now(_)),
    assert(pheromone_now(ID)),

    Pherom_ID = ID,
    Pherom_Conc = Cmax,
    Pherom_Life = Lmax,
    Next_Node = PP,
    Vis = [PP],
    D = 2,
    Type = Need,

    format("Values ~w, ~w, ~w, ~w, ~w, ~w, ~w, to ~w.~n", [Pherom_ID, Pherom_Conc, Pherom_Life, Next_Node, Vis, D, Type, NP]),

    agent_post(platform,(localhost,NP),[add_me,_,add([Pherom_ID, Pherom_Conc, Pherom_Life, Next_Node, Vis, D, Type])]),

    release_pheromones_to_nodes_init(Rest, Need, N),
    !.

release_pheromones_to_nodes_init(_,_):-
    writeln('Release pheromones to nodes failed !!'),
    !.


delete_me(ListToRemove, ListOfLists, NewListOfLists) :-
    delete(ListOfLists, ListToRemove, NewListOfLists).


:-dynamic delete_pheromone_request/2.

delete_pheromone_request([],_).

delete_pheromone_request([H|T],X):-
        
        %writeln('delete_pheromone_chk1..'),
        nth0(0, H, FirstElement),
        (
            
            FirstElement = X -> 
                pheromones_db(DB),
                %writeln('delete_pheromone_chk2..'),
                delete_me(H, DB, DBnew), 
                %writeln('delete_pheromone_chk3..'),
                retractall(pheromones_db(_)), assert(pheromones_db(DBnew))
                %writeln('New Deletion from Pheromone DB, Elements ':DBnew)
                ;
                %writeln('delete_pheromone_chk4..'),
                nothing
        ),

        delete_pheromone_request(T, X),
        !.

delete_pheromone_request([_],_):-
        writeln('Delete pheromone request Failed !!'),
        !.

:- dynamic whisperer_handle_thread/3.
whisperer_handle_thread(X):-
        

        writeln('Trying to delete pheromone..'),
        pheromones_db(DB),
        delete_pheromone_request(DB,X),
        !.

whisperer_handle_thread(_):-
        writeln('Whisperer handel thread Failed!!'),
        !.

:-dynamic whisperer/1.
whisperer(_,deletepherom(PH)):-
        
        %writeln('Arrived whisperer atleast.. Recieved Whispering request from ':NP),
        writeln('Arrived whisperer atleast.. Pheromone, whose request to be deleted, is recieved ':PH),
        %thread_create(whisperer_handle_thread(PH),_,[detached(false)]), 
        whisperer_handle_thread(PH),
        %whisperer_handle_thread(PH),
        !.

whisperer(_,deletepherom(_)):-
        writeln('Whisperer Failed!!'),
        !.

:-dynamic tell_all_other_nodes/2.

tell_all_other_nodes([], _).

tell_all_other_nodes([Node|Nodes], PHnow):-
        
        writeln('Tell other nodes start..'),
        platform_port(P),

        (
                (P = Node)->
                        nothing
                        ;
                        agent_post(platform,(localhost,Node),[whisperer,_,deletepherom(PHnow)])
        ),

        tell_all_other_nodes(Nodes, PHnow),
        !.

tell_all_other_nodes(_, _):-
        writeln('Tell all other nodes failed!!'),
        !.

% Define a predicate to check if the lifetime of a pheromone has expired
is_expired([_, _, Lifetime, _, _, _, _]) :-
    Lifetime =< 0.

% Define a predicate to decrement the lifetime of a pheromone
decrement_lifetime_pheromones([Name, Power, Lifetime, X, Y, I, J], [Name, Power, NewLifetime, X, Y, I, J]) :-
    NewLifetime is Lifetime - 1.

% Define a predicate to remove an element from a list
remove_element(_, [], []).
remove_element(E, [E|T], T).
remove_element(E, [H|T], [H|T_new]) :- remove_element(E, T, T_new).

% Define a predicate to remove expired pheromones from the list
remove_expired_pheromones(PheromonesList, NewPheromonesList) :-

    %writeln('Inside remove_expired_pheromones..'),

    % Traverse the list and decrement the lifetime of each pheromone
    maplist(decrement_lifetime_pheromones, PheromonesList, DecrementedPheromonesList),
    %writeln('before exclude':DecrementedPheromonesList),

    % Remove the expired pheromones
    exclude(is_expired, DecrementedPheromonesList, NewPheromonesList),

    %write('After exclude: '), write(NewPheromonesList), nl,
    !.

remove_expired_pheromones(_,_):-
    writeln('Remove expired pheromones failed !!'),
    !.

add_to_each_neighbour([], _).
add_to_each_neighbour([NP|Nodes], X):-
    agent_post(platform,(localhost,NP),[add_me,_,add(X)]),
    add_to_each_neighbour(Nodes, X),
    !.

add_to_each_neighbour(_,_):-
    writeln('Add to each neighbour failed !!'),
    !.


:-dynamic get_number/3.
get_number(Vis, NN, Res) :-
        %NN = [2,3,4,5],
        %Vis = [4,3,7],

        writeln('Vis':Vis),
        writeln('NN':NN),

        empty_assoc(SS0),
        insert_all(NN, SS0, SS1),
        insert_all(Vis, SS1, SS2),
        writeln('Before deletion:'),
        assoc_to_list(SS2, KVs1),
        writeln(KVs1),
        delete_all(Vis, SS2, SS3),
        writeln('After deletion:'),
        assoc_to_list(SS3, KVs2),
        writeln(KVs2),
        keys(KVs2, Res),
        writeln(Res).

insert_all([], SS, SS).
insert_all([E|Es], SS0, SS) :-
        put_assoc(E, SS0, false, SS1),
        insert_all(Es, SS1, SS).

delete_all([], SS, SS).
delete_all([E|Es], SS0, SS) :-
        ( get_assoc(E, SS0, false) ->
                del_assoc(E, SS0, _, SS1),
                delete_all(Es, SS1, SS)
                ;
                writeln('Failed to delete key:'), writeln(E), false
    ).

keys([], []).
keys([K-_|KVs], [K|Keys]) :-
    keys(KVs, Keys).


transfer_pheromones_util([]).
transfer_pheromones_util([H|T]):-
    
    writeln('Reached  transfer_pheromones_util!!'),
    pheromone_now(Pnow),
    nth0(0, H, FirstElement),

    (Pnow = FirstElement -> nothing
                ;
                % use add_me..
                lmax(Lmax),
                platform_port(PP),
                
                nth0(0, H, ID),
                nth0(1, H, Concentration), nth0(2, H, Pheromlife),
                nth0(4, H, Vis),
                nth0(5, H, D), nth0(6, H, Type),

                NewPherom_ID = ID,
                NewPherom_Conc is Concentration - 100 / D,
                NewPherom_Life is Pheromlife - Lmax/D,
                NewNext_Node = PP,
                NewVis = Vis,
                NewD is D + 1,
                NewType = Type,

                node_neighbours(NN),
                get_number(Vis, NN, Res),

                length(Res, RL),
                writeln('Res ':Res), writeln('RL ':RL),

                (NewPherom_Life > 0 -> add_to_each_neighbour(Res, [NewPherom_ID, NewPherom_Conc, NewPherom_Life, NewNext_Node, NewVis, NewD, NewType]) ; nothing)
    ),

    transfer_pheromones_util(T),
    !.

transfer_pheromones_util(_):-
    writeln('Transfer pheromones util failed !!'),
    !.

transfer_pheromones(DB):-

    writeln("transfer pheromones reached !!"),
    transfer_pheromones_util(DB),
    !.

transfer_pheromones(_):-
    writeln('Transfer Pheromones failed !!'),
    !.

:-dynamic decrement_lifetime_pheromones/0.
decrement_lifetime_pheromones:-


    writeln('Before decrementing start..'),
    pheromones_db(PheromonesList),
    write('PheromonesList: '), write(PheromonesList), nl,

    remove_expired_pheromones(PheromonesList, NewPheromonesList),
    write('NewPheromonesList: '), write(NewPheromonesList), nl,

    retractall(pheromones_db(_)),
    assertz(pheromones_db(NewPheromonesList)),
    !.

decrement_lifetime_pheromones:-
    writeln('Decrement lifetime of pheromone failed !!'),
    !.

:-dynamic pheromones_transfer/0.
pheromones_transfer:-


    pheromones_db(Dbxfer),
    writeln('Before Dbxfer..'),
    transfer_pheromones(Dbxfer),
    writeln('After Dbxfer..'),

    !.

pheromones_transfer:-
    writeln('Transfer failed !!'),
    !.



% -------------------------- Pheromone Predicates End ----------------------------------------


:-dynamic sanitize/3.

sanitize(Aglist, I, Result):-
        % find the intersection of I and Aglist
        intersection(I, Aglist, Intersection),
        % convert the intersection to a list and assign it to Result
        list_to_set(Intersection, Result).


frequencies(L, F) :-
    empty_assoc(E),
    frequencies_helper(L, E, A),
    assoc_to_list(A, P),
    sort(2, @>=, P, F).

frequencies_helper([], A, A).
frequencies_helper([H|T], A0, A) :-
    (   get_assoc(H, A0, V)
    ->  V1 is V+1, put_assoc(H, A0, V1, A1)
    ;   put_assoc(H, A0, 1, A1)
    ),
    frequencies_helper(T, A1, A).

freq_list(F, L) :-
    freq_list(F, [], L).

freq_list([], Acc, L) :-
    reverse(Acc, L).
freq_list([_-Freq|T], Acc, L) :-
    freq_list(T, [Freq|Acc], L).


sorted_pairs(Pairs, SortedPairs) :- sort(Pairs, SortedPairs).

get_agent_types(AgentTypes) :-
    intranode_queue(Agents),
    bagof(Type, Agent^(member(Agent, Agents), agent_type(Agent, Type)), AgentTypes).

give_data(PerAgentPopulation):-
        intranode_queue(I),
        length(I, Len),
        (Len > 0 ->

                get_agent_types(AgentTypes),
                frequencies(AgentTypes, PerAgentPopulation),
                %freq_list(Freqs, PerAgentPopulation),
                writeln('PerAgentPopulation ':PerAgentPopulation)

                ;

                PerAgentPopulation = [1-0, 2-0, 3-0],
                nothing
        ),
        !.

give_data(_):-
        writeln('Give data failed !!'),
        !.


pair_to_atom(Key-Value, Atom) :-
    atomic_list_concat([Key, Value], '-', Atom).


:-dynamic timer_release/2.

timer_release(ID, N):-

        platform_number(PNR),

        (
                (N =:= 1)->
                        (
                                sleep(30)
                        )
                        ;
                        (
                                (
                                        (N =:= 300)->
                                                (
                                                        halt
                                                )
                                                ;
                                                (
                                                        nothing
                                                )
                                )
                        )
        ),

        writeln('Iteration.. ':N),
        writeln('timer_release called..'),
        
        
        posted_lock(GPOST),
        posted_lock_dq(GPOSTT),

        mutex_lock(GPOST),
        mutex_lock(GPOSTT),

        writeln('Thread ID ':ID),


        agent_list_new(Agents_list),
        intranode_queue(Isan),

        sanitize(Agents_list, Isan, Rsan),

        update_intranode_queue(Rsan),

        write('In the beginning of iteration after sanitization, list is '),
        writeln(Rsan),
        
        satisfied_need(SN), 
        
        need(TmpNeed), % remove later
        ((N = 125, TmpNeed \== -1) -> retractall(need(_)), assert(need(0)) ; nothing), % remove later, just to check explosion of PerAgentPopulation
        
        need(Need),

        ((Need =:= 0 ; SN =:= 1)->(
                
                need_train(Need_Train),
                
                (N = 125 -> H = 3 ; random_member(H, Need_Train)), % modify this later, just to check explosion of PerAgentPopulation

                writeln('***************************************************************************'),
                writeln('Platform NEEDS the service of Agent ':H),
                writeln('***************************************************************************'),

                retractall(need(_)),
                assert(need(H)),

                retractall(satisfied_need(_)),
                assert(satisfied_need(0))

        );(nothing)),
        
        need(Needsat),

        (Needsat \== -1 -> see_if_satisfy(Needsat) ; nothing),
        
        satisfied_need(SAN),
        (
                (SAN =:= 1)->
                        (
                                intranode_queue(Ilog),
                                length(Ilog,Lenlog),

                                writeln('Need of Platform satisfied!! At Time Point ':N),

                                pheromone_now(PHnow),
                                
                                ((PHnow = 'None')-> nothing ; all_nodes(AN),tell_all_other_nodes(AN, PHnow)),

                                writeln('Reached after PHnow'),

                                retractall(pheromone_now(_)), assert(pheromone_now('None')),
                                retractall(pheromone_time(_)), assert(pheromone_time(1)),
                                
                                give_data(AgentData),
                                writeln('AgentData ':AgentData),
                                maplist(pair_to_atom, AgentData, Atoms),
                                atomic_list_concat(Atoms, ' ', AtomicList),
                                writeln('AtomicList ':AtomicList),

                                Str1 = N, Str2 = ' ', Str3 = '1', Str4 = ' ', Str5 = Lenlog, Str6 = ' ', Str7 = AtomicList,

                                atom_concat(Str1, Str2, W1), 
                                atom_concat(W1, Str3, W2),
                                atom_concat(W2, Str4, W3),
                                atom_concat(W3, Str5, W4),
                                atom_concat(W4, Str6, W5),
                                atom_concat(W5, Str7, W6),
                                
                                send_log(_, W6)
                        )
                        ;
                        (
                                need(Pheromone),
                                (
                                        Pheromone =:= -1 -> 
                                                        nothing
                                                        ;

                                                        intranode_queue(Ilog),
                                                        length(Ilog,Lenlog),
                                                        platform_port(Port),
                                                        writeln('Need of Platform NOT satisfied at time point ':N),
                                                        writeln('Releasing Pheromones started at ':Port),

                                                        node_neighbours(NN),
                            
                                                        pheromone_now(Pnow),
                                                        pheromone_timeout(PTO),
                                                        
                                                        pheromone_time(Ptime),

                                                        Newptime is Ptime + 1,

                                                        retractall(pheromone_time(_)),
                                                        assert(pheromone_time(Newptime)),

                                                        pheromone_time(PT),

                                                        ((((PT mod PTO) =:= 0), Pnow \== 'None')-> writeln('Inside Timeout 1..'),all_nodes(ANN),tell_all_other_nodes(ANN, Pnow);nothing),

                                                        % If need not equal 0, var is first time occurance of need we will release pheromones.. 
                                                        ((Pnow = 'None' ; ((PT mod PTO) =:= 0))-> release_pheromones_to_nodes_init(NN, Pheromone, N), writeln('releasing init complete') ; nothing),
                                                        

                                                        give_data(AgentData),
                                                        writeln('AgentData ':AgentData),
                                                        maplist(pair_to_atom, AgentData, Atoms),
                                                        atomic_list_concat(Atoms, ' ', AtomicList),
                                                        writeln('AtomicList ':AtomicList),

                                                        Str1 = N, Str2 = ' ', Str3 = '0', Str4 = ' ', Str5 = Lenlog, Str6 = ' ', Str7 = AtomicList,

                                                        atom_concat(Str1, Str2, W1), 
                                                        atom_concat(W1, Str3, W2),
                                                        atom_concat(W2, Str4, W3),
                                                        atom_concat(W3, Str5, W4),
                                                        atom_concat(W4, Str6, W5),
                                                        atom_concat(W5, Str7, W6),
                                                        
                                                        send_log(_, W6)
                                )
                        )
        ),

        decrement_lifetime_pheromones,
        pheromones_transfer,
    
        % find out neighbour, eliminate neighbours[] used in the code.. It will also contain pher/con move, 
        % this predicate lies inside release_agent

        release_agent,

        mutex_unlock(GPOSTT),
        sleep(5),
        mutex_unlock(GPOST),
        sleep(5),

        N1 is N + 1,
        timer_release(ID, N1),
        
        !.
