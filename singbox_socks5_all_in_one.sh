#!/bin/bash
# ================================================
# SOCKS5 脚本 (sing-box内核版 for NAT VPS & IPv4 优先)
# 作者: Djkyc
# 改进: CodeBuddy
# 版本: 1.3 (NAT VPS 优化版)
# ================================================

WORKDIR="/opt/singbox"
SERVICE_NAME="singbox"
INFO_FILE="$WORKDIR/info"
CONFIG_FILE="$WORKDIR/config"
SINGBOX_CONFIG="$WORKDIR/config.json"
SINGBOX_VERSION="1.7.0" # 可以根据需要更新版本
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

# ================================================
# 系统资源检测与优化
# ================================================

# 检测系统资源
check_system_resources() {
    echo -e "${GREEN}[系统检测] 正在检测系统资源...${RESET}"
    
    # 检测内存
    MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    MEM_FREE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo $MEM_FREE)
    MEM_TOTAL_MB=$((MEM_TOTAL/1024))
    MEM_AVAILABLE_MB=$((MEM_AVAILABLE/1024))
    
    # 检测CPU
    CPU_CORES=$(grep -c processor /proc/cpuinfo)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')
    
    # 检测磁盘
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
    
    # 检测系统负载
    LOAD=$(cat /proc/loadavg | awk '{print $1,$2,$3}')
    
    echo -e "${GREEN}[系统信息]${RESET}"
    echo -e "${GREEN}CPU: ${CPU_CORES}核 (${CPU_MODEL})${RESET}"
    echo -e "${GREEN}内存: 总计${MEM_TOTAL_MB}MB, 可用${MEM_AVAILABLE_MB}MB${RESET}"
    echo -e "${GREEN}磁盘: 总计${DISK_TOTAL}, 可用${DISK_AVAIL}${RESET}"
    echo -e "${GREEN}系统负载: ${LOAD}${RESET}"
    
    # 内存不足警告
    if [ $MEM_TOTAL_MB -lt 512 ]; then
        echo -e "${YELLOW}[警告] 检测到系统内存较低 (${MEM_TOTAL_MB}MB)${RESET}"
        echo -e "${YELLOW}将采用低内存模式安装，减少资源占用${RESET}"
        LOW_MEM_MODE=1
    else
        LOW_MEM_MODE=0
    fi
    
    # 返回低内存模式标志
    return $LOW_MEM_MODE
}

# 创建工作目录
mkdir -p $WORKDIR

# ================================================
# 基础功能函数
# ================================================

# 随机端口生成，避免冲突
gen_port() {
    while :; do
        PORT=$((RANDOM % 40000 + 10000))
        if ! ss -tuln | grep -q ":$PORT "; then
            echo $PORT
            return
        fi
    done
}

# 随机用户名密码生成
gen_credentials() {
    # 确保配置目录存在
    mkdir -p $WORKDIR
    
    # 创建或清空配置文件
    > $CONFIG_FILE
    
    # 生成随机凭据
    USERNAME=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
    PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)
    
    # 写入配置
    echo "USERNAME=$USERNAME" >> $CONFIG_FILE
    echo "PASSWORD=$PASSWORD" >> $CONFIG_FILE
}

