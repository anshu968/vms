#!/bin/bash
# ============================================================
#   VPS VM INSTALLER - by Rajveer
#   Supports: Ubuntu, Debian, Kali, Windows
#   KVM Accelerated Version
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

clear

echo -e "${CYAN}"
echo "  ██████╗  █████╗      ██╗██╗   ██╗███████╗███████╗██████╗ "
echo "  ██╔══██╗██╔══██╗     ██║██║   ██║██╔════╝██╔════╝██╔══██╗"
echo "  ██████╔╝███████║     ██║██║   ██║█████╗  █████╗  ██████╔╝"
echo "  ██╔══██╗██╔══██║██   ██║╚██╗ ██╔╝██╔══╝  ██╔══╝  ██╔══██╗"
echo "  ██║  ██║██║  ██║╚█████╔╝ ╚████╔╝ ███████╗███████╗██║  ██║"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝   ╚═══╝  ╚══════╝╚══════╝╚═╝  ╚═╝"
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}          VM Installer — Made by Rajveer${RESET}"
echo -e "${YELLOW}          ─────────────────────────────────${RESET}"
echo ""

# ─── Root Check ───────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[✗] Please run as root (sudo su)${RESET}"
  exit 1
fi

# ─── KVM Check ────────────────────────────────────────────
if ! grep -q -E 'vmx|svm' /proc/cpuinfo; then
  echo -e "${YELLOW}[!] KVM not supported. Use nokvm.sh instead.${RESET}"
  exit 1
fi

# ─── Dependency Install ───────────────────────────────────
echo -e "${BLUE}[*] Installing dependencies...${RESET}"
apt-get update -y &>/dev/null
apt-get install -y qemu-kvm qemu-utils libvirt-daemon-system \
  libvirt-clients bridge-utils virt-manager wget curl \
  sshpass openssh-server net-tools &>/dev/null
echo -e "${GREEN}[✓] Dependencies installed${RESET}"

# ─── OS Selection ─────────────────────────────────────────
echo ""
echo -e "${WHITE}${BOLD}Select OS to install:${RESET}"
echo -e "  ${CYAN}[1]${RESET} Ubuntu 22.04 LTS"
echo -e "  ${CYAN}[2]${RESET} Debian 12"
echo -e "  ${CYAN}[3]${RESET} Kali Linux 2024"
echo -e "  ${CYAN}[4]${RESET} Windows 10"
echo -e "  ${CYAN}[5]${RESET} Windows 11"
echo ""
read -p "$(echo -e ${YELLOW}"Enter choice [1-5]: "${RESET})" OS_CHOICE

case $OS_CHOICE in
  1)
    OS_NAME="Ubuntu 22.04"
    ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"
    ISO_FILE="ubuntu-22.04.iso"
    VM_NAME="ubuntu-vm"
    DEFAULT_USER="ubuntu"
    ;;
  2)
    OS_NAME="Debian 12"
    ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
    ISO_FILE="debian-12.iso"
    VM_NAME="debian-vm"
    DEFAULT_USER="debian"
    ;;
  3)
    OS_NAME="Kali Linux 2024"
    ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"
    ISO_FILE="kali-2024.iso"
    VM_NAME="kali-vm"
    DEFAULT_USER="kali"
    ;;
  4)
    OS_NAME="Windows 10"
    ISO_URL="https://www.itechtics.com/?dl_id=173"
    ISO_FILE="windows10.iso"
    VM_NAME="win10-vm"
    DEFAULT_USER="Administrator"
    ;;
  5)
    OS_NAME="Windows 11"
    ISO_URL="https://www.itechtics.com/?dl_id=233"
    ISO_FILE="windows11.iso"
    VM_NAME="win11-vm"
    DEFAULT_USER="Administrator"
    ;;
  *)
    echo -e "${RED}[✗] Invalid choice. Exiting.${RESET}"
    exit 1
    ;;
esac

# ─── VM Config ────────────────────────────────────────────
echo ""
echo -e "${WHITE}${BOLD}VM Configuration:${RESET}"
read -p "$(echo -e ${YELLOW}"RAM in MB [default: 2048]: "${RESET})" RAM
RAM=${RAM:-2048}

