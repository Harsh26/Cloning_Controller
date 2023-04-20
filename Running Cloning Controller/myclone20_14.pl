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

:-dynamic pheromone_now/1.
:-dynamic carry_id/2.
:-dynamic carry_concentration/2.
:-dynamic carry_plifetime/2.
:-dynamic carry_nextid/2.
:-dynamic carry_myinfo/3.
:-dynamic carry_visp/2.
:-dynamic carry_d/2.


:-dynamic parent/1.
parent('P').

starttar:-
    consult("platform.pl"), 
    start_tartarus(localhost,15014,30),
    retractall(need_train(_)),
    assert(need_train([1])),
    
   assert(all_nodes([15000,15001,15002,15003,15004,15005,15006,15007,15008,15009,15010,15011,15012,15013,15014,15015,15016,15017,15018,15019])),
   
   retractall(platform_number(_)),
   assert(platform_number(14)).

attachneighbour:-
    assert(node_neighbours([15004,15015])).

startcontroller:-
    consult("cloningControllerOnePort.pl"),
    start_clonning_controller(15014),

    Str = 'pheromone',
   platform_number(PNR),
   atom_concat(Str, PNR, Pheromone_name),
   
   writeln('Could create Pheromone name.. ':Pheromone_name),

   platform_port(P),

   create_mobile_agent(Pheromone_name,(localhost, P),pheromone_handler,[30,32]),

   writeln('Pheromone check after begin..'),

   retractall(carry_id(_, _)),
   assert(carry_id(Pheromone_name, -1)),


   writeln('Pheromone check 1!!'),

   retractall(carry_concentration(_,_)),
   assert(carry_concentration(Pheromone_name, -1)),

   retractall(carry_plifetime(_,_)),
   assert(carry_plifetime(Pheromone_name, -1)),

   retractall(carry_nextid(_, _)),
   assert(carry_nextid(Pheromone_name, -1)),

   retractall(carry_myinfo(_, _, _)),
   assert(carry_myinfo(Pheromone_name, PNR, P)),
   
   retractall(carry_visp(_,_)),
   assert(carry_visp(Pheromone_name, [])),

   retractall(carry_d(_,_)),
   assert(carry_d(Pheromone_name, 1)),

   writeln('Pheromone check 2!!'),

   add_payload(Pheromone_name, [(carry_id, 2), (carry_concentration, 2), (carry_plifetime, 2), (carry_nextid, 2), (carry_myinfo, 3), (carry_visp, 2), (carry_d, 2)]),



    init_need(0),
    assert(satisfied_need(0)),
    assert(pheromone_now('None')),
   assert(pheromone_time(1)),
   
    platform_port(15014).


:- dynamic pheromone_handler/3.

pheromone_handler(guid,(_,_), main):-
        writeln('').


my_predicate:-
   starttar,
   attachneighbour,
   startcontroller.

   