# 检测 IPv4 优先
get_public_ip() {
    echo -e "${GREEN}[网络] 正在获取公网IP...${RESET}"
    
    # 先尝试IPv4
    IPv4=$(curl -4 -s --connect-timeout 5 https://ipv4.icanhazip.com || curl -4 -s --connect-timeout 5 https://api.ipify.org)
    
    # 如果IPv4获取失败，再尝试IPv6
    if [[ -z "$IPv4" ]]; then
        echo -e "${YELLOW}[网络] IPv4获取失败，尝试IPv6...${RESET}"
        IPv6=$(curl -6 -s --connect-timeout 5 https://ipv6.icanhazip.com || curl -6 -s --connect-timeout 5 https://api64.ipify.org)
        if [[ -n "$IPv6" ]]; then
            echo -e "${GREEN}[网络] 获取到IPv6地址: ${IPv6}${RESET}"
            echo "$IPv6"
        else
            echo -e "${RED}[错误] 无法获取公网IP${RESET}"
            return 1
        fi
    else
        echo -e "${GREEN}[网络] 获取到IPv4地址: ${IPv4}${RESET}"
        echo "$IPv4"
    fi
}

# ================================================
# 系统优化功能
# ================================================

# 检测 NAT VPS 内存/CPU，推荐并发配置
optimize_sysctl() {
    echo -e "${GREEN}[系统优化] 正在根据系统资源优化网络参数...${RESET}"
    
    MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    CPU_CORES=$(grep -c processor /proc/cpuinfo)
    
    # 根据内存和CPU核心数优化并发连接数
    if [[ $MEM -lt 65536 ]]; then
        MAX_CONN=30
        RECOMMEND="建议并发 < 30"
    elif [[ $MEM -lt 131072 ]]; then
        MAX_CONN=80
        RECOMMEND="建议并发 < 80"
    elif [[ $MEM -lt 262144 ]]; then
        MAX_CONN=150
        RECOMMEND="建议并发 < 150"
    else
        MAX_CONN=300
        RECOMMEND="建议并发 < 300"
    fi
    
    # 系统参数优化 - 针对小内存VPS调整参数
    cat > /etc/sysctl.d/99-singbox-optimize.conf <<EOF
# 增加打开文件数限制
fs.file-max = 51200

# 网络栈优化 - 针对小内存VPS调整
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 1000
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10000 65000

# 内存优化
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

    # 应用系统参数 - 使用安静模式避免大量输出
    sysctl -q -p /etc/sysctl.d/99-singbox-optimize.conf
    
    # 设置系统最大打开文件数
    if ! grep -q "* soft nofile 51200" /etc/security/limits.conf; then
        echo "* soft nofile 51200" >> /etc/security/limits.conf
        echo "* hard nofile 51200" >> /etc/security/limits.conf
    fi
    
    echo -e "${GREEN}[系统优化] 内存: $((MEM/1024))MB, CPU: ${CPU_CORES}核, ${RECOMMEND}${RESET}"
    echo -e "${GREEN}[系统优化] 已优化系统参数，最大连接数设置为: ${MAX_CONN}${RESET}"
    
    # 更新配置文件
    echo "MAX_CONN=$MAX_CONN" >> $CONFIG_FILE
}

# 检测是否启用 BBR
check_bbr() {
    if lsmod | grep -q bbr; then
        echo -e "${GREEN}BBR 已启用${RESET}"
        return 0
    else
        echo -e "${YELLOW}BBR 未启用，可在菜单选择开启${RESET}"
        return 1
    fi
}

# 启用 BBR
enable_bbr() {
    if check_bbr; then
        echo -e "${GREEN}BBR 已经启用，无需再次开启${RESET}"
        return
    fi
    
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    
    if lsmod | grep -q bbr; then
        echo -e "${GREEN}BBR 已成功启用${RESET}"
    else
        echo -e "${YELLOW}BBR 启用配置已写入，请重启 VPS 生效${RESET}"
    fi
}

# ================================================
# DNS 管理功能
# ================================================

# 检查DNS状态
check_dns_status() {
    echo -e "${GREEN}当前DNS配置:${RESET}"
    
    # 检查resolv.conf是否被锁定
    if lsattr /etc/resolv.conf 2>/dev/null | grep -q 'i'; then
        echo -e "${YELLOW}resolv.conf 已被锁定 (使用chattr -i解锁)${RESET}"
    fi
    
    # 显示当前DNS服务器
    echo -e "${GREEN}DNS服务器:${RESET}"
    grep "^nameserver" /etc/resolv.conf | while read line; do
        echo -e "  ${YELLOW}$line${RESET}"
    done
    
    # 检查是否使用CloudFlare DNS
    if grep -q "nameserver 1.1.1.1" /etc/resolv.conf; then
        echo -e "${GREEN}当前使用: CloudFlare DNS${RESET}"
    elif grep -q "nameserver 8.8.8.8" /etc/resolv.conf; then
        echo -e "${GREEN}当前使用: Google DNS${RESET}"
    elif grep -q "nameserver 127.0.0.53" /etc/resolv.conf; then
        echo -e "${GREEN}当前使用: 系统解析器 (systemd-resolved)${RESET}"
    else
        echo -e "${GREEN}当前使用: 其他DNS${RESET}"
    fi
}

# 更换DNS为CloudFlare DNS
change_dns_to_cloudflare() {
    echo -e "${GREEN}正在更换系统DNS为CloudFlare DNS...${RESET}"
    
    # 备份当前的resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf /etc/resolv.conf.bak
    fi
    
    # 解除文件锁定(如果有)
    chattr -i /etc/resolv.conf 2>/dev/null
    
    # 写入CloudFlare DNS
    cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
options timeout:2 attempts:3 rotate single-request-reopen
EOF
    
    # 防止自动覆盖
    chattr +i /etc/resolv.conf 2>/dev/null
    
    # 检查是否成功
    if grep -q "1.1.1.1" /etc/resolv.conf; then
        echo -e "${GREEN}DNS已成功更换为CloudFlare DNS (1.1.1.1 和 1.0.0.1)${RESET}"
    else
        echo -e "${RED}DNS更换失败，请手动检查${RESET}"
    fi
}

# 更换DNS为Google DNS
change_dns_to_google() {
    echo -e "${GREEN}正在更换系统DNS为Google DNS...${RESET}"
    
    # 备份当前的resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf /etc/resolv.conf.bak
    fi
    
    # 解除文件锁定(如果有)
    chattr -i /etc/resolv.conf 2>/dev/null
    
    # 写入Google DNS
    cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2 attempts:3 rotate single-request-reopen
EOF
    
    # 防止自动覆盖
    chattr +i /etc/resolv.conf 2>/dev/null
    
    # 检查是否成功
    if grep -q "8.8.8.8" /etc/resolv.conf; then
        echo -e "${GREEN}DNS已成功更换为Google DNS (8.8.8.8 和 8.8.4.4)${RESET}"
    else
        echo -e "${RED}DNS更换失败，请手动检查${RESET}"
    fi
}

# 恢复原始DNS
restore_original_dns() {
    echo -e "${GREEN}正在恢复原始DNS设置...${RESET}"
    
    # 解除文件锁定
    chattr -i /etc/resolv.conf 2>/dev/null
    
    # 恢复备份
    if [[ -f /etc/resolv.conf.bak ]]; then
        mv /etc/resolv.conf.bak /etc/resolv.conf
        echo -e "${GREEN}已恢复原始DNS设置${RESET}"
    else
        echo -e "${YELLOW}未找到DNS备份，将使用默认设置${RESET}"
        cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    fi
}

# ================================================
# sing-box 安装与管理
# ================================================

# 安装依赖 - 分步安装以减少内存占用
install_dependencies() {
    echo -e "${GREEN}[安装] 正在检查并安装必要依赖...${RESET}"
    
    # 检查是否为低内存模式
    check_system_resources
    LOW_MEM_MODE=$?
    
    # 更新软件源索引 - 使用安静模式减少输出
    echo -e "${GREEN}[安装] 更新软件源...${RESET}"
    apt-get update -qq
    
    # 分步安装依赖，每次安装一个包以减少内存占用
    echo -e "${GREEN}[安装] 安装curl...${RESET}"
    apt-get install -y curl
    
    echo -e "${GREEN}[安装] 安装wget...${RESET}"
    apt-get install -y wget
    
    echo -e "${GREEN}[安装] 安装unzip...${RESET}"
    apt-get install -y unzip
    
    echo -e "${GREEN}[安装] 安装net-tools...${RESET}"
    apt-get install -y net-tools
    
    echo -e "${GREEN}[安装] 安装dnsutils...${RESET}"
    apt-get install -y dnsutils
    
    echo -e "${GREEN}[安装] 所有依赖安装完成${RESET}"
}

# 下载并安装sing-box - 优化下载过程
download_singbox() {
    echo -e "${GREEN}[安装] 正在下载sing-box...${RESET}"
    
    # 检测系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            echo -e "${RED}不支持的系统架构: $ARCH${RESET}"
            return 1
            ;;
    esac
    
    # 创建临时目录
    mkdir -p $WORKDIR/bin
    
    # 下载sing-box - 使用进度条显示下载进度
    DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz"
    echo -e "${GREEN}[下载] 从 ${DOWNLOAD_URL} 下载...${RESET}"
    
    # 使用wget显示进度条，但减少其他输出
    if ! wget --progress=bar:force -O /tmp/sing-box.tar.gz $DOWNLOAD_URL 2>&1; then
        echo -e "${RED}下载sing-box失败，请检查网络连接或版本号${RESET}"
        echo -e "${YELLOW}尝试备用下载方法...${RESET}"
        
        # 备用下载方法 - 使用curl
        if ! curl -L --progress-bar -o /tmp/sing-box.tar.gz $DOWNLOAD_URL; then
            echo -e "${RED}备用下载也失败，无法继续安装${RESET}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}[安装] 下载完成，正在解压...${RESET}"
    
    # 解压并安装 - 使用安静模式减少输出
    tar -xzf /tmp/sing-box.tar.gz -C /tmp
    
    # 移动二进制文件
    mv /tmp/sing-box-${SINGBOX_VERSION}-linux-${ARCH}/sing-box $WORKDIR/bin/
    chmod +x $WORKDIR/bin/sing-box
    
    # 清理临时文件
    rm -rf /tmp/sing-box.tar.gz /tmp/sing-box-${SINGBOX_VERSION}-linux-${ARCH}
    
    # 验证安装
    if [ -f "$WORKDIR/bin/sing-box" ]; 键，然后
        echo -e "${GREEN}sing-box 安装成功${RESET}"
        return 0
    else
        echo -e "${RED}sing-box 安装失败${RESET}"
        return 1
    fi
}

# 创建sing-box配置文件
create_singbox_config() {
    PORT=$1
    USERNAME=$2
    PASSWORD=$3
    
    # 检查是否为低内存模式
    check_system_resources
    LOW_MEM_MODE=$?
    
    # 根据内存情况调整配置
    if [ $LOW_MEM_MODE -eq 1 ]; then
        # 低内存模式配置 - 减少缓冲区大小和并发连接
        cat > $SINGBOX_CONFIG <<EOF
{
  "log": {
    "level": "error",
    "timestamp": true,
    "disabled": false
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "::",
      "listen_port": $PORT,
      "users": [
        {
          "username": "$USERNAME",
          "password": "$PASSWORD"
        }
      ],
      "sniff": false,
      "sniff_override_destination": false
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "experimental": {
    "cache_file": {
      "enabled": false
    }
  }
}
EOF
    else
        # 正常模式配置
        cat > $SINGBOX_CONFIG <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "::",
      "listen_port": $PORT,
      "users": [
        {
          "username": "$USERNAME",
          "password": "$PASSWORD"
        }
      ],
      "sniff": true,
      "sniff_override_destination": false
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF
    fi
}

# 安装 SOCKS5 - 优化安装流程
install_socks5() {
    # 检查是否已安装
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}sing-box 已经安装并运行中，如需重新安装请先卸载${RESET}"
        return
    fi
    
    # 检测系统资源
    check_system_resources
    LOW_MEM_MODE=$?
    
    # 安装依赖
    install_dependencies
    
    # 下载并安装sing-box
    download_singbox
    if [ $? -ne 0 ]; then
        return
    fi
    
    # 设置端口
    echo -ne "${YELLOW}请输入端口号 (10000-65535，回车使用随机端口): ${RESET}"
    read PORT_INPUT
    if [[ -z "$PORT_INPUT" ]]; then
        PORT=$(gen_port)
        echo -e "${GREEN}使用随机端口: ${PORT}${RESET}"
    elif [[ $PORT_INPUT =~ ^[0-9]+$ ]] && [[ $PORT_INPUT -ge 10000 ]] && [[ $PORT_INPUT -le 65535 ]]; then
        PORT=$PORT_INPUT
        echo -e "${GREEN}使用指定端口: ${PORT}${RESET}"
    else
        echo -e "${RED}无效的端口号，使用随机端口${RESET}"
        PORT=$(gen_port)
        echo -e "${GREEN}使用随机端口: ${PORT}${RESET}"
    fi
    
    # 设置用户名
    echo -ne "${YELLOW}请输入用户名 (回车使用随机用户名): ${RESET}"
    read USERNAME_INPUT
    if [[ -z "$USERNAME_INPUT" ]]; then
        USERNAME=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
        echo -e "${GREEN}使用随机用户名: ${USERNAME}${RESET}"
    else
        USERNAME=$USERNAME_INPUT
    fi
    
    # 设置密码
    echo -ne "${YELLOW}请输入密码 (回车使用随机密码): ${RESET}"
    read PASSWORD_INPUT
    if [[ -z "$PASSWORD_INPUT" ]]; then
        PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)
        echo -e "${GREEN}使用随机密码: ${PASSWORD}${RESET}"
    else
        PASSWORD=$PASSWORD_INPUT
    fi
    
    # 创建配置文件
    mkdir -p $WORKDIR
    echo "USERNAME=$USERNAME" > $CONFIG_FILE
    echo "PASSWORD=$PASSWORD" >> $CONFIG_FILE
    
    # 创建sing-box配置
    create_singbox_config $PORT $USERNAME $PASSWORD
    
    # 创建系统服务 - 根据内存情况调整服务配置
    if [ $LOW_MEM_MODE -eq 1 ]; then
        # 低内存模式服务配置
        cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=sing-box Service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
ExecStart=$WORKDIR/bin/sing-box run -c $SINGBOX_CONFIG
Restart=on-failure
RestartSec=10s
LimitNOFILE=51200
# 低内存模式资源限制
MemoryLimit=64M
CPUQuota=30%

[Install]
WantedBy=multi-user.target
EOF
    else
        # 正常模式服务配置
        cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=sing-box Service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
ExecStart=$WORKDIR/bin/sing-box run -c $SINGBOX_CONFIG
Restart=on-failure
RestartSec=10s
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF
    fi

    echo -e "${GREEN}[安装] 正在启动服务...${RESET}"
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME
    
    # 等待服务启动 - 增加超时检测
    echo -e "${GREEN}[安装] 等待服务启动...${RESET}"
    for i in {1..10}; do
        if systemctl is-active --quiet $SERVICE_NAME; then
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    
    # 检查服务状态
    if systemctl is-active --quiet $SERVICE_NAME; then
        # 保存连接信息
        PUBIP=$(get_public_ip)
        echo "IP=$PUBIP" > $INFO_FILE
        echo "PORT=$PORT" >> $INFO_FILE
        echo "USERNAME=$USERNAME" >> $INFO_FILE
        echo "PASSWORD=$PASSWORD" >> $INFO_FILE
        echo "INSTALL_DATE=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> $INFO_FILE
        
        echo -e "${GREEN}========================================${RESET}"
        echo -e "${GREEN}SOCKS5 代理安装成功!${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}服务器地址: ${PUBIP}${RESET}"
        echo -e "${GREEN}端口: ${PORT}${RESET}"
        echo -e "${GREEN}用户名: ${USERNAME}${RESET}"
        echo -e "${GREEN}密码: ${PASSWORD}${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}连接字符串: socks5://${USERNAME}:${PASSWORD}@${PUBIP}:${PORT}${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        echo -e "${GREEN}快捷命令: 输入 ${YELLOW}s${GREEN} 可随时打开此管理菜单${RESET}"
        echo -e "${GREEN}========================================${RESET}"
        
        # 系统优化
        optimize_sysctl
        
        # 设置快捷命令
        setup_shortcut
    else
        echo -e "${RED}SOCKS5 安装失败，请检查日志: journalctl -u $SERVICE_NAME${RESET}"
    fi
}

# 卸载 SOCKS5
uninstall_socks5() {
    echo -e "${YELLOW}正在卸载 sing-box...${RESET}"
    
    systemctl stop $SERVICE_NAME 2>/dev/null
    systemctl disable $SERVICE_NAME 2>/dev/null
    rm -f /etc/systemd/system/$SERVICE_NAME.service
    systemctl daemon-reload
    
    # 删除优化配置
    rm -f /etc/sysctl.d/99-singbox-optimize.conf
    
    # 删除工作目录
    rm -rf $WORKDIR
    
    # 删除快捷命令
    rm -f /usr/bin/s
    
    echo -e "${GREEN}sing-box 已完全卸载${RESET}"
}

# 查看状态 - 优化状态显示
check_status() {
    if [[ -f $INFO_FILE ]]; then
        # 使用安全的方式读取配置文件
        IP=$(grep "^IP=" $INFO_FILE | cut -d= -f2)
        PORT=$(grep "^PORT=" $INFO_FILE | cut -d= -f2)
        USERNAME=$(grep "^USERNAME=" $INFO_FILE | cut -d= -f2)
        PASSWORD=$(grep "^PASSWORD=" $INFO_FILE | cut -d= -f2)
        INSTALL_DATE=$(grep "^INSTALL_DATE=" $INFO_FILE | cut -d= -f2- | sed 's/^"//' | sed 's/"$//')
        
        # 读取配置文件中的其他参数
        if [[ -f $CONFIG_FILE ]]; then
            MAX_CONN=$(grep "^MAX_CONN=" $CONFIG_FILE | cut -d= -f2)
        fi
        
        echo -e "${GREEN}========================================${RESET}"
        echo -e "${GREEN}SOCKS5 代理状态 (sing-box)${RESET}"
        echo -e "${GREEN}----------------------------------------${RESET}"
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}运行状态: 正在运行${RESET}"
            
            # 显示连接信息
            echo -e "${GREEN}服务器地址: ${IP}${RESET}"
            echo -e "${GREEN}端口: ${PORT}${RESET}"
            echo -e "${GREEN}用户名: ${USERNAME}${RESET}"
            echo -e "${GREEN}密码: ${PASSWORD}${RESET}"
            echo -e "${GREEN}安装日期: ${INSTALL_DATE:-未知}${RESET}"
            
            # 显示sing-box版本
            if [[ -f "$WORKDIR/bin/sing-box" ]]; then
                CURRENT_VERSION=$($WORKDIR/bin/sing-box version 2>/dev/null | grep "sing-box version" | awk '{print $3}')
                echo -e "${GREEN}sing-box 版本: ${CURRENT_VERSION:-未知}${RESET}"
            fi
            
            # 显示系统负载 - 使用更安全的方式获取
            LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/,//g' 2>/dev/null || echo "未知")
            echo -e "${GREEN}系统负载: ${LOAD}${RESET}"
            
            # 显示内存使用 - 使用更安全的方式计算
            MEM_USED=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}' 2>/dev/null || echo "未知")
            echo -e "${GREEN}内存使用率: ${MEM_USED}${RESET}"
            
            # 显示当前DNS
            if grep -q "nameserver 1.1.1.1" /etc/resolv.conf 2>/dev/null; then
                echo -e "${GREEN}当前DNS: CloudFlare DNS${RESET}"
            elif grep -q "nameserver 8.8.8.8" /etc/resolv.conf 2>/dev/null; then
                echo -e "${GREEN}当前DNS: Google DNS${RESET}"
            elif grep -q "nameserver 127.0.0.53" /etc/resolv.conf 2>/dev/null; then
                echo -e "${GREEN}当前DNS: 系统默认 (127.0.0.53)${RESET}"
            else
                echo -e "${GREEN}当前DNS: 其他${RESET}"
            fi
            
            echo -e "${GREEN}----------------------------------------${RESET}"
            echo -e "${GREEN}连接字符串: socks5://${USERNAME}:${PASSWORD}@${IP}:${PORT}${RESET}"
        else
            echo -e "${RED}运行状态: 未运行${RESET}"
            echo -e "${YELLOW}请使用 '重启服务' 选项启动服务${RESET}"
        fi
        
        echo -e "${GREEN}========================================${RESET}"
    else
        echo -e "${RED}sing-box 未安装或配置文件丢失${RESET}"
    fi
}

