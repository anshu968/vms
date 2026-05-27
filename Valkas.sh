#!/bin/bash
# ============================================================
#   RAJVEER VMS — All-in-One Script
#   bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/rajveer.sh)
#   Made by Rajveer
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
echo -e "${WHITE}${BOLD}           All-in-One VM Tool — Made by Rajveer${RESET}"
echo -e "${YELLOW}           github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}           ────────────────────────────────────${RESET}"
echo ""

# ─── Root Check ───────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[!] Not root. Trying sudo...${RESET}"
  exec sudo bash "$0" "$@"
  exit
fi

# ─── Detect Platform ──────────────────────────────────────
if [ -n "$REPL_ID" ] || [ -d "/home/runner" ]; then
  PLATFORM="Replit"
elif [ -n "$CODESPACE_NAME" ] || [ -d "/workspaces" ]; then
  PLATFORM="GitHub Codespaces"
elif [ -d "/sandbox" ] || [ -n "$CSB_CONTAINER" ]; then
  PLATFORM="CodeSandbox"
else
  PLATFORM="Linux VPS"
fi

echo -e "${BLUE}[*] Platform : ${GREEN}${PLATFORM}${RESET}"

# ─── KVM Check ────────────────────────────────────────────
if grep -q -E 'vmx|svm' /proc/cpuinfo 2>/dev/null; then
  KVM_OK=true
  echo -e "${BLUE}[*] KVM      : ${GREEN}Supported ✓${RESET}"
else
  KVM_OK=false
  echo -e "${BLUE}[*] KVM      : ${YELLOW}Not supported — No-KVM mode${RESET}"
fi
echo ""

# ══════════════════════════════════════════════════════════
#  STEP 1 — AUTO SETUP
# ══════════════════════════════════════════════════════════
echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}${BOLD}║      STEP 1 — Installing Dependencies        ║${RESET}"
echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

apt-get update -y &>/dev/null

install_pkg() {
  local NAME=$1
  local PKG=${2:-$1}
  printf "  ${CYAN}%-24s${RESET}" "$NAME"
  if command -v "$NAME" &>/dev/null; then
    echo -e "${GREEN}already installed ✓${RESET}"
    return
  fi
  apt-get install -y "$PKG" &>/dev/null
  if command -v "$NAME" &>/dev/null; then
    echo -e "${GREEN}installed ✓${RESET}"
  else
    echo -e "${YELLOW}skipped${RESET}"
  fi
}

install_pkg curl
install_pkg wget
install_pkg git
install_pkg screen
install_pkg tmux
install_pkg unzip
install_pkg nano
install_pkg htop
install_pkg net-tools
install_pkg netcat nc
install_pkg openssh-server ssh
install_pkg sshpass
install_pkg socat
install_pkg qemu-img qemu-utils
install_pkg qemu-system-x86_64 qemu-system-x86

if [ "$KVM_OK" = true ]; then
  apt-get install -y qemu-kvm libvirt-daemon-system \
    libvirt-clients bridge-utils virtinst &>/dev/null
  echo -e "  ${CYAN}kvm/libvirt             ${GREEN}installed ✓${RESET}"
fi

echo ""
echo -e "${GREEN}[✓] All dependencies ready!${RESET}"
echo ""

# ══════════════════════════════════════════════════════════
#  STEP 2 — MAIN MENU
# ══════════════════════════════════════════════════════════
echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}${BOLD}║              STEP 2 — What to do?            ║${RESET}"
echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}[1]${RESET} Install VM only"
echo -e "  ${CYAN}[2]${RESET} Keep-Alive only"
echo -e "  ${CYAN}[3]${RESET} ${GREEN}Install VM + Keep-Alive ← recommended${RESET}"
echo -e "  ${CYAN}[4]${RESET} Exit"
echo ""

while true; do
  read -p "$(echo -e ${YELLOW}"Enter choice [1-4]: "${RESET})" MENU
  [[ "$MENU" =~ ^[1-4]$ ]] && break
  echo -e "${RED}[✗] Please enter 1, 2, 3 or 4${RESET}"
done

