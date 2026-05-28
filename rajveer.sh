#!/bin/bash
# ============================================================
#   RAJVEER.SH — All-in-One Script — by Rajveer
#   bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/rajveer.sh)
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
echo -e "${WHITE}${BOLD}         All-in-One VM Tool — Made by Rajveer${RESET}"
echo -e "${YELLOW}         github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}         ──────────────────────────────────────${RESET}"
echo ""

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[!] Not root. Trying sudo...${RESET}"
  exec sudo bash "$0" "$@"; exit
fi

# ─── Platform ─────────────────────────────────────────────
if [ -n "$REPL_ID" ] || [ -d "/home/runner" ]; then PLATFORM="Replit"
elif [ -n "$CODESPACE_NAME" ] || [ -d "/workspaces" ]; then PLATFORM="GitHub Codespaces"
elif [ -d "/sandbox" ] || [ -n "$CSB_CONTAINER" ]; then PLATFORM="CodeSandbox"
else PLATFORM="Linux VPS"; fi
echo -e "${BLUE}[*] Platform : ${GREEN}${PLATFORM}${RESET}"

# ─── KVM ──────────────────────────────────────────────────
if grep -q -E 'vmx|svm' /proc/cpuinfo 2>/dev/null; then KVM_OK=true
  echo -e "${BLUE}[*] KVM      : ${GREEN}Supported ✓${RESET}"
else KVM_OK=false
  echo -e "${BLUE}[*] KVM      : ${YELLOW}Not supported — No-KVM mode${RESET}"; fi

# ─── Public IP ────────────────────────────────────────────
echo -e "${BLUE}[*] Public IP: ${RESET}fetching..."
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(hostname -I | awk '{print $1}')
PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo -e "${BLUE}[*] Public IP: ${GREEN}${PUBLIC_IP}${RESET}"
echo ""

# ══════════════════════════════════════════════════════════
#  STEP 1 — SETUP
# ══════════════════════════════════════════════════════════
echo -e "${WHITE}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${WHITE}${BOLD}║      STEP 1 — Installing Dependencies        ║${RESET}"
echo -e "${WHITE}${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
apt-get update -y &>/dev/null

install_pkg() {
  local NAME=$1; local PKG=${2:-$1}
  printf "  ${CYAN}%-26s${RESET}" "$NAME"
  if command -v "$NAME" &>/dev/null; then echo -e "${GREEN}already installed ✓${RESET}"; return; fi
  apt-get install -y "$PKG" &>/dev/null
  command -v "$NAME" &>/dev/null && echo -e "${GREEN}installed ✓${RESET}" || echo -e "${YELLOW}skipped${RESET}"
}

install_pkg curl; install_pkg wget; install_pkg git
install_pkg screen; install_pkg tmux; install_pkg unzip
install_pkg nano; install_pkg htop; install_pkg net-tools
install_pkg netcat nc; install_pkg openssh-server ssh
install_pkg sshpass; install_pkg socat
install_pkg qemu-img qemu-utils
install_pkg qemu-system-x86_64 qemu-system-x86

if [ "$KVM_OK" = true ]; then
  apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst &>/dev/null
  echo -e "  ${CYAN}kvm + libvirt             ${GREEN}installed ✓${RESET}"
fi
service ssh start &>/dev/null || systemctl start ssh &>/dev/null || true
echo -e "  ${CYAN}ssh server                ${GREEN}started ✓${RESET}"
echo ""
echo -e "${GREEN}[✓] All dependencies ready!${RESET}"
echo ""

# ══════════════════════════════════════════════════════════
#  NGROK SETUP (for Replit/Codespaces/CodeSandbox)
# ══════════════════════════════════════════════════════════
USE_NGROK=false; NGROK_HOST=""; NGROK_PORT_OUT=""

