file_path="C:\Windows\System32\drivers\etc\hosts"

def delete_last_line():
    with open(file_path, 'r') as file:
        lines = file.readlines()
    # Remove the last line
    if lines:
        lines.pop()
    # print("Hello World!")
    with open(file_path, 'w') as file:
        file.writelines(lines)

if __name__ == '__main__':
    delete_last_line()