:-dynamic handler1/3.
:-dynamic neighbour/2.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.



start:-
   consult("platform.pl"),
   %consult("cloningController.pl"),
   consult("cloningOriginal.pl"),
   start_tartarus(localhost,15000,30),
   start_clonning_controller(15100,15200),
   assert(neighbour(15001,15101)),
   create_mobile_agent(agent1,(localhost,15000),handler1,[30,32]),
   retractall(agent_resource(_,_)), assert(agent_resource(guid,100)), retractall(agent_max_resource(_,_)), assert(agent_max_resource(guid,100)),
   add_payload(agent1,[(agent_resource,2),(agent_max_resource,2)]),
   leave_queue(agent1,localhost,15001).

agent_init:-
   create_mobile_agent(agent2,(localhost,15000),handler1,[30,32]),
   retractall(agent_resource(_,_)), assert(agent_resource(guid,100)), retractall(agent_max_resource(_,_)), assert(agent_max_resource(guid,100)),
   add_payload(agent2,[(agent_resource,2),(agent_max_resource,2)]).



handler1(guid,(_,_),main):-
    writeln('hi').
   