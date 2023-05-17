import os

# Spawn a terminal to set the log file
os.system('gnome-terminal --command="bash -c \'swipl -s log.pl -g set_log; exec bash\'"')

# Define the prefix for the Prolog file names
prefix = 'mesh_myclone50_'

# Get the list of Prolog files in the current working directory
prolog_files = [f for f in os.listdir() if f.startswith(prefix)]

# Sort the list of Prolog files by their number (assuming they have a format of "myclone20_N.pl")
prolog_files = sorted(prolog_files, key=lambda f: int(int(f[-5]) * 10 + int(f[-4])))

print(prolog_files)

# Spawn a terminal for each Prolog file in order
for f in prolog_files:
    # Construct the command to execute the Prolog file with a specific predicate
    command = f'gnome-terminal --command="bash -c \'swipl -s {f} -g my_predicate; exec bash\'"'
    
    # Spawn the terminal and execute the command
    os.system(command)
    
    

