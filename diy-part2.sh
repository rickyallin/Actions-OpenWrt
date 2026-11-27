#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 1. 修改默认后台 IP 为 192.168.8.1
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# 2. 彻底剥离 SSR Plus+ 对 xray-core 及冗余组件的强制依赖
SSR_MK="feeds/helloworld/luci-app-ssr-plus/Makefile"
if [ -f "$SSR_MK" ]; then
    sed -i 's/+xray-core//g' "$SSR_MK"
    sed -i 's/default y.*/default n/g' "$SSR_MK"
    rm -rf tmp
fi

# 3. 强制关闭编译并剔除多余默认包（释放 6MB+ 闪存与内存）
cat << 'EOF' >> .config
CONFIG_PACKAGE_xray-core=n
CONFIG_PACKAGE_v2ray-core=n
CONFIG_PACKAGE_trojan=n
CONFIG_PACKAGE_chinadns-ng=n
CONFIG_PACKAGE_dns2socks=n
CONFIG_PACKAGE_dns2tcp=n
CONFIG_PACKAGE_simple-obfs=n
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=n
CONFIG_PACKAGE_shadowsocksr-libev-ssr-redir=n
CONFIG_PACKAGE_shadowsocksr-libev-ssr-check=n
CONFIG_PACKAGE_shadowsocks-rust-sslocal=n
CONFIG_PACKAGE_hysteria=n
CONFIG_PACKAGE_naiveproxy=n
CONFIG_PACKAGE_luci-app-vsftpd=n
CONFIG_PACKAGE_vsftpd=n
CONFIG_PACKAGE_ddns-scripts=n
CONFIG_PACKAGE_ddns-scripts-services=n
CONFIG_PACKAGE_ddns-scripts_aliyun=n
CONFIG_PACKAGE_ddns-scripts_dnspod=n
CONFIG_PACKAGE_luci-theme-design=n
CONFIG_PACKAGE_luci-app-filetransfer=n
CONFIG_PACKAGE_luci-app-autoreboot=n
CONFIG_PACKAGE_nping=n
EOF

# 4. 植入 1KB Xray 动态拉取脚本（从 fastly 加速节点下载 UPX 压缩版核心至内存 /tmp）
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/xray
#!/bin/sh
if [ ! -f /tmp/xray ]; then
    while ! (curl -sfLk --connect-timeout 10 -m 60 -o /tmp/xray https://fastly.jsdelivr.net/gh/rickyallin/Backup@main/mt7620_mt7621_upx/xray); do
        sleep 2
    done
    chmod +x /tmp/xray
fi
exec /tmp/xray $@
EOF
chmod +x files/usr/bin/xray

# 5. 将 45MB 内存上限直接写入 SSR Plus+ 启动脚本，防止 128MB 内存溢出
sed -i '2i export GOMEMLIMIT=45MiB' feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
