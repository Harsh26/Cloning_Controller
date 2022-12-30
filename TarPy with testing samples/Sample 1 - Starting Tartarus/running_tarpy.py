# Import Tarpy class from Tartarus file
from Tartarus import Tarpy

# Create an object of the class Tarpy
tar = Tarpy()

# Consult the Tartarus platform file which is a string
tar.consult('platform_ubuntu.pl')

# Start tartarus with a specific IP, Port and Token. Make sure to use even numbered Port numbers
tar.start_tartarus("localhost", 5000, 2)

# Keep the platform alive
# keep_alive function waits for any Prolog query to be executed. If 'halt' (without quotes) is entered, it closes Tartarus
tar.keep_alive()

# Type halt to close Tartarus in input