if [ "$PLATFORM" != "Linux VPS" ]; then
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${YELLOW}║  ⚠️  Free platforms need Ngrok for Termius access   ║${RESET}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
  echo -e "  ${CYAN}[1]${RESET} Yes — install Ngrok (get real IP for Termius)"
  echo -e "  ${CYAN}[2]${RESET} No  — skip"
  echo ""
  while true; do
    read -p "$(echo -e ${YELLOW}"Choice [1-2]: "${RESET})" NG
    [[ "$NG" =~ ^[1-2]$ ]] && break; echo -e "${RED}[✗] Enter 1 or 2${RESET}"
  done
  if [ "$NG" = "1" ]; then
    echo -e "${BLUE}[*] Installing Ngrok...${RESET}"
    wget -q -O /tmp/ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
    unzip -o /tmp/ngrok.zip -d /usr/local/bin/ &>/dev/null
    chmod +x /usr/local/bin/ngrok
    echo -e "${GREEN}[✓] Ngrok installed${RESET}"
    echo -e "${WHITE}Get your free token at: ${CYAN}https://ngrok.com${RESET}"
    while true; do
      read -p "$(echo -e ${YELLOW}"Ngrok authtoken: "${RESET})" NGROK_TOKEN
      [[ -n "$NGROK_TOKEN" ]] && break; echo -e "${RED}[✗] Cannot be empty${RESET}"
    done
    ngrok config add-authtoken "$NGROK_TOKEN" &>/dev/null
    echo -e "${GREEN}[✓] Ngrok token saved${RESET}"
    USE_NGROK=true
  fi
  echo ""
fi

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
  [[ "$MENU" =~ ^[1-4]$ ]] && break; echo -e "${RED}[✗] Enter 1 to 4${RESET}"
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
    read -p "$(echo -e ${YELLOW}"Method [1-4]: "${RESET})" KA
    [[ "$KA" =~ ^[1-4]$ ]] && break; echo -e "${RED}[✗] Enter 1 to 4${RESET}"
  done
  if [ "$KA" = "4" ]; then
    while true; do
      read -p "$(echo -e ${YELLOW}"Web port (e.g. 8080): "${RESET})" WEB_PORT
      [[ "$WEB_PORT" =~ ^[0-9]+$ ]] && break; echo -e "${RED}[✗] Enter valid port${RESET}"
    done
  fi

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
    1) screen -dmS rjv_ping bash /tmp/rjv_ping.sh; echo -e "${GREEN}[✓] Ping loop active${RESET}" ;;
    2) screen -dmS rjv_cpu bash /tmp/rjv_cpu.sh; echo -e "${GREEN}[✓] CPU heartbeat active${RESET}" ;;
    3) screen -dmS rjv_ping bash /tmp/rjv_ping.sh
       screen -dmS rjv_cpu bash /tmp/rjv_cpu.sh
       echo -e "${GREEN}[✓] Ping + CPU active${RESET}" ;;
    4) cat > /tmp/rjv_web.sh << WEBEOF
#!/bin/bash
while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nRajveer KeepAlive - \$(date)" | nc -l -p ${WEB_PORT} -q 1 &>/dev/null || true
  sleep 1
