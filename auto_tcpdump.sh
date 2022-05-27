mount -o rw,remount -t auto /
if [ ! -f "/sbin/tcpdump" ]
then
	cd sbin
	curl -OJLk https://www.androidtcpdump.com/download/4.99.1.1.10.1/tcpdump
	if [$? != 0]
	then
		echo "sorry download failed" 
		exit 1
	fi
	chmod 777 tcpdump
fi
sh ./sbin/tcpdump --help
