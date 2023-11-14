#!/bin/bash

# Vajra EDR client installer script for linux
# Author: Arjun Sable, IEOR, IIT Bombay
# Date: 2023-07-26
start_time=$(date +%s.%N)
scriptVersion="1.0.0.1"

# Create log file
LogFile="vajra_install_log.txt"
if [ -f "$LogFile" ]; then
    rm "$LogFile"
fi

# Log error/info messages into file
logError() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LogFile"
}

# Function to check if the script is running with root privileges
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "\e[31m [-] ERROR: Script running without root privileges! \e[0m"
        echo -e "\e[31m [-] ERROR: Please run this script with root privileges! Use sudo to run script. \e[0m"
		logError "ERROR" "Script running without root privileges!"
		read -n 1 -s -r -p "Press any key to exit ..."
        exit 1
	else
		echo -e "\e[32m [+] SUCCESS: Script running with root privileges! Proceeding with the installation.\e[0m"
        logError "INFO" "Script running with root privileges!"
    fi
}

# Check Linux version and architecture
check_linux_version() {
	supported_kernel_version="4.18"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        linux_flavor=$NAME
    else
        linux_flavor=$(uname -s)
    fi

    # Get the Linux version
    kernel_version=$(uname -r)

    # Check for architecture
    if [ "$(uname -m)" == "x86_64" ]; then
        architecture="64"
    else
        architecture="32"
    fi

    # Print the results

	logError "INFO" "Linux flavour $linux_flavor, $kernel_version and architecture $architecture bits"

    if [ "$(printf '%s\n' "$supported_kernel_version" "$kernel_version" | sort -V | head -n1)" == "$supported_kernel_version" ]; then
		echo -e "\e[33m [+] Vajra EDR client supports the current Linux flavour $linux_flavor, kernel version $kernel_version and $architecture bits.\e[0m"
		echo -e "\e[33m [+] Continuing the installation process.\e[0m"
		logError "INFO" "Linux flavour $linux_flavour, $kernel_version and architecture $architecture bits"
    else
		echo -e "\e[33m [-] Vajra EDR client does not support current Linux kernel version.\e[0m"
		echo -e "\e[33m [-] Vajra EDR client currently supports Linux kernel version above $supported_kernel_version.\e[0m"
		echo -e "\e[31m [-] Aborting the installation process.\e[0m"
		logError "ERROR" "Vajra EDR Client does not support current system configuration Linux flavour $linux_flavour, $kernel_version and architecture $architecture bits"
		read -n 1 -s -r -p "Press any key to exit ..."
        exit 1
    fi
}

# Check if Vajra service is already running
check_vajra_service() {
    if systemctl is-active --quiet vajra.service; then
        echo -e "\e[31m [-] ERROR: The Vajra EDR service is already running. Exiting...\e[0m"
        logError "ERROR: The Vajra service is already running."
		read -n 1 -s -r -p "Press any key to exit ..."
        exit 1
    else
        echo -e "\e[32m [+] The Vajra EDR service is not running. Proceeding with the installation...\e[0m"
		logError "INFO" "The Vajra service does not exist"
    fi
}

create_directories() {
	# Create necessary directories
	echo -e "\e[33m [+] Creating installation directories \e[0m "
	sudo mkdir -p /etc/osquery/
}

