% Title: FInal version - Cloning Controller for Tartarus
% Author: Tushar Semwal + Harsh Bijwe
% Date: 18-05-2023

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

:-dynamic need/1.    % need = -1 means that node will not require any type of service ever
                     % need = 0 means that node will require service but it is not satisfied yet
                     % need = 1 means that node will require service and it is satisfied                  

:-dynamic agent_inherit/2. % agent_inherit = 'P' means that the agent is a parent agent
                           % agent_inherit = 'C' means that the agent is a child agent
:-dynamic agent_visit/2.   

:-dynamic intranode_queue/1.
intranode_queue([]). % All transcations happens via the queue only..

:-dynamic ack_q/1.
ack_q([]).

:-dynamic transit_req/1.
transit_req(0).

:-dynamic clone_lifetime/1. % Lifetime of the clone
clone_lifetime(10).

:-dynamic clone_resource/1. % Resource of the clone
clone_resource(10).

:-dynamic queue_threshold/1.
queue_threshold(5).     % Threshold or Max size of the intranode queue



:-dynamic tau_c/1.
tau_c(0.1).             

:-dynamic tau_r/1.
tau_r(5).

:-dynamic sigma/1.
sigma(7).

:-dynamic child/1.
child('C').

:-dynamic agent_max_resource/1.
agent_max_resource(100).        % Maximum resource that an agent can have

:-dynamic agent_min_resource/1.
agent_min_resource(10).         % Minimum resource that an agent can have

:-dynamic type_of_agents/1.
type_of_agents(3).              % Number of types of agents, has to be set by user.

:-dynamic global_mutex/1.
:-dynamic posted_lock/1.
:-dynamic posted_lock_dq/1.
:-dynamic platform_number/1.
:-dynamic satisfied_need/1.

:-dynamic bufferin/1.

%---------------------Declarations End----------------------------------------%


start_clonning_controller(P):-

                mutex_create(GMID),
                assert(global_mutex(GMID)), % Lock for internal operations, may not be required, just to ensure
                                            % no operation happens without taking a lock.

                
                mutex_create(GPOST),        % Lock for enqueuing the Agent. Ensures that no enqueue operation happens
                assert(posted_lock(GPOST)), % when platform is executing the Algorithm in the paper. After the 
                                            % algorithm is executed, the lock is released and the enqueue of agents can take place.
                
                mutex_create(GPOSTT),           % Lock for dequeueing the Agent. Ensures that no dequeue operation happens
                assert(posted_lock_dq(GPOSTT)), % when platform is executing the Algorithm in the paper. After the 
                                                % algorithm is executed, the lock is released and the dequeue of agents can take place.

                set_log_server(localhost, 6666), % setting up the Log server. Will result in error as per the Tartarus implementaion
                                                 % if not setup before running the code. It is already taken care of when we use spawn.py to execute.  

                q_manager(P),   % All enqueue related predicates are called in here.
                dq_manager(P),  % All dequeue related predicates are called in here.

                thread_create(timer_release(ID, 1),ID,[detached(false)]), % Cloning Controller runs as a seprate thread. 

                !.


start_queue_manager(P):- write('start_queue_manager Failed'),!.

% Initializes the need of the node.
init_need(N):-
        retractall(need(_)),
        assert(need(N)),
        !.


q_manager(P):-
              write('=====Q-Manager====='),
              write('started at port': P),!.

q_manager(P):- write('q_manager failed'),!.