# 重启服务 - 优化重启过程
restart_socks5() {
    if systemctl list-unit-files | grep -q $SERVICE_NAME; then
        echo -e "${GREEN}正在重启 sing-box 服务...${RESET}"
        systemctl restart $SERVICE_NAME
        
        # 等待服务启动 - 增加超时检测
        for i in {1..5}; do
            if systemctl is-active --quiet $SERVICE_NAME; then
                break
            fi
            echo -n "."
            sleep 1
        done
        echo ""
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}sing-box 服务已成功重启${RESET}"
        else
            echo -e "${RED}sing-box 服务重启失败，请检查日志: journalctl -u $SERVICE_NAME${RESET}"
        fi
    else
        echo -e "${RED}sing-box 服务未安装${RESET}"
    fi
}

# 查看日志 - 优化日志显示
view_logs() {
    echo -e "${GREEN}显示最近 50 行日志:${RESET}"
    
    # 检查服务是否存在
    if ! systemctl list-unit-files | grep -q $SERVICE_NAME; then
        echo -e "${RED}sing-box 服务未安装${RESET}"
        return
    fi
    
    # 使用安静模式显示日志
    journalctl -u $SERVICE_NAME -n 50 --no-pager
}

# 修改配置 - 优化配置修改流程
change_config() {
    if [[ ! -f $INFO_FILE ]]; then
        echo -e "${RED}sing-box 未安装或配置文件丢失${RESET}"
        return
    fi
    
    # 使用安全的方式读取配置文件
    IP=$(grep "^IP=" $INFO_FILE | cut -d= -f2)
    PORT=$(grep "^PORT=" $INFO_FILE | cut -d= -f2)
    USERNAME=$(grep "^USERNAME=" $INFO_FILE | cut -d= -f2)
    PASSWORD=$(grep "^PASSWORD=" $INFO_FILE | cut -d= -f2)
    
    echo -e "${GREEN}当前配置:${RESET}"
    echo -e "${GREEN}1. 端口: ${PORT}${RESET}"
    echo -e "${GREEN}2. 用户名: ${USERNAME}${RESET}"
    echo -e "${GREEN}3. 密码: ${PASSWORD}${RESET}"
    echo -e "${GREEN}4. 返回${RESET}"
    
    echo -ne "${YELLOW}请选择要修改的选项: ${RESET}"
    read config_choice
    
    case $config_choice in
        1)
            echo -ne "${YELLOW}请输入新端口 (10000-65535，回车使用随机端口): ${RESET}"
            read new_port
            if [[ -z "$new_port" ]]; then
                new_port=$(gen_port)
                echo -e "${GREEN}使用随机端口: ${new_port}${RESET}"
            elif [[ $new_port =~ ^[0-9]+$ ]] && [[ $new_port -ge 10000 ]] && [[ $new_port -le 65535 ]]; then
                echo -e "${GREEN}使用指定端口: ${new_port}${RESET}"
            else
                echo -e "${RED}无效的端口号，使用随机端口${RESET}"
                new_port=$(gen_port)
                echo -e "${GREEN}使用随机端口: ${new_port}${RESET}"
            fi
            
            sed -i "s/PORT=.*/PORT=$new_port/" $INFO_FILE
            # 更新sing-box配置
            create_singbox_config $new_port $USERNAME $PASSWORD
            echo -e "${GREEN}端口已修改为 ${new_port}${RESET}"
            restart_socks5
            ;;
        2)
            echo -ne "${YELLOW}请输入新用户名 (回车使用随机用户名): ${RESET}"
            read new_username
            if [[ -z "$new_username" ]]; then
                new_username=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
                echo -e "${GREEN}使用随机用户名: ${new_username}${RESET}"
            fi
            
            sed -i "s/USERNAME=.*/USERNAME=$new_username/" $INFO_FILE
            if [[ -f $CONFIG_FILE ]]; then
                sed -i "s/USERNAME=.*/USERNAME=$new_username/" $CONFIG_FILE
            fi
            # 更新sing-box配置
            create_singbox_config $PORT $new_username $PASSWORD
            echo -e "${GREEN}用户名已修改为 ${new_username}${RESET}"
            restart_socks5
            ;;
        3)
            echo -ne "${YELLOW}请输入新密码 (回车使用随机密码): ${RESET}"
            read new_password
            if [[ -z "$new_password" ]]; then
                new_password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)
                echo -e "${GREEN}使用随机密码: ${new_password}${RESET}"
            fi
            
            sed -i "s/PASSWORD=.*/PASSWORD=$new_password/" $INFO_FILE
            if [[ -f $CONFIG_FILE ]]; then
                sed -i "s/PASSWORD=.*/PASSWORD=$new_password/" $CONFIG_FILE
            fi
            # 更新sing-box配置
            create_singbox_config $PORT $USERNAME $new_password
            echo -e "${GREEN}密码已修改为 ${new_password}${RESET}"
            restart_socks5
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效选项${RESET}"
            ;;
    esac
}

