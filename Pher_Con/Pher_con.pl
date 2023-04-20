
:-dynamic cmax/1.                                                       % Max Concentration..
cmax(1000).

:-dynamic lmax/1.
lmax(20).                                                               % Max Lifetime..

:-dynamic pheromones_db/1.
pheromones_db([]).                                                      % All pheromones at this Node..

:-dynamic need/1.                                                       % Need of platform..
:-dynamic satisfied_need/1.                                             % To check if need is satisfied or not
:-dynamic pheromone_now/1.                                              % Pheromone present Now..
:-dynamic pheromone_time/1.

:-dynamic pheromone_timeout/1.
pheromone_timeout(20).


:-dynamic global_mutex/1.


% Define a predicate to insert a pheromone into the list
insert_pheromone(Pheromone, List, NewList) :-
    % Check if the pheromone is already present in the list

        nth0(0, Pheromone, Name),
        nth0(1, Pheromone, Concentration),

    (member([Name, OldConcentration, _, _, _, _, _], List) ->
        % If the pheromone is already present, compare the concentrations
        (Concentration > OldConcentration ->
        % If the new pheromone has higher concentration, remove the old one
        remove_element([Name, OldConcentration, _, _, _, _, _], List, TempList),
        % Insert the new pheromone into the list
        insert_pheromone(Pheromone, TempList, NewList)
        ;
        % If the old pheromone has higher concentration, do not insert the new one
        NewList = List
        )
    ;
        % If the pheromone is not already present, insert it into the list
        enqueue(Pheromone, List, NewList)
    ).


% Define a predicate to update the list
update_list([Name, Power, Lifetime, X, Y, I, J], [Name, Power, Lifetime, X, [NewValue|Y], I, J], NewValue).

:-dynamic add_me_thread/2.
add_me_thread(_, X):-

    global_mutex(GMID),
    mutex_lock(GMID),

    pheromones_db(DB),
    platform_port(PP),

    % update vis and then add in DB..
    update_list(X, NewX, PP),

    insert_pheromone(NewX, DB, DBnew),

    retractall(pheromones_db(_)),
    assert(pheromones_db(DBnew)),

    writeln('New Addition to Pheromone DB, Elements ':DBnew),
    
    mutex_unlock(GMID),
    !.

add_me_thread(_, _):-
    writeln('add_me_thread failed !!'),
    !.


:-dynamic add_me/2.
add_me(_,add(X)):-

    thread_create(add_me_thread(_, X), _, [detached(false)]),
    writeln('Add me ended..'),
    !.

add_me(_,_):-
    writeln('Add me failed !!'),
    !.


:-dynamic release_pheromones_to_nodes_init/2.                           % Release Pheromones to neighbours
release_pheromones_to_nodes_init([], _, _).

release_pheromones_to_nodes_init([NP|Rest], Need, N):-                              
    
    cmax(Cmax),
    lmax(Lmax),
    platform_port(PP),
    platform_number(Pnum),
    
    Name1 = 'Pheromone',
    atom_concat(Name1, Pnum, Name2),
    atom_concat(Name2, '_', Name3),
    atom_concat(Name3, N, ID),
    
    retractall(pheromone_now(_)),
    assert(pheromone_now(ID)),

    Pherom_ID = ID,
    Pherom_Conc = Cmax,
    Pherom_Life = Lmax,
    Next_Node = PP,
    Vis = [PP],
    D = 2,
    Type = Need,

    format("Values ~w, ~w, ~w, ~w, ~w, ~w, ~w.~n", [Pherom_ID, Pherom_Conc, Pherom_Life, Next_Node, Vis, D, Type]),

    agent_post(platform,(localhost,NP),[add_me,_,add([Pherom_ID, Pherom_Conc, Pherom_Life, Next_Node, Vis, D, Type])]),

    release_pheromones_to_nodes_init(Rest, Need, N),
    !.

