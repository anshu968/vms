#!/bin/bash
# ============================================================
#   VALKAS / RAJVEER VMS â€” REAL VM INSTALLER
#   Made by Rajveer & Nissal
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

clear

echo -e "${MAGENTA}"
echo " â–ˆâ–ˆâ•—   â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—"
echo " â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•”â•â•â•â•â•"
echo " â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â• â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—"
echo " â•šâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•— â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â•šâ•â•â•â•â–ˆâ–ˆâ•‘"
echo "  â•šâ–ˆâ–ˆâ–ˆâ–ˆâ•”â• â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘"
echo "   â•šâ•â•â•â•  â•šâ•â•  â•šâ•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•â•šâ•â•  â•šâ•â•â•šâ•â•â•â•â•â•â•"
echo -e "${RESET}"

echo -e "${WHITE}${BOLD}         VALKAS REAL VM INSTALLER${RESET}"
echo -e "${CYAN}         Made by Rajveer & Nissal${RESET}"
echo ""

# ============================================================
# ROOT CHECK
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Switching to root...${RESET}"
    exec sudo bash "$0" "$@"
    exit
fi

# ============================================================
# VPS CONFIGURATION
# ============================================================

echo ""
echo -e "${WHITE}${BOLD}VPS Configuration${RESET}"
echo ""

# Hostname
while true; do
read -p "Hostname (example root@rajveer): " CUSTOM_HOST
[[ -n "$CUSTOM_HOST" ]] && break
echo -e "${RED}[âœ—] Hostname cannot be empty${RESET}"
done

hostnamectl set-hostname "$CUSTOM_HOST"
echo "127.0.0.1 $CUSTOM_HOST" >> /etc/hosts

# VM Name
while true; do
read -p "VM Name: " VM_NAME
[[ -n "$VM_NAME" ]] && break
echo -e "${RED}[âœ—] VM Name cannot be empty${RESET}"
done

# Username
while true; do
read -p "Username: " VM_USER
[[ -n "$VM_USER" ]] && break
echo -e "${RED}[âœ—] Username cannot be empty${RESET}"
done

# Password
while true; do
read -p "Password: " VM_PASS
[[ -n "$VM_PASS" ]] && break
echo -e "${RED}[âœ—] Password cannot be empty${RESET}"
done

# RAM
while true; do
read -p "RAM in MB (example 2048): " RAM
[[ "$RAM" =~ ^[0-9]+$ ]] && [ "$RAM" -ge 512 ] && break
echo -e "${RED}[âœ—] Enter valid RAM${RESET}"
done

# CPU
while true; do
read -p "CPU Cores (example 2): " CPU
[[ "$CPU" =~ ^[0-9]+$ ]] && [ "$CPU" -ge 1 ] && break
echo -e "${RED}[âœ—] Enter valid CPU${RESET}"
done

# Disk
while true; do
read -p "Disk Size in GB (example 20): " DISK
[[ "$DISK" =~ ^[0-9]+$ ]] && [ "$DISK" -ge 5 ] && break
echo -e "${RED}[âœ—] Enter valid Disk${RESET}"
done

# ============================================================
# DDoS ASK
# ============================================================

echo ""
echo -e "${WHITE}${BOLD}Do you want DDoS Protection?${RESET}"
echo ""
echo " [1] Yes"
echo " [2] No"
echo ""

while true; do
read -p "Select [1-2]: " DDOS_CHOICE
[[ "$DDOS_CHOICE" =~ ^[1-2]$ ]] && break
done

DDOS_ENABLED=false

if [ "$DDOS_CHOICE" = "1" ]; then

echo ""
echo -e "${CYAN}Premium DDoS Protection${RESET}"
echo ""
echo -e "${GREEN}Buy From:${RESET} rajveer_6362"
echo -e "${GREEN}Buy From:${RESET} nissalop2"
echo ""

read -p "Enter Premium License: " USER_KEY

VALID=false

