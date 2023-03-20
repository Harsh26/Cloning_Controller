:-dynamic agent_task/3, agent_task2/3.

node1:-
    consult('platform.pl'), 
    start_tartarus(localhost, 50000,1111), 
    create_mobile_agent(testagent,(localhost,50000),agent_task,[1111]),
    set_log_server(localhost, 6666),
    send_log(testagent, 'Hello log server from agent 1..'),
    create_mobile_agent(testagent2,(localhost,50000),agent_task2,[1111]),
    send_log(testagent2, 'Hello log server from agent 2..').

agent_task(guid,(_,_),main):-
    writeln('hi').

agent_task2(guid,(_,_),main):-
    writeln('bye').