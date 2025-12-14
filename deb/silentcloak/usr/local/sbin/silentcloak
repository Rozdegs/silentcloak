#!/bin/bash

# ============================================================
# silentcloak — режим сетевой тишины
#
# Функции:
#  - Закрытие всех входящих портов, кроме SSH
#  - Ограничение SSH по частоте
#  - Снижение сетевой атрибуции хоста
#  - Полный откат всех изменений
# ============================================================

STATE_DIR="/var/lib/silentcloak"
IPTABLES_BACKUP="$STATE_DIR/iptables.backup"
SYSCTL_BACKUP="$STATE_DIR/sysctl.backup"

SSH_PORT=22
WINDOWS_TTL=128

# ------------------------------------------------------------
# Проверка прав
# ------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] Скрипт должен быть запущен от root"
  exit 1
fi

mkdir -p "$STATE_DIR"

# ------------------------------------------------------------
# Сохранение sysctl-параметров
# ------------------------------------------------------------
backup_sysctl() {
  echo "[*] Сохраняю текущие sysctl-параметры"

  cat <<EOF > "$SYSCTL_BACKUP"
net.ipv4.ip_default_ttl=$(sysctl -n net.ipv4.ip_default_ttl)
net.ipv4.tcp_timestamps=$(sysctl -n net.ipv4.tcp_timestamps)
net.ipv4.tcp_syncookies=$(sysctl -n net.ipv4.tcp_syncookies)
net.ipv4.conf.all.rp_filter=$(sysctl -n net.ipv4.conf.all.rp_filter)
net.ipv4.icmp_echo_ignore_all=$(sysctl -n net.ipv4.icmp_echo_ignore_all)
EOF
}

# ------------------------------------------------------------
# Восстановление sysctl-параметров
# ------------------------------------------------------------
restore_sysctl() {
  echo "[*] Восстанавливаю sysctl-параметры"

  while read -r line; do
    sysctl -w "$line" > /dev/null
  done < "$SYSCTL_BACKUP"
}

# ------------------------------------------------------------
# Включение тихого режима
# ------------------------------------------------------------
enable_silentcloak() {
  echo "[*] Включение режима silentcloak..."

  if [[ -f "$IPTABLES_BACKUP" ]]; then
    echo "[!] Тихий режим уже включён"
    exit 1
  fi

  echo "[*] Сохраняю iptables"
  iptables-save > "$IPTABLES_BACKUP"

  backup_sysctl

  echo "[*] Сброс iptables"
  iptables -F
  iptables -X

  echo "[*] Политики по умолчанию: INPUT DROP"
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT

  echo "[*] Разрешаю loopback"
  iptables -A INPUT -i lo -j ACCEPT

  echo "[*] Разрешаю ESTABLISHED, RELATED"
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  echo "[*] Ограничение SSH по частоте"
  iptables -A INPUT -p tcp --dport "$SSH_PORT" -m conntrack --ctstate NEW \
           -m limit --limit 3/min --limit-burst 3 -j ACCEPT

  echo "[*] Блокировка ICMP Echo (ping)"
  sysctl -w net.ipv4.icmp_echo_ignore_all=1 > /dev/null

  echo "[*] Установка TTL = $WINDOWS_TTL"
  sysctl -w net.ipv4.ip_default_ttl="$WINDOWS_TTL" > /dev/null

  echo "[*] Отключение TCP timestamps (fingerprinting)"
  sysctl -w net.ipv4.tcp_timestamps=0 > /dev/null

  echo "[*] Включение SYN cookies"
  sysctl -w net.ipv4.tcp_syncookies=1 > /dev/null

  echo "[*] Включение rp_filter (anti-spoofing)"
  sysctl -w net.ipv4.conf.all.rp_filter=1 > /dev/null

  echo "[+] Режим silentcloak включён"
}

# ------------------------------------------------------------
# Отключение тихого режима
# ------------------------------------------------------------
disable_silentcloak() {
  echo "[*] Отключение режима silentcloak..."

  if [[ ! -f "$IPTABLES_BACKUP" ]]; then
    echo "[!] Нет данных для отката"
    exit 1
  fi

  echo "[*] Восстанавливаю iptables"
  iptables-restore < "$IPTABLES_BACKUP"

  restore_sysctl

  rm -f "$IPTABLES_BACKUP" "$SYSCTL_BACKUP"

  echo "[+] Режим silentcloak отключён"
}

# ------------------------------------------------------------
# Справка
# ------------------------------------------------------------
show_help() {
  cat <<EOF

silentcloak

Назначение:
  Временное снижение сетевой видимости и атрибуции хоста.
  Используется для рабочих узлов SOC, не предназначенных
  для постоянного присутствия в сети.

Возможности:
  - Блокировка всех входящих соединений, кроме SSH
  - Ограничение частоты SSH-подключений (rate-limit)
  - Отключение ICMP Echo (ping)
  - Изменение TTL на Windows-подобный (128)
  - Отключение TCP timestamps
  - Включение SYN cookies
  - Включение rp_filter (anti-spoofing)
  - Полный откат всех изменений

Режимы работы:
  on        Включить режим silentcloak
  off       Отключить режим silentcloak и восстановить настройки
  status    Показать текущий статус
  help      Показать эту справку

Важно:
  - Скрипт должен запускаться от root
  - Перед включением убедись, что SSH-доступ работает
  - Рекомендуется иметь вторую SSH-сессию при активации
  - Скрипт не маскирует хост полностью, а снижает его заметность

Пример использования:
  sudo ./silentcloak.sh on
  sudo ./silentcloak.sh status
  sudo ./silentcloak.sh off

EOF
}


# ------------------------------------------------------------
# CLI
# ------------------------------------------------------------
case "$1" in
  on)
    enable_silentcloak
    ;;
  off)
    disable_silentcloak
    ;;
  status)
    if [[ -f "$IPTABLES_BACKUP" ]]; then
      echo "[*] silentcloak: ВКЛЮЧЁН"
    else
      echo "[*] silentcloak: ВЫКЛЮЧЕН"
    fi
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    echo "[!] Неизвестный параметр: $1"
    echo "Используй '$0 help' для справки"
    ;;
esac