# ================================================
# 更新功能
# ================================================

# 更新脚本 - 优化更新流程
update_script() {
    echo -e "${GREEN}正在检查脚本更新...${RESET}"
    
    # 获取脚本的绝对路径
    SCRIPT_PATH=$(readlink -f "$0")
    
    # 创建备份
    cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
    echo -e "${GREEN}已创建脚本备份: ${SCRIPT_PATH}.bak${RESET}"
    
    # 从GitHub获取最新版本
    echo -e "${GREEN}正在从GitHub下载最新版本...${RESET}"
    TEMP_SCRIPT="/tmp/singbox_socks5_new.sh"
    
    # 尝试使用curl下载 - 使用低资源模式
    if ! curl -s -L --connect-timeout 10 -o "$TEMP_SCRIPT" https://raw.githubusercontent.com/djkcyl/socks5-script/main/singbox_socks5_all_in_one.sh; then
        # 如果curl失败，尝试使用wget
        if ! wget -q --timeout=10 -O "$TEMP_SCRIPT" https://raw.githubusercontent.com/djkcyl/socks5-script/main/singbox_socks5_all_in_one.sh; then
            echo -e "${RED}下载失败，无法连接到GitHub${RESET}"
            echo -e "${YELLOW}您可以手动下载最新版本: https://github.com/djkcyl/socks5-script${RESET}"
            return 1
        fi
    fi
    
    # 检查下载是否成功
    if [[ -s "$TEMP_SCRIPT" ]]; then
        # 验证下载的文件是否为有效的bash脚本
        if grep -q "#!/bin/bash" "$TEMP_SCRIPT"; then
            # 替换当前脚本
            cat "$TEMP_SCRIPT" > "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            
            # 更新备份脚本
            mkdir -p $WORKDIR
            cp "$SCRIPT_PATH" "$WORKDIR/singbox_socks5.sh"
            chmod +x "$WORKDIR/singbox_socks5.sh"
            
            # 更新快捷命令
            setup_shortcut
            
            rm -f "$TEMP_SCRIPT"
            echo -e "${GREEN}脚本已更新成功！将在下次启动时生效${RESET}"
            echo -e "${GREEN}如需立即应用更新，请退出后重新运行脚本${RESET}"
        else
            echo -e "${RED}下载的文件不是有效的bash脚本，更新失败${RESET}"
            echo -e "${YELLOW}恢复备份中...${RESET}"
            cp "${SCRIPT_PATH}.bak" "$SCRIPT_PATH"
        fi
    else
        echo -e "${RED}下载的脚本内容为空，更新失败${RESET}"
        echo -e "${YELLOW}恢复备份中...${RESET}"
        cp "${SCRIPT_PATH}.bak" "$SCRIPT_PATH"
    fi
}

