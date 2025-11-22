# ZUJ_DVWA

This script automates the deployment of DVWA (Damn Vulnerable Web Application) using Docker on Linux systems. Designed specifically for ZUJ students, it allows you to quickly set up a local environment for web security testing and learning without manual configuration. Just run the script, and DVWA will be ready to use on your machine.

## Features

- **Automatic Distribution Detection**: Supports Debian/Ubuntu, RHEL/CentOS/Fedora, and Arch Linux
- **Automatic Docker Installation**: Installs Docker if not already present on your system
- **Service Management**: Automatically starts and enables the Docker service
- **Log Management**: All operations and container logs are saved to `dvwa-docker.log` in the script directory
- **Port Conflict Resolution**: Automatically stops any containers using port 80
- **Simple Execution**: Single command to get DVWA up and running

## Requirements

- A Linux system (Debian/Ubuntu, RHEL/CentOS/Fedora, or Arch Linux)
- sudo privileges (for Docker installation and service management)
- Internet connection (for downloading Docker and DVWA image)

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/VictorRayyan19/ZUJ_DVWA.git
   cd ZUJ_DVWA
   ```

2. Run the script:
   ```bash
   ./start-dvwa.sh
   ```

3. Access DVWA in your web browser:
   ```
   http://localhost
   ```

4. Default DVWA credentials:
   - Username: `admin`
   - Password: `password`

## What the Script Does

1. **Detects your Linux distribution** to use the appropriate package manager
2. **Checks if Docker is installed**, and installs it if needed
3. **Starts the Docker service** if it's not already running
4. **Pulls the DVWA Docker image** (`vulnerables/web-dvwa`)
5. **Stops any existing containers** using port 80
6. **Runs the DVWA container** with the command:
   ```bash
   docker run --rm -it -p 80:80 vulnerables/web-dvwa
   ```
7. **Logs all output** to `dvwa-docker.log` in the script directory

## Logs

All script operations and Docker container logs are saved to `dvwa-docker.log` in the same directory as the script. You can review these logs to troubleshoot any issues or monitor container activity.

## Stopping the Container

Press `Ctrl+C` in the terminal where the script is running. The container will be automatically removed (thanks to the `--rm` flag).

## Troubleshooting

- **Permission denied**: Make sure the script is executable with `chmod +x start-dvwa.sh`
- **Port 80 already in use**: The script will automatically stop any containers using port 80
- **Docker group membership**: If you see permission errors, you may need to log out and back in after the script adds you to the docker group
- **Check logs**: Review `dvwa-docker.log` for detailed information about what went wrong

## Security Note

DVWA is intentionally vulnerable and should **ONLY** be used in a safe, isolated environment for educational purposes. Never expose it to the internet or use it in a production environment.

## License

This project is open source and available under the MIT License.