% Main predicate of enqueue operation. 
:- dynamic q_manager_handle_thread/3.
q_manager_handle_thread(ID,(IP,NP),X, Tokens):-
                
                writeln('Atleast till qmht'),

                posted_lock(GPOST), 
                mutex_lock(GPOST),      % Acquire the required lock..

                writeln('Request received for the arrival of agent':X),
                writeln('Arrival of agent from Port ':NP),
                
                intranode_queue(Li), 
                length(Li,Q_Len),
                
                queue_threshold(Len),

                findall(_, bufferin(_), Buffer),
                length(Buffer, B_Len),
                writeln('Bufferin Len':B_Len),
                
                ack_q(ACK_Q),
                length(ACK_Q,ACK_Len),
                
                platform_port(QP),
                
                L is Q_Len + B_Len, % Combined length of the queue and the bufferin list will result in decision whether to send ACK or NAK.
                writeln(Len), writeln(Q_Len), writeln(ACK_Len), writeln(L), platform_token(Ptoken),
                (
                        (L<Len, member(Ptoken, Tokens))->
                        (                       
                                ack_q(Ack_Q),               % Just to keep track of ACK, no important use of Ack_Q.
                                append([X],Ack_Q,Nw_Ack_Q), % Just to keep track of ACK, no important use of Ack_Q.

                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),ack(X)]), % Give back ACK to the sender.
                                writeln('Space is available in the queue. ACK sent.'),
                                %writeln('Ack Queue':Nw_Ack_Q),
                                update_ack_queue(Nw_Ack_Q),
                                movedagent(_,(localhost, NP), X) % Add the agent to the buffer initially.
                        )
                        ;
                        (
                                agent_post(platform,(IP,NP),[dq_manager_handle,_,(localhost,QP),nack(X)]), % Give back NAK to the sender.
                                writeln('No space is available in queue or Tokens do not match. NAK sent...')
                        )
                ),

                mutex_unlock(GPOST), % release the Acquired lock.
                !.

q_manager_handle_thread(ID,(IP,NP),X, _):-
                writeln('Q_maanger_handle_thread failed !!'), !.

:- dynamic q_manager_handle_thread_id/1.

% Predicate to reuse the old thread. Avoids creating new thread for each incoming requests foe enqueue. 
:-dynamic call_count/1.
call_count(0).

:- dynamic q_manager_handle/3.

q_manager_handle(_,(IP,NP),recv_agent(X, Token)):-

                call_count(Cnt),

                (Cnt =:= 0 -> 
                        (
                                % The initial call of entering the agent has no thread running so create one !!..

                                writeln('Atleast till q_manager_handle'),
                                retractall(call_count(_)),
                                assert(call_count(1)),
                                thread_create(q_manager_handle_thread(ID, (IP, NP), X, Token),ID,[detached(false)]),
                                assert(q_manager_handle_thread_id(ID))
                        )
                        ;
                        (
                                writeln('Atleast till q_manager_handle'),
                                
                                q_manager_handle_thread_id(ThreadID),

                                thread_property(ThreadID, status(Status)),
                                (
                                        Status == running -> 
                                                % If old thread is running then use it to handle the request.

                                                writeln('Using older thread...'),
                                                q_manager_handle_thread_id(OldID),
                                                thread_send_message(OldID, q_manager_handle_thread(OldID, (IP, NP), X, Token)) 
                                                ;
                                                % Else create a new thread and use it to handle the request.

                                                retract(q_manager_handle_thread_id(ThreadID)),
                                                thread_create(q_manager_handle_thread(NewID, (IP, NP), X, Token),NewID,[detached(false)]),
                                                assert(q_manager_handle_thread_id(NewID))
                                )
                        )
                ),

                !.
                
q_manager_handle(guid,(IP,P),recv_agent(X, _)):- write('Q-manager handler failed!!'),!.

%%=============================== Q-Manager handler ends=======================================



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%===Inserting into own queue===%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Enqueues the agent to rear of the intranode queue..
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


% Just some print stmts..
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

% Assigns the clone same type as that of parent. And inherit type as 'C' for clone.
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

        agent_min_resource(Rmin),
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


% For now rewards are useless, but can be used in future.
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

% Adding agent to buffer..
:-dynamic movedagent/3.
movedagent(_,(IP,NP), X):-    	

                
        writeln('Agent arrived for insertion to queue ':X),
        writeln('Agent arrived from ':NP),
        platform_port(Thisport),

        writeln('This executed..'),
        assert(bufferin(X)), % Add the agent to the buffer. 
        %intranode_queue(I),
        writeln('This also executed..'),
        
        %enqueue(X,I,Inew),
        

        writeln('This did execute'),
        %update_intranode_queue(Inew),
        %writeln('Agent added to the queue':Inew),

        !.
                
