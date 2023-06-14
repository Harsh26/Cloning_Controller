# Cloning_Controller
Controls the clone an agent can produce

Author: Harsh Bijwe

Institute: IIT Guwahati

Please go through the paper thoroughly to understand the working of the code. The paper can be found at: https://link.springer.com/chapter/10.1007/978-3-662-44509-9_3

Basics: You need to create as many number of .pl files as the platforms you desire in cloning controller code. Ensure that Python and SWI-Prolog is installed in your system. There are various example files available with the code as well. Please go through the structure of each of them. A beginner level understanding of Tartarus is required. 

Running Instructions:

  1. Ensure that Python and SWI-Prolog is installed in your system.
  2. There is a file named cloningControllerOnePort.pl  inside Running Cloning Controller Folder which is the ultimate file.
  3. For running use spawn.py script to run any of the topology namely line, grid etc. by changing "prefix" of spawn.py file.
  4. It will open about 50 terminals corresponding to each topology which signify different platforms, the spawn.py can be modified in case more number of files are there. 
  5. Cloning controller process will automatically start. View log server for the details, since all the platforms will be running rapidly and changes cannot be viewed easily. 

Bonus:
  1. There is a writer.py script that changes node_neighbour predicate based on input.txt. Carefully modify it to change node_neighbour of desired files at once.
  2. Server_log.txt contains all the information happening at all the nodes. You may modify code of cloning controller to view more details if you feel so.
  3. Structure of server_log.txt after "--->" is Iteration_number | Satisfied/Not-Satisfied | Number of Agents | Per Agent Population. 
  4. Various Graphs for various cases as per their nomenclature can be found inside Graph folder.
  5. Separate code for PherCon Approach can be found in Pher_Con Folder. Please Note, cloning controller code does NOT take input from this folder. All code related to pheromones for Cloning Controller was copied and pasted in the same file (cloningControllerOnePort.pl). So both are not dependent on each other. I made it separate so that it can be utilized for other works. 
