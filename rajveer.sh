#!/bin/bash

# ==========================================================
# RAJVEER VMS — Ultimate VPS + VM Manager
# Made by Rajveer
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

LOG_FILE="/var/log/rajveer-vms.log"
VM_DIR="/opt/rajveer-vms"
CONFIG_DIR="$VM_DIR/configs"

mkdir -p "$VM_DIR"
mkdir -p "$CONFIG_DIR"

clear

# ==========================================================
# UI
# ==========================================================

echo -e "${CYAN}"
echo " ██████╗  █████╗      ██╗██╗   ██╗███████╗███████╗██████╗ "
echo " ██╔══██╗██╔══██╗     ██║██║   ██║██╔════╝██╔════╝██╔══██╗"
echo " ██████╔╝███████║     ██║██║   ██║█████╗  █████╗  ██████╔╝"
echo " ██╔══██╗██╔══██║██   ██║╚██╗ ██╔╝██╔══╝  ██╔══╝  ██╔══██╗"
echo " ██║  ██║██║  ██║╚█████╔╝ ╚████╔╝ ███████╗███████╗██║  ██║"
echo " ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝   ╚═══╝  ╚══════╝╚══════╝╚═╝  ╚═╝"
echo -e "${RESET}"

echo -e "${WHITE}${BOLD}Ultimate VPS + VM Manager${RESET}"
echo -e "${MAGENTA}Made by Rajveer${RESET}"
echo ""

# ==========================================================
# ROOT CHECK
# ==========================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Running with sudo...${RESET}"
    exec sudo bash "$0" "$@"
    exit
fi

# ==========================================================
# LOGGING
# ==========================================================

log() {
    echo "[$(date)] $1" >> "$LOG_FILE"
}

# ==========================================================
# PUBLIC IP
# ==========================================================

HOST_IP=$(curl -s ifconfig.me)

# ==========================================================
# KVM CHECK
# ==========================================================

if grep -q -E 'vmx|svm' /proc/cpuinfo; then
    KVM_OK=true
    KVM_MODE="KVM"
else
    KVM_OK=false
    KVM_MODE="No-KVM"
fi

echo -e "${BLUE}[*] Public IP : ${GREEN}${HOST_IP}${RESET}"
echo -e "${BLUE}[*] Mode      : ${GREEN}${KVM_MODE}${RESET}"
echo ""

# ==========================================================
# SPINNER
# ==========================================================

spinner() {
    local pid=$1
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}[%c] Installing...${RESET}" "${spin:$i:1}"
        sleep .1
    done

    printf "\r${GREEN}[✓] Done                     ${RESET}\n"
}

# ==========================================================
# INSTALL DEPENDENCIES
# ==========================================================

install_deps() {

    echo -e "${WHITE}${BOLD}Installing dependencies...${RESET}"

    apt update -y >/dev/null 2>&1 &
    spinner $!

    apt install -y \
    curl wget git screen tmux unzip nano htop \
    net-tools netcat-openbsd openssh-server \
    sshpass socat qemu-utils qemu-system-x86 \
    qemu-kvm virtinst bridge-utils libvirt-daemon-system \
    libvirt-clients aria2 >/dev/null 2>&1 &

    spinner $!

    systemctl enable libvirtd >/dev/null 2>&1
    systemctl start libvirtd >/dev/null 2>&1

    echo -e "${GREEN}[✓] Dependencies installed${RESET}"
}

# ==========================================================
# KEEPALIVE
# ==========================================================

keepalive_menu() {

    echo ""
    echo -e "${CYAN}[1] Ping Loop"
    echo -e "[2] Web Server"
    echo -e "[3] Back${RESET}"
    echo ""

    read -p "Choice: " KA

    case $KA in

        1)

cat > /tmp/rjv_ping.sh << 'EOF'
#!/bin/bash
while true; do
curl -s http://localhost >/dev/null 2>&1
echo "$(date) ping" >> /tmp/rjv_keepalive.log
sleep 30
done
EOF

chmod +x /tmp/rjv_ping.sh

screen -dmS rjv_ping bash /tmp/rjv_ping.sh

echo -e "${GREEN}[✓] Ping loop active${RESET}"

        ;;

        2)

read -p "Port: " PORT

