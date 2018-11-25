#!/usr/bin/awk -f
# Created by PMelsen
#
#

function abs(x){return ((x < 0.0) ? -x : x)};

function getproc(a,b,c) {
#	print a" "b" "c;
	fcmd = "ps -o command hwwp "a;
	if ((fcmd | getline) > 0) {
		print b" "a" "c"\n"$0"\n";
	} else print b" "a" "c"\nProcess is no longer active - most likely compression or disk usage\n";
	return 0;
}

BEGIN {
  if ( ("id -u" | getline id) > 0 && id != 0 ) {print "Please use \"sudo ./LPdiag\"";exit;}
  close ("id -u")

print "from pylib import mongo" > "/tmp/remote.py"
print "from mongokit import ObjectId" >> "/tmp/remote.py"
print "db = mongo.get_makalu()" >> "/tmp/remote.py"
print "installation = db.loginspect.find()" >> "/tmp/remote.py"
print "name = installation[0][\"name\"]" >> "/tmp/remote.py"
print "ip = installation[0][\"ip_dns\"]" >> "/tmp/remote.py"
print "print name+\" \"+ip+\" 127.0.0.1\"" >> "/tmp/remote.py"
print "for rlist in db.remoteconnection.find():" >> "/tmp/remote.py"
print "  for rconn in  rlist[\"clients\"]:" >> "/tmp/remote.py"
print "    print rconn[\"name\"]+\" \"+rconn[\"remote\"]+\" \"+rconn[\"private_ip\"]" >> "/tmp/remote.py"
close("/tmp/remote.py");

# Initialize remote tables
cmd = "/opt/immune/bin/envdo python /tmp/remote.py"
while ((cmd | getline) > 0) {
	rname[$3]=$1;
	rrealip[$3]=$2
}
close(cmd);


print "#!/opt/immune/bin/envdo python" > "/tmp/lua.py"
print "import platform" >> "/tmp/lua.py"
print "import codecs" >> "/tmp/lua.py"
print "import os" >> "/tmp/lua.py";
print "from bson import ObjectId" >> "/tmp/lua.py";
print "from pylib import mongo,configgenerator" >> "/tmp/lua.py";
print "db = mongo.get_makalu()" >> "/tmp/lua.py";
print "" >> "/tmp/lua.py";
print "def get_user_activity(result,repo_show,query_show):" >> "/tmp/lua.py";
print "  user_list = []" >> "/tmp/lua.py";
print "  for user in list(db.user.find({'active':True})):" >> "/tmp/lua.py";
print "    user_list.append(user['username'])" >> "/tmp/lua.py";
print "    dashboards=user['dashboard']" >> "/tmp/lua.py";
print "    dashboard = db.dereference(dashboards)" >> "/tmp/lua.py";
print "    if dashboard['active']:" >> "/tmp/lua.py";
print "      for tabs in dashboard['tabs']:" >> "/tmp/lua.py";
print "        tab = db.dereference(tabs)" >> "/tmp/lua.py";
print "        if tab['active']:" >> "/tmp/lua.py";
print "          for widget in tab[\"widgets\"]:" >> "/tmp/lua.py";
print "            widget = db.dereference(widget)" >> "/tmp/lua.py";
print "            if widget['active']:" >> "/tmp/lua.py";
print "              livesearch = db.dereference(widget[\"livesearch\"])" >> "/tmp/lua.py";
print "              time=[livesearch['timerange_day'],livesearch['timerange_hour'],livesearch['timerange_minute']]" >> "/tmp/lua.py";
print "              result.write('%s////DASH////%s////%s////%s////%s////%s////life_%s\\n' % (user['username'], tab['name'], widget['name'],  livesearch['query'], livesearch['repos'], time, configgenerator.get_life_id_of_live_search(livesearch)))" >> "/tmp/lua.py";
print "" >> "/tmp/lua.py";
print "    for alerts in db.alertrules.find({'user':user['username'],'active':True}):" >> "/tmp/lua.py";
print "      livesearch = db.livesearch.find_one({'_id': ObjectId(alerts['livesearch'])})" >> "/tmp/lua.py";
print "      time=[livesearch['timerange_day'],livesearch['timerange_hour'],livesearch['timerange_minute']]" >> "/tmp/lua.py";
print "      extra_config=alerts[\"extra_config\"]" >> "/tmp/lua.py";
print "      result.write('%s////ALRT////%s//// ////%s////%s////%s////life_%s\\n' % (user['username'], alerts['name'], extra_config['query'], extra_config['repos'], time, alerts['life_id']))" >> "/tmp/lua.py";
print "" >> "/tmp/lua.py";
print "def main():" >> "/tmp/lua.py";
print "  myfile = '/tmp/livesearch_info.txt'" >> "/tmp/lua.py";
print "  result = codecs.open(myfile,'w',encoding='utf-8')" >> "/tmp/lua.py";
print "  get_user_activity(result,True,True)" >> "/tmp/lua.py";
print "" >> "/tmp/lua.py";
print "if __name__ == \"__main__\":" >> "/tmp/lua.py";
print "    main()" >> "/tmp/lua.py";
close("/tmp/lua.py");

	SFS=FS;
	FS=": ";
	cmd="dmidecode -t 1";
	while ( (cmd | getline ) > 0 ) {
		if($1~/Manufacturer/)Man=$2;
		if($1~/Product Name/)Prod=$2;
		if($1~/Serial Number/)SerNo=$2
	}
	close(cmd);
	print "Hardware: "Man", "Prod"\nSerial number: "SerNo;


	# Get OS version
	cmd = "uname -v"
	if ((cmd | getline) > 0) print "OS version: "$0;
	close(cmd);

	# Get LogPoint version
	if ((getline < "/opt/immune/etc/vers") > 0) print "LogPoint version: "$0"\n";
	close("/opt/immune/etc/vers");

	FS=SFS;
	print "Getting current CPU, Memory, Disk and Network stats - please standby...";
	"nproc" | getline NumCPU;
	if ( (getline < "/proc/meminfo") > 0 ) TotalMem = $2;
	else { print "Cannot read /proc/meminfo"; exit 1;}
	close("/proc/meminfo");
	cmd = "vmstat -a 1 2";
	Ln=0;
	while ((cmd | getline)	> 0) {
		if (Ln++ == 3) {
			InactiveMem = $5;
		}
	}
	close (cmd);
# Read Idle and wait stats
	cmd = "atsar -u -s `date --date=\"-19 minutes\" +%H:%M` | grep all";
	if ((cmd | getline)	> 0) {
			 Idle = $9;
#			 Wait = $8;
	}
	close (cmd);
#Read swap stat
	cmd = "atsar -p -s `date --date=\"-19 minutes\" +%H:%M`";
	Ln=0;
	while ((cmd | getline)	> 0) {
		if (Ln++ == 4) {
			Swap = $4 + $5;
		}
	}
	close (cmd);
#Read Free stat
	cmd = "atsar -r -s `date --date=\"-19 minutes\" +%H:%M`";
	Ln=0;
	while ((cmd | getline)	> 0) {
		if (Ln++ == 4) {
			 Free = int($3);
		}
	}
	close (cmd);
#Read Load5 stat
	cmd = "atsar -P -s `date --date=\"-19 minutes\" +%H:%M`";
	Ln=0;
	while ((cmd | getline)	> 0) {
		if (Ln++ == 4) {
			LoadAvg5 = $6;
		}
	}
	close (cmd);
#Read disk queue and iowait
	cmd = "atsar -D -s `date --date=\"-19 minutes\" +%H:%M`";
	Ln=0;
	while ((cmd | getline)	> 0) {
		if (Ln++ == 4) {
			DiskQ = $9;
			IOwait = $10;
		}
	}
	close (cmd);
#Read network stats
	cmd = "atsar -L -s `date --date=\"-19 minutes\" +%H:%M`";
	Ln=0;
	SFS=FS;
	FS="[ ]+"; 
	while ((cmd | getline)	> 0) {
		if (Ln++ > 3) {
			Drops+=$5;
		}
	}
	close (cmd);
	FS=SFS;

# atopsar -xO -b `date --date="-19 minutes" +%H:%M`

	print "CPU cores: "NumCPU"\nTotalMem (MB): "TotalMem/1024"\nFree (MB): "Free"\nInactiveMem: "InactiveMem/1024"\nSwapping (I/O): "Swap"\nLoadAvg5: "LoadAvg5"\nIdle (%): "Idle"\nDiskQueue: "DiskQ"\nIOWait: "IOwait"\nNetwork drops/sec: "Drops"\n";

	have_atopsar=0;
	if(system("[ -f /usr/bin/atopsar ]") == 0) have_atopsar=1;
	print "-----------";
	if (LoadAvg5 < 1.5*NumCPU) print "No CPU load problems detected";
	else {
		print "High CPU load: "LoadAvg5" on "NumCPU" cores...";
		if (have_atopsar) {
			print "Here's the top 3 CPU consumers last 10 minutes....";
			cmd = "atopsar -xO -b `date --date=\"-19 minutes\" +%H:%M` | tail -2";
			if ((cmd | getline) > 0) {
				p1=$2; u1=$4; c1=$3;
				p2=$6; u2=$8; c2=$7;
				p3=$10; u3=$12; c3=$11;
				print "Usage  Pid  Cmd  Full";
				getproc(p1,u1,c1);
				getproc(p2,u2,c2);
				getproc(p3,u3,c3);
			}
			close(cmd);
		}
	}
	if (Swap < 10) print "No memory problems detected";
	else {
		print "Excessive swapping: "Swap"... Please check memory allocation of services"
		if (have_atopsar) {
			print "Here's the top 3 memory consumers last 10 minutes....";
			cmd = "atopsar -xG -b `date --date=\"-19 minutes\" +%H:%M` | tail -2";
			if ((cmd | getline) > 0) {
				p1=$2; u1=$4; c1=$3;
				p2=$6; u2=$8; c2=$7;
				p3=$10; u3=$12; c3=$11;
				print "Usage  Pid  Cmd  Full";
				getproc(p1,u1,c1);
				getproc(p2,u2,c2);
				getproc(p3,u3,c3);
			}
			close(cmd);
		}
	}
	#if (IOWait < 1) print "No disk IO load problems detected";
	if (IOWait < 0) print "No disk IO load problems detected";
	else {
		print "High disk IO load: "IOwait"... It may be necessary to distribute the disk IO to faster drives or reduce the IO demand"
		if (have_atopsar) {
			print "Here's the top 3 disk IO consumers last 10 minutes....";
			cmd = "atopsar -xD -b `date --date=\"-19 minutes\" +%H:%M` | tail -2";
			if ((cmd | getline) > 0) {
				p1=$2; u1=$4; c1=$3;
				p2=$6; u2=$8; c2=$7;
				p3=$10; u3=$12; c3=$11;
				print "Usage  Pid  Cmd  Full";
				getproc(p1,u1,c1);
				getproc(p2,u2,c2);
				getproc(p3,u3,c3);
			}
			close(cmd);
		}
	}
	if (Drops == 0) print "No Network IO drops detected currently";
	else print "Network IO drops detected: "Drops"... Most likely the cause of queueing at later processing stages - watch for queues in the collection."

	# Check for dropped UDP since last service restart
	Ln=0
	while((getline < "/proc/net/udp6") > 0) {
		if (Ln == 0) {Ln++;continue;}  # Skip the header
		split($2,a,":");
		b=strtonum("0x"a[2])
		if ($NF > 0) {
			if (Ln == 1) print "Number of dropped UDP packets since last service restart (syslog=514, openvpn=1193/4, snare=6161):";
			print "Port: "b"   Drops: "$NF;
		}
	}
        close ("/proc/net/udp6");

	print "\nChecking the kernel vm setting for swap..."
	if ((getline < "/proc/sys/vm/swappiness") > 0) {
		if ($1 > 1) print "vm.swappiness = "$1" - please set it to 1 by adding \"vm.swappiness=1\" to /etc/sysctl.conf\nand set it using \"sysctl vm.swappiness=1\"";
		else print "vm.swappiness=1 - is set ok!\n"
	}
        close ("/proc/sys/vm/swappiness");

	print "\nLooking for queues in the collection..."

# Queues towards norm_front
	cmd = "netstat -anpt | awk '$5 ~ /5502/&&($2!=\"0\"||$3!=\"0\"){split($NF,a,\"/\");print $2+$3\" \"a[1]}'"
	normfrontQ=Ln=0;
	while ((cmd | getline)	> 0) {
		Q = $1;
		proc = $2;
		if ( Q > 100000 && proc != "-")
		{ 
			if (Ln == 0) print "\nQueues detected from collection layer towards norm_front";
			Ln++;
			cmd1 = "ps hfwwp "$2;
			if ((cmd1 | getline) > 0) {
				print "Queue of size: "Q" found affecting:"
				print $0;
			}
			close (cmd1);
		}
	}
	close (cmd);
	if ( Ln > 0 ) normfrontQ = 1;

# Queues towards normalizers
	cmd = "netstat -anpt | awk '$5 ~ /5505/&&($2!=\"0\"||$3!=\"0\"){split($NF,a,\"/\");print $2+$3\" \"a[1]}'"
	normalizerQ=Ln=0;
	while ((cmd | getline)	> 0) {
		Q = $1;
		proc = $2;
		if ( Q > 100000 && proc != "-")
		{ 
			if (Ln == 0) print "\nQueues detected from collection layer towards normalizers";
			Ln++;
			cmd1 = "ps hfwwp "$2;
			if ((cmd1 | getline) > 0) {
				print "Queue of size: "Q" found affecting:"
				print $0;
			}
			close (cmd1);
		}
	}
	close (cmd);
	if ( Ln > 0 ) normalizerQ = 1;

# Queues towards storehandler
	cmd = "netstat -anpt | awk '$5 ~ /5503/&&($2!=\"0\"||$3!=\"0\"){split($NF,a,\"/\");print $2+$3\" \"a[1]}'"
	storehandlerQ=Ln=0;
	while ((cmd | getline)	> 0) {
		Q = $1;
		proc = $2;
		if ( Q > 100000 && proc != "-")
		{ 
			if (Ln == 0) print "\nQueues detected from collection layer towards store_handler";
			Ln++;
			cmd1 = "ps hfwwp "$2;
			if ((cmd1 | getline) > 0) {
				print "Queue of size: "Q" found affecting:"
				print $0;
			}
			close (cmd1);
		}
	}
	close (cmd);
	if ( Ln > 0 ) storehandlerQ = 1;

	cmd = "ss -xp | awk 'NR==1{next}$5 ~ /repo_storage_in/&&($3!=\"0\"||$4!=\"0\"){split($NF,a,\",\");split(a[2],b,\"=\");print $3+$4\" \"b[2]}'"
	filekeeperQ=Ln=0;
	while ((cmd | getline)	> 0) {
		Q = $1;
		proc = $2;
		if ( Q > 50000 && proc != "-")
		{ 
			if (Ln == 0) print "\nQueues detected from collection layer towards filekeeper";
			Ln++;
			cmd1 = "ps hfwwp "$2;
			if ((cmd1 | getline) > 0) {
				print "Queue of size: "Q" found affecting:"
				print $0;
			}
			close (cmd1);
		}
	}
	close (cmd);
	if ( Ln > 0 ) filekeeperQ = 1;

	cmd = "ss -xp | awk 'NR==1{next}$5 ~ /repo_indexing/&&($3!=\"0\"||$4!=\"0\"){split($NF,a,\",\");split(a[2],b,\"=\");print $3+$4\" \"b[2]}'"
	indexsearcherQ=Ln=0;
	while ((cmd | getline)	> 0) {
		Q = $1;
		proc = $2;
		if ( Q > 50000 && proc != "-")
		{ 
			if (Ln == 0) print "\nQueues detected from collection layer towards indexsearcher (the repo filekeeper is reported below - but it is the indexsearcher that is causing the queue)";
			Ln++;
			cmd1 = "ps hfwwp "$2;
			if ((cmd1 | getline) > 0) {
				print "Queue of size: "Q" found affecting:"
				print $0;
			}
			close (cmd1);
		}
	}
	close (cmd);
	if ( Ln > 0 ) indexsearcherQ = 1;

	if (indexsearcherQ) {
		print "\nSeeing queues all the way through the collection system towards a indexsearcher indicates a problem with the indexsearcher. The queues could be caused by a high volume of logs which might require tuning the java process (heap, indexing threads), delayed logs causing too many open file descriptors or high disk IO (difficult to tune), or even corrupted files causing the processes to lock - investigate - then try restarting the process";
	} if (!indexsearcherQ && filekeeperQ) {
		print "\nSeeing queues all the way through the collection system towards a filekeeper indicates a problem with the file keeper. The queues could be caused by a high volume of logs which might require tuning the java process (heap or filedescriptors), delayed logs causing too many open file descriptors or high disk IO (difficult to tune), or even corrupted files causing the processes to lock - investigate - then try restarting the process";
	}if (!indexsearcherQ && !filekeeperQ && storehandlerQ) {
		print "\nSeeing queues all the way through the collection system to the store_handler but not towards the filekeepers or indexsearchers indicates that there might be a problem with the store_handler itself (investigate then restart)";
	} if (!indexsearcherQ && !filekeeperQ && !storehandlerQ && normalizerQ) {
		print "\nQueuing towards the normalizers indicate that the normalizing layer is not able to process at logs at the rate they are being received. There are 2 possible reasons for this:\n1. the normalization polices are inefficient\n2. there are too few normalizers.";
	} if (!indexsearcherQ && !filekeeperQ && !storehandlerQ && !normalizerQ && normfrontQ) {
		print "\nQueing towards the norm_front without seeing queues towards the normalizers indicate a problem with the norm_front process. Investigate - then try restarting the process.";
	} if (!indexsearcherQ && !filekeeperQ && !storehandlerQ && !normalizerQ && !normfrontQ) print "No queues detected";
	if (indexsearcherQ || filekeeperQ || storehandlerQ || normalizerQ || normfrontQ) print "PLEASE NOTE: sometimes queues occur for a period of time - it is perfectly ok in a busy system. If queues are observed along with problems - like fx reports of packets being dropped - then they can often provide a good indication of the source of the problem."

#	TODO
#	Check for repos that didn't have any logs today
#

	print "\nChecking for issues with local repo files"
	SFS=FS;
	FS="[./ ]"; 
	cmd = "cd /opt/immune/storage;find logs/*/`date +%Y/%m/%d`	-type f -printf '%T@ %p\n'";
	while ((cmd | getline) > 0) {
		if(logs[$4]<$1)logs[$4]=$1;
	}
	close(cmd);
	cmd = "cd /opt/immune/storage;find indexes/*/`date +%Y/%m/%d`	-type f -printf '%T@ %p\n'"
	while ((cmd | getline) > 0) {
		if(indexes[$4]<$1)indexes[$4]=$1;
	}
	close(cmd);
	for (i in logs) {
		diff = abs(indexes[i]-logs[i]);
		if (diff > 60) {print "Repo files not in sync: "i" time diff: "diff; OoS=1;}
	}
	delete indexes;
	delete logs;
	FS=SFS;
	if (OoS) print "If logs should be arriving for a repo, time differences observed between the logs and indexes may indicate problems with the file_keeper or indexsearcher. If no logs are expected into the repo then time differences will not have any significance.";
	else print "No time differences found with the repo files."
	
# explain queues in the collector part - check for the need of more normalizers (100%)
	print "\nChecking normalizer stats";
	cmd = "egrep 'normalizer.*no_of_services' /opt/immune/storage/lp_services_config.json";
	FS="[: ]+"
	if ((cmd | getline) > 0) {
		for (i = 1; i <= NF; i++) {
			if ($i ~ /no_of_services/) print "Configured normalizers: "int($(i+1));
		}
	} 
	close(cmd);

	FS=SFS;
	cmd = "ps auxww";
	norm_found=norm_load=0;
	while ((cmd | getline) > 0) {
		if ($0 ~ /normalizer.py/) {
			norm_found++;
			norm_load+=$3;
		}
	}
	close(cmd);
	print "Running normalizers: "norm_found"\nAvg normalizer load (%CPU): "norm_load/norm_found" - Total load from normalizers (%CPU): "norm_load

	Ln=0;
	cmd = "netstat -anpt | awk '/5505/&&/ESTABLISHED/{split($4,a,\":\");split($5,b,\":\");split($7,c,\"/\");if(a[2]!=5505)pn[a[2]]=c[1];if(b[2]!=5505)d[b[2]]=\"\"}END{for(i in d)delete pn[i];for(i in pn)print pn[i]}'"
	while ((cmd | getline)	> 0) {
		if (Ln++ == 0) print "The following normalizers seem to be disconnected from the norm_front - this will make the EPS numbers reported later too high!\nConsider restarting the mentioned normalizer(s) to restore normal operation...";
		cmd1 = "ps hfwwp "$1;
		if ((cmd1 | getline) > 0) {
			print $0;
		}
		close (cmd1);
	}
	close (cmd);
        
	cmd = "tail --quiet --lines 1 /opt/immune/var/log/benchmarker/normalizer_*.log";
	FS="[;=]";
	actualmps=doablemps=0;
	while ((cmd | getline) > 0) {
		actualmps+=$6;
		doablemps+=$8;
	}
	close(cmd);
	FS="[/]";
	print "Avg current EPS pr normalizer: "actualmps/norm_found"\nAvg doable EPS pr normalizer: "doablemps/norm_found;
	print "Total current EPS via local normalizers: "actualmps"\nTotal doable EPS: "doablemps;
	if (norm_load/norm_found > 95) {
		print "Normalizing capacity depleted ... Consider adding more normalizers...";
		if (LoadAvg5 < 1.5*NumCPU) print "Currently there is available capacity to add more normalizers";
		else print "Unfortunately the system is current so loaded that this does not seem like a good option";
	} else if (doablemps/norm_found < 100) print "The processing speed of the normalizers indicate inefficient norm policies or use of inefficient signatures - please investigate";
	
# Look for evidence of performance issues in the logs (current)
	print "\nChecking application logs for memory issues since midnight - please standby...";
	cmd = "egrep -li -e \"`date +%Y-%m-%d`.*(OutOfMemoryError|DFA out of memory)\" /opt/immune/var/log/service/*/current";
	mem_log_issues=0;
	while ((cmd | getline) > 0) {
		if (mem_log_issues++ == 0) print "Memory issues found in the logs from: ";
		print $7;
	}
	if (mem_log_issues == 0) print "No memory issues found in logs";
	else print "Check the logs of the named applications for \"OutOfMemory\" errors";
	close(cmd);

# look for java processes needing heap and other tuning
	print "\nChecking for memory configuration problems of java services";
	# Discard stats for MainApplication as user reports etc
	cmd = "/opt/immune/bin/lido jps -m | grep -v MainApplication";
	FS="[/ ]";
	Ln=0
	while ((cmd | getline) > 0) {
		if ( $8 != "" ) {
			cur_app=$8;
			cur_pid=$1;
			cmd1 = "/opt/immune/bin/lido jstat -gc -t "$1" | tail -1";
			SFS1=FS;
			FS=SFS;
			if ((cmd1 | getline) > 0) {
				if ($NF/$1 > 0.01) {
					print cur_app"("cur_pid"): % of GC time of total run time: "$NF/$1*100;
					Ln++;
				}
#				if ($12 > 0) {
##					# More than 50 ms sb tuned - adding a little "buffer" to avoid being too hysterical
#					if ($13/$12 > 0.1) print cur_app"("cur_pid"): Young GC is too slow, takes: "$13/$12*1000" millisecs (avg), sb. no more than 50 ms in avg";
#					# Less that 10 secs sb tuned - adding a little ...
#					if ($1/$12 < 5) print cur_app"("cur_pid"): Young GC running too frequently in average every: "$1/$12" secs, sb. at least 10 secs";
#				}
#				if ($14 > 0) {
#					# More than 1 secs sb tuned - adding a little ...
#					if ($15/$14 > 2) print cur_app"("cur_pid"): Full GC is too slow: "$15/$14" secs, sb. no more than 1 sec in avg";
#					# Less than 600 secs sb tuned - adding a little ...
#					if ($1/$14 < 300) print cur_app"("cur_pid"): Full GC running too frequently an average every: "$1/$14" secs, sb at least 600 secs";
#				}
			}
			close(cmd1);
			FS=SFS1;
		}
	}
	close(cmd);
	if (Ln == 0) print "No problems identified";

# Check premerger
		ccmd = "ls -1 /opt/immune/storage/premerger/results/ | wc -l"
		if ( (ccmd | getline i) > 0 && i != 0) 
		{
			print "\nChecking premerger stats";
			print "Checking widget completion";
			system("/opt/immune/bin/envdo python /tmp/lua.py");
			cmd = "awk 'BEGIN{true=false=0}/complete.*false/{false++}/complete.*true/{true++}END{print true\" \"false}' /opt/immune/storage/premerger/results/*"
			if ((cmd | getline) > 0) print "Complete widgets: "$1", InComplete widgets: "$2;
			if ($2/($1+$2) < 0.05) print "Widget completion looks fine!!";
			close(cmd);

			cnt=0;
			cmd = "/opt/immune/bin/envdo python /opt/immune/installed/idx/apps/pre_merger/pyscripts/request_status.py | awk 'BEGIN{a=0}a==1&&/\\},/{a=0}a==1{sub(/5504/,\"5504@\",$0);print}/Failed\\/Non responding/{a=1}'"
			FS="[\"@: ,]";
			while ((cmd | getline) > 0) {
				if(cnt == 0) print "Premerger has marked the following repo's as offline or non responding:"
				print $4" "rname[$4]" "$6;
				cnt++;
			}
			close(cmd);
			if (cnt > 0) print "This will likely cause a number of queries to be marked incomplete";


			if ($2 > 0) {
				print "Listing incomplete live searches: ";
				FS=".";
				cmd = "cd /opt/immune/storage/premerger/results;grep -l complete.*false *.json";
				system("rm -f /tmp/LPdiag.tmp");
				while ((cmd | getline) > 0) {
					cmd1 = "grep "$1" /tmp/livesearch_info.txt";
					FS="////";
					if ((cmd1 | getline) > 0) {
						lua_line=$0;
						user=$1;
						type=$2;
						name=$3;
						widget=$4;
					 cmd2 = "/opt/immune/bin/envdo python /opt/immune/installed/idx/apps/pre_merger/pyscripts/lifegrp.py "$8" -";
						if ((cmd2 | getline) > 0) {
							if ( ! ($1 in life_grp) ) {
								if ( type == "DASH" ) life_grp[$1] = "\nUser: "user" Type: "type" Name: "name" Widget: "widget;
								else life_grp[$1] = "\nUser: "user" Type: "type" Name: "name ;
							} else {
								if ( type == "DASH" ) life_grp[$1] = life_grp[$1]"\nUser: "user" Type: "type" Name: "name" Widget: "widget"\n";
								else life_grp[$1] = life_grp[$1]"\nUser: "user" Type: "type" Name: "name"\n";
							}
						}
						close(cmd2);
						print lua_line"////"$0 >> "/tmp/LPdiag.tmp";
					}
					close(cmd1);
					FS=".";
				}
				close(cmd);
				close("/tmp/LPdiag.tmp");
				cmd = "sort /tmp/LPdiag.tmp";
				FS="////";
				user=type=name="";
				while ((cmd | getline) > 0) {
					if (user != $1) {user=$1;print "\n===== User: "user" ===================================";}
					if (type != $2) {type=$2;}
					if (name != $3) {name=$3;if(type=="DASH")print "\n----- Dashboard Name: "name;else print "\n----- Alert Name: "name;}
					widget=$4;
					if (type == "DASH") print "\nWidget name: "widget;
					print "Query: "$5;
					print "Repos: "$6;
					print "Time (Day,Hour,Minute): "$7;
					print "Life_id: "$8", Life_grp: "$9;
					print "Life Assoc: "life_grp[$9];
					cmd1 = "/opt/immune/bin/envdo python /opt/immune/installed/idx/apps/pre_merger/pyscripts/remaining_request.py "$8
					OFS=FS;
					FS="[\"@: ,]";
					cnt=0;
					while ((cmd1 | getline) > 0) {
						if ($10 > 0) {
							if (cnt == 0) print "The following repo(s) have outstanding requests:"
							print $4" "rname[$4]" "$6" "$10;cnt++;
						}
					}
					close(cmd1);
					if (cnt == 0) print "Either premerger just returned the last results while we were checking - or a repo used in this search is marked as failed.\nIf neither is the case - premerger might have lost track of the livesearch - try restarting the process."
					FS=OFS;
				}
				close(cmd);
				print "\nCheck repo selection, timeranges and the queries on the listed livesearches to identify possible points for optimizations"
			}
	}
        else print "\nPremerger currently not used"
	close(ccmd)

#	cmd = "/opt/immune/bin/lido python /opt/immune/installed/idx/apps/pre_merger/pyscripts/repo_stats.py";
	

# list queries that use ha_repos
# list queries that use "all repos" like [127.0.0.1:5504]
# list users who use widgets with slow queries
# look for queues in the premerger
# look for outstanding queries in the premerger
# look for lagging live searches in the premerger
# identify "bad" queries from premerger
}

