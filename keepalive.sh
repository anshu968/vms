#!/bin/bash
# ============================================================
#   KEEP ALIVE — by Rajveer
#   Keeps GitHub Codespaces / Replit / CodeSandbox running 24/7
#   Prevents sleep/timeout on free tier platforms
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
echo "  ██╗  ██╗███████╗███████╗██████╗      █████╗ ██╗     ██╗██╗   ██╗███████╗"
echo "  ██║ ██╔╝██╔════╝██╔════╝██╔══██╗    ██╔══██╗██║     ██║██║   ██║██╔════╝"
echo "  █████╔╝ █████╗  █████╗  ██████╔╝    ███████║██║     ██║██║   ██║█████╗  "
echo "  ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝     ██╔══██║██║     ██║╚██╗ ██╔╝██╔══╝  "
echo "  ██║  ██╗███████╗███████╗██║         ██║  ██║███████╗██║ ╚████╔╝ ███████╗"
echo "  ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝         ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝  ╚══════╝"
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}          24/7 Keep-Alive — Made by Rajveer${RESET}"
echo -e "${YELLOW}          ──────────────────────────────────────${RESET}"
echo ""

# ─── Detect Platform ──────────────────────────────────────
detect_platform() {
  if [ -n "$CODESPACE_NAME" ] || [ -d "/workspaces" ]; then
    echo "GitHub Codespaces"
  elif [ -n "$REPL_ID" ] || [ -d "/home/runner" ]; then
    echo "Replit"
  elif [ -d "/sandbox" ] || [ -n "$CSB_CONTAINER" ]; then
    echo "CodeSandbox"
  else
    echo "Unknown/Custom"
  fi
}

PLATFORM=$(detect_platform)
echo -e "${BLUE}[*] Platform detected: ${GREEN}${PLATFORM}${RESET}"
echo ""

# ─── Select Keep-Alive Method ─────────────────────────────
echo -e "${WHITE}${BOLD}Select keep-alive method:${RESET}"
echo -e "  ${CYAN}[1]${RESET} Ping loop (basic, low resource)"
echo -e "  ${CYAN}[2]${RESET} CPU activity loop (stronger keep-alive)"
echo -e "  ${CYAN}[3]${RESET} Both (recommended for 24/7)"
echo -e "  ${CYAN}[4]${RESET} Web server keep-alive (Replit/Codespaces UptimeRobot)"
echo ""
read -p "$(echo -e ${YELLOW}"Enter choice [1-4]: "${RESET})" METHOD
METHOD=${METHOD:-3}

# ─── Install Dependencies ─────────────────────────────────
echo ""
echo -e "${BLUE}[*] Checking dependencies...${RESET}"

install_if_missing() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${YELLOW}[!] Installing $1...${RESET}"
    apt-get install -y "$1" &>/dev/null || \
    yum install -y "$1" &>/dev/null || \
    npm install -g "$1" &>/dev/null || true
  fi
}

install_if_missing curl
install_if_missing screen
echo -e "${GREEN}[✓] Dependencies ready${RESET}"

# ─── Ping Loop ────────────────────────────────────────────
start_ping_loop() {
  cat > /tmp/rajveer_ping.sh << 'PING'
#!/bin/bash
while true; do
  # Self-ping to keep network alive
  curl -s http://localhost:8080 &>/dev/null || true
  curl -s http://127.0.0.1 &>/dev/null || true
  # Write a timestamp so the platform sees activity
  echo "$(date) - Rajveer KeepAlive ping" >> /tmp/rajveer_keepalive.log
  # Trim log to last 100 lines
  tail -100 /tmp/rajveer_keepalive.log > /tmp/rajveer_keepalive.log.tmp && \
    mv /tmp/rajveer_keepalive.log.tmp /tmp/rajveer_keepalive.log
  sleep 20
done
PING
  chmod +x /tmp/rajveer_ping.sh
  screen -dmS rajveer_ping bash /tmp/rajveer_ping.sh
  echo -e "${GREEN}[✓] Ping loop started (session: rajveer_ping)${RESET}"
}

# ─── CPU Activity Loop ────────────────────────────────────
start_cpu_loop() {
  cat > /tmp/rajveer_cpu.sh << 'CPU'
#!/bin/bash
while true; do
  # Light CPU activity to prevent idle timeout
  for i in $(seq 1 1000); do echo "$i" > /dev/null; done
  echo "$(date) - Rajveer CPU heartbeat" >> /tmp/rajveer_keepalive.log
  sleep 30
done
CPU
  chmod +x /tmp/rajveer_cpu.sh
  screen -dmS rajveer_cpu bash /tmp/rajveer_cpu.sh
  echo -e "${GREEN}[✓] CPU heartbeat started (session: rajveer_cpu)${RESET}"
}

