# 2024-2025 VPS检查身体配置 常用脚本
<a href="https://github.com/adysec/script/stargazers"><img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/adysec/script?color=yellow&logo=riseup&logoColor=yellow&style=flat-square"></a>
<a href="https://github.com/adysec/script/network/members"><img alt="GitHub forks" src="https://img.shields.io/github/forks/adysec/script?color=orange&style=flat-square"></a>
<a href="https://github.com/adysec/script/issues"><img alt="GitHub issues" src="https://img.shields.io/github/issues/adysec/script?color=red&style=flat-square"></a>

## VPS性能测试

```
#VPS基本信息、IO性能、全球测速
wget -qO- bench.sh | bash
#VPS基本信息、IO性能、国内测速
bash <(curl -Lso- git.io/superbench.sh)
#VPS基本信息、IO性能、国内外测速、Ping、路由测试
bash <(curl -Lso- https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh)
#IO测试、宽带测试、SpeedTest国内节点测试、世界各地下载速度测试、路由测试、回程路由测试、全国Ping测试、国外Ping测试、UnixBench跑分测试
wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/91yuntest/master/test.sh && bash test.sh -i "io,bandwidth,chinabw,download,traceroute,backtraceroute,allping"
```
## Mr.zou大佬写的脚本

```
#方便测试回程Ping值
#目前支持众多区域和各大运营商
wget https://raw.githubusercontent.com/helloxz/mping/master/mping.sh
```
## 秋水逸冰大佬的写的Bench.sh脚本
 
```
#显示当前测试的各种系统信息；
取自世界多处的知名数据中心的测试点，下载测试比较全面；
支持 IPv6 下载测速；
IO 测试三次，并显示平均值。
wget -qO- bench.sh | bash
#或者
curl -Lso- bench.sh | bash
#或者
wget -qO- 86.re/bench.sh | bash
#或者
curl -so- 86.re/bench.sh | bash
```
## 融合怪命令
```
#完全支持的系统	Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch
半支持系统	FreeBSD (前提已执行 pkg install -y curl bash)，Armbian
支持架构	amd64 (x86_64)、arm64、i386、arm
支持地域	能连得上网都支持。
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -m 1
```
## 老鬼大佬的SuperBench测试脚本
```
#改进了显示的模式，基本参数添加了颜色，方面区分与查找。
I/O测试，更改了原来默认的测试的内容，采用小文件，中等文件，大文件，分别测试IO性能，然后取平均值。
速度测试替换成了 Superspeed 里面的测试，第一个默认节点是，Speedtest 默认，其他分别测试到中国电信，联通，移动，各三个不同地区的速度。
wget -qO- git.io/superbench.sh | bash 
#或者
curl -Lso- git.io/superbench.sh | bash
#或者
wget -qO- oldking.net/superbench.sh | bash
```
## BBR加速

```
bash <(curl -Lso- https://github.com/teddysun/across/raw/master/bbr.sh)
```

## 三网测速

```
bash <(curl -Lso- https://raw.githubusercontent.com/uxh/superspeed/master/superspeed.sh)
```

## 线路测试

```
curl https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh -sSf | sh
bash <(curl -Lso- https://raw.githubusercontent.com/flyzy2005/shell/master/autoBestTrace.sh)
bash <(curl -Lso- https://raw.githubusercontent.com/nanqinlang-script/testrace/master/testrace.sh)
```

## IP质量检测

```
bash <(curl -Ls IP.Check.Place)
```

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

# SOCKS5 代理服务器脚本

这是一个用于快速部署和管理 SOCKS5 代理服务器的脚本，针对 NAT VPS 环境进行了优化，并提供了完整的用户认证和系统优化功能。

## 主要特性

- **用户认证**: 实现了完整的用户名/密码认证机制
- **IPv4/IPv6 支持**: 自动检测并优先使用 IPv4
- **系统优化**: 根据服务器内存和CPU自动优化系统参数
- **BBR 加速**: 内置 BBR 加速选项
- **连接限制**: 根据系统资源自动设置最大连接数
- **完整日志**: 详细的连接和错误日志记录
- **简易管理**: 通过菜单界面轻松管理代理服务

## 安装方法

```bash
# 下载脚本
wget -O socks5.sh https://raw.githubusercontent.com/dj56959566/vps/refs/heads/main/s5

# 添加执行权限
chmod +x socks5.sh

# 运行脚本
bash socks5.sh
```

或者使用一键安装命令:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/dj56959566/vps/refs/heads/main/s5)
```

## 使用方法

脚本提供了简单的菜单界面，包含以下功能:

1. **安装 SOCKS5 代理** - 自动安装并配置SOCKS5服务
2. **卸载 SOCKS5 代理** - 完全卸载SOCKS5服务
3. **查看代理状态** - 显示当前运行状态和连接信息
4. **重启代理服务** - 重新启动SOCKS5服务
5. **查看代理日志** - 显示最近的运行日志
6. **修改代理配置** - 修改端口、用户名、密码等配置
7. **检测/开启 BBR** - 检查并启用BBR加速
8. **系统优化检测** - 根据系统资源优化配置
9. **退出** - 退出脚本

安装完成后，可以使用快捷命令 `s5` 随时打开管理菜单。

## 连接信息

安装完成后，脚本会显示连接信息，包括:

- 服务器地址 (IP)
- 端口
- 用户名
- 密码
- 连接字符串

这些信息也可以通过 "查看代理状态" 选项随时查看。

## 系统要求

- 支持 systemd 的 Linux 系统 (如 Ubuntu, Debian, CentOS 7+)
- Python 3
- root 权限

## 安全说明

- 脚本会自动生成随机端口和认证信息，提高安全性
- 所有连接都需要用户名和密码认证
- 可以根据需要随时修改认证信息

## 改进说明

相比原始脚本，此版本进行了以下改进:

1. 添加了完整的用户名/密码认证机制
2. 修复了SOCKS5协议实现中的问题
3. 添加了详细的日志记录
4. 增加了连接限制和超时处理
5. 优化了系统参数配置
6. 增强了错误处理和异常恢复
7. 添加了更多管理功能

