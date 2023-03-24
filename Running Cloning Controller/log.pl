

set_log:-
    consult('platform.pl'),
    open('server_log.txt',write,X),
    close(X),
    start_tartarus(localhost, 6666,30).