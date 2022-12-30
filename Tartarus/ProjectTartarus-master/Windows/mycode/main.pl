:-dynamic current/4.

current(guid, 1, 150, 160).
current(guid, 2, 250, 350).

start:-
%writeln('hello'),
get_tartarus_details(IP, Port),
create_mobile_agent(referee,(IP, Port),agent_handler,[1,2]),
add_payload(referee, [(current, 4)]),
execute_agent(referee, (IP, Port),agent_handler).