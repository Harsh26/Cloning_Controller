main(Node):-
        consult('platform.pl'),consult('network_2x2_grid.pl'),%consult('E:\\copy\\Cloning_controller\\Tartarus\\network_4_4_grid.pl'),
        atom_number(Atom,Node),atom_concat(n,Atom,Node_name),
        node(Node_name).