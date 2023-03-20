
import matplotlib.pyplot as plt

import re


res = []

# Open the file
with open("server_log.txt", "r") as f:
    # Read each line
    for line in f:
        # Check if line contains the pattern
        
        pattern = "--->"

        match = re.search(pattern, line)
        if match:
            #print(line[match.end():], end=" ")
            res.append(line[match.end():])

#print(res)

result = []

# Iterate over list
for string in res:
    # Split string into list of strings
    int_list = string.split()
    # Convert strings to integers
    int_list = [int(x) for x in int_list]

    result.append(int_list)

#for element in result:
#    print(element, end=', ')

mp = {}

for e in result:
    if 1 <= e[0] <= 200:
        if e[0] not in mp:
            mp[e[0]] = [e[1], e[2]]
        else:
            mp[e[0]][0] += e[1]
            mp[e[0]][1] += e[2]

x = []
y1 = []
y2 = []

for k, v in mp.items():
    #print(f"{k}: {v[0]} {v[1]}")
    x.append(k)
    y1.append(v[0])
    y2.append(v[1])



plt.plot(x,y1,label='Number of RRS Serviced')
plt.plot(x,y2,label='Total Number of Agents')

plt.legend()
plt.show()