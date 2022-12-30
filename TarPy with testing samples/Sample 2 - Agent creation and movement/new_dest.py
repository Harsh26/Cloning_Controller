# Import Tarpy class from Tartarus file
from Tartarus import Tarpy

# Create an object of the class Tarpy
tar = Tarpy()

# Declare and initialize IP, Port and Token
IP = "localhost"
Port = 5004
Token = 2211

#Agent = "test_agent"

# Consult the Tartarus platform file which is a string
tar.consult("platform_ubuntu.pl")

# Start tartarus with a specific IP, Port and Token. Make sure to use even numbered Port numbers
tar.start_tartarus(IP, Port, Token)

# Keep the platform alive
# keep_alive function waits for any Prolog query to be executed. If 'halt' (without quotes) is entered, it closes Tartarus
tar.keep_alive()