:-dynamic all_nodes/1.
:-dynamic node_neighbours/1.
:-dynamic need_train/1.
:-dynamic platform_number/1.

starttar:-
    consult("platform.pl"), 
    start_tartarus(localhost,15018,30),
    retractall(platform_number(_)),
    assert(platform_number(18)),
    retractall(need_train(_)),
    assert(need_train([1])),
    assert(all_nodes([15009,15016,15011,15004,15012,15013,15001,15010,15014,15019,15000,15007,15005,15015,15006,15017,15008,15002,15003])).


attachneighbour:-
    assert(node_neighbours([15010,15016])).

startphercon:-
    consult('Pher_con.pl'),
    platform_port(PP),
    assert(pheromone_now('None')),
    assert(satisfied_need(0)),
    assert(need(0)),
    assert(pheromone_time(1)),
    release_pheromones(PP).
   
my_predicate:-
   starttar,
   attachneighbour,
   startphercon.

   