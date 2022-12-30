
th_create:-
    thread_create(timer_release,_,[detached(false)]),

    !.

:-dynamic timer_release/0.

timer_release:-
               sleep(2),call_me,
               timer_release,
               !.

call_me:-
    writeln('hi').