# ══════════════════════════════════════════════════════════
#  KEEP-ALIVE FUNCTION
# ══════════════════════════════════════════════════════════
do_keepalive() {
  echo ""
  echo -e "${WHITE}${BOLD}── Keep-Alive Method ──${RESET}"
  echo -e "  ${CYAN}[1]${RESET} Ping loop"
  echo -e "  ${CYAN}[2]${RESET} CPU heartbeat"
  echo -e "  ${CYAN}[3]${RESET} ${GREEN}Both ← recommended${RESET}"
  echo -e "  ${CYAN}[4]${RESET} Web server (use with UptimeRobot)"
  echo ""

  while true; do
    read -p "$(echo -e ${YELLOW}"Keep-alive method [1-4]: "${RESET})" KA
    [[ "$KA" =~ ^[1-4]$ ]] && break
    echo -e "${RED}[✗] Please enter 1, 2, 3 or 4${RESET}"
  done

  cat > /tmp/rjv_ping.sh << 'PING'
#!/bin/bash
while true; do
  curl -s http://localhost:8080 &>/dev/null || true
  echo "$(date) - Rajveer ping" >> /tmp/rjv_keepalive.log
  tail -100 /tmp/rjv_keepalive.log > /tmp/rjv_ka.tmp && mv /tmp/rjv_ka.tmp /tmp/rjv_keepalive.log
  sleep 20
done
PING

  cat > /tmp/rjv_cpu.sh << 'CPU'
#!/bin/bash
while true; do
  for i in $(seq 1 1000); do echo "$i" > /dev/null; done
  echo "$(date) - Rajveer heartbeat" >> /tmp/rjv_keepalive.log
  sleep 30
done
CPU

  chmod +x /tmp/rjv_ping.sh /tmp/rjv_cpu.sh

  case $KA in
    1) screen -dmS rjv_ping bash /tmp/rjv_ping.sh
       echo -e "${GREEN}[✓] Ping loop active${RESET}" ;;
    2) screen -dmS rjv_cpu bash /tmp/rjv_cpu.sh
       echo -e "${GREEN}[✓] CPU heartbeat active${RESET}" ;;
    3) screen -dmS rjv_ping bash /tmp/rjv_ping.sh
       screen -dmS rjv_cpu bash /tmp/rjv_cpu.sh
       echo -e "${GREEN}[✓] Ping + CPU heartbeat active${RESET}" ;;
    4)
       while true; do
         read -p "$(echo -e ${YELLOW}"Web server port (e.g. 8080): "${RESET})" WEB_PORT
         [[ "$WEB_PORT" =~ ^[0-9]+$ ]] && break
         echo -e "${RED}[✗] Enter a valid port number${RESET}"
       done
       cat > /tmp/rjv_web.sh << WEBEOF
#!/bin/bash
while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nRajveer KeepAlive - \$(date)" | nc -l -p ${WEB_PORT} -q 1 &>/dev/null || true
  sleep 1
done
WEBEOF
       chmod +x /tmp/rjv_web.sh
       screen -dmS rjv_web bash /tmp/rjv_web.sh
       screen -dmS rjv_ping bash /tmp/rjv_ping.sh
       KA_HOST=$(hostname -I | awk '{print $1}')
       echo -e "${GREEN}[✓] Web server active on port ${WEB_PORT}${RESET}"
       echo -e "${WHITE}Add to UptimeRobot: ${CYAN}http://${KA_HOST}:${WEB_PORT}${RESET}" ;;
  esac

  # Watchdog
  cat > /tmp/rjv_watchdog.sh << 'WATCH'
#!/bin/bash
while true; do
  for s in rjv_ping rjv_cpu rjv_web; do
    if ! screen -list | grep -q "$s"; then
      [ -f "/tmp/${s}.sh" ] && screen -dmS "$s" bash "/tmp/${s}.sh"
    fi
  done
  sleep 60
done
WATCH
  chmod +x /tmp/rjv_watchdog.sh
  screen -dmS rjv_watchdog bash /tmp/rjv_watchdog.sh
  echo -e "${GREEN}[✓] Watchdog active (auto-restarts sessions)${RESET}"
}

