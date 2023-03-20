

need_a_member(Need, []).
need_a_member(Need, [H|T]) :- 
        
        agent_type(H, Typ),
        writeln('Check integrity ':H),
        writeln('Check integrity ':Typ),
        writeln('Check integrity ':Need),

        satisfied_need(SN),

        ((Typ = Need, SN =:= 0)->(retractall(satisfied_need(_)), assert(satisfied_need(1)), update_resource(H), update_lifetime(H));(nothing)), 

        need_a_member(Need, T), 
        
        !.


start:-
    R is 10 mod 7,
    ((R = 3)->(writeln('go here'));(writeln('go there'))),
    writeln('conjuct here').
