:-dynamic neighbour/2.
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
    start_tartarus(localhost,15007,30),
    retractall(need_train(_)),
    assert(need_train([3,2])),
   retractall(platform_number(_)),
   assert(platform_number(7)).

attachneighbour:-
    assert(node_neighbours([15010,15006,15014,15003,15013,15017,15001,15018,15016,15005,15008,15019,15011,15015,15002,15004,15009,15012,15000])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    start_clonning_controller(15007),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15007).


   