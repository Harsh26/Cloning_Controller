:-dynamic neighbour/2.
:-dynamic platform_port/1.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
:-dynamic node_neighbours/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.


starttar:-
    consult("platform.pl"),
    start_tartarus(localhost,15007,30).

attachneighbour:-
    assert(node_neighbours([[15005, 15105], [15006, 15106]])).

startcontroller:-
    consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   start_clonning_controller(15107,15207),
   platform_port(15007).

%attachneighbour:-
%   assert(neighbour(15000,15100)).
   