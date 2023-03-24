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
    start_tartarus(localhost,15017,30),
    retractall(need_train(_)),
    assert(need_train([1,2])),
   retractall(platform_number(_)),
   assert(platform_number(17)).

attachneighbour:-
    assert(node_neighbours([15015,15009,15011,15018,15006,15014,15005,15016,15002,15010,15012,15003,15008,15000,15019,15004,15001,15007,15013])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    start_clonning_controller(15017),
    init_need(0),
    assert(satisfied_need(0)),
    platform_port(15017).


   