read -p "$(echo -e ${YELLOW}"Disk size in GB [default: 20]: "${RESET})" DISK
DISK=${DISK:-20}

read -p "$(echo -e ${YELLOW}"CPU cores [default: 2]: "${RESET})" CPUS
CPUS=${CPUS:-2}

read -p "$(echo -e ${YELLOW}"SSH Port for VM [default: 2222]: "${RESET})" SSH_PORT
SSH_PORT=${SSH_PORT:-2222}

# ─── Credentials ──────────────────────────────────────────
VM_PASS="Rajveer@$(shuf -i 1000-9999 -n 1)"
VM_USER="${DEFAULT_USER}"

# ─── Disk Image ───────────────────────────────────────────
DISK_IMG="/var/lib/libvirt/images/${VM_NAME}.qcow2"
echo ""
echo -e "${BLUE}[*] Creating ${DISK}GB virtual disk...${RESET}"
qemu-img create -f qcow2 "$DISK_IMG" "${DISK}G" &>/dev/null
echo -e "${GREEN}[✓] Disk created: ${DISK_IMG}${RESET}"

# ─── ISO Download ─────────────────────────────────────────
ISO_PATH="/var/lib/libvirt/boot/${ISO_FILE}"
mkdir -p /var/lib/libvirt/boot

if [ ! -f "$ISO_PATH" ]; then
  echo -e "${BLUE}[*] Downloading ${OS_NAME} ISO...${RESET}"
  wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
  echo -e "${GREEN}[✓] ISO downloaded${RESET}"
else
  echo -e "${GREEN}[✓] ISO already exists, skipping download${RESET}"
fi

# ─── Get Host IP ──────────────────────────────────────────
HOST_IP=$(hostname -I | awk '{print $1}')

# ─── Launch VM ────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*] Launching VM with KVM...${RESET}"

virt-install \
  --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$CPUS" \
  --disk path="$DISK_IMG",format=qcow2 \
  --cdrom "$ISO_PATH" \
  --os-variant detect=on \
  --network network=default \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --boot cdrom,hd &>/dev/null

sleep 5

# ─── Enable SSH Forwarding ────────────────────────────────
echo -e "${BLUE}[*] Setting up SSH port forwarding (host:${SSH_PORT} → VM:22)...${RESET}"
iptables -t nat -A PREROUTING -p tcp --dport "$SSH_PORT" -j DNAT --to-destination 192.168.122.2:22 &>/dev/null
iptables -A FORWARD -p tcp -d 192.168.122.2 --dport 22 -j ACCEPT &>/dev/null

# ─── Summary Box ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║        🖥️  VM READY — TERMIUS CONNECTION INFO        ║${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}VM Name   :${RESET} ${CYAN}${VM_NAME}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}OS        :${RESET} ${CYAN}${OS_NAME}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}RAM       :${RESET} ${CYAN}${RAM} MB${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Disk      :${RESET} ${CYAN}${DISK} GB${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}CPUs      :${RESET} ${CYAN}${CPUS}${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${GREEN}${BOLD}── Connect via Termius / SSH ──${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}IP / Host :${RESET} ${GREEN}${HOST_IP}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Port      :${RESET} ${GREEN}${SSH_PORT}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Username  :${RESET} ${GREEN}${VM_USER}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Password  :${RESET} ${GREEN}${VM_PASS}${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${MAGENTA}Made by Rajveer${RESET}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${WHITE}Quick SSH command:${RESET}"
echo -e "${CYAN}  ssh ${VM_USER}@${HOST_IP} -p ${SSH_PORT}${RESET}"
echo ""
echo -e "${WHITE}Or in Termius:${RESET}"
echo -e "  Host: ${GREEN}${HOST_IP}${RESET}  |  Port: ${GREEN}${SSH_PORT}${RESET}  |  User: ${GREEN}${VM_USER}${RESET}  |  Pass: ${GREEN}${VM_PASS}${RESET}"
echo ""
echo -e "${YELLOW}[!] Note: VM is installing the OS. SSH will be available after install completes.${RESET}"
echo -e "${YELLOW}    Use 'virsh console ${VM_NAME}' to watch progress.${RESET}"
echo ""
