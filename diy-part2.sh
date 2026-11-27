#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# 植入 1KB Xray 动态拉取脚本（从 fastly 加速节点下载 UPX 压缩版核心至内存 /tmp）
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

# 将 45MB 内存上限直接写入 SSR Plus+ 启动脚本，防止 128MB 内存溢出
sed -i '2i export GOMEMLIMIT=45MiB' feeds/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
