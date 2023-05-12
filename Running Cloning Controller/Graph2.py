import matplotlib.pyplot as plt
import math
import re
import random

MaxReqPossible = 48
number_of_agents = 3
explosion_pts = [1, 50, 100]

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
timepoints = []



# Iterate over list
for string in res:
    # Split string into list of strings
    int_list = string.split()

    timepoints.append(int(int_list[0]))

    # Convert to pairs of integers
    int_list = [(int(x.split('-')[0]), int(x.split('-')[1])) for x in int_list[3:]]

    result.append(int_list)
    


#for element in result:
#    print(element, end=', ')


# print('Number of agents: ', number_of_agents)
# print('Timepoints: ', timepoints)

# Create an ordered dictionary to keep track of population per timepoint
from collections import OrderedDict
population_map = OrderedDict()

# Initialize population map with zeros
for tp in timepoints:
    population_map[tp] = [0] * number_of_agents

# Update population map with actual population values
for tp, pop in zip(timepoints, result):
    for p in pop:
        agent_type, agent_pop = p
        population_map[tp][agent_type-1] += agent_pop
        random_number = random.randint(0, 10)
        population_map[tp][agent_type-1] = min(population_map[tp][agent_type-1], 300)#190 - random_number)

# Print population map
#for tp, pop in population_map.items():
#    print(tp, pop)


# Define the x-axis and y-axis variables
x_axis = list(population_map.keys())
num_agents = len(population_map[x_axis[0]])
y_axes = [[] for _ in range(num_agents)]
agent_labels = [f"Agent {i+1}" for i in range(num_agents)]

# Collect the y-axis data for each agent
for t in x_axis:
    for i in range(num_agents):
        y_axes[i].append(population_map[t][i])

# Create the line plot
for i in range(num_agents):
    plt.plot(x_axis, y_axes[i], label=agent_labels[i])

# Add labels and legend to the plot
plt.xlabel('Timepoint')
plt.ylabel('Population')
plt.title('Agent population_map over Time')
plt.legend()
plt.legend(loc="upper right")

for ep in explosion_pts:
	plt.axvline(x=ep, linestyle='--', color='grey')


# Show the plot
plt.show()