case "$USER_KEY" in
"Made by rajveer & nissal"|
"Thx for use this tool"|
"rajveermishra6362@gmail.com"|
"Buyfrom nissalop22"|
"Buy from rajveer_6362")
VALID=true
;;
esac

if [ "$VALID" = false ]; then
echo -e "${RED}[âœ—] Invalid License${RESET}"
exit 1
fi

DDOS_ENABLED=true

echo -e "${GREEN}[âœ“] Premium Activated${RESET}"

fi

# ============================================================
# RANDOM PORTS
# ============================================================

generate_port() {
shuf -i 2000-65000 -n 1
}

SSH_PORT=$(generate_port)
WEB_PORT=$(generate_port)
VNC_PORT=5901

# ============================================================
# INSTALL PACKAGES
# ============================================================

echo ""
echo -e "${BLUE}[*] Installing Packages...${RESET}"

apt-get update -y

PACKAGES=(
curl
wget
git
screen
tmux
unzip
nano
htop
net-tools
netcat-openbsd
openssh-server
sshpass
socat
qemu-utils
qemu-system-x86
qemu-kvm
libvirt-daemon-system
libvirt-clients
bridge-utils
virtinst
neofetch
fastfetch
)

for pkg in "${PACKAGES[@]}"; do
apt-get install -y $pkg
done

systemctl enable ssh
systemctl restart ssh

echo -e "${GREEN}[âœ“] Packages Installed${RESET}"

# ============================================================
# CUSTOM DDOS
# ============================================================

if [ "$DDOS_ENABLED" = true ]; then

echo ""
echo -e "${BLUE}[*] Installing Custom DDoS Protection...${RESET}"

mkdir -p /opt/valkas-ddos
chmod -R 777 /opt/valkas-ddos

echo -e "${GREEN}[âœ“] Custom DDoS Protection Enabled${RESET}"

else

echo -e "${YELLOW}[!] DDoS Protection Skipped${RESET}"

fi

# ============================================================
# SELECT OS
# ============================================================

echo ""
echo -e "${WHITE}${BOLD}Select Operating System${RESET}"
echo ""
echo " [1] Ubuntu 22.04"
echo " [2] Debian 12"
echo " [3] Kali Linux"
echo ""

read -p "Select OS [1-3]: " OS

case $OS in

1)
OS_NAME="Ubuntu 22.04"
ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"
ISO_NAME="ubuntu.iso"
;;

2)
OS_NAME="Debian 12"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
ISO_NAME="debian.iso"
;;

3)
OS_NAME="Kali Linux"
ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"
ISO_NAME="kali.iso"
;;

*)
echo -e "${RED}[âœ—] Invalid OS${RESET}"
exit 1
;;

esac

# ============================================================
# PUBLIC IP DETECT
# ============================================================

echo ""
echo -e "${BLUE}[*] Detecting Public IP...${RESET}"

HOST_IP=$(curl -4 -s ifconfig.me || curl -4 -s ipv4.icanhazip.com)

if [[ -z "$HOST_IP" ]]; then
HOST_IP=$(hostname -I | awk '{print $1}')
fi

echo -e "${GREEN}[âœ“] Public IP:${RESET} ${CYAN}${HOST_IP}${RESET}"

# ============================================================
# CREATE VM
# ============================================================

mkdir -p /opt/valkas-vms

VM_DISK="/opt/valkas-vms/${VM_NAME}.qcow2"
ISO_PATH="/opt/valkas-vms/${ISO_NAME}"

echo ""
echo -e "${BLUE}[*] Creating ${DISK}GB Disk...${RESET}"

qemu-img create -f qcow2 "$VM_DISK" ${DISK}G

echo -e "${GREEN}[âœ“] Disk Created${RESET}"

# ============================================================
# DOWNLOAD ISO
# ============================================================

if [ ! -f "$ISO_PATH" ]; then

echo ""
echo -e "${BLUE}[*] Downloading ${OS_NAME} ISO...${RESET}"