# 更新sing-box - 优化更新流程
update_singbox() {
    echo -e "${GREEN}正在检查sing-box更新...${RESET}"
    
    # 获取当前版本
    if [[ -f "$WORKDIR/bin/sing-box" ]]; then
        CURRENT_VERSION=$($WORKDIR/bin/sing-box version 2>/dev/null | grep "sing-box version" | awk '{print $3}')
        echo -e "${GREEN}当前版本: ${CURRENT_VERSION}${RESET}"
    else
        echo -e "${RED}sing-box未安装${RESET}"
        return
    fi
    
    # 获取最新版本 - 使用低资源模式
    echo -e "${GREEN}正在获取最新版本信息...${RESET}"
    LATEST_VERSION=$(curl -s --connect-timeout 10 https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4 | cut -c 2-)
    
    if [[ -z "$LATEST_VERSION" ]]; then
        echo -e "${RED}无法获取最新版本信息${RESET}"
        return
    fi
    
    echo -e "${GREEN}最新版本: ${LATEST_VERSION}${RESET}"
    
    # 比较版本
    if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
        echo -e "${GREEN}已经是最新版本${RESET}"
        return
    fi
    
    echo -ne "${YELLOW}是否更新到最新版本? (y/n): ${RESET}"
    read update_choice
    
    if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
        echo -e "${YELLOW}取消更新${RESET}"
        return
    fi
    
    # 停止服务
    echo -e "${GREEN}停止服务...${RESET}"
    systemctl stop $SERVICE_NAME
    
    # 备份当前配置
    cp $SINGBOX_CONFIG $SINGBOX_CONFIG.bak
    
    # 更新SINGBOX_VERSION变量
    SINGBOX_VERSION=$LATEST_VERSION
    
    # 下载并安装新版本
    download_singbox
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}更新失败，恢复原配置${RESET}"
        mv $SINGBOX_CONFIG.bak $SINGBOX_CONFIG
        systemctl start $SERVICE_NAME
        return
    fi
    
    # 启动服务
    echo -e "${GREEN}启动服务...${RESET}"
    systemctl start $SERVICE_NAME
    
    # 检查服务状态
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}sing-box 已成功更新到 ${LATEST_VERSION}${RESET}"
        rm -f $SINGBOX_CONFIG.bak
    else
        echo -e "${RED}更新后服务启动失败，恢复原配置${RESET}"
        mv $SINGBOX_CONFIG.bak $SINGBOX_CONFIG
        systemctl start $SERVICE_NAME
    fi
}

