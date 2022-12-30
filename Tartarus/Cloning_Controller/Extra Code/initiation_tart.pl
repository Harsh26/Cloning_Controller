
start_exe1:-
		platform_assert_file('agent_phercon.pl'),
		create_phercon_agent(G,Pr),
		platform_assert_file('payload.pl'),
		add_payload(G,[(task_info,3),(ex1_task,1)]),
		agent_post(G,[],migration(GUID,P)),
		write(`~M~JAgent Moved Away!!!`),!.


start_exe2:-
		platform_assert_file('agent_phercon.pl'),
		create_phercon_agent(G,Pr),
		platform_assert_file('payload2.pl'),
		add_payload(G,[(task_info,3),(ex2_task,1)]),
		agent_post(G,[],migration(GUID,P)),
		write(`~M~JAgent Moved Away!!!`),!.


start_exe3:-
		platform_assert_file('agent_phercon.pl'),
		create_phercon_agent(G,Pr),
		platform_assert_file('payload3.pl'),
		add_payload(G,[(task_info,3),(ex3_task,1)]),
		agent_post(G,[],migration(GUID,P)),
		write(`~M~JAgent Moved Away!!!`),!.


start_exe4:-
		platform_assert_file('agent_phercon.pl'),
		create_phercon_agent(G,Pr),
		platform_assert_file('payload4.pl'),
		add_payload(G,[(task_info,3),(ex4_task,1)]),
		agent_post(G,[],migration(GUID,P)),
		write(`~M~JAgent Moved Away!!!`),!.


start_exe5:-
		platform_assert_file('agent_phercon.pl'),
		create_phercon_agent(G,Pr),
		platform_assert_file('payload5.pl'),
		add_payload(G,[(task_info,3),(ex5_task,1)]),
		agent_post(G,[],migration(GUID,P)),
		write(`~M~JAgent Moved Away!!!`),!.