# ══════════════════════════════════════════════════════════
#  VM INSTALL FUNCTION
# ══════════════════════════════════════════════════════════
do_vm_install() {
  echo ""
  echo -e "${WHITE}${BOLD}── Select OS ──${RESET}"
  echo -e "  ${CYAN}[1]${RESET} Ubuntu 22.04 LTS"
  echo -e "  ${CYAN}[2]${RESET} Debian 12"
  echo -e "  ${CYAN}[3]${RESET} Kali Linux 2024"
  echo -e "  ${CYAN}[4]${RESET} Windows 10"
  echo -e "  ${CYAN}[5]${RESET} Windows 11"
  echo ""

  while true; do
    read -p "$(echo -e ${YELLOW}"Select OS [1-5]: "${RESET})" OS_CHOICE
    [[ "$OS_CHOICE" =~ ^[1-5]$ ]] && break
    echo -e "${RED}[✗] Please enter 1 to 5${RESET}"
  done

  case $OS_CHOICE in
    1) OS_NAME="Ubuntu 22.04"
       ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"
       ISO_FILE="ubuntu-22.04.iso"; VM_NAME_DEF="ubuntu-vm"; DEFAULT_USER="ubuntu" ;;
    2) OS_NAME="Debian 12"
       ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
       ISO_FILE="debian-12.iso"; VM_NAME_DEF="debian-vm"; DEFAULT_USER="debian" ;;
    3) OS_NAME="Kali Linux 2024"
       ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"
       ISO_FILE="kali-2024.iso"; VM_NAME_DEF="kali-vm"; DEFAULT_USER="kali" ;;
    4) OS_NAME="Windows 10"
       ISO_URL="https://www.itechtics.com/?dl_id=173"
       ISO_FILE="windows10.iso"; VM_NAME_DEF="win10-vm"; DEFAULT_USER="Administrator" ;;
    5) OS_NAME="Windows 11"
       ISO_URL="https://www.itechtics.com/?dl_id=233"
       ISO_FILE="windows11.iso"; VM_NAME_DEF="win11-vm"; DEFAULT_USER="Administrator" ;;
  esac

  echo ""
  echo -e "${WHITE}${BOLD}── VM Configuration (fill every field) ──${RESET}"
  echo ""

  # VM Name
  while true; do
    read -p "$(echo -e ${YELLOW}"VM Name (e.g. my-vps): "${RESET})" VM_NAME
    [[ -n "$VM_NAME" ]] && break
    echo -e "${RED}[✗] VM name cannot be empty${RESET}"
  done

  # Username
  while true; do
    read -p "$(echo -e ${YELLOW}"Username (e.g. rajveer): "${RESET})" VM_USER
    [[ -n "$VM_USER" ]] && break
    echo -e "${RED}[✗] Username cannot be empty${RESET}"
  done

  # Password
  while true; do
    read -p "$(echo -e ${YELLOW}"Password (e.g. MyPass@123): "${RESET})" VM_PASS
    [[ -n "$VM_PASS" ]] && break
    echo -e "${RED}[✗] Password cannot be empty${RESET}"
  done

  # RAM
  while true; do
    read -p "$(echo -e ${YELLOW}"RAM in MB (e.g. 2048 = 2GB): "${RESET})" RAM
    [[ "$RAM" =~ ^[0-9]+$ ]] && [ "$RAM" -ge 256 ] && break
    echo -e "${RED}[✗] Enter a valid RAM size (minimum 256)${RESET}"
  done

  # Disk
  while true; do
    read -p "$(echo -e ${YELLOW}"Disk size in GB (e.g. 20): "${RESET})" DISK
    [[ "$DISK" =~ ^[0-9]+$ ]] && [ "$DISK" -ge 5 ] && break
    echo -e "${RED}[✗] Enter a valid disk size (minimum 5)${RESET}"
  done

  # CPUs
  while true; do
    read -p "$(echo -e ${YELLOW}"CPU cores (e.g. 2): "${RESET})" CPUS
    [[ "$CPUS" =~ ^[0-9]+$ ]] && [ "$CPUS" -ge 1 ] && break
    echo -e "${RED}[✗] Enter a valid CPU count (minimum 1)${RESET}"
  done

  # SSH Port
  while true; do
    read -p "$(echo -e ${YELLOW}"SSH Port (e.g. 2222): "${RESET})" SSH_PORT
    [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ] && break
    echo -e "${RED}[✗] Enter a valid port (1-65535)${RESET}"
  done

  HOST_IP=$(hostname -I | awk '{print $1}')
  VM_MODE=$( [ "$KVM_OK" = true ] && echo "KVM" || echo "No-KVM" )

  mkdir -p /opt/rajveer-vms
  DISK_IMG="/opt/rajveer-vms/${VM_NAME}.qcow2"
  ISO_PATH="/opt/rajveer-vms/${ISO_FILE}"

  echo ""
  echo -e "${BLUE}[*] Creating ${DISK}GB disk image...${RESET}"
  qemu-img create -f qcow2 "$DISK_IMG" "${DISK}G" &>/dev/null
  echo -e "${GREEN}[✓] Disk ready${RESET}"

  if [ ! -f "$ISO_PATH" ]; then
    echo -e "${BLUE}[*] Downloading ${OS_NAME} ISO...${RESET}"
    wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
    echo -e "${GREEN}[✓] ISO downloaded${RESET}"
  else
    echo -e "${GREEN}[✓] ISO cached — skipping download${RESET}"
  fi

  echo ""
  echo -e "${BLUE}[*] Launching VM (${VM_MODE})...${RESET}"

  if [ "$KVM_OK" = true ]; then
    virt-install \
      --name "$VM_NAME" --ram "$RAM" --vcpus "$CPUS" \
      --disk path="$DISK_IMG",format=qcow2 \
      --cdrom "$ISO_PATH" --os-variant detect=on \
      --network network=default \
      --graphics vnc,listen=0.0.0.0 \
      --noautoconsole --boot cdrom,hd &>/dev/null
    iptables -t nat -A PREROUTING -p tcp --dport "$SSH_PORT" \
      -j DNAT --to-destination 192.168.122.2:22 &>/dev/null
  else
    screen -dmS "${VM_NAME}" qemu-system-x86_64 \
      -m "${RAM}" -smp "${CPUS}" \
      -hda "${DISK_IMG}" -cdrom "${ISO_PATH}" \
      -boot d \
      -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
      -device virtio-net,netdev=net0 \
      -nographic -serial mon:stdio
  fi

  echo -e "${GREEN}[✓] VM launched successfully!${RESET}"

  # Save creds to file
  cat > /tmp/rjv_creds.txt << CREDS
