#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes  qw(tv_interval gettimeofday);

############### dataSender.pl ###################
#                                               #
# Transfer data from file to influxDB DB        #
#       Robert J Krasowski                      #
#       14 July 2018                            #
#                                               #
#################################################



my $server = "192.168.1.51:8086";
my $data;
my $output= "";
my $text = "";

open (FH, "/home/pi/BeeCounter/beeData.dat") or die "Can not open file $!\n";

while (my $line = <FH>)
	{
		$text .= $line;
	}

my $CPUTemp = `cat /sys/class/thermal/thermal_zone0/temp`;
$CPUTemp = $CPUTemp * 0.001;
$CPUTemp = sprintf("%.1f",$CPUTemp);
$CPUTemp = ",CPUTemp=$CPUTemp";



my @dataArray = split (/\n/,$text);


my $dataArray;

foreach (@dataArray)
	{
		$_ =~ s/nan/0/;
		$output = `curl -i -k -XPOST "https://$server/write?db=beeTraffic&precision=s" --data-binary '$_$CPUTemp'`;
		sleep(1);
	}


if ($output =~/error/)
        {
                print "Error !!!\n";
                # send me an message
                exit();

        }

#open (FH, "/home/pi/BeeCounter/beeData.dat") or die "Can not read file [$!}\n";               # Open file
truncate "/home/pi/BeeCounter/beeData.dat",0;                # Empty the file
close FH;





