# save_to_file.py

message = "Hello, GitHub Actions!"
file_path = "output.txt"

# Open the file in write mode and save the message
with open(file_path, "w") as file:
    file.write(message)

print(f"Saved '{message}' to {file_path}")
