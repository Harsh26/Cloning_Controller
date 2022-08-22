:-dynamic neighbour/2.

starttar:-
    consult("platform.pl"),
    start_tartarus(localhost,15001,30).

start:-
   consult("cloningController.pl"),
   %consult("cloningOriginal.pl"),
   start_clonning_controller(15101,15201),
   assert(neighbour(15000,15100)).
   