cat > /tmp/rjv_web.sh << EOF
#!/bin/bash
while true; do
echo -e "HTTP/1.1 200 OK\r\n\r\nRajveer VMS" | nc -l $PORT
done
EOF

chmod +x /tmp/rjv_web.sh

screen -dmS rjv_web bash /tmp/rjv_web.sh

echo -e "${GREEN}[✓] Web server active${RESET}"
echo -e "${CYAN}http://${HOST_IP}:${PORT}${RESET}"

        ;;

    esac
}

# ==========================================================
# CREATE VM
# ==========================================================

create_vm() {

    echo ""
    echo -e "${WHITE}${BOLD}Select OS${RESET}"
    echo ""

    echo "[1] Ubuntu 22.04"
    echo "[2] Debian 12"
    echo "[3] Kali Linux"
    echo "[4] Windows 10"
    echo "[5] Windows 11"
    echo ""

    read -p "Choice: " OS

    case $OS in

        1)
            OS_NAME="Ubuntu"
            ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"
            ISO_FILE="ubuntu.iso"
        ;;

        2)
            OS_NAME="Debian"
            ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
            ISO_FILE="debian.iso"
        ;;

        3)
            OS_NAME="Kali"
            ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"
            ISO_FILE="kali.iso"
        ;;

        4)
            OS_NAME="Windows10"
            ISO_URL="https://software.download.prss.microsoft.com/dbazure/Win10_22H2_English_x64v1.iso"
            ISO_FILE="win10.iso"
        ;;

        5)
            OS_NAME="Windows11"
            ISO_URL="https://software.download.prss.microsoft.com/dbazure/Win11_23H2_English_x64v2.iso"
            ISO_FILE="win11.iso"
        ;;

    esac

    echo ""

    read -p "VM Name: " VM_NAME
    read -p "Hostname (example: rajveer-vps): " VM_HOSTNAME
    read -p "Username (example: root): " VM_USER
    read -p "Password: " VM_PASS
    read -p "RAM MB: " RAM
    read -p "Disk GB: " DISK
    read -p "CPU Cores: " CPU
    read -p "SSH Port: " SSH_PORT

    FREE_RAM=$(free -m | awk '/Mem:/ {print $7}')

    if [ "$RAM" -gt "$FREE_RAM" ]; then
        echo -e "${RED}[✗] Not enough RAM${RESET}"
        return
    fi

    DISK_IMG="$VM_DIR/${VM_NAME}.qcow2"
    ISO_PATH="$VM_DIR/${ISO_FILE}"

    echo -e "${BLUE}[*] Creating disk...${RESET}"

    qemu-img create -f qcow2 "$DISK_IMG" "${DISK}G" >/dev/null

    echo -e "${GREEN}[✓] Disk created${RESET}"

    if [ ! -f "$ISO_PATH" ]; then

        echo -e "${BLUE}[*] Downloading ISO...${RESET}"

        aria2c -x 16 -s 16 -o "$ISO_FILE" -d "$VM_DIR" "$ISO_URL"

    fi

    echo -e "${GREEN}[✓] ISO Ready${RESET}"

    if [ "$KVM_OK" = true ]; then

        virt-install \
        --name "$VM_NAME" \
        --ram "$RAM" \
        --vcpus "$CPU" \
        --disk path="$DISK_IMG",format=qcow2 \
        --cdrom "$ISO_PATH" \
        --network network=default \
        --graphics vnc,listen=0.0.0.0 \
        --noautoconsole &

        virsh autostart "$VM_NAME"

    else

        screen -dmS "$VM_NAME" qemu-system-x86_64 \
        -m "$RAM" \
        -smp "$CPU" \
        -hda "$DISK_IMG" \
        -cdrom "$ISO_PATH" \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
        -device virtio-net,netdev=net0 \
        -nographic

    fi

# ==========================================================
# SAVE CONFIG
# ==========================================================

cat > "$CONFIG_DIR/${VM_NAME}.conf" << EOF
NAME=${VM_NAME}
HOSTNAME=${VM_HOSTNAME}
USERNAME=${VM_USER}
PASSWORD=${VM_PASS}
RAM=${RAM}
DISK=${DISK}
CPU=${CPU}
PORT=${SSH_PORT}
OS=${OS_NAME}
EOF

log "VM Created: $VM_NAME"

