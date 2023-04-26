
:-dynamic intranode_queue/1.
intranode_queue([]).

enqueue(E, [], [E]).

enqueue(E, [H | T], [H | Tnew]) :-enqueue(E, T, Tnew).


start:-
    X = 'agent1',
    Y = 15000,

    intranode_queue(I),

    enqueue(X, I, In),

    retractall(intranode_queue(_)),
    assert(intranode_queue(In)),

    intranode_queue(Inn),

    enqueue(Y, Inn, Innn),

    writeln(Innn).
