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
cd /
/sbin/tcpdump --help
