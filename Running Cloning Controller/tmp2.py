nodes = range(15000, 15050)
adj_list = {}

# Create an adjacency list
for i in nodes:
    adj_list[i] = []
    for j in nodes:
        if i != j:
            adj_list[i].append(j)

# Print the adjacency list
for node in adj_list:
    print(f"{node}: {', '.join(str(n) for n in adj_list[node])}")