done
WEBEOF
       chmod +x /tmp/rjv_web.sh
       screen -dmS rjv_web bash /tmp/rjv_web.sh
       screen -dmS rjv_ping bash /tmp/rjv_ping.sh
       echo -e "${GREEN}[✓] Web server on port ${WEB_PORT}${RESET}"
       echo -e "${WHITE}UptimeRobot URL: ${CYAN}http://${PUBLIC_IP}:${WEB_PORT}${RESET}" ;;
  esac

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
  echo -e "${GREEN}[✓] Watchdog active${RESET}"
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
    [[ "$OS_CHOICE" =~ ^[1-5]$ ]] && break; echo -e "${RED}[✗] Enter 1 to 5${RESET}"
  done
  case $OS_CHOICE in
    1) OS_NAME="Ubuntu 22.04"; ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso"; ISO_FILE="ubuntu-22.04.iso" ;;
    2) OS_NAME="Debian 12"; ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"; ISO_FILE="debian-12.iso" ;;
    3) OS_NAME="Kali Linux 2024"; ISO_URL="https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-amd64.iso"; ISO_FILE="kali-2024.iso" ;;
    4) OS_NAME="Windows 10"; ISO_URL="https://www.itechtics.com/?dl_id=173"; ISO_FILE="windows10.iso" ;;
    5) OS_NAME="Windows 11"; ISO_URL="https://www.itechtics.com/?dl_id=233"; ISO_FILE="windows11.iso" ;;
  esac

  echo ""
  echo -e "${WHITE}${BOLD}── VM Configuration (fill every field) ──${RESET}"
  echo ""
  while true; do
    read -p "$(echo -e ${YELLOW}"VM Hostname   (e.g. my-server)  : "${RESET})" VM_NAME
    [[ -n "$VM_NAME" ]] && break; echo -e "${RED}[✗] Cannot be empty${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"Username      (e.g. rajveer)    : "${RESET})" VM_USER
    [[ -n "$VM_USER" ]] && break; echo -e "${RED}[✗] Cannot be empty${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"Password      (e.g. Pass@1234)  : "${RESET})" VM_PASS
    [[ -n "$VM_PASS" ]] && break; echo -e "${RED}[✗] Cannot be empty${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"RAM in MB     (e.g. 2048)       : "${RESET})" RAM
    [[ "$RAM" =~ ^[0-9]+$ ]] && [ "$RAM" -ge 256 ] && break; echo -e "${RED}[✗] Minimum 256 MB${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"Disk in GB    (e.g. 20)         : "${RESET})" DISK
    [[ "$DISK" =~ ^[0-9]+$ ]] && [ "$DISK" -ge 5 ] && break; echo -e "${RED}[✗] Minimum 5 GB${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"CPU cores     (e.g. 2)          : "${RESET})" CPUS
    [[ "$CPUS" =~ ^[0-9]+$ ]] && [ "$CPUS" -ge 1 ] && break; echo -e "${RED}[✗] Minimum 1${RESET}"
  done
  while true; do
    read -p "$(echo -e ${YELLOW}"SSH Port      (e.g. 2222)       : "${RESET})" SSH_PORT
    [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && [ "$SSH_PORT" -ge 1 ] && [ "$SSH_PORT" -le 65535 ] && break
    echo -e "${RED}[✗] Enter valid port 1-65535${RESET}"
  done

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

  echo -e "${BLUE}[*] Starting VM (${VM_MODE})...${RESET}"
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
  echo -e "${GREEN}[✓] VM launched!${RESET}"

  # Ngrok tunnel
  if [ "$USE_NGROK" = true ] && command -v ngrok &>/dev/null; then
    echo -e "${BLUE}[*] Starting Ngrok on port ${SSH_PORT}...${RESET}"
    screen -dmS rjv_ngrok ngrok tcp "$SSH_PORT"
    sleep 5
    NGROK_ADDR=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"tcp://[^"]*"' | grep -o 'tcp://[^"]*' | head -1)
    if [ -n "$NGROK_ADDR" ]; then
      NGROK_HOST=$(echo "$NGROK_ADDR" | cut -d: -f2 | tr -d '/')
      NGROK_PORT_OUT=$(echo "$NGROK_ADDR" | cut -d: -f3)
      echo -e "${GREEN}[✓] Ngrok tunnel active!${RESET}"
    fi
  fi

  # Save creds
  cat > /tmp/rjv_creds.txt << CREDS