release_pheromones_to_nodes_init(_,_):-
    writeln('Release pheromones to nodes failed !!'),
    !.

enqueue(E, [], [E]).
enqueue(E, [H | T], [H | Tnew]) :-enqueue(E, T, Tnew).

delete_me(ListToRemove, ListOfLists, NewListOfLists) :-
    delete(ListOfLists, ListToRemove, NewListOfLists).


:-dynamic delete_pheromone_request/2.

delete_pheromone_request([],_).

delete_pheromone_request([H|T],X):-
        
        pheromones_db(DB),
        nth0(0, H, FirstElement),
        (
            
            FirstElement = X -> 
                delete_me(H, DB, DBnew), retractall(pheromones_db(_)), assert(pheromones_db(DBnew)),
                writeln('New Deletion from Pheromone DB, Elements ':DBnew)
                ;
                nothing
        ),

        delete_pheromone_request(T, X),
        !.

delete_pheromone_request([_|_],_):-
        writeln('Delete pheromone request Failed !!'),
        !.

:- dynamic whisperer_handle_thread/3.
whisperer_handle_thread(X):-
        global_mutex(GMID),
        mutex_lock(GMID),

        writeln('Trying to delete pheromone..'),
        pheromones_db(DB),
        delete_pheromone_request(DB,X),

        mutex_unlock(GMID),
        !.

whisperer_handle_thread(_):-
        writeln('Whisperer handel thread Failed!!'),
        !.

:-dynamic whisperer/1.
whisperer(_,deletepherom(PH)):-
        
        %writeln('Arrived whisperer atleast.. Recieved Whispering request from ':NP),
        writeln('Arrived whisperer atleast.. Pheromone, whose request to be deleted, is recieved ':PH),
        thread_create(whisperer_handle_thread(PH),_,[detached(true)]), 

        %whisperer_handle_thread(PH),
        !.

whisperer(_,deletepherom(_)):-
        writeln('Whisperer Failed!!'),
        !.

:-dynamic tell_all_other_nodes/2.

tell_all_other_nodes([], _).

tell_all_other_nodes([Node|Nodes], PHnow):-
        
        writeln('Tell other nodes start..'),
        platform_port(P),

        (
                (P = Node)->
                        nothing
                        ;
                        agent_post(platform,(localhost,Node),[whisperer,_,deletepherom(PHnow)])
        ),

        tell_all_other_nodes(Nodes, PHnow),
        !.

tell_all_other_nodes(_, _):-
        writeln('Tell all other nodes failed!!'),
        !.

% Define a predicate to check if the lifetime of a pheromone has expired
is_expired([_, _, Lifetime, _, _, _, _]) :-
    Lifetime =< 0.

% Define a predicate to decrement the lifetime of a pheromone
decrement_lifetime_pheromones([Name, Power, Lifetime, X, Y, I, J], [Name, Power, NewLifetime, X, Y, I, J]) :-
    NewLifetime is Lifetime - 1.

% Define a predicate to remove an element from a list
remove_element(_, [], []).
remove_element(E, [E|T], T).
remove_element(E, [H|T], [H|T_new]) :- remove_element(E, T, T_new).

% Define a predicate to remove expired pheromones from the list
remove_expired_pheromones(PheromonesList, NewPheromonesList) :-

    %writeln('Inside remove_expired_pheromones..'),

    % Traverse the list and decrement the lifetime of each pheromone
    maplist(decrement_lifetime_pheromones, PheromonesList, DecrementedPheromonesList),
    %writeln('before exclude':DecrementedPheromonesList),

    % Remove the expired pheromones
    exclude(is_expired, DecrementedPheromonesList, NewPheromonesList),

    %write('After exclude: '), write(NewPheromonesList), nl,
    !.

remove_expired_pheromones(_,_):-
    writeln('Remove expired pheromones failed !!'),
    !.

