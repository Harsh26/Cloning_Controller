:-dynamic handler1/3.
:-dynamic neighbour/2.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
:-dynamic handler2/3.
:-dynamic platform_port/1.
:-dynamic node_neighbours/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.

starttar:-
   consult("platform.pl"),
   start_tartarus(localhost,15002,30).

attachneighbour:-
   retractall(node_neighbours(_)),
   assert(node_neighbours([[15000, 15100],[15003, 15103], [15004, 15104]])).


startcontroller:-
   consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   create_mobile_agent(agent2,(localhost,15002),handler2,[30,32]),
   retractall(agent_resource(_,_)), assert(agent_resource(guid,100)), retractall(agent_lifetime(_,_)), assert(agent_lifetime(guid, 10)), retractall(my_service_reward(_,_)), assert(my_service_reward(guid, 0)),
   add_payload(agent2, [(agent_resource,2), (agent_lifetime, 2), (my_service_reward, 2)]),
   %add_payload(agent2,[(agent_resource,2)]),
   %leave_queue(agent1,localhost,15001).
   %q_manager_handle(guid, (localhost, 15000), agent1),
   platform_port(15002),
   migrate_typhlet(agent2).

%attachneighbour:-   
%   assert(neighbour(15001,15101)).
%   assert(neighbour(15002,15102)).
   

%doprocess:-
   
   
   
   %set_to_move(agent1),
   %leave_queue(agent1,localhost,15001)
   %clone_if_necessary(agent1)
   %.

%agent_init:-
   %create_mobile_agent(agent2,(localhost,15000),handler1,[30,32]),
   %retractall(agent_resource(_,_)), assert(agent_resource(guid,100)), retractall(agent_max_resource(_,_)), assert(agent_max_resource(guid,100)),
   %add_payload(agent2,[(agent_resource,2),(agent_max_resource,2)]).



handler2(guid,(_,_),main):-
    writeln('Namaste'),
    agent_lifetime(guid, A),
    writeln('My lifetime is ':A),
    my_service_reward(guid, B),
    writeln('My service reward is ':B),
    agent_resource(guid, C),
    writeln('My Cloning Resource is ':C).