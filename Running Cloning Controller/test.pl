stat_start(Id,T) :-
    alarm(T,stat_point(Id,T),Id,[remove(false),install(true)]).

stat_point(Id,T) :-
    
    uninstall_alarm(Id),
    install_alarm(Id,T),
    my_right.

my_right:-
    writeln('hi ').