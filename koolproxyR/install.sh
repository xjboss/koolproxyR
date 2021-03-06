#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export koolproxyR_`
# mkdir -p /tmp/upload

# 判断路由架构和平台
case $(uname -m) in
	armv7l)
		logger "本KoolProxyR插件用于koolshare OpenWRT/LEDE x86_64固件平台，arm平台不能安装！！！"
		logger "退出KoolProxyR安装！"
		exit 1
	;;
	mips)
		logger "本KoolProxyR插件用于koolshare OpenWRT/LEDE x86_64固件平台，mips平台不能安装！！！"
		logger "退出KoolProxyR安装！"！
		exit 1
	;;
	x86_64)
		fw867=`cat /etc/banner|grep fw867`
		if [ -d "/koolshare" ] && [ -n "$fw867" ];then
			logger "固件平台【koolshare OpenWRT/LEDE x86_64】符合安装要求，开始安装插件！"
		else
			logger "本KoolProxyR插件用于koolshare OpenWRT/LEDE x86_64固件平台，其它x86_64固件平台不能安装！！！"
			logger "退出KoolProxyR安装！"
			exit 1
		fi
	;;
  *)
		logger 本KoolProxyR插件用于koolshare OpenWRT/LEDE x86_64固件平台，其它平台不能安装！！！
  		logger "退出KoolProxyR安装！"
		exit 1
	;;
esac
# 感谢这位大佬的教程。
# https://www.linuxquestions.org/questions/debian-26/debian-hangs-at-boot-with-random-crng-init-done-4175613405/#post5889997
# 此举解决了kpr与v2ray冲突，与SS冲突，导致开机过慢的问题
# haveged 项目的目的是提供一个易用、不可预测的随机数生成器，基于 HAVEGE 算法。

entropy_avail=`cat /proc/sys/kernel/random/entropy_avail`

# 如果值比较低(<1000),建议安装 haveged. 否则加密程序会等待系统有足够的熵。

if [ "$entropy_avail" -lt 1000 ];then
	opkg update && opkg install haveged
fi
# stop first
KP_ENBALE=`dbus get koolproxy_enable`
koolproxyR_enable=`dbus get koolproxyR_enable`
[ "$KP_ENBALE" == "1" ] && sh $KSROOT/koolproxy/kp_config.sh stop >> /tmp/upload/kpr_log.txt
# 删除KP的二进制和核心配置文件。保留其他所有配置，避免小白两个都安装导致一些莫名其妙的问题。
rm -rf $KSROOT/koolproxy/kp_config.sh >/dev/null 2>&1
rm -rf $KSROOT/koolproxy/koolproxy >/dev/null 2>&1
[ "$koolproxyR_enable" == "1" ] && sh $KSROOT/koolproxyR/kpr_config.sh stop >> /tmp/upload/kpr_log.txt

# remove old files
rm -rf $KSROOT/bin/koolproxy >/dev/null 2>&1
rm -rf $KSROOT/scripts/KoolProxyR_* >/dev/null 2>&1
rm -rf $KSROOT/webs/Module_koolproxyR.asp >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/koolproxy >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/*.sh >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/data/gen_ca.sh >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/data/koolproxyR_ipset.conf >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/data/openssl.cnf >/dev/null 2>&1
rm -rf $KSROOT/koolproxyR/data/version >/dev/null 2>&1
mv $KSROOT/koolproxyR/data/rules/user.txt /tmp/user.txt.tmp
rm -rf $KSROOT/koolproxyR/data/rules/* >/dev/null 2>&1

# copy new files
cd /tmp
mkdir -p $KSROOT/koolproxyR
mkdir -p $KSROOT/init.d
mkdir -p $KSROOT/koolproxyR/data
cp -rf /tmp/koolproxyR/scripts/* $KSROOT/scripts/
cp -rf /tmp/koolproxyR/webs/* $KSROOT/webs/
cp -rf /tmp/koolproxyR/init.d/* $KSROOT/init.d/
if [ ! -f $KSROOT/koolproxyR/data/rules/user.txt ];then
	cp -rf /tmp/koolproxyR/* $KSROOT/
else
	mv $KSROOT/koolproxyR/data/rules/user.txt /tmp/user.txt.tmp
	cp -rf /tmp/koolproxyR/* $KSROOT/
	mv /tmp/user.txt.tmp $KSROOT/koolproxyR/data/rules/user.txt
fi
cp -f /tmp/koolproxyR/uninstall.sh $KSROOT/scripts/uninstall_koolproxyR.sh
rm -rf $KSROOT/install.sh
rm -rf $KSROOT/uninstall.sh

[ ! -L "/tmp/upload/user.txt" ] && ln -sf $KSROOT/koolproxyR/data/rules/user.txt /tmp/upload/user.txt

cd /
chmod 755 $KSROOT/koolproxyR/*
chmod 755 $KSROOT/koolproxyR/data/*
chmod 755 $KSROOT/scripts/*
chmod 755 $KSROOT/init.d/*
ln -sf  $KSROOT/koolproxyR/koolproxy  $KSROOT/bin/koolproxy

# remove install tar
rm -rf /tmp/koolproxy* >/dev/null 2>&1

# remove old files if exist
find /etc/rc.d/ -name *koolproxyR.sh* | xargs rm -rf
[ ! -L "/etc/rc.d/S93koolproxyR.sh" ] && ln -sf $KSROOT/init.d/S93koolproxyR.sh /etc/rc.d/S93koolproxyR.sh

[ -z "$koolproxyR_mode" ] && dbus set koolproxyR_mode="1"
[ -z "$koolproxyR_acl_default" ] && dbus set koolproxyR_acl_default="1"
[ -z "$koolproxyR_acl_list" ] && dbus set koolproxyR_acl_list=" "
[ -z "$koolproxyR_arp" ] && dbus set koolproxyR_arp=" "

# add icon into softerware center
dbus set softcenter_module_koolproxyR_description="KPR更多规则更舒服！"
dbus set softcenter_module_koolproxyR_install=1
dbus set softcenter_module_koolproxyR_home_url="Module_koolproxyR.asp"
dbus set softcenter_module_koolproxyR_name=koolproxyR
dbus set softcenter_module_koolproxyR_version=900.8.39
dbus set koolproxyR_version=900.8.39

[ "$koolproxyR_enable" == "1" ] && sh $KSROOT/koolproxyR/kpr_config.sh restart