VM_NAME="${VM_NAME}"
OS_NAME="${OS_NAME}"
RAM="${RAM}"
DISK="${DISK}"
CPUS="${CPUS}"
VM_MODE="${VM_MODE}"
HOST_IP="${HOST_IP}"
SSH_PORT="${SSH_PORT}"
VM_USER="${VM_USER}"
VM_PASS="${VM_PASS}"
CREDS
}

# ══════════════════════════════════════════════════════════
#  RUN MENU CHOICE
# ══════════════════════════════════════════════════════════
case $MENU in
  1) do_vm_install ;;
  2) do_keepalive ;;
  3) do_vm_install; do_keepalive ;;
  4) echo -e "${YELLOW}Bye!${RESET}"; exit 0 ;;
esac

# ══════════════════════════════════════════════════════════
#  FINAL SUMMARY — Always shown at the end
# ══════════════════════════════════════════════════════════
echo ""
echo ""

if [ -f /tmp/rjv_creds.txt ]; then
  source /tmp/rjv_creds.txt
  rm -f /tmp/rjv_creds.txt

  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${YELLOW}║       🖥️  VM READY — TERMIUS CONNECTION INFO        ║${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}VM Name   :${RESET}  ${CYAN}${VM_NAME}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}OS        :${RESET}  ${CYAN}${OS_NAME}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}RAM       :${RESET}  ${CYAN}${RAM} MB${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Disk      :${RESET}  ${CYAN}${DISK} GB${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}CPUs      :${RESET}  ${CYAN}${CPUS}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Mode      :${RESET}  ${CYAN}${VM_MODE}${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
  echo -e "${YELLOW}║${RESET}  ${GREEN}${BOLD}── Open Termius → New Host → paste below ──${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}IP / Host :${RESET}  ${GREEN}${HOST_IP}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Port      :${RESET}  ${GREEN}${SSH_PORT}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Username  :${RESET}  ${GREEN}${VM_USER}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Password  :${RESET}  ${GREEN}${VM_PASS}${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}SSH CMD   :${RESET}  ${CYAN}ssh ${VM_USER}@${HOST_IP} -p ${SSH_PORT}${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
fi

if screen -list 2>/dev/null | grep -q "rjv_"; then
  echo -e "${YELLOW}║${RESET}  ${WHITE}Keep-Alive:${RESET}  ${GREEN}Active 🟢${RESET}"
  echo -e "${YELLOW}║${RESET}  ${CYAN}screen -ls${RESET}  ← list sessions"
  echo -e "${YELLOW}║${RESET}  ${CYAN}tail -f /tmp/rjv_keepalive.log${RESET}  ← live log"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
fi

echo -e "${YELLOW}║${RESET}  ${MAGENTA}Made by Rajveer — github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

