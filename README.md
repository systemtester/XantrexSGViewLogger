Xantrex Inverter Logger
=======================

This script generates a log file that is similar to the Windows based [SG View](http://pvoutput.org/help.html#integration) software.
Its existence then allows a suitably configured [PVOuput Integration Service](http://code.google.com/p/pvoutput-integration-service/) to parse the contents and upload to that site.

Dependencies
------------

The following packages are required for this script to operate correctly.

###Script
* [Text::CSV](http://search.cpan.org/~makamaka/Text-CSV-1.21/lib/Text/CSV.pm#DESCRIPTION) -- `sudo yum install perl-text-CSV` (Preinstalled on Fedora 17 but noting here for completeness)
* [Device::SerialPort](http://search.cpan.org/~cook/Device-SerialPort-1.04/SerialPort.pm#DESCRIPTION) -- `sudo yum install perl-Device-SerialPort` (Preinstalled on Fedora 17 but noting here for completeness)

###PVOutput
The following configurations dependancies are noted to reduce confusion (change to suit your own locations)
pvoutput.ini

	dir=/var/log/pvoutput

corresponds to the following script configuration

	$logdir

pvoutput.ini

	file=solarDataLog {MM-dd-yyyy}

corresponds to the following script configuration

	$logfile

Tested On
---------
* Fedora 17 x86_64
* Perl v5.14.3

Usage
-----

The script is set to execute every minute between 4:00am and 8:00pm every day.

	* 04-20 * * * cd "/usr/local"; ./XantrexLogger.pl &

The PVOutput Integration Service is executed at reboot
	
	@reboot cd "/usr/local/org.pvoutput.integration.v1.4.0.2/bin"; ./pvoutput.sh &
	
To Do
-----

I continue to get the following when this script hits Line 70.  Feel free to adjust that.

	Use of uninitialized value $mantissa in substr at ./XantrexLogger.pl line 70.
	
While not required for PVOutput the efficiency 

Attribution
-----------

Many thanks to the following sites for doing a lot of the hard work for me.

http://www.planetchan.com/laurie/energy/solar/Xantrex%20serial%20commands.pdf

http://blog.our-files.com/2012/10/solar-monitoring-stuff/

http://home.exetel.com.au/frolektrics/projects/integrating-a-samilpower-inverter-with-pvoutput

Grubs aurora script on WP: http://forums.whirlpool.net.au/archive/1960759#r35311466

http://solar.js.cx/

Contributing
------------

1. Fork it.
2. Create a branch (`git checkout -b my_XantrexLogger`)
3. Commit your changes (`git commit -am "Code Optimised :)"`)
4. Push to the branch (`git push origin my_XantrexLogger`)
5. Open a [Pull Request][1]
6. Enjoy a refreshing Coke Zero and wait

[1]: http://github.com/github/markup/pulls

