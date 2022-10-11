:-dynamic neighbour/2.
:-dynamic platform_port/1.

:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.
:-dynamic node_neighbours/1.


starttar:-
    consult("platform.pl"),
    start_tartarus(localhost,15001,30).

attachneighbour:-
    assert(node_neighbours([[15003, 15103],[]])).

startcontroller:-
    consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   start_clonning_controller(15101,15201),
   platform_port(15001).

%attachneighbour:-
%   assert(neighbour(15000,15100)).
   