moveagent(_,(IP,P),recv_agent(X)):- writeln('moveagent in cloning controller failed!!'),!.

% Update the lifetime of agent, with help of sigma based on the equations of the paper.
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

        
% Update the resource of agent, with help of tau_r and tau_c based on the equations of the paper.
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
                mutex_lock(GPOSTT),     % Acquire the required lock..

                agent_list_new(Aglist),
                (member(X, Aglist)->
                        writeln('ACK by the receiver':P:X),
                        initiate_migration(X, P),
                        dq_manager_handler(_,(IP,P),X)

                        ;

                        nothing
                ),
        
                mutex_unlock(GPOSTT), % Release the Acquired lock..
                !.

dq_manager_thread_ack(ID, (IP, P), X):-
                writeln('Dq_manager_thread_ack failed !!'), !.


% If NAK is recieved from the destination..
:-dynamic dq_manager_thread_nak/3.
dq_manager_thread_nak(ID, (IP, P), X):-

                posted_lock_dq(GPOSTT),
                mutex_lock(GPOSTT),    % Acquire the required lock..
                
                intranode_queue(I),
                length(I, Len),

                (Len > 0 -> 
                        intranode_queue([H|T]), agent_list_new(Aglist),
                        ((member(X, Aglist), H = X)->
                                writeln('Migration Denied (NAK) by the receiver'),
                                migrate_typhlet(X) % Add the agent back to the queue..
                                ;
                                nothing
                        )
                        ;
                        nothing
                ),
                
                mutex_unlock(GPOSTT), % Release the Acquired lock..

                !.

dq_manager_thread_nak(ID, (IP, P), X):-
                writeln('Dq_manager_thread_nak failed !!'), !.


% Create respective thread for the response.
:- dynamic dq_manager_handle/3.
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


% To release agent from the intranode queue.
:-dynamic dq_manager_handler/3.
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
                        enqueue(PP, Vis, Visnew), % Update vis that the agent carries.

                        retractall(agent_visit(Agent, _)), assert(agent_visit(Agent, Visnew)),

                        move_agent(Agent,(localhost,NP)), % Actually the agent moves.

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


% Find out the node where maximum concentration of pheromone of the required type is present, out of neighbours
% and move our Next_Node will be that node.
:-dynamic pher/2.
pher(H, NP):-
        find_highest_concentration_pheromone(H, PherName, NxtNode), writeln('Nxt Node ':NxtNode),
        NP = NxtNode,
        !.
pher(_, _):-
        writeln('Pher predicate failed !!'),
        !.

% If no pheromone is present, then move to a random neighbour which is not recently visited.
:-dynamic cons/2.
cons(H, NP):-
        nn_minus_vis(H, Nxtnode), writeln('Nxt node ':Nxtnode),
        NP = Nxtnode,
        !.
cons(_, _):-
        writeln('Cons predicate failed !!'),
        !.

delete_first([_|T], T).


% Define a predicate to decide whether to follow pheromone trail or go for conscientious movement.
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


% Subtracts the set of Node neighbours with Vis list of agent, if resultant sets length = 0 then randomly go to any neighbour 
nn_minus_vis(Agent, NxtNode):-
        node_neighbours(NN),
        agent_visit(Agent, Vis),

        subtract(NN, Vis, Result),

        writeln('NN ':NN),
        writeln('Vis ':Vis),
        writeln('Result ':Result),

        length(Result, Len),

        (Len = 0 -> random_member(NxtNode, NN) ; random_member(NxtNode, Result)).

% Return the Next node to which the agent should move.
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

% Algorithm that paper follows.. 
:- dynamic release_agent/0.
release_agent:-
                        global_mutex(GMID),
                        mutex_lock(GMID), % Not that necessary to put this lock, just to ensure completeness.
                                                
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

                                                phercon_neighbour(NP), % Based on PherCon Approach decide the next node to move to.. Given by NP.
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

% Show or write the lifetimes of all agents present in queue to console.
:-dynamic show_lf/1.
show_lf([]).
show_lf([H|T]):-
        
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

% Delete the agents whose lifetime is zero.
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

% Decrement lifetimes of each agent in the intranode queue.
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
        

