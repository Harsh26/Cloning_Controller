:-dynamic all_nodes/1.
:-dynamic node_neighbours/1.
:-dynamic need_train/1.
:-dynamic platform_number/1.

starttar:-
   consult("platform.pl"),
   start_tartarus(localhost,15002,30),
   retractall(platform_number(_)),
   assert(platform_number(2)),
   retractall(need_train(_)),
   assert(need_train([3])),
   assert(all_nodes([15000,15001,15002,15003,15004,15005,15006,15007,15008,15009,15010,15011,15012,15013,15014,15015,15016,15017,15018,15019])).

attachneighbour:-
   retractall(node_neighbours(_)),
   assert(node_neighbours([15003,15001])).


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