VM_NAME="${VM_NAME}"
OS_NAME="${OS_NAME}"
RAM="${RAM}"
DISK="${DISK}"
CPUS="${CPUS}"
VM_MODE="${VM_MODE}"
PUBLIC_IP="${PUBLIC_IP}"
PRIVATE_IP="${PRIVATE_IP}"
SSH_PORT="${SSH_PORT}"
VM_USER="${VM_USER}"
VM_PASS="${VM_PASS}"
NGROK_HOST="${NGROK_HOST}"
NGROK_PORT_OUT="${NGROK_PORT_OUT}"
CREDS
}

# ══════════════════════════════════════════════════════════
#  RUN
# ══════════════════════════════════════════════════════════
case $MENU in
  1) do_vm_install ;;
  2) do_keepalive ;;
  3) do_vm_install; do_keepalive ;;
  4) echo -e "${YELLOW}Bye!${RESET}"; exit 0 ;;
esac

# ══════════════════════════════════════════════════════════
#  FINAL TERMIUS BOX — Always at the end
# ══════════════════════════════════════════════════════════
echo ""
echo ""

if [ -f /tmp/rjv_creds.txt ]; then
  source /tmp/rjv_creds.txt
  rm -f /tmp/rjv_creds.txt

  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${YELLOW}║       🖥️  VM READY — TERMIUS CONNECTION INFO        ║${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}VM Hostname :${RESET}  ${CYAN}${VM_NAME}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}OS          :${RESET}  ${CYAN}${OS_NAME}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}RAM         :${RESET}  ${CYAN}${RAM} MB${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Disk        :${RESET}  ${CYAN}${DISK} GB${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}CPUs        :${RESET}  ${CYAN}${CPUS}${RESET}"
  echo -e "${YELLOW}║${RESET}  ${WHITE}Mode        :${RESET}  ${CYAN}${VM_MODE}${RESET}"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"

  if [ -n "$NGROK_HOST" ] && [ -n "$NGROK_PORT_OUT" ]; then
    echo -e "${YELLOW}║${RESET}  ${GREEN}${BOLD}── Termius via Ngrok (USE THIS) ──${RESET}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}IP / Host   :${RESET}  ${GREEN}${NGROK_HOST}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Port        :${RESET}  ${GREEN}${NGROK_PORT_OUT}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Username    :${RESET}  ${GREEN}${VM_USER}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Password    :${RESET}  ${GREEN}${VM_PASS}${RESET}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}SSH CMD     :${RESET}  ${CYAN}ssh ${VM_USER}@${NGROK_HOST} -p ${NGROK_PORT_OUT}${RESET}"
  else
    echo -e "${YELLOW}║${RESET}  ${GREEN}${BOLD}── Termius / SSH ──${RESET}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}IP / Host   :${RESET}  ${GREEN}${PUBLIC_IP}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Port        :${RESET}  ${GREEN}${SSH_PORT}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Username    :${RESET}  ${GREEN}${VM_USER}${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}Password    :${RESET}  ${GREEN}${VM_PASS}${RESET}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${YELLOW}║${RESET}  ${WHITE}SSH CMD     :${RESET}  ${CYAN}ssh ${VM_USER}@${PUBLIC_IP} -p ${SSH_PORT}${RESET}"
    if [ "$PLATFORM" != "Linux VPS" ]; then
      echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
      echo -e "${YELLOW}║${RESET}  ${YELLOW}⚠ Run: ngrok tcp ${SSH_PORT}  for real Termius access${RESET}"
    fi
  fi
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
fi

if screen -list 2>/dev/null | grep -q "rjv_"; then
  echo -e "${YELLOW}║${RESET}  ${WHITE}Keep-Alive  :${RESET}  ${GREEN}Active 🟢${RESET}"
  echo -e "${YELLOW}║${RESET}  ${CYAN}screen -ls${RESET}  ← list all running sessions"
  echo -e "${YELLOW}║${RESET}  ${CYAN}tail -f /tmp/rjv_keepalive.log${RESET}  ← live log"
  echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
fi

echo -e "${YELLOW}║${RESET}  ${MAGENTA}Made by Rajveer — github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

