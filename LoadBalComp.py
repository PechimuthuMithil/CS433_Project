import random
import matplotlib.pyplot as plt

# Constants
NUM_SERVERS = 2
MAX_USERS_PER_SERVER = 100
NUM_TIME_INTERVALS = 100

# Initialize server loads
server_loads = [0] * NUM_SERVERS

# Load balancing techniques
def round_robin(server_loads, new_connections):
    if prev_rr_conn == 0:
        return 1
    else:
        return 0

def LeastLoaded(server_loads, new_connections):
    return server_loads.index(min(server_loads))

def weighted_round_robin(server_loads, new_connections):
    # Assign clients based on load (weighted)
    server_weights = [load / MAX_USERS_PER_SERVER for load in server_loads]
    return server_weights.index(min(server_weights))

def random_balancing(server_loads, new_connections):
    return random.randint(0, NUM_SERVERS - 1)

def hash_balancing(server_loads, new_connections):
    # Implement a simple hash-based load balancing
    return hash(str(new_connections)) % NUM_SERVERS

# Load balancing techniques dictionary
load_balancing_techniques = {
    "Round Robin": round_robin,
    "Least Loaded": LeastLoaded,
    "Weighted Round Robin": weighted_round_robin,
    "Random": random_balancing,
    "Hash": hash_balancing,
}

# Separate data storage for each technique
technique_data = {technique: {"server_a": [0]*NUM_TIME_INTERVALS, "server_b": [0]*NUM_TIME_INTERVALS} for technique in load_balancing_techniques}

# Simulation and plotting for each technique

server_loads = [0] * NUM_SERVERS  # Reset server loads for each technique
prev_rr_conn = 0
for time in range(NUM_TIME_INTERVALS):
    new_connections = random.randint(0, 20)  # Simulate new connections
    client_count = sum(server_loads) + new_connections

    # Simulate users dropping out (disconnect)
    users_to_disconnect = random.randint(0, 20)
    if users_to_disconnect > client_count:
        users_to_disconnect = client_count

    client_count -= users_to_disconnect

    for _ in range(new_connections):
        for technique in load_balancing_techniques:
            chosen_server = load_balancing_techniques[technique](server_loads, new_connections)
            if technique == 'Round Robin':
                prev_rr_conn = chosen_server
            if (server_loads[chosen_server] < MAX_USERS_PER_SERVER):
                server_loads[chosen_server] += 1
            if chosen_server == 0:
                technique_data[technique]["server_a"][time]+=1
            else:
                technique_data[technique]["server_b"][time] += 1

    k =min(users_to_disconnect,random.randint(0,20))
    partA = min(server_loads[0],k)
    partB = min(server_loads[1],users_to_disconnect - k)
    
    server_loads[0] -= partA
    server_loads[1] -= partB

    # Store data for plotting
   
# Create separate plots for each technique
for technique in load_balancing_techniques:
    plt.figure()
    time_intervals = range(NUM_TIME_INTERVALS)
    plt.plot(time_intervals, technique_data[technique]["server_a"], label="Server A Load")
    plt.plot(time_intervals, technique_data[technique]["server_b"], label="Server B Load")
    plt.xlabel("Time Intervals")
    plt.ylabel("Server Load")
    plt.legend()
    plt.title(f"Server Load Balancing Comparison ({technique})")

plt.show()
