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

# SOCKS5代理服务器 (sing-box内核版)

这是一个基于sing-box内核的SOCKS5代理服务器安装和管理脚本，适用于各种Linux系统，特别优化了在NAT VPS上的性能。

## 功能特点

- 基于高性能的sing-box内核
- 支持用户名/密码认证
- 自动优化系统参数
- 支持BBR加速
- 完整的管理界面
- 快捷命令支持
- 自动更新功能
- DNS优化选项

## 安装方法

```bash
# 下载脚本
bash <(curl -Ls https://raw.githubusercontent.com/dj56959566/vps/refs/heads/main/s5.sh)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/dj56959566/vps/refs/heads/main/singbox_socks5_all_in_one)

# 添加执行权限
chmod +x singbox_socks5.sh

# 运行脚本
./singbox_socks5.sh
```

## 使用方法

安装完成后，可以通过以下方式使用：

1. 在终端中输入 `s` 命令打开管理菜单
2. 使用生成的连接字符串在客户端配置代理

## 管理菜单选项

- 安装/卸载SOCKS5代理
- 查看代理状态
- 重启代理服务
- 查看代理日志
- 修改代理配置（端口/用户名/密码）
- 更新sing-box内核
- 更新脚本
- 检测/开启BBR
- 系统优化检测
- DNS优化选项

## 主要改进

本脚本相比原始版本有以下改进：

1. 修复了快捷命令`s`在任何目录下都能正常工作
2. 优化了系统参数配置
3. 增强了错误处理和异常情况的恢复
4. 改进了用户界面和提示信息
5. 添加了更多的配置选项和功能

## 系统要求

- 支持systemd的Linux系统
- root权限
- curl或wget工具
- 建议内存至少128MB

## 注意事项

- 脚本会自动设置系统参数，如果您有特殊的系统配置，请先备份
- 默认使用随机端口，避免常见端口被封
- 建议开启BBR加速以获得更好的性能


