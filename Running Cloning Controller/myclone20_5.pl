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
    start_tartarus(localhost,15005,30),
    retractall(need_train(_)),
    assert(need_train([2])).

attachneighbour:-
    assert(node_neighbours([15004,15018,15015,15010,15000,15007,15014,15012,15001,15017,15003,15008,15011,15009,15016,15002,15013,15019,15006])).

startcontroller:-
    consult("cloningController.pl"),
    start_clonning_controller(15005),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15005).


   