import requests

def get_replica_ip():
    response = requests.get("http://sudoDNS.iitgn.ac.in:5000/get_replica_ip")
    data = response.json()
    return data['ip']

if __name__ == '__main__':
    replica_ip = get_replica_ip()
    print(replica_ip)
    # Now you can use 'replica_ip' to connect to the selected replicated server