# ─── Web Server (for UptimeRobot) ─────────────────────────
start_web_server() {
  read -p "$(echo -e ${YELLOW}"Web server port [default: 8080]: "${RESET})" WEB_PORT
  WEB_PORT=${WEB_PORT:-8080}

  cat > /tmp/rajveer_web.sh << WEBSERVER
#!/bin/bash
# Simple HTTP server for UptimeRobot pinging
while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nRajveer KeepAlive - \$(date)" | \
    nc -l -p ${WEB_PORT} -q 1 &>/dev/null || true
  sleep 1
done
WEBSERVER

  chmod +x /tmp/rajveer_web.sh
  screen -dmS rajveer_web bash /tmp/rajveer_web.sh
  echo -e "${GREEN}[✓] Web server started on port ${WEB_PORT} (session: rajveer_web)${RESET}"
  echo ""
  HOST_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "your-replit-url.repl.co")
  echo -e "${WHITE}Add this URL to UptimeRobot (free):${RESET}"
  echo -e "  ${CYAN}http://${HOST_IP}:${WEB_PORT}${RESET}"
  echo -e "  ${YELLOW}Set ping interval: every 5 minutes${RESET}"
}

# ─── GitHub Codespaces specific ───────────────────────────
codespaces_keepalive() {
  if [ "$PLATFORM" = "GitHub Codespaces" ]; then
    echo -e "${BLUE}[*] Applying Codespaces-specific tweaks...${RESET}"
    # Prevent VS Code server timeout
    cat > /tmp/rajveer_cs.sh << 'CS'
#!/bin/bash
while true; do
  # Keep codespace active by touching files
  touch /tmp/rajveer_active_$(date +%s)
  find /tmp -name "rajveer_active_*" -mmin +60 -delete 2>/dev/null
  sleep 60
done
CS
    chmod +x /tmp/rajveer_cs.sh
    screen -dmS rajveer_cs bash /tmp/rajveer_cs.sh
    echo -e "${GREEN}[✓] Codespaces heartbeat active${RESET}"
  fi
}

# ─── Run Selected Method ──────────────────────────────────
echo ""
case $METHOD in
  1) start_ping_loop ;;
  2) start_cpu_loop ;;
  3)
    start_ping_loop
    start_cpu_loop
    codespaces_keepalive
    ;;
  4)
    start_web_server
    start_ping_loop
    ;;
  *)
    echo -e "${RED}[✗] Invalid choice, using method 3${RESET}"
    start_ping_loop
    start_cpu_loop
    ;;
esac

# ─── Auto-restart on crash ────────────────────────────────
cat > /tmp/rajveer_watchdog.sh << 'WATCH'
#!/bin/bash
# Watchdog: restart sessions if they die
while true; do
  for session in rajveer_ping rajveer_cpu rajveer_web rajveer_cs; do
    if screen -list | grep -q "$session"; then
      : # still running
    else
      # Restart the session script if it exists
      SCRIPT="/tmp/${session//rajveer_/rajveer_}.sh"
      [ -f "$SCRIPT" ] && screen -dmS "$session" bash "$SCRIPT"
    fi
  done
  sleep 60
done
WATCH
chmod +x /tmp/rajveer_watchdog.sh
screen -dmS rajveer_watchdog bash /tmp/rajveer_watchdog.sh

# ─── Summary ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║        🟢  KEEP-ALIVE ACTIVE — by Rajveer           ║${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Platform  :${RESET} ${CYAN}${PLATFORM}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Method    :${RESET} ${CYAN}Option ${METHOD}${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Watchdog  :${RESET} ${GREEN}Active (auto-restarts sessions)${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Log file  :${RESET} ${CYAN}/tmp/rajveer_keepalive.log${RESET}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${GREEN}${BOLD}── Useful Commands ──${RESET}"
echo -e "${YELLOW}║${RESET}  ${CYAN}screen -ls${RESET}                    ← list sessions"
echo -e "${YELLOW}║${RESET}  ${CYAN}screen -r rajveer_ping${RESET}         ← view ping log"
echo -e "${YELLOW}║${RESET}  ${CYAN}screen -r rajveer_watchdog${RESET}     ← view watchdog"
echo -e "${YELLOW}║${RESET}  ${CYAN}tail -f /tmp/rajveer_keepalive.log${RESET} ← live log"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${MAGENTA}Made by Rajveer${RESET}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${GREEN}[✓] All sessions running in background. Platform will stay alive 24/7.${RESET}"
echo -e "${WHITE}Run this on startup to auto-enable on every session.${RESET}"
echo ""

