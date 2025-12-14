#!/bin/bash
set -e

PKG_NAME="silentcloak"

echo "[*] Сборка .deb пакета $PKG_NAME"

dpkg-deb --build "$PKG_NAME"

echo "[+] Готово: $PKG_NAME.deb"

