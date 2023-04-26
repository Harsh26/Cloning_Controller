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
:-dynamic agent_visit/2.
:-dynamic all_nodes/1.

:-dynamic parent/1.
parent('P').

starttar:-
    consult("platform.pl"), 
    start_tartarus(localhost,15011,30),
    retractall(need_train(_)),
    assert(need_train([3])),
    
    assert(all_nodes([15000,15001,15002,15003,15004,15005,15006,15007,15008,15009,15010,15011,15012,15013,15014,15015,15016,15017,15018,15019])),
   
    retractall(platform_number(_)),
    assert(platform_number(11)).

attachneighbour:-
    assert(node_neighbours([15010,15006,15012,15005])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    init_need(0),
    assert(satisfied_need(0)),
    assert(pheromone_now('None')),
    assert(pheromone_time(1)).

my_predicate:-
   starttar,
   attachneighbour,
   startcontroller.
   