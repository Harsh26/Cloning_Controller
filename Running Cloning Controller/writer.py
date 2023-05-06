import re
import os

# read data.txt containing new node neighbor lists
with open('input.txt', 'r') as f:
    data = f.readlines()

# loop over 50 files and update node neighbor lists
for i in range(50):
    old_filename = f"line_myclone50_{i:02}.pl"
    new_filename = f"grid_myclone50_{i:02}.pl"
    
    # read contents of old file and replace line using regex
    with open(old_filename, 'r') as f:
        contents = f.read()
        #print(data[i])
        data_line = data[i]
        data_line = data_line.split(": ")[1] # remove the first part before colon
        data_line = data_line.replace(" ", "") # remove any white spaces
        result = data_line.strip() # remove leading/trailing white spaces
        new_contents = re.sub(r"assert\(node_neighbours\(\[.*\]\)\)", f"assert(node_neighbours(["+ result +"]))", contents)
    
    # write modified contents to new file
    with open(new_filename, 'w') as f:
        f.write(new_contents)

    
#line = "15000: 15001, 15003, 15006"

#print(result) # output: "15001,15003,15006"

