:-dynamic neighbour/2.

start:-
   consult("platform.pl"),
   %consult("cloningController.pl"),
   consult("cloningOriginal.pl"),
   start_tartarus(localhost,15001,30),
   start_clonning_controller(15101,15201),
   assert(neighbour(15000,15100)).
   

   