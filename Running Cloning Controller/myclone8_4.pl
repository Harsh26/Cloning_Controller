:-dynamic neighbour/2.
:-dynamic platform_port/1.
:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
:-dynamic node_neighbours/1.
:-dynamic agent_lifetime/2.
:-dynamic my_service_reward/2.


starttar:-
    consult("platform.pl"),
    start_tartarus(localhost,15004,30).

attachneighbour:-
    assert(node_neighbours([[15003, 15103], [15005, 15105], [15006, 15106], [15007, 15107]])).

startcontroller:-
    consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   platform_port(15004).

%attachneighbour:-
%   assert(neighbour(15000,15100)).
   