#!/bin/bash

# رنگ‌ها برای زیبایی منو
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# مسیرهای فایل
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/DaggerConnect"
SYSTEMD_DIR="/etc/systemd/system"

# --- منبع دانلود اختصاصی تو ---
# اینجا لینک فایل پچ شده خودت را گذاشتم
BINARY_URL="https://github.com/Alfred-1313/daggerConnect/releases/download/v1.0.0/DaggerConnect"

show_banner() {
    echo -e "${CYAN}***************************************${NC}"
    echo -e "${GREEN}    DaggerConnect (Unlocked Edition)   ${NC}"
    echo -e "${CYAN}       Patched by Alfred-1313          ${NC}"
    echo -e "${CYAN}***************************************${NC}"
}

# نصب پیش‌نیازها
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    apt update -qq && apt install -y wget curl openssl iproute2 > /dev/null 2>&1
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# دانلود فایل پچ شده
download_binary() {
    echo -e "${YELLOW}⬇️  Downloading Patched DaggerConnect...${NC}"
    if wget -q --show-progress "$BINARY_URL" -O "$INSTALL_DIR/DaggerConnect"; then
        chmod +x "$INSTALL_DIR/DaggerConnect"
        echo -e "${GREEN}✓ Download complete (License Bypassed)${NC}"
    else
        echo -e "${RED}✖ Failed to download from your GitHub!${NC}"
        exit 1
    fi
}

# بهینه‌سازی سیستم (بسیار مهم برای پینگ و پایداری)
optimize_system() {
    echo -e "${YELLOW}🚀 Optimizing TCP & BBR for Tunnel...${NC}"
    # فعال‌سازی BBR و بهینه‌سازی بافرهای شبکه
    cat > /etc/sysctl.d/99-daggerconnect.conf << 'EOF'
net.core.rmem_max=8388608
net.core.wmem_max=8388608
net.ipv4.tcp_rmem=4096 65536 8388608
net.ipv4.tcp_wmem=4096 65536 8388608
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq_codel
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_low_latency=1
EOF
    sysctl -p /etc/sysctl.d/99-daggerconnect.conf > /dev/null 2>&1
    echo -e "${GREEN}✓ System Optimized for Iran-Germany Tunnel${NC}"
}

# ساخت سرویس برای اجرای خودکار
create_service() {
    local MODE=$1
    cat > "$SYSTEMD_DIR/dagger.service" << EOF
[Unit]
Description=DaggerConnect Unlocked ($MODE)
After=network.target

[Service]
ExecStart=$INSTALL_DIR/DaggerConnect -c $CONFIG_DIR/config.yaml
Restart=always
User=root
WorkingDirectory=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now dagger
}

# منوی اصلی
main_menu() {
    clear
    show_banner
    echo "1) Install Server (Germany/Foreign)"
    echo "2) Install Client (Iran)"
    echo "3) System Optimizer (BBR & TCP)"
    echo "4) Show Status & Logs"
    echo "5) Uninstall"
    echo "0) Exit"
    echo ""
    read -p "Select: " choice

    case $choice in
        1)
            install_dependencies
            download_binary
            # اینجا دستور ساخت کانفیگ را اجرا می‌کند
            $INSTALL_DIR/DaggerConnect -gen server
            mv *.yaml "$CONFIG_DIR/config.yaml" 2>/dev/null
            create_service "Server"
            echo -e "${GREEN}Server is running! Edit config at $CONFIG_DIR/config.yaml${NC}"
            ;;
        2)
            install_dependencies
            download_binary
            $INSTALL_DIR/DaggerConnect -gen client
            mv *.yaml "$CONFIG_DIR/config.yaml" 2>/dev/null
            create_service "Client"
            echo -e "${GREEN}Client is running! Edit config at $CONFIG_DIR/config.yaml${NC}"
            ;;
        3) optimize_system ;;
        4) systemctl status dagger ;;
        5) 
            systemctl stop dagger
            rm -f "$INSTALL_DIR/DaggerConnect"
            rm -rf "$CONFIG_DIR"
            echo "Uninstalled."
            ;;
        0) exit 0 ;;
    esac
}

# شروع اسکریپت
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Please run as root!${NC}"
   exit 1
fi

main_menu
