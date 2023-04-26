discover_net(RefreshTime):-
	%netrange(NetRangeList),			%ignore this line
	%discover(NetRangeList),			%ignore this line
	%not(abort_discovery),			%ignore this line
	writeln('here '),
	alarm(10,discover_net(RefreshTime),X, [install(true), remove(true)]).
	%alarm is the predicate, which every 10 seconds calls the discover_net predicate, 
	%X is an id and need not be bound to any value, remove(true) indicates that the timer is removed automatically after fireing
	%install(true) indicates timer is scheduled for execution
	%refer the documentation for more information

discover_net(_):- %retract(abort_discovery), 
	writeln('Discovery Aborted!').