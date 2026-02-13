#!/bin/bash

# رنگ‌بندی برای خروجی زیباتر
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# متغیرهای اصلی
BINARY_URL="https://github.com/Alfred-1313/daggerConnect/releases/download/v1.0.0/DaggerConnect"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/DaggerConnect"

echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}    DaggerConnect Installer (Patched)  ${NC}"
echo -e "${CYAN}        Developed by Alfred-1313       ${NC}"
echo -e "${CYAN}=======================================${NC}"

# ۱. بررسی دسترسی روت
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ لطفا اسکریپت را با دسترسی root اجرا کنید.${NC}"
   exit 1
fi

# ۲. نصب پیش‌نیازها
echo -e "${YELLOW}📦 در حال نصب پیش‌نیازها...${NC}"
apt update -qq && apt install -y wget curl openssl > /dev/null 2>&1

# ۳. دانلود فایل پچ‌شده
echo -e "${YELLOW}⬇️ در حال دانلود نسخه آنلاک شده...${NC}"
mkdir -p "$CONFIG_DIR"
wget -q --show-progress "$BINARY_URL" -O "$INSTALL_DIR/DaggerConnect"
chmod +x "$INSTALL_DIR/DaggerConnect"

# ۴. بهینه‌سازی TCP و فعال‌سازی BBR (برای سرعت عالی)
echo -e "${YELLOW}🚀 در حال بهینه‌سازی شبکه (BBR)...${NC}"
cat > /etc/sysctl.d/99-dagger.conf << EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
EOF
sysctl -p /etc/sysctl.d/99-dagger.conf > /dev/null 2>&1

# ۵. ساخت فایل سرویس Systemd
echo -e "${YELLOW}⚙️ در حال ساخت سرویس سیستم...${NC}"
cat > /etc/systemd/system/dagger.service << EOF
[Unit]
Description=DaggerConnect Unlocked Service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/DaggerConnect -c $CONFIG_DIR/config.yaml
Restart=always
User=root
WorkingDirectory=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF

# ۶. تولید کانفیگ اولیه اگر وجود نداشته باشد
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    echo -e "${YELLOW}📄 در حال تولید کانفیگ پیش‌فرض...${NC}"
    cd "$CONFIG_DIR"
    $INSTALL_DIR/DaggerConnect -gen server > /dev/null 2>&1
    mv *.yaml config.yaml 2>/dev/null
fi

systemctl daemon-reload
systemctl enable dagger > /dev/null 2>&1

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ نصب با موفقیت انجام شد!${NC}"
echo -e "${CYAN}دایرکتوری تنظیمات: $CONFIG_DIR${NC}"
echo -e "${YELLOW}دستور مشاهده وضعیت: systemctl status dagger${NC}"
echo -e "${GREEN}=======================================${NC}"
