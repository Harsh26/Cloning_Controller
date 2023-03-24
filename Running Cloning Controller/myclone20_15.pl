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
    start_tartarus(localhost,15015,30),
    retractall(need_train(_)),
    assert(need_train([3,1])),
   retractall(platform_number(_)),
   assert(platform_number(15)).

attachneighbour:-
    assert(node_neighbours([15009,15002,15014,15004,15017,15003,15001,15012,15006,15000,15010,15016,15013,15005,15018,15019,15008,15007,15011])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    start_clonning_controller(15015),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15015).


   