# ================================================
# 快捷命令设置
# ================================================

# 设置快捷命令 s
setup_shortcut() {
    # 确保工作目录存在
    mkdir -p "$WORKDIR"
    
    # 获取当前脚本的绝对路径
    CURRENT_SCRIPT=$(readlink -f "$0")
    
    # 复制脚本到固定位置
    cp "$CURRENT_SCRIPT" "$WORKDIR/singbox_socks5.sh"
    chmod +x "$WORKDIR/singbox_socks5.sh"
    
    # 创建快捷命令脚本 - 使用绝对路径并添加错误处理
    cat > /usr/bin/s <<'EOF'
#!/bin/bash
# 快捷命令 - SOCKS5代理管理脚本
SCRIPT_PATH="/opt/singbox/singbox_socks5.sh"

if [ -f "$SCRIPT_PATH" ]; then
    bash "$SCRIPT_PATH"
else
    echo -e "\033[0;31m错误: 找不到SOCKS5管理脚本\033[0m"
    echo -e "\033[0;33m尝试修复中...\033[0m"
    
    # 尝试从当前目录查找脚本
    CURRENT_DIR=$(pwd)
    if [ -f "$CURRENT_DIR/singbox_socks5_all_in_one.sh" ]; then
        echo -e "\033[0;32m找到脚本，正在修复...\033[0m"
        mkdir -p /opt/singbox
        cp "$CURRENT_DIR/singbox_socks5_all_in_one.sh" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "\033[0;32m修复成功，正在启动...\033[0m"
        bash "$SCRIPT_PATH"
    else
        echo -e "\033[0;31m无法自动修复，请重新安装脚本\033[0m"
        echo -e "\033[0;33m可以使用以下命令重新安装:\033[0m"
        echo -e "\033[0;33mbash <(curl -Ls https://raw.githubusercontent.com/djkcyl/socks5-script/main/singbox_socks5_all_in_one.sh)\033[0m"
    fi
fi
EOF
    chmod +x /usr/bin/s
    
    echo -e "${GREEN}快捷命令 's' 已设置，您可以随时输入 's' 打开此菜单${RESET}"
}

