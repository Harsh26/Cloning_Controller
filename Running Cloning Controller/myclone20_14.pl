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
    start_tartarus(localhost,15014,30),
    retractall(need_train(_)),
    assert(need_train([1])),
   retractall(platform_number(_)),
   assert(platform_number(14)).

attachneighbour:-
    assert(node_neighbours([15002,15005,15001,15017,15004,15015,15006,15019,15000,15013,15003,15018,15007,15009,15012,15008,15016,15010,15011])).

startcontroller:-
    consult("cloningController.pl"),
    start_clonning_controller(15014),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15014).


   