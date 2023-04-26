:-dynamic handler1/3.
:-dynamic neighbour/2.
:-dynamic agent_resource/2.
:-dynamic handler2/3.
:-dynamic platform_port/1.
:-dynamic node_neighbours/1.
:-dynamic my_service_reward/2.
:-dynamic agent_type/2.
:-dynamic agent_inherit/2.
:-dynamic need_train/1.
:-dynamic agent_visit/2.
:-dynamic all_nodes/1.



:-dynamic parent/1.
parent('P').

starttar:-
   consult("platform.pl"), 
   start_tartarus(localhost,15000,30),
   retractall(need_train(_)),
   assert(need_train([1,3])),
   retractall(platform_number(_)),
assert(all_nodes([15000,15001,15002,15003])),
   assert(platform_number(0)).

attachneighbour:-
assert(node_neighbours([15001,15002,15003])).


startcontroller:-
   consult("cloningControllerOnePort.pl"),
   platform_port(PP),
   start_clonning_controller(PP),
   create_mobile_agent(agent1,(localhost,15000),handler1,[30,32]),
   retractall(agent_resource(_,_)), assert(agent_resource(guid,20)), retractall(agent_lifetime(_,_)), assert(agent_lifetime(guid, 5)), retractall(my_service_reward(_,_)), assert(my_service_reward(guid, 0)),
   retractall(agent_type(_,_)), assert(agent_type(guid, 1)), retractall(agent_inherit(_,_)), assert(agent_inherit(guid, 'P')),
   retractall(agent_visit(_,_)), assert(agent_visit(guid, [PP])),
   add_payload(agent1,[(agent_resource,2), (agent_lifetime, 2), (my_service_reward, 2), (agent_type,2), (agent_inherit,2), (agent_visit, 2)]),
   platform_port(15000),
   
   init_need(0),              
   assert(satisfied_need(0)),
   assert(pheromone_now('None')),
   assert(pheromone_time(1)),
   
   migrate_typhlet(agent1).


handler1(guid,(_,_),main):-
    writeln('hi').


my_predicate:-
   starttar,
   attachneighbour,
   startcontroller.
