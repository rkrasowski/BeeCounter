#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes  qw(tv_interval gettimeofday);
use List::Util qw(sum);

				
##########################  Config parameters #########################
my $numOfChannels = 12;
my $delay = 60;			# Time delay for sending data to DB in sec
my $distance = 5; 		# Distance between sensors
my $file = "beeData.dat";	# temporary data storage
#######################################################################

# Create variables
my $in = 0;
my $out = 0;
my @inArray= (0,0,0,0,0,0,0,0,0,0,0,0);
my $inArray;
my @outArray= (0,0,0,0,0,0,0,0,0,0,0,0);
my $outArray;
my @timeBeeStart = (0,0,0,0,0,0,0,0,0,0,0,0);
my $timeBeeStart;
my $timeBeeFinish;
my $timeBeeDiff;
my @timeBeeDBIn;
my $timeBeeDBIn;
my @timeBeeDBOut;
my $timeBeeDBOut;


my $time2Send = `date +%s` + $delay; 			# Calculate time for next send


while(1)
	{
		my $data = `/home/pi/Programming/bees/shiftRegister`;
		my  $start = [gettimeofday];

		my @dataArray = split (//,$data);;
		my $dataArray;

		#print "Data outside @dataArray";


		my $ref = \@dataArray;
		for (my $i = 1;  $i<= $numOfChannels; $i++)
			{
				counter($ref,$i);
			}
		
		if (`date +%s` >= $time2Send)
			{
				$time2Send = `date +%s` + $delay;
				sendDB();;
			}

		my $finish = [gettimeofday];
		my $elapsed = tv_interval($start,$finish);
		$elapsed = sprintf("%.4f",$elapsed);

		print  "In: $in Out:$out Elapsed Time: $elapsed\r";
		
		
	}
########################################## Subroutines ##############################
sub counter {
	my $refInside = shift;
	my $channel = shift;
	my $firstElemArray = ($channel * 2) - 2;
        my $secondElemArray = ($channel *2) -1;	
	my $inoutElemArray = $channel -1;

	# IN triggered : Bee getting from Outside to Inside, so it is gettin IN  (outside sensor in first):

	if (${$refInside}[$firstElemArray] == 1 and ${$refInside}[$secondElemArray] == 0)
		{
			if ($inArray[$inoutElemArray] == 0)    					# Checking if channel IN is ative		
				{
					$timeBeeStart[$inoutElemArray] =`date +%s%N | cut -b1-13`;
					$in = $in + 1;
					$inArray[$inoutElemArray] = 1;				# Desactivating IN channel
				}
		}


	# IN and OUT sensor triggered direction: Getting inside	

	if (${$refInside}[$firstElemArray] == 1 and ${$refInside}[$secondElemArray] == 1 and $inArray[$inoutElemArray] == 1)
		{

			if ($outArray[$inoutElemArray] == 0)						# Checking if channel OUT is active
				{
					$timeBeeFinish = `date +%s%N | cut -b1-13`;
					$timeBeeDiff = $timeBeeFinish - $timeBeeStart[$inoutElemArray];
					push (@timeBeeDBIn,$timeBeeDiff);
					$outArray[$inoutElemArray] = 1;

				}
		}	

	# OUT triggered: Bee is getting from Inside to outside, so it is getting OUT (Inside sensor triggered first)

	if (${$refInside}[$secondElemArray] == 1 and ${$refInside}[$firstElemArray] == 0) 
		{
			if ($outArray[$inoutElemArray] == 0)    					# Checking if channel OUT is ative		
				{
					$timeBeeStart[$inoutElemArray] =	`date +%s%N | cut -b1-13`;
					$out = $out + 1;
					$outArray[$inoutElemArray] = 1;				# Desactivating OUT channel
				}	
		}

	# OUT and IN triggered direction OUT: bee is getting  OUTSIDE
			
	if ($inArray[$inoutElemArray] == 0  and ${$refInside}[$firstElemArray] == 1 and $outArray[$inoutElemArray] == 1)

				{
					$timeBeeFinish = `date +%s%N | cut -b1-13`;
					$timeBeeDiff = $timeBeeFinish - $timeBeeStart[$inoutElemArray];
					push (@timeBeeDBOut,$timeBeeDiff);
					$inArray[$inoutElemArray] = 1;
				}
		
	# Reactivate channels

	if (${$refInside}[$firstElemArray] == 0  and ${$refInside}[$secondElemArray] ==0)
		{
			$inArray[$inoutElemArray] = 0;
			$outArray[$inoutElemArray] = 0;
		}
}






sub sendDB
	{
		print "Data sent to DB\n";
		my $speedIn = 0;
		my $speedOut = 0;;


		if (@timeBeeDBIn > 0)
			{
				my $meanTimeIn = sum(@timeBeeDBIn) / @timeBeeDBIn;
				$speedIn = $distance / ($meanTimeIn * 0.05 );
				$speedIn = sprintf("%.1f",$speedIn);
				print "Speed In: $speedIn mm/sec\n";
				@timeBeeDBIn = ();
				
			}	
		if (@timeBeeDBOut > 0)
			{
				my $meanTimeOut = sum(@timeBeeDBOut) / @timeBeeDBOut;
				$speedOut = $distance / ($meanTimeOut * 0.05);
				$speedOut = sprintf("%.1f",$speedOut);
				@timeBeeDBOut = ();
				print "Speed Out: $speedOut mm/sec\n";

			}


		open (FH,'>>',$file) or die "Can not open $file $!\n";
		my $string = "Counts,Apiary=2,Hive=43 In=$in,Out=$out,InSpeed=$speedIn,OutSpeed=$speedOut\n";
		#$string =~ s/.*[^[:print:]]+//;
		print FH $string;
		close FH;

		$in = 0;
		$out = 0;

	}

############################################## Subroutines #########################################################