% Consolidate predicates to decrement lifetime of agents cum delete agents with zero lifetime.
% I know a bit complex for a very easy task. But thats how it is.
:- dynamic decrement_lifetime/0.
decrement_lifetime:-

        intranode_queue(I),
        do_decr(I),
        intranode_queue(Ii),
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

% Check if need is satisfied or not. By going through the agents in intranode queue.
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

% See if the need of platform is satisfied or not by calling need_a_member predicate.
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
pheromones_db([]).                                                      % Database of All pheromones at this Node..


:-dynamic pheromone_now/1.                                              % Pheromone present Now..
:-dynamic pheromone_time/1.                                             % When Time reaches TimeOut, re-emit the pheromones..

:-dynamic pheromone_timeout/1.
pheromone_timeout(20).                                                  % Timeout for pheromone..


% Define a predicate to insert a pheromone into the list
insert_pheromone(Pheromone, List, NewList) :-
    % Check if the pheromone is already present in the list

        nth0(0, Pheromone, Name),
        nth0(1, Pheromone, Concentration),
        nth0(2, Pheromone, Lifetime),
        nth0(3, Pheromone, Port),
        nth0(4, Pheromone, Vis),
        nth0(5, Pheromone, X),
        nth0(6, Pheromone, Y),

        writeln('insp chk 1'),

    (member([Name, OldConcentration, _, _, _, _, _], List) ->
        % If the pheromone is already present, compare the concentrations
        (Concentration > OldConcentration ->
        writeln('insp chk 2'),
        % If the new pheromone has higher concentration, remove the old one
        remove_element([Name, OldConcentration, _, _, _, _, _], List, TempList),
        % Insert the new pheromone into the list
        insert_pheromone(Pheromone, TempList, NewList)
        ;
        writeln('insp chk 3'),
        % If the old pheromone has higher concentration, do not insert the new one
        NewList = List
        )
    ;
        % If the pheromone is not already present, insert it into the list
        append(List, [[Name, Concentration, Lifetime, Port, Vis, X, Y]], NewList)
    ),
    !.

insert_pheromone(_,_,_):-
        writeln('insert_pheromone failed !!'),
        !.


% Define a predicate to update the list
update_list([Name, Power, Lifetime, X, Y, I, J], [Name, Power, Lifetime, X, [NewValue|Y], I, J], NewValue).

% Predicate to add the pheromone to the list..
:-dynamic add_me_thread/2.
add_me_thread(_, X):-


    pheromones_db(DB),
    platform_port(PP),

    % update vis and then add in DB..
    update_list(X, NewX, PP),

    writeln('Updated the pheromone..vis..'),

    insert_pheromone(NewX, DB, DBnew),

    writeln('Updated the pheromone insert..'),
    
    writeln('DBnew ':DBnew),

    retractall(pheromones_db(_)),
    assert(pheromones_db(DBnew)),

    writeln('New Addition to Pheromone DB, Elements ':DBnew),
    !.

add_me_thread(_, _):-
    writeln('add_me_thread pheromone lifetime zero, or moved..!!'),
    !.


% Calls the predicate which adds the pheromone to DB..
:-dynamic add_me/2.
add_me(_,add(X)):-

    %thread_create(add_me_thread(_, X), _, [detached(false)]),
    add_me_thread(_, X),
    writeln('Add me ended..'),
    !.

add_me(_,_):-
    writeln('Add me failed !!'),
    !.

% Release Pheromones to neighbours..
:-dynamic release_pheromones_to_nodes_init/2.                           
release_pheromones_to_nodes_init([], _, _).

release_pheromones_to_nodes_init([NP|Rest], Need, N):-                              
    
    cmax(Cmax),
    lmax(Lmax),
    platform_port(PP),
    platform_number(Pnum),
    
    Name1 = 'Pheromone',
    atom_concat(Name1, Pnum, Name2),
    atom_concat(Name2, '_', Name3),
    atom_concat(Name3, N, ID), % ID of the pheromone, which will always be unique..
    
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


% Deletes pheromone with the specified name or ID.. 
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

