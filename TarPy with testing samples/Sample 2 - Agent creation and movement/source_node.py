# Import Tarpy class from Tartarus file
from Tartarus import Tarpy

# Create an object of the class Tarpy
tar = Tarpy()

# Consult the Tartarus platform file which is a string
tar.consult("platform_ubuntu.pl")

IP = "localhost"
Port = 5000
Token = 2211
Agent= "test_agent"

# Start tartarus with a specific IP, Port and Token. Make sure to use even numbered Port numbers
tar.start_tartarus(IP, Port, Token)

# Create a mobile agent with a behavior file attached to it
# Syntax - tar.create_mobile_agent(<Agent_name>, <behavior_filename>, <IP>, <Port>, <List of Tokens>)
tar.create_mobile_agent(Agent, "behavior.py", IP, Port, [Token])

tar.assign_val(Agent, "prime", [2,3])
tar.add_payload(Agent, "prime")

#tar.agent_execute(Agent,"localhost", 5000)



# Move agent to dest_node
# Syntax - tar.move_agent(<Agent_name>, <IP>, <Port>)
tar.move_agent(Agent, IP, 5002)

# Keep the platform alive - specially in case of mobile agent movement as acknowledgement will be recieved from dest
# keep_alive function waits for any Prolog query to be executed. If 'halt' (without quotes) is entered, it closes Tartarus
tar.keep_alive()
