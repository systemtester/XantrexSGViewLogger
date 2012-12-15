#!/usr/bin/perl
use warnings;
use strict;
use Text::CSV;
use Device::SerialPort;

# This scripts creates a log file very similar to the Windows based SG-View software
# A lot of what is logged by that software, and this script, is not used by the PVOutput
# Integration Service (yet)
# Setup vars for log file creation.
# If using the PVOutput Integration Service ensure the file naming structure
# defined in pvoutput.ini is the same as the code below
# The filename compiled below uses the following file name
# solarDataLog MM-dd-yyyy
my $serial_port ="/dev/ttyS0";  #dmesg | grep tty to find this
my $serial_lock = "/tmp/ttyS0.lock";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
my $Time = sprintf('%02d', $hour).':'.sprintf('%02d', $min).':'.sprintf('%02d', $sec);
$mon++;
$year += 1900;
my $Date = $mon."-".$mday."-".$year; #Important that the month/day ordering follows the logfile month/day ordering.
my $logdir="/var/log/pvoutput"; #All Xantrex Logs will be stored here.  Ensure pvoutput.ini is configured to look here.
my $logfile = "$logdir/solarDataLog ".sprintf('%02d',$mon)."-".sprintf('%02d',$mday)."-".sprintf('%02d',$year);
my $logdata;
my $csv = Text::CSV->new ({ binary => 1, sep_char => "\t"}) or die "Cannot use CSV: ".Text::CSV->error_diag (); #Default sep_char is COMMA
my ($VDC,$DCAmps,$MPPT,$DCPwr,$ACPwr,$Eff,$VAC,$ACKWh, $ACWh,$HSTemp,$Freq, $STATUS);
my ($num, $mantissa);

# Wait until unlocked
while (-e $serial_lock)
{ 
	sleep (1);
}
$serial_port = new Device::SerialPort ($serial_port, "", $serial_lock) || die "Can't open $serial_port: $!\n";
$serial_port->baudrate(9600)				|| die "failed setting baudrate";
$serial_port->parity("none")				|| die "failed setting parity";
$serial_port->databits(8)				|| die "failed setting databits";
$serial_port->handshake("none")			|| die "failed setting handshake";
$serial_port->write_settings				|| die "no settings";
$serial_port->read_const_time(40); # const time for read (milliseconds)

$serial_port->write("IIN?\r"); #Input Current
(my $DCAmpCharCount, $DCAmps) = $serial_port->read(255);

if ($DCAmps && $DCAmps > 0) #Don't Log if Inverter is not getting the juice
{
	$serial_port->write("VIN?\r"); #Input Voltage
	(my $VDCCharCount, $VDC) = $serial_port->read(255);
	$VDC = substr $VDC, 0, $VDCCharCount - 1;

	$serial_port->write("IIN?\r"); #Input Current
	(my $DCAmpCharCount, $DCAmps) = $serial_port->read(255);

	$serial_port->write("MPPTSTAT?\r"); #MPPT Statistics V:[a] TD:[b] PL:[c]
	(my $MPPTCharCount, $MPPT) = $serial_port->read(255);
	$MPPT = substr $MPPT, 2, 5; #Get Voltage value
	
	$serial_port->write("PIN?\r"); #Input Power
	(my $DCPwrCharCount, $DCPwr) = $serial_port->read(255);

	$serial_port->write("POUT?\r"); #Inverter Output Power
	(my $ACPwrCharCount, $ACPwr) = $serial_port->read(255); 

	# The SG-View software logs a calculated Efficiency value
	# The Inverter does not store or calculate this so we're calculating it now
	if ($ACPwr && $ACPwr > 0)
	{
		$Eff = 100 * int($ACPwr) / int($DCPwr);
		my @values = split ('\.', $Eff);
		if (scalar(@values) == 2)
		{
			$Eff = $values[0]. "." . substr $values[1], 0, 2;
		}
		else
		{
			$Eff = $values[0]. ".00"; #Not needed but logfile looks better with it.
		}
		$Eff .= "\r";  #Without adding this the regex on L121 & L122 complains
	}
	else
	{
		$Eff = 0;
	}

	$serial_port->write("VOUT?\r");
	(my $VACCharCount, $VAC) = $serial_port->read(255);

	$serial_port->write("KWHTODAY?\r"); # Inverter energy production today (KWh)
	(my $ACKWhCharCount, $ACKWh) = $serial_port->read(255);

	$ACWh = 1000 * $ACKWh; #Needs conversion to send to PVOutput

	$serial_port->write("MEASTEMP?\r"); #Response is 'C:[a] F:[b]' [a] = 0-125.0 [b] = 32.0-257.0
	(my $HCTempCharCount, $HSTemp) = $serial_port->read(255);
	$HSTemp = substr $HSTemp, 2, 4; #Get Celcius value

	$serial_port->write("FREQ?\r");
	(my $FreqCharCount, $Freq) = $serial_port->read(255);
	($num, $mantissa) = split ('\.', $Freq);
	$mantissa = substr $mantissa, 0, 1;
	if ($mantissa == 0) { #Following logic used in SG View here.  .0 is dropped and the whole number remains.
		$Freq = $num;
	}
	else {
		$Freq = $num.".".$mantissa;
	}
	
	$serial_port->write("POWSEQ?\r");
	(my $StatusCharCount, $STATUS) = $serial_port->read(255);
	
	unless (-e $logfile)
	{
		$logdata = "Xantrex Performance Logger"."\r\n";
		$logdata .= "Inverter Logged Performance Data"."\r\n";
		$logdata .= "Date	Time	VDC	DC Amps	MPPT	DC Pwr	AC Pwr	Eff	VAC	AC Wh	HS Tmp	Freq	Status"."\r\n";
	}
	
	my @data = ($Date,$Time,$VDC,$DCAmps,$MPPT,$DCPwr,$ACPwr,$Eff,$VAC,$ACWh,$HSTemp,$Freq, $STATUS);
	foreach my $data (@data) #Remove trailing CR from each Inverter-supplied value.  csv->combine needs this
	{
		$data =~ s/^\s+//;
		$data =~ s/\s+$//;
	}
	if ($csv->combine(@data))
	{
		$logdata .= $csv->string;
	}
	else
	{
		my $err = $csv->error_input;
		print "combine() failed on argument: ", $err, "\n";
		exit;
	}



open LOGFILE, ">>$logfile" or die "cannot open logfile $logfile for append: $!";
print LOGFILE $logdata."\r\n";
close LOGFILE;

}
$serial_port->close || warn "close failed";
undef $serial_port;
exit 0;