add_to_each_neighbour([], _).
add_to_each_neighbour([NP|Nodes], X):-
    agent_post(platform,(localhost,NP),[add_me,_,add(X)]),
    add_to_each_neighbour(Nodes, X),
    !.

add_to_each_neighbour(_,_):-
    writeln('Add to each neighbour failed !!'),
    !.


:-dynamic get_number/3.
get_number(Vis, NN, Res) :-
        %NN = [2,3,4,5],
        %Vis = [4,3,7],

        writeln('Vis':Vis),
        writeln('NN':NN),

        empty_assoc(SS0),
        insert_all(NN, SS0, SS1),
        insert_all(Vis, SS1, SS2),
        writeln('Before deletion:'),
        assoc_to_list(SS2, KVs1),
        writeln(KVs1),
        delete_all(Vis, SS2, SS3),
        writeln('After deletion:'),
        assoc_to_list(SS3, KVs2),
        writeln(KVs2),
        keys(KVs2, Res),
        writeln(Res).

insert_all([], SS, SS).
insert_all([E|Es], SS0, SS) :-
        put_assoc(E, SS0, false, SS1),
        insert_all(Es, SS1, SS).

delete_all([], SS, SS).
delete_all([E|Es], SS0, SS) :-
        ( get_assoc(E, SS0, false) ->
                del_assoc(E, SS0, _, SS1),
                delete_all(Es, SS1, SS)
                ;
                writeln('Failed to delete key:'), writeln(E), false
    ).

keys([], []).
keys([K-_|KVs], [K|Keys]) :-
    keys(KVs, Keys).


transfer_pheromones_util([]).
transfer_pheromones_util([H|T]):-
    
    writeln('Reached  transfer_pheromones_util!!'),
    pheromone_now(Pnow),
    nth0(0, H, FirstElement),

    (Pnow = FirstElement -> nothing
                ;
                % use add_me..
                lmax(Lmax),
                platform_port(PP),
                
                nth0(0, H, ID),
                nth0(1, H, Concentration), nth0(2, H, Pheromlife),
                nth0(4, H, Vis),
                nth0(5, H, D), nth0(6, H, Type),

                NewPherom_ID = ID,
                NewPherom_Conc is Concentration - 100 / D,
                NewPherom_Life is Pheromlife - Lmax/D,
                NewNext_Node = PP,
                NewVis = Vis,
                NewD is D + 1,
                NewType = Type,

                node_neighbours(NN),
                get_number(Vis, NN, Res),

                length(Res, RL),
                writeln('Res ':Res), writeln('RL ':RL),

                (NewPherom_Life > 0 -> add_to_each_neighbour(Res, [NewPherom_ID, NewPherom_Conc, NewPherom_Life, NewNext_Node, NewVis, NewD, NewType]) ; nothing)
    ),

    transfer_pheromones_util(T),
    !.

transfer_pheromones_util(_):-
    writeln('Transfer pheromones util failed !!'),
    !.

transfer_pheromones(DB):-

    writeln("transfer pheromones reached !!"),
    transfer_pheromones_util(DB),
    !.

transfer_pheromones(_):-
    writeln('Transfer Pheromones failed !!'),
    !.

:-dynamic decrement_lifetime_pheromones/0.
decrement_lifetime_pheromones:-

    global_mutex(GMID),
    mutex_lock(GMID),

    writeln('Before decrementing start..'),
    pheromones_db(PheromonesList),
    write('PheromonesList: '), write(PheromonesList), nl,

    remove_expired_pheromones(PheromonesList, NewPheromonesList),
    write('NewPheromonesList: '), write(NewPheromonesList), nl,

    retractall(pheromones_db(_)),
    assertz(pheromones_db(NewPheromonesList)),

    mutex_unlock(GMID),
    !.

decrement_lifetime_pheromones:-
    writeln('Decrement lifetime of pheromone failed !!'),
    !.

