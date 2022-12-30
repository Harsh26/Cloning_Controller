% 27th MAY 2020
% AUTHOR: SHIVASHANKAR B NAIR
% TO BE USED IN CONJUNCTION WITH TARTARUS NODES

/*************************************************************************/
% ===========>>>>>>>PRIMARY INFORMATION<<<<<<<<==========================

%OBJECTIVE:  
% TIMED NODE TO NODE DISCOVERY AND NETWORK CONNECTIVITY MAINTAINENCE
% FORMING A NETLIST AT ALL THE CURRENTLY CONNECTED NODES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE PREDICATE discover_net/1 TAKES IN THE NETWORK-CONNECTIVITY-CHECK REFRESH TIME AND
% ALSO THE netrange/1 WHICH HAS TO BE ASSERTED A PRIORI
% **NB**: netrange([(ip1,startport1, endport1), (ip2, startport1,endport2),...]) NEEDS TO BE ASSERTED FIRST
% **NB**: NOTE THAT discover_net/1 CAN CONNECT TO PORTS AT DIFFERENT IPs 
% AND COULD BE USED ACROSS MACHINES (====>>>>>NEEDS TO BE TESTED<<<<<<======)
% IF A PLATFORM BECOMES INACTIVE, THE netlist/1 IS UPDATED BASED ON THE REFRESH TIME
% IF THE SAME PLATFORM AGAIN BECOMES ACTIVE, IT IS CONNECTED ONCE AGAIN
% **NB**: discover_net/1 NEEDS TO BE STARTED AT THIS REACTIVATED NODE.
% CURRENTLY close_tartarus/0 DOES NOT STOP discover_net/1.
% discover_net/1 CAN BE STOPPED USING stop_discovery/0.
% **NB**: LIMITATION: discover_net/1 CAN CONNECT AND CHECK ONLY THOSE PLATFORMS INCLUDED IN netrange/1
%
% USAGE: AFTER ENSURING THAT netrange/1 IS ASSERTED, USE
% discover_net(25)  THIS WILL PING AND UPDATE net/1 EVERY 25 SECONDS
%
/*************************************************************************/
% ===========>>>>>>>SECONDARY INFORMATION<<<<<<<<==========================
% USE OF connect/2
% AFTER EACH NODE IS CONNECTED USING 
% THE PREDICATE connect/2 A DYNAMIC PREDICATE LIST netlist/1
% IN THE FORM:
%             netlist([(ip1,port1), (ip2,port2),...]).
% IS ASSERTED. netlist/1 IS REFRESHED CONSTANTLY AT THE RATE 'NETWORK-CONNECTIVITY-CHECK REFRESH TIME'
% USES THE PREDICATE ack/2 TO CONNECT TO THE SENDER NODE 
% THE SENDER IN TURN ALSO PRESERVES THE IP AND PORT# OF THE ACKING NODE IN ITS netlist/1 LOCALLY
% THIS WAY BOTH THE SENDER AND RECEIVER NODES HAVE THEIR RESPECTIVE IPs AND PORT NOs. 
% EVEN IF connect/2 WERE TO BE REPEATEDLY USED, THE PROGRAM ENSURES THAT THERE WILL BE ONLY ONE UNIQUE 
% (ip, port) TUPLE IN THE netlist/1
%
% USAGE: 		connect(DestinationIP, DestinationPort)
% RESULTS IN: 	netlist([(ip1,port1), (ip2,port2),...]) in each platform being updated.
% YOU NEED TO RUN connect/2 FROM ALL NODES. 
% REDUNDANT CONNECTIONS ARE TAKEN CARE OF EVEN IF IP &/OR PORTS ARE SAME
% REPEATED USE OF connect/2 WILL NOT CREATE ISSUES APART FROM FLAGGING THAT THE CONNECTIONS WERE ALREADY MADE.
%
% THE network/3 PREDICATE USES connect/2 TO CONNECT A PLATFORM WITHIN THE LOCALHOST TO OTHERS 
% WHOSE PORTS RANGE FROM StartPort to EndPort.
% PRESENTLY WORKS ONLY FOR localhost
% FOR DIFFERENT IPs WE NEED TO GENERATE THE DIFFERENT IPs IN THAT RANGE
% network/3 IS TARGETTED AT BEING USED ALONGWITH A BATCH FILE (e.g. SEE node-test.pl AND start_mobile-test.bat) 
% THAT OPENS UP SEVERAL PLATFORMS IN THE LOCALHOST
%
% NB: THE PREDICATE cross_check_IP_Port/2 (CALLED WITHIN connect/2) USES TWO TARTARUS PLATFORM PREDICATES 
%
% NB FOR DEVELOPERS:  
% AFTER RIGOROUS TESTING AND DECISION ON THE NAMES GIVEN TO THE PREDICATES VIZ.
% connect/2,assrt_nbd/3, ack/2, network/3 THE ASSOCIATED CLAUSES FOR THESE MAY BE ADDED TO THE TARTARUS PLATFORM/MANUAL
%
% consult('NetCreator_Node1.pl').
% e.g. network(localhost, 25501,25502).
% 27th MAY 2020
% ADDED FEATURES: connect/2 ALONGWITH refresh_net/1 NOW CATER TO TIMED REFRESH OF netlist/1
% refresh_net(RefreshTime) TAKES IN THE REFRESHING TIME AND CONTINUOUSLY PINGS THE TUPLES IN netlist/1
% IN CASE IT DOES NOT GET A RESPONSE FROM THE OTHER NODE IT DELETES THE SAME FROM netlist/1



