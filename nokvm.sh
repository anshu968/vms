#!/bin/bash
# ============================================================
#   VPS VM INSTALLER (NO KVM) - by Rajveer
#   Supports: Ubuntu, Debian, Kali, Windows
#   Works on VPS without KVM/hardware virtualization
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

echo -e "${MAGENTA}"
echo "  ██████╗  █████╗      ██╗██╗   ██╗███████╗███████╗██████╗ "
echo "  ██╔══██╗██╔══██╗     ██║██║   ██║██╔════╝██╔════╝██╔══██╗"
echo "  ██████╔╝███████║     ██║██║   ██║█████╗  █████╗  ██████╔╝"
echo "  ██╔══██╗██╔══██║██   ██║╚██╗ ██╔╝██╔══╝  ██╔══╝  ██╔══██╗"
echo "  ██║  ██║██║  ██║╚█████╔╝ ╚████╔╝ ███████╗███████╗██║  ██║"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝   ╚═══╝  ╚══════╝╚══════╝╚═╝  ╚═╝"
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}       VM Installer (No-KVM) — Made by Rajveer${RESET}"
echo -e "${YELLOW}       ─────────────────────────────────────────${RESET}"
echo ""

# ─── Root Check ───────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[✗] Please run as root (sudo su)${RESET}"
  exit 1
fi

# ─── Dependencies ─────────────────────────────────────────
echo -e "${BLUE}[*] Installing dependencies...${RESET}"
apt-get update -y &>/dev/null
apt-get install -y qemu-system-x86 qemu-utils wget curl \
  sshpass openssh-server net-tools iptables \
  screen &>/dev/null
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
    VM_NAME="ubuntu-nokvm"
    DEFAULT_USER="ubuntu"
    ;;
  2)
    OS_NAME="Debian 12"
    ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
    ISO_FILE="debian-12.iso"
    VM_NAME="debian-nokvm"
    DEFAULT_USER="debian"
    ;;
  3)
    OS_NAME="Kali Linux 2024"
    ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"
    ISO_FILE="kali-2024.iso"
    VM_NAME="kali-nokvm"
    DEFAULT_USER="kali"
    ;;
  4)
    OS_NAME="Windows 10"
    ISO_URL="https://www.itechtics.com/?dl_id=173"
    ISO_FILE="windows10.iso"
    VM_NAME="win10-nokvm"
    DEFAULT_USER="Administrator"
    ;;
  5)
    OS_NAME="Windows 11"
    ISO_URL="https://www.itechtics.com/?dl_id=233"
    ISO_FILE="windows11.iso"
    VM_NAME="win11-nokvm"
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
mkdir -p /opt/rajveer-vms
DISK_IMG="/opt/rajveer-vms/${VM_NAME}.qcow2"

echo ""
echo -e "${BLUE}[*] Creating ${DISK}GB virtual disk...${RESET}"
qemu-img create -f qcow2 "$DISK_IMG" "${DISK}G" &>/dev/null
echo -e "${GREEN}[✓] Disk created: ${DISK_IMG}${RESET}"

# ─── ISO Download ─────────────────────────────────────────
ISO_PATH="/opt/rajveer-vms/${ISO_FILE}"

if [ ! -f "$ISO_PATH" ]; then
  echo -e "${BLUE}[*] Downloading ${OS_NAME} ISO...${RESET}"
  wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
  echo -e "${GREEN}[✓] ISO downloaded${RESET}"
else
  echo -e "${GREEN}[✓] ISO already cached, skipping download${RESET}"
fi

# ─── Get Host IP ──────────────────────────────────────────
HOST_IP=$(hostname -I | awk '{print $1}')

# ─── Launch VM (No KVM — software emulation) ──────────────
echo ""
echo -e "${BLUE}[*] Launching VM (QEMU software emulation, no KVM)...${RESET}"
echo -e "${YELLOW}[!] No-KVM mode is slower than KVM. This is normal.${RESET}"

screen -dmS "${VM_NAME}" qemu-system-x86_64 \
  -m "${RAM}" \
  -smp "${CPUS}" \
  -hda "${DISK_IMG}" \
  -cdrom "${ISO_PATH}" \
  -boot d \
  -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
  -device virtio-net,netdev=net0 \
  -nographic \
  -serial mon:stdio

echo -e "${GREEN}[✓] VM launched in background screen session: ${VM_NAME}${RESET}"

# ─── Summary Box ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║      🖥️  VM READY (NO-KVM) — TERMIUS CONNECTION     ║${RESET}"
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
echo -e "${WHITE}Useful commands:${RESET}"
echo -e "  ${CYAN}screen -r ${VM_NAME}${RESET}   ← attach to VM console"
echo -e "  ${CYAN}screen -ls${RESET}             ← list all VMs"
echo -e "  ${CYAN}screen -X -S ${VM_NAME} quit${RESET}  ← stop VM"
echo ""
echo -e "${YELLOW}[!] SSH will be available after OS installation completes inside the VM.${RESET}"
echo ""