# ==========================================================
# FINAL OUTPUT
# ==========================================================

echo ""

echo -e "${YELLOW}╔════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║           🖥️ VM CONNECTION INFO            ║${RESET}"
echo -e "${YELLOW}╠════════════════════════════════════════════╣${RESET}"

echo -e "${YELLOW}║${RESET} ${WHITE}VM Name   :${RESET} ${GREEN}${VM_NAME}${RESET}"
echo -e "${YELLOW}║${RESET} ${WHITE}Hostname  :${RESET} ${GREEN}${VM_HOSTNAME}${RESET}"
echo -e "${YELLOW}║${RESET} ${WHITE}Username  :${RESET} ${GREEN}${VM_USER}${RESET}"
echo -e "${YELLOW}║${RESET} ${WHITE}Password  :${RESET} ${GREEN}${VM_PASS}${RESET}"
echo -e "${YELLOW}║${RESET} ${WHITE}IP        :${RESET} ${GREEN}${HOST_IP}${RESET}"
echo -e "${YELLOW}║${RESET} ${WHITE}Port      :${RESET} ${GREEN}${SSH_PORT}${RESET}"

echo -e "${YELLOW}╠════════════════════════════════════════════╣${RESET}"

echo -e "${YELLOW}║${RESET} ${CYAN}SSH Command:${RESET}"
echo -e "${YELLOW}║${RESET} ssh ${VM_USER}@${HOST_IP} -p ${SSH_PORT}"

echo -e "${YELLOW}╠════════════════════════════════════════════╣${RESET}"

echo -e "${YELLOW}║${RESET} ${MAGENTA}Hostname Preview:${RESET}"
echo -e "${YELLOW}║${RESET} ${CYAN}${VM_USER}@${VM_HOSTNAME}${RESET}"

echo -e "${YELLOW}╚════════════════════════════════════════════╝${RESET}"

echo ""
echo -e "${GREEN}[✓] VM Successfully Created${RESET}"
}

# ==========================================================
# MANAGE VMS
# ==========================================================

manage_vm() {

    echo ""
    echo "[1] List VMs"
    echo "[2] Start VM"
    echo "[3] Stop VM"
    echo "[4] Delete VM"
    echo "[5] Back"
    echo ""

    read -p "Choice: " VM_M

    case $VM_M in

        1)
            virsh list --all
        ;;

        2)
            read -p "VM Name: " VM
            virsh start "$VM"
            echo -e "${GREEN}[✓] VM Started${RESET}"
        ;;

        3)
            read -p "VM Name: " VM
            virsh shutdown "$VM"
            echo -e "${GREEN}[✓] VM Stopped${RESET}"
        ;;

        4)
            read -p "VM Name: " VM

            virsh destroy "$VM" >/dev/null 2>&1
            virsh undefine "$VM" >/dev/null 2>&1

            rm -f "$VM_DIR/${VM}.qcow2"
            rm -f "$CONFIG_DIR/${VM}.conf"

            echo -e "${GREEN}[✓] VM Deleted${RESET}"
        ;;

    esac
}

# ==========================================================
# SYSTEM INFO
# ==========================================================

system_info() {

    clear

    echo -e "${WHITE}${BOLD}System Information${RESET}"
    echo ""

    echo -e "${CYAN}Hostname:${RESET} $(hostname)"
    echo -e "${CYAN}IP:${RESET} $HOST_IP"

    echo ""
    free -h

    echo ""
    df -h /

    echo ""
}

# ==========================================================
# START
# ==========================================================

install_deps

while true; do

    echo ""
    echo -e "${WHITE}${BOLD}Main Menu${RESET}"
    echo ""

    echo -e "${CYAN}[1]${RESET} Create VM"
    echo -e "${CYAN}[2]${RESET} Manage VMs"
    echo -e "${CYAN}[3]${RESET} KeepAlive"
    echo -e "${CYAN}[4]${RESET} System Info"
    echo -e "${CYAN}[5]${RESET} Exit"
    echo ""

    read -p "Select: " MENU

    case $MENU in

        1)
            create_vm
        ;;

        2)
            manage_vm
        ;;

        3)
            keepalive_menu
        ;;

        4)
            system_info
        ;;

        5)
            echo -e "${YELLOW}Bye!${RESET}"
            exit 0
        ;;

    esac

done