# ================================================
# 主菜单
# ================================================

# 菜单 - 优化显示
menu() {
    clear
    echo -e "${GREEN}"
    echo -e "  ____  _              ____            "
    echo -e " / ___|(_)_ __   __ _ | __ )  _____  __"
    echo -e "  \___ \| | '_ \ / _\` ||  _ \ / _ \ \/ /"
    echo -e "  ___) | | | | | (_| || |_) | (_) >  < "
    echo -e " |____/|_|_| |_|\__, ||____/ \___/_/\_\\"
    echo -e "                |___/                  "
    echo -e "  SOCKS5 代理管理面板 v1.3 (NAT VPS 优化版) "
    echo -e "     快捷命令: 输入 ${YELLOW}s${GREEN} 打开此菜单     "
    echo -e "===================================="
    
    # 检查系统资源
    check_system_resources
    LOW_MEM_MODE=$?
    
    # 检查是否已安装
    if systemctl is-active --quiet $SERVICE_NAME; then
        # 使用安全的方式读取配置文件
        if [[ -f $INFO_FILE ]]; then
            IP=$(grep "^IP=" $INFO_FILE | cut -d= -f2)
            PORT=$(grep "^PORT=" $INFO_FILE | cut -d= -f2)
            echo -e "${GREEN}状态: 运行中 - ${IP}:${PORT}${RESET}"
        else
            echo -e "${GREEN}状态: 运行中${RESET}"
        fi
        
        # 显示当前DNS
        if grep -q "nameserver 1.1.1.1" /etc/resolv.conf 2>/dev/null; then
            echo -e "${GREEN}当前DNS: CloudFlare DNS${RESET}"
        elif grep -q "nameserver 8.8.8.8" /etc/resolv.conf 2>/dev/null; then
            echo -e "${GREEN}当前DNS: Google DNS${RESET}"
        elif grep -q "nameserver 127.0.0.53" /etc/resolv.conf 2>/dev/null; then
            echo -e "${GREEN}当前DNS: 系统默认 (127.0.0.53)${RESET}"
        else
            echo -e "${GREEN}当前DNS: 其他${RESET}"
        fi
        
        # 显示内存模式
        if [ $LOW_MEM_MODE -eq 1 ]; then
            echo -e "${YELLOW}运行模式: 低内存模式${RESET}"
        fi
    elif systemctl list-unit-files | grep -q $SERVICE_NAME; then
        echo -e "${RED}状态: 已安装但未运行${RESET}"
    else
        echo -e "${YELLOW}状态: 未安装${RESET}"
        
        # 显示内存模式
        if [ $LOW_MEM_MODE -eq 1 ]; then
            echo -e "${YELLOW}安装模式: 将使用低内存模式${RESET}"
        fi
    fi
    
    echo "===================================="
    echo "1. 安装 SOCKS5 代理"
    echo "2. 卸载 SOCKS5 代理"
    echo "3. 查看代理状态"
    echo "4. 重启代理服务"
    echo "5. 查看代理日志"
    echo "6. 修改代理配置"
    echo "7. 更新 sing-box"
    echo "8. 更新脚本"
    echo "9. 检测/开启 BBR"
    echo "10. 系统优化检测"
    echo "11. DNS管理"
    echo "12. 退出"
    echo

    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read choice
    case $choice in
        1) install_socks5 ;;
        2) uninstall_socks5 ;;
        3) check_status ;;
        4) restart_socks5 ;;
        5) view_logs ;;
        6) change_config ;;
        7) update_singbox ;;
        8) update_script ;;
        9) check_bbr; echo -ne "${YELLOW}是否启用 BBR? (y/n): ${RESET}"; read yn; [[ $yn == y || $yn == Y ]] && enable_bbr ;;
        10) optimize_sysctl ;;
        11) dns_menu ;;
        12) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
    echo
    echo -ne "${GREEN}按回车继续...${RESET}"
    read
    menu
}