% Whisper is the predicate that calls the delete pheromone predicate..
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

% Recursively tell all the neighbour nodes about pheromone to be deleted..
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

% Recursively call each neighbour for diffusing pheromones..
add_to_each_neighbour([], _).
add_to_each_neighbour([NP|Nodes], X):-
    agent_post(platform,(localhost,NP),[add_me,_,add(X)]),
    add_to_each_neighbour(Nodes, X),
    !.

add_to_each_neighbour(_,_):-
    writeln('Add to each neighbour failed !!'),
    !.


% Number of neighbours that have not been visited by the pheromone..
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


% For transferring pheromones of other nodes to this nodes neighbours..
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

% Decrements lifetime of pheromones and removes expired pheromones..
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


% Just a normal check to find if any transferred agent still residing in the queue, If yes delete that element, else do nothing
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

% For finding the Per Agent Population..
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


% Pour Buffer elements to the intranode queue, make sure to take appropriate locks..
:-dynamic take_in_buffer/0.
take_in_buffer:-
        posted_lock(GPOST),
        mutex_lock(GPOST),

        writeln('Take in buffer check 1..'),

        findall(X, bufferin(X), Values),

        writeln('Values in buffer ':Values),

        assertz_to_queue(Values),

        writeln('Take in buffer check 2..'),

        mutex_unlock(GPOST),
        !.

take_in_buffer:-
        writeln('Take in buffer failed !!'),
        !.


assertz_to_queue([]).
assertz_to_queue([X|Xs]) :-
        agent_list_new(Aglist),
        (member(X, Aglist)->
                intranode_queue(I),
                enqueue(X, I, In),
                update_intranode_queue(In),
                retract(bufferin(X))
                ;
                nothing
        ),

        assertz_to_queue(Xs),
    !.

assertz_to_queue(_,_):-
        writeln('Assertz to queue failed !!'),
        !.

% Ignore this.. just for Plotting the Graph of Worst case.. 
decide_H(Num, H):-
	
	platform_number(PNR),
	
	(Num =:= 1 -> ( PNR < 15 -> H = 1 ; (PNR < 30 -> H = 2 ; H = 3));nothing),
	(Num =:= 2 -> ( PNR < 15 -> H = 2 ; (PNR < 30 -> H = 3 ; H = 1));nothing),
	(Num =:= 3 -> ( PNR < 15 -> H = 3 ; (PNR < 30 -> H = 1 ; H = 2));nothing).
	

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
        posted_lock_dq(GPOSTT), % Acquire lock for dequeue..

        mutex_lock(GPOST),
        mutex_lock(GPOSTT),     % Acquire lock for enqueue..

        writeln('Thread ID ':ID),


        agent_list_new(Agents_list),
        intranode_queue(Isan),

        sanitize(Agents_list, Isan, Rsan),

        update_intranode_queue(Rsan),

        write('In the beginning of iteration after sanitization, list is '),
        writeln(Rsan),
        
        satisfied_need(SN),
        need(Need),

        ((Need =:= 0 ; SN =:= 1)->(
                
                need_train(Need_Train),
                random_member(H, Need_Train), 

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
                                % If platforms need is satisfied, tell all other nodes to delete the Pheromone with respective ID..
                                % Give data to log server about the satisfaction..  
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
                                                        % If this platform cannot generate Need dont do anything
                                                        nothing
                                                        ;

                                                        % If need of platform Not satisfied,
                                                        % Release pheromones to neighbours, and give data to log server..
                                                        % If timeout occurs then call delete predicates for pheromone and start releasing pheromones again..

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

        decrement_lifetime_pheromones,  % Decrement lifetime of pheromone, and remove expired pheromones..
        pheromones_transfer,            % Transfer pheromones of other nodes to neighbours of this node..
    
        % find out neighbour, eliminate neighbours[] used in the code.. It will also contain pher/con move, 
        % this predicate lies inside release_agent

        release_agent,

        mutex_unlock(GPOSTT),
        sleep(5),

        mutex_unlock(GPOST),
        sleep(5),

        take_in_buffer,

        N1 is N + 1,
        timer_release(ID, N1),
        
        !.