:-dynamic pheromones_transfer/0.
pheromones_transfer:-

    global_mutex(GMID),
    mutex_lock(GMID),

    pheromones_db(Dbxfer),
    writeln('Before Dbxfer..'),
    transfer_pheromones(Dbxfer),
    writeln('After Dbxfer..'),

    mutex_unlock(GMID),
    !.

pheromones_transfer:-
    writeln('Transfer failed !!'),
    !.

:-dynamic release_pheromones_thread/3.
release_pheromones_thread(ID, Port, N):-

    writeln('Iteration number... ':N),

    (
        (N =:= 1)->
            (
                sleep(5)
            )
            ;
            (
                (
                    (N =:= 25)->
                        (
                            halt
                        )
                        ;
                        (
                        nothing
                        )
                )
            )
    ),

    need(Need), 
    satisfied_need(SN),

    (
        (Need =:= 0 ; SN =:= 1) -> 
    
            need_train([H|T]),

            writeln('***************************************************************************'),
            writeln('Platform NEEDS the service of Agent ':H),
            writeln('***************************************************************************'),

            retractall(need(_)),
            assert(need(H)),

            enqueue(H, T, Tn),                 
            retractall(need_train(_)), 
            assert(need_train(Tn)),

            retractall(satisfied_need(_)),
            assert(satisfied_need(0))

            ;
    
            nothing
    ),

    platform_number(PNR),
    ((mod(N, 5) =:= 0, Need \== -1, PNR =:= 0) -> retractall(satisfied_need(_)), assert(satisfied_need(1)) ; nothing),    % Check if need is satified.. This is user dependent. But I am writing a random function for the same
    
    satisfied_need(SAN),
    (
        (SAN =:= 1)->
            (

                writeln('Need of Platform satisfied!! At Time Point ':N),
            
                pheromone_now(PHnow),
                writeln('PHnow ':PHnow),
                            
                ((PHnow = 'None')-> nothing ; all_nodes(AN),tell_all_other_nodes(AN, PHnow)),

                writeln('Reached after PHnow'),

                retractall(pheromone_now(_)), assert(pheromone_now('None')),
                retractall(pheromone_time(_)), assert(pheromone_time(1))
                            
            )
            ;
            (
                need(Pheromone),
                (
                    Pheromone =:= -1 -> 
                            nothing
                            ;
                            writeln('Need of Platform NOT satisfied at time point ':N),
                            writeln('Releasing Pheromones started at ':Port),
                            node_neighbours(NN),
                            

                            pheromone_now(Pnow),
                            pheromone_timeout(PTO),
                            
                            pheromone_time(Ptime),

                            Newptime = Ptime + 1,

                            retractall(pheromone_time(_)),
                            assert(pheromone_time(Newptime)),

                            pheromone_time(PT),

                            ((((PT mod PTO) =:= 0), Pnow \== 'None')-> writeln('Inside Timeout 1..'),all_nodes(ANN),tell_all_other_nodes(ANN, Pnow);nothing),

                            % If need not equal 0, var is first time occurance of need we will release pheromones.. 
                            ((Pnow = 'None' ; ((PT mod PTO) =:= 0))-> release_pheromones_to_nodes_init(NN, Pheromone, N), writeln('releasing init complete') ; nothing)
                        
                )
            )
    ),

    decrement_lifetime_pheromones,
    pheromones_transfer,
    
    N1 is N + 1,

    sleep(5),
    release_pheromones_thread(ID, Port, N1),

    !.

release_pheromones_thread(_, _, _):-
    writeln('release_pheromones_thread failed !!'),
    !.

:-dynamic release_pheromones/2.
release_pheromones(Port):-
    
    mutex_create(GMID),
    assert(global_mutex(GMID)),

    thread_create(release_pheromones_thread(ID, Port, 1),ID,[detached(false)]),
    !.

release_pheromones(_):-
    writeln('Release pheromones failed !!'),
    !.