wget -O "$ISO_PATH" "$ISO_URL"

echo -e "${GREEN}[âœ“] ISO Downloaded${RESET}"

else

echo -e "${GREEN}[âœ“] ISO Already Exists${RESET}"

fi

# ============================================================
# KEEP ALIVE
# ============================================================

cat > /tmp/keepalive.sh << EOF
#!/bin/bash
while true; do
curl -s http://localhost:${WEB_PORT} >/dev/null 2>&1
sleep 20
done
EOF

chmod +x /tmp/keepalive.sh

screen -dmS keepalive bash /tmp/keepalive.sh

# ============================================================
# WEB SERVER
# ============================================================

cat > /tmp/webserver.sh << EOF
#!/bin/bash
while true; do
echo -e "HTTP/1.1 200 OK\r\n\r\nVALKAS VPS ONLINE" | nc -l -p ${WEB_PORT} -q 1
done
EOF

chmod +x /tmp/webserver.sh

screen -dmS webserver bash /tmp/webserver.sh

# ============================================================
# START VM
# ============================================================

echo ""
echo -e "${BLUE}[*] Starting Virtual Machine...${RESET}"

screen -dmS "${VM_NAME}" qemu-system-x86_64 \
-enable-kvm \
-m "${RAM}" \
-smp "${CPU}" \
-hda "$VM_DISK" \
-cdrom "$ISO_PATH" \
-boot d \
-netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
-device virtio-net,netdev=net0 \
-vnc :1

sleep 5

echo -e "${GREEN}[âœ“] VM Started${RESET}"

# ============================================================
# FINAL INFO
# ============================================================

clear

echo -e "${GREEN}"
echo "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—"
echo "â•‘                VPS READY                          â•‘"
echo "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo -e "${RESET}"

echo ""
echo -e "${GREEN}${BOLD}TERMIUS LOGIN DETAILS${RESET}"
echo ""

echo -e "${CYAN}IP Address : ${WHITE}${HOST_IP}${RESET}"
echo -e "${CYAN}SSH Port   : ${WHITE}${SSH_PORT}${RESET}"
echo -e "${CYAN}Username   : ${WHITE}${VM_USER}${RESET}"
echo -e "${CYAN}Password   : ${WHITE}${VM_PASS}${RESET}"

echo ""
echo -e "${GREEN}${BOLD}VPS DETAILS${RESET}"
echo ""

echo -e "${CYAN}Hostname   : ${WHITE}${CUSTOM_HOST}${RESET}"
echo -e "${CYAN}VM Name    : ${WHITE}${VM_NAME}${RESET}"
echo -e "${CYAN}RAM        : ${WHITE}${RAM} MB${RESET}"
echo -e "${CYAN}CPU        : ${WHITE}${CPU} Cores${RESET}"
echo -e "${CYAN}Disk       : ${WHITE}${DISK} GB${RESET}"
echo -e "${CYAN}OS         : ${WHITE}${OS_NAME}${RESET}"

echo ""
echo -e "${CYAN}VNC        : ${WHITE}${HOST_IP}:${VNC_PORT}${RESET}"

echo ""
echo -e "${YELLOW}SSH Command:${RESET}"
echo -e "${WHITE}ssh ${VM_USER}@${HOST_IP} -p ${SSH_PORT}${RESET}"

echo ""
echo -e "${GREEN}KEEP ALIVE URL${RESET}"
echo -e "${WHITE}http://${HOST_IP}:${WEB_PORT}${RESET}"

echo ""
echo -e "${MAGENTA}Running Neofetch...${RESET}"
sleep 1
neofetch

echo ""
echo -e "${MAGENTA}Running Fastfetch...${RESET}"
sleep 1
fastfetch

echo ""
echo -e "${GREEN}[âœ“] Installation Completed${RESET}"
echo -e "${YELLOW}Made by Rajveer & Nissal${RESET}"