:- dynamic netlist/1, netrange/1, abort_discovery/0.
% e.g. netrange([[ip1,startPort1,endPort1],[ip2,startPort2,endPort2]]).
netlist([]). 					% NB: Ensure that this is asserted in start_tartarus
netrange([(localhost, 80000,80001),(localhost, 80002,80003)]).





% network/3 Connects current node to all others in localhost with port nos. starting from StartPort to EndPort

network(localhost, StartPort, StartPort):- 		% Terminating clause
	writeln('Connecting to:':StartPort),		
	connect(localhost, StartPort),
	writeln('Network created in localhost!'),nl.


network(localhost, StartPort, EndPort):-  		% Recursive clause to connect from StartPort to EndPort
	writeln(StartPort:EndPort),
	writeln('Connecting2:':StartPort),
	connect(localhost, StartPort), 				% Clause that actually connects
	StartPortNxt is StartPort+1,!,
	network(localhost, StartPortNxt, EndPort).

% connect/2 takes destination IP and Port and makes a netlist/1 of neighbour with tuples of the form (ip, port#).
% It keeps adding more connections to this list in each node. 
% netlist/1 can be used for routing agents or messages to 1-hop neighbours
connect(DestIP, DestPort):-			
	cross_check_IP_Port(DestIP, DestPort,Status),				% Performs crosscheck to ensure node doesn't connect to itself.
	Status == 'ok' 		,										% Check whether the DestIP/DestPort is that of itself
	get_platform_details(SourceIP,SourcePort),
	post_agent(platform,(DestIP, DestPort),[assrt_nbd,_,(SourceIP,SourcePort),connect2source]),   % The list has the destination handler 
	writeln("Message posted to the destination"),nl.												  %  and its arguments.				  

connect(DestIP, DestPort):- 
	get_platform_details(SourceIP,SourcePort),
	SourceIP == DestIP, SourcePort == DestPort,
	writeln('Cannot connect the platform to itself!': DestIP:DestPort),nl.

connect(DestIP, DestPort):- 
	retract(netlist(NList)),
	delete(NList, (DestIP, DestPort),NewNList),
	assert(netlist(NewNList)),
	writeln('Destination platform inactive/non-existent!':DestIP:DestPort),nl.

cross_check_IP_Port(DestIP,_,'ok'):- 							% Performs crosscheck to ensure node doesn't connect to itself 
	(not(platform_Ip(DestIP))).									% if IP &/or Port are same.

cross_check_IP_Port(_, DestPort,'ok'):- 
	(not(platform_port(DestPort))).


assrt_nbd(_,(SourceIP,SourcePort),connect2source):- 			% Handler for post_agent when another node connects to this node.
	netlist(NetList), 											% It adds the source IP & Port into netlist/1
	not(nth1(_,NetList,(SourceIP,SourcePort))),    							  
	!, 
	nth1(_,NewNetList,(SourceIP,SourcePort),NetList),
	retract(netlist(_)),
	assert(netlist(NewNetList)),
	!, ack(SourceIP,SourcePort).								% Acknowledges the connection.	  

assrt_nbd(_,(DestIP,DestPort),ack2destination):- 				% Handler for post_agent to ack connection from another node.
	writeln('Here'),   							  
	netlist(NetList), 											% It adds the IP and Port of the node that ACKed.
	not(nth1(_,NetList,(DestIP,DestPort))), 
	 !, 
	retract(netlist(_)),
    nth1(_,NewNetList,(DestIP,DestPort),NetList),
	assert(netlist(NewNetList)).						  

assrt_nbd(_,(_,_),_):-											% By chance if connect/2 is used a second time, this clause
	writeln('Already Connected!'),nl.								% ensures that the netlist is not updated with redundant information.

ack(SourceIP,SourcePort):-										% Acknowledges the connection by sending its own IP and Port to the connector node
	get_platform_details(DestIP,DestPort),
	post_agent(platform,(SourceIP,SourcePort),[assrt_nbd,_,(DestIP,DestPort),ack2destination]),   
	writeln("Connect Message posted to the sender").

ack(SourceIP,SourcePort):- 
	writeln('Problem in acknowledging' : SourceIP: SourcePort).




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%netrange([(localhost, 80000,80001),(localhost, 80002,80003)]).

discover_net(RefreshTime):-
	netrange(NetRangeList),			%[(IP,StartPort, EndPort|TailRange],)
		discover(NetRangeList),
		not(abort_discovery),
		alarm(10,discover_net(RefreshTime),X, [install(true), remove(true)]).
discover_net(_):- retract(abort_discovery), writeln('Discovery Aborted!').


discover([]).
discover([(IP,StartPort,EndPort)|Tail]):-
	network(IP,StartPort,EndPort),!,discover(Tail).

stop_discovery:- assert(abort_discovery).


