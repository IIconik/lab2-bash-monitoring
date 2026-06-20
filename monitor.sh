#!/bin/bash
# ─────────────────────────────────────────────
# monitor.sh — Monitoring serveur Linux
# Usage : ./monitor.sh
# Cron  : */5 * * * * /root/lab2-bash-monitoring/monitor.sh
# ─────────────────────────────────────────────
set -euo pipefail

# ── Constantes ────────────────────────────────
LOG="/var/log/monitor.log"
RAPPORT="/tmp/health_report.json"
SEUIL_DISK=80        # % avant WARNING
SEUIL_DISK_CRIT=90   # % avant CRITICAL
SEUIL_RAM=85         # % avant WARNING
SEUIL_HTTP=500       # ms avant WARNING
SERVICES=("ssh" "ufw" "fail2ban" "log-python")

# ── Couleurs terminal ─────────────────────────
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
CRIT="\e[31m[CRIT]\e[0m"

# ── Fonction log ──────────────────────────────
log() {
    local niveau=$1
    local message=$2
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] [$niveau] $message" | tee -a "$LOG"
}

# ── Vérification disque ───────────────────────
log "INFO" "=== Début monitoring $(hostname) ==="

check_disk() {
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

    if [ "$usage" -ge "$SEUIL_DISK_CRIT" ]; then
        log "CRITICAL" "Disque à ${usage}% (seuil critique : ${SEUIL_DISK_CRIT}%)"
        echo -e "$CRIT Disque : ${usage}%"
        return 2
    elif [ "$usage" -ge "$SEUIL_DISK" ]; then
        log "WARNING" "Disque à ${usage}% (seuil : ${SEUIL_DISK}%)"
        echo -e "$WARN Disque : ${usage}%"
        return 1
    else
        log "INFO" "Disque OK : ${usage}%"
        echo -e "$OK Disque : ${usage}%"
        return 0
    fi
}
check_disk

# ── Vérification RAM ──────────────────────────
check_ram() {
    local total used usage
    total=$(free | awk 'NR==2 {print $2}')
    used=$(free | awk 'NR==2 {print $3}')
    usage=$(( used * 100 / total ))

    if [ "$usage" -ge "$SEUIL_RAM" ]; then
        log "WARNING" "RAM à ${usage}% (seuil : ${SEUIL_RAM}%)"
        echo -e "$WARN RAM : ${usage}%"
        return 1
    else
        log "INFO" "RAM OK : ${usage}%"
        echo -e "$OK RAM : ${usage}%"
        return 0
    fi
}

check_ram

# ── Vérification services ─────────────────────
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        log "INFO" "Service $service : actif"
        echo -e "$OK Service : $service"
        return 0
    else
        log "CRITICAL" "Service $service : INACTIF"
        echo -e "$CRIT Service : $service INACTIF"
        return 1
    fi
}

for service in "${SERVICES[@]}"; do
    check_service "$service" || true
done

# ── Vérification HTTP ─────────────────────────
check_http() {
    local url=$1
    local start end duration code

    start=$(date +%s%3N)
    code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "$url")
    end=$(date +%s%3N)
    duration=$(( end - start ))

    if [ "$code" -eq 000 ]; then
        log "CRITICAL" "HTTP $url : injoignable"
        echo -e "$CRIT HTTP $url : injoignable"
        return 2
    elif [ "$code" -ne 200 ]; then
        log "WARNING" "HTTP $url : code $code"
        echo -e "$WARN HTTP $url : code $code"
        return 1
    elif [ "$duration" -gt "$SEUIL_HTTP" ]; then
        log "WARNING" "HTTP $url : lent (${duration}ms)"
        echo -e "$WARN HTTP $url : ${duration}ms"
        return 1
    else
        log "INFO" "HTTP $url : OK (${duration}ms)"
        echo -e "$OK HTTP $url : ${duration}ms"
        return 0
    fi
}

check_http "http://localhost" || true

# ── Rapport JSON ──────────────────────────────
generer_rapport() {
    local disk ram
    disk=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    ram=$(free | awk 'NR==2 {used=$3; total=$2; print int(used*100/total)}')

    cat > "$RAPPORT" << EOF
{
  "date": "$(date '+%Y-%m-%d %H:%M:%S')",
  "hostname": "$(hostname)",
  "disque_pct": $disk,
  "ram_pct": $ram,
  "services": {
    "ssh": "$(systemctl is-active ssh)",
    "ufw": "$(systemctl is-active ufw)",
    "fail2ban": "$(systemctl is-active fail2ban)",
    "log-python": "$(systemctl is-active log-python)"
  }
}
EOF
    log "INFO" "Rapport JSON généré : $RAPPORT"
}

generer_rapport
log "INFO" "=== Fin monitoring ==="
