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
        if [ ! -d "/storage/emulated/0/tcpdump_data" ]
        then
                echo "mkdir tcodump_data dir"
                mkdir "/storage/emulated/0/tcpdump_data"
        fi
        while true
        do
                flash_space=$(get_flash_memory_remaining_space)
                if [ $flash_space -gt 10485760 ]
                then
                        #echo "Space is enough"
                        return
                fi
                cd /storage/emulated/0/tcpdump_data
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
        if [ $? != 0 ]
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
        file_size=$(ls -l $file_name | awk '{ print $5 }')
        if [ $file_size -gt 1073741824 ]
        then
			flash_space=$(get_flash_memory_remaining_space)
			remain_space=$(expr $flash_space \* 1024)
			double_file_size=$(expr $file_size \* 2)
			if [ $remain_space -gt $double_file_size ]
			then
				cd /storage/emulated/0/tcpdump_data
				tcpdump -r $file_name.pcap -w $file_name"_" -C 1000
			fi
        fi
        loop_delete_tcpdump_data_file
        sleep 60
done
