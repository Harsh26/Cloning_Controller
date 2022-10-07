
node_neighbours([[15001, 15101], [15002, 15102]]).

begin:-
    node_neighbours([A | B]),
    nth0(0, A, Elem),
    nth0(1, A, Elem1),
    writeln('Elem ':Elem),
    writeln('Elem1':Elem1).

:-dynamic list1/1.
list1([[15001, 15101], [15002, 15102]]).

start:- list1(NewL), length(NewL,Len1), nth1(Num1,NewL,Elem1), [A|B1] = Elem1, [B|_] = B1.


