
import matplotlib.pyplot as plt
import math
import re

MaxReqPossible = 48

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

# print(res)

result = []

# Iterate over list
for string in res:
    # Split string into list of strings
    int_list = string.split()
    # Convert first three strings to integers
    int_list = [int(x) for x in int_list[:3]]

    result.append(int_list)



#for element in result:
#    print(element, end=', ')

mp = {}

for e in result:
    if 1 <= e[0] <= 500:
        if e[0] not in mp:
            if e[1] == 0:
                mp[e[0]] = [e[1], e[2], 1]
            else:
                mp[e[0]] = [e[1], e[2], 1]
                
        else:
            if e[1] == 0:
                mp[e[0]][0] += e[1]
            else:
                mp[e[0]][0] += (e[1])
                
            mp[e[0]][1] += e[2]
            mp[e[0]][2] += 1

x = []
y1 = []
y2 = []

for k, v in mp.items():
    #print(f"{k}: {v[0]} {v[1]}")
    x.append(k)
    y1.append(math.ceil( (v[0]/v[2]) * MaxReqPossible ))
    y2.append(v[1])



plt.plot(x,y1,label='Number of RRS Serviced')
plt.plot(x,y2,label='Total Number of Agents')

plt.legend()
plt.show()