# silentcloak

`silentcloak` — утилита для временного снижения сетевой видимости и
сетевой атрибуции Linux-хоста.

Инструмент ориентирован на использование в SOC / BlueTeam окружениях,
когда рабочий узел используется ограниченное время и не должен
привлекать внимание при сетевом сканировании.

---

## Назначение

`silentcloak` включает режим «сетевой тишины»:

- блокирует все входящие соединения, кроме SSH
- минимизирует сетевые сигналы, используемые для fingerprinting
- не устанавливает постоянные сервисы
- полностью откатывает все изменения

Утилита **не делает хост «невидимым»**, а снижает его заметность и
выделяемость в сети.

---

## Основные возможности

- DROP-политика для входящих соединений
- Разрешение только:
  - loopback
  - ESTABLISHED / RELATED
  - SSH (с rate-limit)
- Ограничение частоты SSH-подключений
- Отключение ICMP Echo (ping)
- Изменение TTL на Windows-подобный (128)
- Отключение TCP timestamps
- Включение SYN cookies
- Включение rp_filter (anti-spoofing)
- Полный и безопасный откат всех изменений

---

## Требования

- Linux (Debian / Ubuntu / Raspberry Pi OS)
- `iptables`
- `bash`
- root-доступ

---

## Установка

### Через .deb пакет

```bash
sudo dpkg -i silentcloak.deb


## Удаление

sudo apt remove silentcloak

## Использование

sudo silentcloak on
sudo silentcloak status
sudo silentcloak off

## Справка 

silentcloak help

