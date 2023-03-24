:-dynamic neighbour/1.
:-dynamic platform_port/1.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
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
    start_tartarus(localhost,15001,30),
    retractall(need_train(_)),
    assert(need_train([5])),
    assert(platform_number(1)).

attachneighbour:-
    assert(node_neighbours([15003,15002,15000])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    start_clonning_controller(15001),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15001).
   