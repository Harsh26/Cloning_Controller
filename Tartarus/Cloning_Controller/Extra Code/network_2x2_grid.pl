node_list0([n0,n1,n2,n3,n4,n5,n6,n7]). 	%172.16.27.129
node_list1([n8,n9,n10,n11,n12,n13,n14]). 	%172.16.27.143
node_list2([n15,n16,n17,n18,n19,n20,n21]). 	%172.16.27.154
node_list3([n22,n23,n24,n25,n26,n27,n28]). 	%172.16.27.145
node_list4([n29,n30,n31,n32,n33,n34,n35]). 	%172.16.27.140
node_list5([n36,n37,n38,n39,n40,n41,n42]). 	%172.16.27.144
node_list6([n43,n44,n45,n46,n47,n48,n49]). 	%172.16.26.218



node(n0):-
%assert(node_info('n0',`172.16.27.129`,49250)),
assert(node_info('n0',localhost ,49250)),
%assert(neighbors('n5',`172.16.27.129`,49255,55005,60005)),
assert(neighbors('n5',localhost,49255,55005,60005)),
%assert(neighbors('n1',`172.16.27.129`,49251,55001,60001)),
assert(neighbors('n1',localhost,49251,55001,60001)),
platform_start(49250),
start_task_manager(50000),
start_queue_manager(55000,60000),
consult('initiation.pl'),
nothing,
write('~M~JNODE:n0~M~J').

node(n1):-
%assert(node_info('n1',`172.16.27.129`,49251)),
assert(node_info('n1',localhost,49251)),
%assert(neighbors('n6',`172.16.27.129`,49256,55006,60006)),
assert(neighbors('n6',localhost,49256,55006,60006)),
%assert(neighbors('n2',`172.16.27.129`,49252,55002,60002)),
assert(neighbors('n2',localhost,49252,55002,60002)),
%assert(neighbors('n0',`172.16.27.129`,49250,55000,60000)),
assert(neighbors('n0',localhost,49250,55000,60000)),
platform_start(49251),
start_task_manager(50001),
start_queue_manager(55001,60001),
consult('initiation.pl'),
nothing,
write(`~M~JNODE:n1~M~J`).

node(n2):-
%assert(node_info('n2',`172.16.27.129`,49252)),
assert(node_info('n2',localhost,49252)),
%assert(neighbors('n7',`172.16.27.129`,49257,55007,60007)),
assert(neighbors('n7',localhost,49257,55007,60007)),
%assert(neighbors('n3',`172.16.27.129`,49253,55003,60003)),
assert(neighbors('n3',localhost,49253,55003,60003)),
%assert(neighbors('n1',`172.16.27.129`,49251,55001,60001)),
assert(neighbors('n1',localhost,49251,55001,60001)),
platform_start(49252),
start_task_manager(50002),
start_queue_manager(55002,60002),
consult('initiation.pl'),
nothing,
write(`~M~JNODE:n2~M~J`).

node(n3):-
%assert(node_info('n3',`172.16.27.129`,49253)),
assert(node_info('n3',localhost,49253)),
%assert(neighbors('n8',`172.16.27.143`,49258,55008,60008)),
assert(neighbors('n8',localhost,49258,55008,60008)),
%assert(neighbors('n4',`172.16.27.129`,49254,55004,60004)),
assert(neighbors('n4',localhost,49254,55004,60004)),
%assert(neighbors('n2',`172.16.27.129`,49252,55002,60002)),
assert(neighbors('n2',localhost,49252,55002,60002)),
platform_start(49253),
start_task_manager(50003),
start_queue_manager(55003,60003),
consult('initiation.pl'),
nothing,
write(`~M~JNODE:n3~M~J`).