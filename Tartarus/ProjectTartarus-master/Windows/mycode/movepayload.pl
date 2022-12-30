:-dynamic agent_handler/3.

agent_handler(guid,(IP, Port),main):-
    writeln('I am a handler'), (Port=6001-> current(guid, 1, X,Y), writeln(X), writeln(Y), write('On platform 6001'), move_agent(guid,(localhost, 6002))
    ;
    writeln('Not on platform 6001'),
    current(guid, 2, X, Y), writeln(X), writeln(Y)).
