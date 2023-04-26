import re

# loop through all files
for i in range(50):
    file_name = f"myclone50_{i}.pl"
    
    # read contents of file
    with open(file_name, 'r') as file:
        file_contents = file.read()
        
    # use regex to replace init_need(0) with init_need(-1)
    file_contents = re.sub(r"init_need\(-2\)", r"init_need(0)", file_contents)
    
    # write modified contents back to file
    with open(file_name, 'w') as file:
        file.write(file_contents)
