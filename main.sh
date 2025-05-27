#!/bin/bash

# رنگ‌ها برای خروجی
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # بدون رنگ

# 1. آپدیت و آپگرید سیستم با تأیید خودکار
echo -e "${GREEN}Updating and upgrading the system...${NC}"
sudo apt update && sudo apt upgrade -y --force-confdef --force-confold
if [ $? -eq 0 ]; then
    echo -e "${GREEN}System update and upgrade completed successfully.${NC}"
else
    echo -e "${RED}Error during system update or upgrade. Exiting.${NC}"
    exit 1
fi

# 2. نصب نرم‌افزارهای ضروری با تأیید خودکار
echo -e "${GREEN}Installing essential software...${NC}"
sudo apt install -y tmux nano htop curl wget git unzip net-tools ufw
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Essential software installed successfully.${NC}"
else
    echo -e "${RED}Error installing essential software. Exiting.${NC}"
    exit 1
fi

# 3. استخراج آدرس IP عمومی
echo -e "${GREEN}Fetching public IP address...${NC}"
PUBLIC_IP=$(curl -s ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}Failed to fetch public IP. Exiting.${NC}"
    exit 1
fi
echo -e "${GREEN}Public IP detected: $PUBLIC_IP${NC}"

# 5. ویرایش فایل /etc/hosts با خروجی hostname
echo -e "${GREEN}Updating /etc/hosts file with hostname...${NC}"
HOSTNAME=$(hostname)
if ! grep -q "$HOSTNAME" /etc/hosts; then
    echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}/etc/hosts updated successfully with $HOSTNAME.${NC}"
        echo -e "${GREEN}Current /etc/hosts content:${NC}"
        cat /etc/hosts
    else
        echo -e "${RED}Error updating /etc/hosts. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Hostname $HOSTNAME already exists in /etc/hosts. Skipping update.${NC}"
fi

# 6. تنظیم منطقه زمانی به America/Los_Angeles (واشنگتن)
echo -e "${GREEN}Setting timezone to America/Los_Angeles (Washington)...${NC}"
sudo timedatectl set-timezone America/Los_Angeles
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Timezone set to America/Los_Angeles successfully.${NC}"
    date
else
    echo -e "${RED}Error setting timezone. Continuing with default.${NC}"
fi

# 7. ریستارت تمام سرویس‌ها
echo -e "${GREEN}Restarting all services...${NC}"
sudo systemctl restart networking
sudo systemctl restart ssh
sudo systemctl restart docker 2>/dev/null || true # اگر نصب نباشد، خطا نادیده گرفته شود
sudo systemctl restart apache2 2>/dev/null || true
sudo systemctl restart nginx 2>/dev/null || true
echo -e "${GREEN}Services restarted. System will reboot in 5 seconds...${NC}"
sleep 5
sudo reboot
