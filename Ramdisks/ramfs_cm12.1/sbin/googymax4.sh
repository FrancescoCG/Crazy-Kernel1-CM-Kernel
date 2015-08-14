#!/system/xbin/busybox sh

BB=/system/xbin/busybox

	# disabling knox security at boot
	pm disable com.sec.knox.seandroid
	setsebool debugfs 0
	setenforce 0

time=$(date +"%T")
$BB echo "$time : googymax4 script start" > /data/.googymax4/log.ggy

time=$(date +"%T")
$BB echo "$time : Busybox installed" >> /data/.googymax4/log.ggy

OPEN_RW()
{
        $BB mount -o remount,rw /system
	$BB mount -t rootfs -o remount,rw rootfs
}

time=$(date +"%T")
$BB echo "$time : qcom_post_boot done" >> /data/.googymax4/log.ggy

OPEN_RW

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R system:system /data/anr
	$BB chown -R root:root /tmp
	$BB chown -R root:root /res
	$BB chown -R root:root /sbin
	$BB chown -R root:root /lib
	$BB chmod -R 777 /tmp/
	$BB chmod -R 775 /res/
	$BB chmod -R 0777 /data/anr/
	$BB chmod -R 0400 /data/tombstones
}
CRITICAL_PERM_FIX;

if [ ! -d /data/.googymax4 ]; then
	$BB mkdir -p /data/.googymax4
fi

$BB chmod -R 0777 /data/.googymax4/

. /res/customconfig/customconfig-helper;

time=$(date +"%T")
$BB echo "$time : config-helper done" >> /data/.googymax4/log.ggy

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.googymax4/.ccxmlsum`" ];
then
   $BB rm -f /data/.googymax4/*.profile
   $BB echo ${ccxmlsum} > /data/.googymax4/.ccxmlsum;
fi

[ ! -f /data/.googymax4/default.profile ] && $BB cp /res/customconfig/default.profile /data/.googymax4/default.profile;
[ ! -f /data/.googymax4/battery.profile ] && $BB cp /res/customconfig/battery.profile /data/.googymax4/battery.profile;
[ ! -f /data/.googymax4/balanced.profile ] && $BB cp /res/customconfig/balanced.profile /data/.googymax4/balanced.profile;
[ ! -f /data/.googymax4/performance.profile ] $BB && cp /res/customconfig/performance.profile /data/.googymax4/performance.profile;

read_defaults;
read_config;

time=$(date +"%T")
$BB echo "$time : read_config done" >> /data/.googymax4/log.ggy

# set governor & min max freqs
stop mpdecision
$BB echo "1" > /sys/devices/system/cpu/cpu0/online
$BB echo "1" > /sys/devices/system/cpu/cpu1/online
$BB echo "1" > /sys/devices/system/cpu/cpu2/online
$BB echo "1" > /sys/devices/system/cpu/cpu3/online
$BB echo "$cpu_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB echo "$cpu_governor" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
$BB echo "$cpu_governor" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
$BB echo "$cpu_governor" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
$BB echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
$BB echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
start mpdecision
 
time=$(date +"%T")
$BB echo "$time : cpu settings applied" >> /data/.googymax4/log.ggy

if [ "$logger_mode" == "on" ]; then
	$BB echo "1" > /sys/kernel/logger_mode/logger_mode
else
	$BB echo "0" > /sys/kernel/logger_mode/logger_mode
fi

time=$(date +"%T")
$BB echo "$time : logger settings applied" >> /data/.googymax4/log.ggy

# scheduler
$BB echo "$int_scheduler" > /sys/block/mmcblk0/queue/scheduler
$BB echo "$int_read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb
$BB echo "$ext_scheduler" > /sys/block/mmcblk1/queue/scheduler
$BB echo "$ext_read_ahead_kb" > /sys/block/mmcblk1/bdi/read_ahead_kb

time=$(date +"%T")
$BB echo "$time : scheduler settings applied" >> /data/.googymax4/log.ggy

# apply STweaks defaults
export CONFIG_BOOTING=1
/res/uci.sh apply
export CONFIG_BOOTING=

time=$(date +"%T")
$BB echo "$time : uci apply done" >> /data/.googymax4/log.ggy

OPEN_RW;

time=$(date +"%T")
$BB echo "$time : init.d scripts executed" >> /data/.googymax4/log.ggy

time=$(date +"%T")
$BB echo "$time : knox settings applied" >> /data/.googymax4/log.ggy

	# Fix critical perms again after init.d mess
	CRITICAL_PERM_FIX;
	
time=$(date +"%T")
$BB echo "$time : CRITICAL_PERM_FIX done" >> /data/.googymax4/log.ggy

	$BB mount -t rootfs -o remount,ro rootfs
	$BB mount -o remount,ro /system

	time=$(date +"%T")
$BB echo "$time : googymax4 script end" >> /data/.googymax4/log.ggy

