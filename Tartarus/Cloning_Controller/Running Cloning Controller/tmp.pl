:- initialization(main).

append_to_list(List,Item) :-
    append_to_list(List,Item,0).

append_to_list(List,Item,Index) :-
    % using SWI-Prologs nth0 predicate
    (nth0(Index,List,Check_Item),
    var(Check_Item),
    nth0(Index,List,Item));
    (Next_Index is Index+1,
    append_to_list(List,Item,Next_Index)).

main :-
    A = [1,2,3|_],
    append_to_list(A,4),
    append_to_list(A,7),
    writeln(A).