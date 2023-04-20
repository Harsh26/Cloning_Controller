import os

# Spawn a command prompt to set the log file
# os.system('start cmd /k "swipl -s log.pl -g set_log"')

# Define the prefix for the Prolog file names
prefix = 'myclone20_'

# Get the list of Prolog files in the current working directory
prolog_files = [f for f in os.listdir() if f.startswith(prefix)]


# Sort the list of Prolog files by their number (assuming they have a format of "myclone20_N.pl")
prolog_files = sorted(prolog_files, key=lambda f: int(f.split("_")[1].split(".")[0]))

# Spawn a command prompt for each Prolog file in order
for f in prolog_files:
    # Construct the command to execute the Prolog file with a specific predicate
    command = f'start cmd /k "swipl -s {f} -g my_predicate"'
    
    # Spawn the command prompt and execute the command
    os.system(command)
