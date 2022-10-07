:-dynamic neighbour/2.
:-dynamic platform_port/1.

:-dynamic agent_resource/2.
:-dynamic agent_max_resource/2.

starttar:-
    consult("platform.pl"),
    start_tartarus(localhost,15002,30).

startcloningcontroller:-
    consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   start_clonning_controller(15102,15202),
   platform_port(15002).

attachneighbour:-
   assert(neighbour(15000,15102)).