copy_files() {

	sources=(
    "common/cert.pem"
    "common/enrollment_secret"
    "common/osquery.flags"
	"common/osqueryd"
	"common/vajra.service"
	"common/vajra.service"
	"common/vajra.sh"
	)

	destinations=(
		"/etc/osquery/"
		"/etc/osquery/"
		"/etc/osquery/"
		"/usr/bin/"
		"/lib/systemd/system/"
		"/etc/systemd/system/"
		"/usr/bin/"
	)
    for ((i = 0; i < ${#sources[@]}; i++)); do
        source="${sources[$i]}"
        destination="${destinations[$i]}"
        
        # Check if the source file exists
        if [ -f "$source" ]; then
            cp "$source" "$destination"
            
            # Check the exit status of the copy command
            if [ $? -eq 0 ]; then
                echo -e "\e[33m [+] Copied $source to $destination successfully.\e[0m"
				logError "INFO" "Copied $source to $destination successfully."
            else
                echo -e "\e[31m [-] ERROR: Failed to copy $source to $destination.\e[0m "
				logError "ERROR" "Failed to copy $source to $destination."
            fi
        else
            echo -e "\e[31m [-] ERROR: Source file $source not found.\e[0m "
			echo -e "\e[31m [-] Aborting the installation process\e[0m "
            echo -e "\e[33m [-] Cleaning up the installation files\e[0m "
            uninstall_osquery
        fi
    done
}

set_permissions_to_binary() {
	sudo chmod +x /usr/bin/osqueryd
	sudo chmod +x /usr/bin/vajra.sh
	sudo chmod 644 /etc/systemd/system/vajra.service
}

create_vajra_service() {
	# Creating Vajra service
	#sudo python3 /home/kaushal/Downloads/vajraclient/linux/pseudoDNS.py
	ip_address=$(python3 /home/kaushal/Downloads/vajraclient/linux/pseudoDNS.py)
	echo "Adding $ip_address s3.ieor.iitb.ac.in to /etc/hosts"
	sudo sh -c "echo '$ip_address	s3.ieor.iitb.ac.in' >> /etc/hosts"
	
	sudo systemctl start vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Vajra service started successfully.\e[0m"
        logError "INFO" "Successfully started Vajra service."
    else
        echo -e "\e[31m [-] ERROR: Failed to start Vajra service.\e[0m"
        logError "ERROR" "Failed to start Vajra service."
    fi

	# Enabling to start service on system boot
	sudo systemctl enable vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Vajra service enabled to start on boot successfully.\e[0m"
        logError "INFO" "Vajra service enabled to start on boot successfully."
    else
        echo -e "\e[31m [-] ERROR: Vajra service failed to enable on boot.\e[0m"
        logError "ERROR" "Vajra service failed to enable on boot."
    fi
	}
	

install_osquery() {
    echo -e "\e[32m [+] Installing Vajra EDR client version $scriptVersion on your system, an indigenously developed endpoint security system at Indian Institute of Technology, Bombay (an institute of national importance).\e[0m"
    logError "INFO" "Vajra EDR client installation script version $scriptVersion"

    # ------------------------------------- Part 1 : Testing the system compatibility -------------------------------------
    # Check root privileges
    echo -e "\e[33m [+] Verifying that script is running with root privileges\e[0m"
    check_permissions

    check_linux_version

    check_vajra_service

    create_directories

    copy_files

    set_permissions_to_binary

    create_vajra_service

}

uninstall_osquery() {

	echo -e "\e[33m [+] Uninstalling Vajra EDR Client. Please wait ...\e[0m"
    logError "INFO" "Uninstalling Vajra EDR Client."

	# Stopping Vajra service 
	echo -e "\e[33m [+] Stopping Vajra service\e[0m"
	sudo sed -i '$ d' /etc/hosts
	sudo systemctl stop vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Stopped Vajra service successfully.\e[0m"
        logError "INFO" "Stopped Vajra service successfully"
    else
        echo -e "\e[31m [-] ERROR: Failed to stop Vajra service.\e[0m"
        logError "ERROR" "Failed to stop Vajra service"
    fi

	# Disabling Vajra service
	echo -e "\e[33m [+] Disabling Vajra service\e[0m"
	sudo systemctl disable vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Disabled Vajra service successfully.\e[0m"
        logError "INFO" "Disabled Vajra service successfully"
    else
        echo -e "\e[31m [-] ERROR: Failed to disable Vajra service.\e[0m"
        logError "ERROR" "Failed to disable Vajra service"
    fi

	# Removing Osquery binary
	echo -e "\e[33m [+] Removing Osquery binary\e[0m"
	sudo rm -rf /usr/bin/osqueryd
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery binary successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery binary successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery binary\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery binary"
    fi

	# Removing Osquery script
	echo -e "\e[33m [+] Removing Osquery script\e[0m"
	sudo rm -rf /usr/bin/vajra.sh
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery script successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery script successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery script\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery script"
    fi
	
	# Removing Osquery configurations
	echo -e "\e[33m [+] Removing Osquery configurations\e[0m"
	sudo rm -rf /etc/osquery/
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery configurations successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery configurations successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery configurations\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery configurations"
    fi

	# Removing Osquery service
	echo -e "\e[33m [+] Removing Osquery service\e[0m"
	sudo rm -rf /lib/systemd/system/vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery service successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery service successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery service\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery service"
    fi

	sudo rm -rf /etc/systemd/system/vajra.service
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery service successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery service successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery service\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery service"
    fi

	# Removing Osquery log files
	echo -e "\e[33m [+] Removing Osquery log files\e[0m"
	sudo rm -rf /var/osquery/
    if [ $? -eq 0 ]; then
        echo -e "\e[32m [+] Removed Vajra osquery log files successfully.\e[0m"
        logError "INFO" "Removed Vajra osquery log files successfully."
    else
        echo -e "\e[31m [-] ERROR: Failed to remove Vajra osquery log files\e[0m"
        logError "ERROR" "Failed to remove Vajra osquery log files"
    fi

	echo -e "\e[32mVajra EDR Client uninstallation successfull\e[0m"
}


# Main

if [ $# -eq 0 ] || [ $# -eq 1 ]; then

    if [ "$1" = "-install" ] || [ "$1" = "" ]; then
        install_osquery
    elif [ "$1" = "-uninstall" ]; then
        uninstall_osquery
    else
        echo -e "\e[31mInvalid argument: $1\e[0m"
        echo -e "\e[31mUsage: $0 [-install | -uninstall]\e[0m"
        echo -e "\e[32mIf no option is selected, by default the script will install osquery \e[0m"
        echo -e "\e[31mVajra EDR Client installation failed\e[0m"
        exit 1
    fi
else
    echo -e "\e[32mMultiple arguments provided.\e[0m"
fi

end_time=$(date +%s.%N)
elapsed_time=$(echo "$end_time - $start_time" | bc)
echo "Operation took: $elapsed_time seconds"
