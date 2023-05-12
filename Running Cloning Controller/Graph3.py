import matplotlib.pyplot as plt
import math
import re
import random

MaxReqPossible = 48
explosion_pts = [1, 50, 100]

res2 = []

with open("server_log.txt", "r") as f:
    # Read each line
    for line in f:
        # Check if line contains the pattern
        
        pattern = "--->"

        match = re.search(pattern, line)
        if match:
            #print(line[match.end():], end=" ")
            res2.append(line[match.start()-6:match.start()]  + line[match.end():match.end()+7])

#print(res2)

result2 = []

for string in res2:
    # Split string into list of strings
    int_list = string.split()
    # Convert first three strings to integers
    int_list = [int(x) for x in int_list[:]]

    result2.append(int_list)


for element in result2:
    print(element, end=', ')

mp2 = {}
mp3 = {}
for e in result2:
    if 1 <= e[1] <= 500:
        if e[0] not in mp2:
            if e[2] == 0:
                mp2[e[0]] = [e[1], e[2]]
            
            else:
                if e[0] not in mp3:
                    mp3[e[0]] = [0, 0]
                
                else:
                    mp3[e[0]][0] += 0
                    mp3[e[0]][1] += 1
        
        else:
            if e[2] == 1:
                
                if e[0] not in mp3:
                    mp3[e[0]] = [e[1] - mp2[e[0]][0], 0]
                
                else:
                    mp3[e[0]][0] += e[1] - mp2[e[0]][0]
                    mp3[e[0]][1] += 1
                
                #mp2.erase(e[0])
                del mp2[e[0]]


#print(mp3)
#print(mp2)


x = []
y = []

for k, v in mp3.items():
    #print(f"{k}: {v[0]} {v[1]}")
    x.append(k)
    if v[1] <= 0:
        y.append(0)
    else:
        y.append(math.ceil( (v[0]/v[1]) ))
    


plt.bar(x,y,label='Waiting Time Plot')

# Add labels and legend to the plot
plt.xlabel('Avg Waiting Time')
plt.ylabel('Platform')
plt.title('Avg Waiting Time Plot')
plt.legend()
plt.legend(loc="upper right")

plt.legend()
plt.show()



