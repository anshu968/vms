#!/bin/bash
# ============================================================
#   SETUP.SH — by Rajveer
#   bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/setup.sh)
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
echo -e "${GREEN}"
echo "  ███████╗███████╗████████╗██╗   ██╗██████╗ "
echo "  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
echo "  ███████╗█████╗     ██║   ██║   ██║██████╔╝"
echo "  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
echo "  ███████║███████╗   ██║   ╚██████╔╝██║     "
echo "  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}     First-Time Setup — Made by Rajveer${RESET}"
echo -e "${YELLOW}     github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}     ──────────────────────────────────────${RESET}"
echo ""

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[!] Not root. Trying sudo...${RESET}"
  exec sudo bash "$0" "$@"; exit
fi

# Detect platform
if [ -n "$REPL_ID" ] || [ -d "/home/runner" ]; then PLATFORM="Replit"
elif [ -n "$CODESPACE_NAME" ] || [ -d "/workspaces" ]; then PLATFORM="GitHub Codespaces"
elif [ -d "/sandbox" ] || [ -n "$CSB_CONTAINER" ]; then PLATFORM="CodeSandbox"
else PLATFORM="Linux VPS"; fi
echo -e "${BLUE}[*] Platform : ${GREEN}${PLATFORM}${RESET}"

# KVM
if grep -q -E 'vmx|svm' /proc/cpuinfo 2>/dev/null; then KVM_OK=true; echo -e "${BLUE}[*] KVM      : ${GREEN}Supported ✓${RESET}"
else KVM_OK=false; echo -e "${BLUE}[*] KVM      : ${YELLOW}Not supported${RESET}"; fi
echo ""

echo -e "${WHITE}${BOLD}Installing all dependencies...${RESET}"
echo ""
apt-get update -y &>/dev/null

install_pkg() {
  local NAME=$1; local PKG=${2:-$1}
  printf "  ${CYAN}%-26s${RESET}" "$NAME"
  if command -v "$NAME" &>/dev/null; then echo -e "${GREEN}already installed ✓${RESET}"; return; fi
  apt-get install -y "$PKG" &>/dev/null
  command -v "$NAME" &>/dev/null && echo -e "${GREEN}installed ✓${RESET}" || echo -e "${YELLOW}skipped${RESET}"
}

install_pkg curl
install_pkg wget
install_pkg git
install_pkg screen
install_pkg tmux
install_pkg unzip
install_pkg nano
install_pkg vim
install_pkg htop
install_pkg net-tools
install_pkg netcat nc
install_pkg openssh-server ssh
install_pkg sshpass
install_pkg socat
install_pkg rsync
install_pkg lsof
install_pkg qemu-img qemu-utils
install_pkg qemu-system-x86_64 qemu-system-x86
install_pkg python3
install_pkg node nodejs
install_pkg npm

if [ "$KVM_OK" = true ]; then
  apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst &>/dev/null
  echo -e "  ${CYAN}kvm + libvirt             ${GREEN}installed ✓${RESET}"
fi

service ssh start &>/dev/null || systemctl start ssh &>/dev/null || true
echo -e "  ${CYAN}ssh server                ${GREEN}started ✓${RESET}"

echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║         ✅  SETUP COMPLETE — by Rajveer             ║${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Platform  :${RESET} ${CYAN}${PLATFORM}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}KVM       :${RESET} ${CYAN}$( [ "$KVM_OK" = true ] && echo "Supported" || echo "Not supported" )${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${GREEN}Run next:${RESET}"
echo -e "${YELLOW}║${RESET}  ${CYAN}bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/vm.sh)${RESET}"
echo -e "${YELLOW}║${RESET}  ${CYAN}bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/nokvm.sh)${RESET}"
echo -e "${YELLOW}║${RESET}  ${CYAN}bash <(curl -fsSL https://raw.githubusercontent.com/anshu968/vms/main/keepalive.sh)${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${MAGENTA}Made by Rajveer — github.com/anshu968/vms${RESET}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

