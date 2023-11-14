from flask import Flask, request
import json

app = Flask(__name__)

replicated_servers = ["192.168.137.1","192.168.137.128"]
current_index = 0

@app.route('/get_replica_ip', methods=['GET'])
def get_replica_ip():
    global current_index
    selected_ip = replicated_servers[current_index]
    current_index = (current_index + 1) % len(replicated_servers)
    return json.dumps({"ip": selected_ip})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
