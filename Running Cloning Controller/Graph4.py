import random
import matplotlib.pyplot as plt


# Define the x-axis and y-axis variables
x_axis = list(range(1, 150))
num_agents = 1
y_axes = [[] for _ in range(num_agents)]

# Generate the random values for each agent
for t in x_axis:
    if t <= 10:
        agent_values = [random.randint(1, 40) for _ in range(num_agents)]
    elif 10 < t <= 20:
        agent_values = [random.randint(20, 60) for _ in range(num_agents)]
    elif 20 < t <= 50:
        agent_values = [random.randint(50, 100) for _ in range(num_agents)]
    elif 50 < t <=60:
        agent_values = [random.randint(80, 140) for _ in range(num_agents)]
    elif 60 < t <= 80:
        agent_values = [random.randint(60, 120) for _ in range(num_agents)]
    elif 80 < t <= 90:
        agent_values = [random.randint(30, 50) for _ in range(num_agents)]
    elif 90 < t <= 100:
        agent_values = [random.randint(10, 40) for _ in range(num_agents)]
    elif 100 < t <= 150:
        agent_values = [random.randint(1, 20) for _ in range(num_agents)]
    for i in range(num_agents):
        y_axes[i].append(agent_values[i])

# Create the line plot
for i in range(num_agents):
    plt.plot(x_axis, y_axes[i])



plt.axvline(x=50, linestyle='--', color='grey')
plt.text(50, -10, 'Request Shutdown', color='grey', ha='center')

plt.axvline(x=117, linestyle='--', color='green')     
plt.text(117, -10, 'All platform satisfied', color='green', ha='center')

# Add labels and legend to the plot
plt.xlabel('Iteration')
plt.ylabel('Total Number of Agents')
plt.title('Total Population over Time')
plt.show()
