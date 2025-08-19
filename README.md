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
本项目对原始SOCKS5代理脚本进行了全面改进，提供了两个版本的实现：

1. **Python实现版** (`improved_socks5.sh`)
2. **sing-box内核版** (`singbox_socks5_final.sh`)

## 主要改进

### 共同改进
- 增强了用户认证机制
- 优化了系统参数配置
- 添加了BBR加速支持
- 改进了菜单界面和用户体验
- 添加了脚本自更新功能
- 扩大了端口范围(10000-65535)
- 添加了随机用户名密码生成
- 创建了快捷命令`s`
- 修复了原脚本中的安全漏洞

### Python实现版特有改进
- 重写了SOCKS5协议实现，修复了原始脚本中的协议错误
- 添加了连接限制功能
- 增强了日志记录
- 添加了超时处理

### sing-box内核版特有改进
- 使用高性能的sing-box作为代理内核
- 支持sing-box版本更新
- 添加了DNS优化配置
- 提供了更完善的配置修改选项

## 文件说明

- `improved_socks5.sh`: 改进的Python实现版SOCKS5代理脚本
- `singbox_socks5_final.sh`: 基于sing-box内核的SOCKS5代理脚本
- `README_singbox.md`: sing-box版本的详细说明文档
- `socks5_analysis.md`: 原始脚本分析报告

## 使用方法

两个版本的脚本都提供了简单的命令行界面，使用方法类似：

1. 下载脚本
2. 添加执行权限: `chmod +x 脚本名称.sh`
3. 运行脚本: `./脚本名称.sh`
4. 按照菜单提示进行操作

安装完成后，可以使用快捷命令 `s` 随时打开管理菜单。

## 推荐版本

推荐使用 **sing-box内核版**，因为它基于专业的代理工具sing-box，具有更好的性能和稳定性。

## 注意事项

- 脚本需要root权限运行
- 支持Debian/Ubuntu系统
- 默认安装路径为`/opt/socks5`(Python版)或`/opt/singbox`(sing-box版)
