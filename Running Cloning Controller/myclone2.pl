:-dynamic handler1/3.
:-dynamic neighbour/1.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
:-dynamic handler2/3.
:-dynamic platform_port/1.
:-dynamic node_neighbours/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.
:-dynamic agent_type/2.
:-dynamic agent_inherit/2.
:-dynamic need_train/1.

:-dynamic parent/1.
parent('P').


starttar:-
   consult("platform.pl"),
   start_tartarus(localhost,15002,30),
   retractall(need_train(_)),
   assert(need_train([1,3])),
   assert(platform_number(2)).

attachneighbour:-
   retractall(node_neighbours(_)),
   assert(node_neighbours([15000,15003,15001])).


startcontroller:-
   consult("cloningController.pl"),
   start_clonning_controller(15002),
   create_mobile_agent(agent2,(localhost,15002),handler1,[30,32]),
   retractall(agent_resource(_,_)), assert(agent_resource(guid,100)), retractall(agent_lifetime(_,_)), assert(agent_lifetime(guid, 10)), retractall(my_service_reward(_,_)), assert(my_service_reward(guid, 0)),
   retractall(agent_type(_,_)), assert(agent_type(guid, 2)), retractall(agent_inherit(_,_)), assert(agent_inherit(guid, 'P')),
   add_payload(agent2, [(agent_resource,2), (agent_lifetime, 2), (my_service_reward, 2), (agent_type,2), (agent_inherit,2)]),
   platform_port(15002),
   init_need(0),
   assert(satisfied_need(0)),
   migrate_typhlet(agent2).



handler1(guid,(_,_),main):-
    writeln('Namaste').