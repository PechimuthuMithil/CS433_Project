import requests
file_path="C:\Windows\System32\drivers\etc\hosts"
def get_replica_ip():
    response = requests.get("http://sudoDNS.iitgn.ac.in:5000/get_replica_ip")
    data = response.json()
    return data['ip']
def write_into_file(replica):
    with open(file_path,'a') as file:
        file.write(f"\n{replica}\ts3.ieor.iitb.ac.in")
if __name__ == '__main__':
    replica_ip = get_replica_ip()
    print("Selected Replica IP:", replica_ip)
    write_into_file(replica_ip)
    # Now you can use 'replica_ip' to connect to the selected replicated server
