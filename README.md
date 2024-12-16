these scripts were created as an experiment "by IP address to service", I needed to do `ip a add`, but doing it through `/etc/network/interfaces` is not convenient, especially in terms of automatic adding/removing addresses, the scripts here are intended for ipv6 but you can use the script for v4

# Setup Guide

This guide provides steps to set up the "IP per service" system. You can either use the provided Ansible playbook for automated installation or follow the manual setup steps outlined below.

## Prerequisites

- A Linux system with IPv6 enabled.
- `bash` and `systemd` installed on the system.
- (optional)local or remote installed `ansible`


1. Clone the repository:  
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

---

## Installation via Ansible Playbook

2. Run the Ansible playbook(don't forget to specify the inventory file via -i if it is not registered at the system level):  
    ```bash
    ansible-playbook playbook-install.yaml
    ```

3. You can also specify which services need these IPs
    ```bash
    ansible-playbook playbook-install.yaml -e 'dependent_services=docker.service'
    ```

---

## Manual Installation

2. Copy the `ip-per-service.sh` script to `/usr/sbin`:  
    ```bash
    sudo cp ./ip-per-service.sh /usr/sbin/ip-per-service.sh
    sudo chmod +x /usr/sbin/ip-per-service.sh
    ```

3. Create a directory for IP list files:  
    ```bash
    sudo mkdir -p /usr/local/share/services-ips/
    ```

4. Prepare an IP list file for the desired network interface (e.g., `eth0`):  
    ```bash
    sudo touch /usr/local/share/services-ips/ips-eth0.list
    ```

5. Copy the `ip-per-service@.service` file to `/etc/systemd/system`:  
    ```bash
    sudo cp ./ip-per-service@.service.j2 /etc/systemd/system/ip-per-service@.service
    ```

6. replace {{ script_path }} and {{ ip_list_prefix_path }} in the file with the correct paths
    ```bash
    # Replace {{ script_path }} with the correct path
    sudo sed -i 's|{{ script_path }}|/usr/sbin/ip-per-service.sh|g' /etc/systemd/system/ip-per-service@.service

    # Replace {{ ip_list_prefix_path }} with the correct path
    sudo sed -i 's|{{ ip_list_prefix_path }}|/usr/local/share/services-ips/|g' /etc/systemd/system/ip-per-service@.service
    ```
7. Reload `systemd` to register the service:  
    ```bash
    sudo systemctl daemon-reload
    ```

8. Enable and start the service for your network interface (e.g., `eth0`):  
    ```bash
    sudo systemctl enable ip-per-service@eth0.service
    sudo systemctl start ip-per-service@eth0.service
    ```
---

9. You can also specify which services need these IPs, open the service that requires an ip address. example for docker.service and eth0 interface:
    ```bash
    sudo tee /etc/systemd/system/docker.service.d/90-ip-per-service-eth0-dep.conf > /dev/null << EOF
    [Unit]
    After=ip-per-service@eth0.service
    Wants=ip-per-service@eth0.service
    EOF
    ```
    
10. Reload `systemd` to register the service:  
    ```bash
    sudo systemctl daemon-reload
    ```

---
  
## Usage

1. Add desired IPv6 addresses to the appropriate IP list file:  
    ```bash
    echo "2001:db8::1/64" | sudo tee -a /usr/local/share/services-ips/ips-eth0.list
    ```

2. Restart the service to apply the changes:  
    ```bash
    sudo systemctl restart ip-per-service@eth0.service
    ```

3. you can check the status of address assignment (number of assigned and missing)
    ```bash
    journalctl -eu ip-per-service@eth0.service
    ```
The system will ensure all IPs in the list are assigned to the specified network interface.
