:- use_module(library(assoc)).

frequencies(L, F) :-
    empty_assoc(E),
    frequencies_helper(L, E, A),
    assoc_to_list(A, P),
    sort(2, @>=, P, F).

frequencies_helper([], A, A).
frequencies_helper([H|T], A0, A) :-
    (   get_assoc(H, A0, V)
    ->  V1 is V+1, put_assoc(H, A0, V1, A1)
    ;   put_assoc(H, A0, 1, A1)
    ),
    frequencies_helper(T, A1, A).

freq_list(F, L) :-
    freq_list(F, [], L).

freq_list([], Acc, L) :-
    reverse(Acc, L).
freq_list([_-Freq|T], Acc, L) :-
    freq_list(T, [Freq|Acc], L).


sorted_pairs(Pairs, SortedPairs) :- sort(Pairs, SortedPairs).


query:- 
    frequencies([1,3,2,1,4,3,2], F), sorted_pairs(F, NF), writeln(NF), freq_list(NF, L), writeln(L),
    maplist(pair_to_atom, NF, Atoms),
    atomic_list_concat(Atoms, ', ', Atom),
    writeln(Atom),
    PerAgentPopulation = [0-0, 0-0, 0-0],
    maplist(pair_to_atom, PerAgentPopulation, Atoms1),
    atomic_list_concat(Atoms1, ', ', Atom1),
    writeln(Atom1).

pair_to_atom(Key-Value, Atom) :-
    atomic_list_concat([Key, Value], '-', Atom).