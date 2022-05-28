get_zero_time_difference_value(){
	day=86400
	current_time=$(date +%s)
	remain=$(expr $day - $current_time \% $day - 8 \* 3600)
	echo $remain
	return $?
}
get_flash_memory_remaining_space(){
	data=$(df -a | grep /storage/emulated | grep -Eo '[0-9]{1,100}')
	array=($data)
	echo ${array[2]}
	return $?
}
loop_delete_tcpdump_data_file(){
	while true
	do
		flash_space=$(get_flash_memory_remaining_space)
		if [ $flash_space -gt 10485760 ]
		then
			#echo "Space is enough"
			return
		fi
		file_name=$(ls -rt | head -n 1)
		if [ ${#file_name} == 0 ]
		then
			echo "/storage/emulated/0/tcpdump_data no files, Flash space is less than 10g"
			exit 1
		fi
		echo "delete The oldest file"
		rm -f $file_name
	done
}

mount -o rw,remount -t auto /
[ -f "/sbin/tcpdump" ]
if [ $? != 0 ]
then
	cd /sbin
	curl -OJLk https://www.androidtcpdump.com/download/4.99.1.1.10.1/tcpdump
	if [$? != 0]
	then
		echo "sorry download failed" 
		exit 1
	fi
	chmod 777 /sbin/tcpdump
fi
if [ ! -d "/storage/emulated/0/tcpdump_data" ]
then
	echo "mkdir tcodump_data dir"
	mkdir "/storage/emulated/0/tcpdump_data"
fi
flash_space=$(get_flash_memory_remaining_space)
if [ $flash_space -lt 10485760 ]
then
	echo "sorry Flash space is less than 10g"
	exit 1
fi
echo $(date +%s)
while true
do
	echo "tcpdump start"
	file_name=$(date "+%Y%m%d_%H%M%S")
	tcpdump -i wlan0 -s 0 -w /storage/emulated/0/tcpdump_data/$file_name.pcap&
	diff_time=$(get_zero_time_difference_value)
	echo $diff_time
	sleep $diff_time
	echo "tcpdump stop"
	killall -SIGINT tcpdump
	loop_delete_tcpdump_data_file
	sleep 60
done