# DNS管理菜单
dns_menu() {
    clear
    echo -e "${GREEN}"
    echo -e "  DNS 管理菜单"
    echo -e "===================================="
    
    # 显示当前DNS
    if grep -q "nameserver 1.1.1.1" /etc/resolv.conf 2>/dev/null; then
        echo -e "${GREEN}当前DNS: CloudFlare DNS${RESET}"
    elif grep -q "nameserver 8.8.8.8" /etc/resolv.conf 2>/dev/null; then
        echo -e "${GREEN}当前DNS: Google DNS${RESET}"
    elif grep -q "nameserver 127.0.0.53" /etc/resolv.conf 2>/dev/null; then
        echo -e "${GREEN}当前DNS: 系统默认 (127.0.0.53)${RESET}"
    else
        echo -e "${GREEN}当前DNS: 其他${RESET}"
    fi
    
    echo "===================================="
    echo "1. 查看DNS状态"
    echo "2. 更换为CloudFlare DNS (1.1.1.1)"
    echo "3. 更换为Google DNS (8.8.8.8)"
    echo "4. 恢复原始DNS"
    echo "5. 返回主菜单"
    echo

    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read choice
    case $choice in
        1) check_dns_status ;;
        2) change_dns_to_cloudflare ;;
        3) change_dns_to_google ;;
        4) restore_original_dns ;;
        5) return ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
    echo
    echo -ne "${GREEN}按回车继续...${RESET}"
    read
    dns_menu
}

# ================================================
# 主程序入口
# ================================================

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}错误: 此脚本必须以root用户身份运行${RESET}"
    exit 1
fi

# 设置快捷命令 s (如果不存在)
if [[ ! -f /usr/bin/s ]]; then
    setup_shortcut
else
    # 确保快捷命令指向正确的脚本
    setup_shortcut
fi

# 主程序入口
menu
