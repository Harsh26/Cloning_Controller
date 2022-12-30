node_list([n0,n1,n2,n3]).      %172.16.117.143


%:-retractall(config_file(_)),assert(config_file('network\network_1_grid_10.pl')).

%:-retractall(topology_file(_)),assert(topology_file('network\topology_1_grid_10.pl')).

node(n0):-
%assert(node_info('n0','172.16.117.143',25500)),
assert(node_info('n0',localhost,25500)),
%assert(neighbors('n3','172.16.117.143',25503,55003,60003)),
assert(neighbors('n3',localhost,25503,55003,60003)),
%assert(neighbors('n1','172.16.117.143',25501,55001,60001)),
assert(neighbors('n1',localhost,25501,55001,60001)),
platform_start(25500),
%start_task_manager(35000),

writeln('Node n0').

node(n1):-
assert(node_info('n1','172.16.117.143',25501)),
assert(neighbors('n2','172.16.117.143',25502,55002,60002)),
assert(neighbors('n0','172.16.117.143',25500,55000,60000)),
platform_start(25501),
%start_task_manager(35001),
writeln('Node n1').

node(n2):-
assert(node_info('n2','172.16.117.143',25502)),
assert(neighbors('n3','172.16.117.143',25503,55003,60003)),
assert(neighbors('n1','172.16.117.143',25501,55001,60001)),
platform_start(25502),
%start_task_manager(35002),
writeln('Node n2').

node(n3):-
assert(node_info('n3','172.16.117.143',25503)),
assert(neighbors('n2','172.16.117.143',25502,55002,60002)),
assert(neighbors('n0','172.16.117.143',25500,55000,60000)),
platform_start(25503),
%start_task_manager(35003),
writeln('Node n3').


%load_config:-

