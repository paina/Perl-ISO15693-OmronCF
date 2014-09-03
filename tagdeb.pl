#!/usr/bin/perl

use strict;
use warnings;

# load modules
#use POSIX (":termios_h");
use Device::SerialPort;

# config
my $rate = 9600; #bitrate
$/ = "\r";
my ($port, $operation, @option) = @ARGV;



if (defined $operation) {
    if ($operation eq 'dumpuma') {
	exit &oper_dumpuma;
    } elsif ($operation eq 'clearuma') {
	exit &oper_clearuma;
    } elsif ($operation eq 'getuid') {
	exit &oper_getuid;
    } elsif ($operation eq 'fillwrite') {
	exit &oper_fillwrite;
    }
}
print $operation;
&usage;
exit(-1);

sub oper_dumpuma {
    my $portfh = &open_serial_port($port);
    &send_command($portfh, "313000FFFF"); # read bank0
    my $bank0 = &recieve_msg($portfh);
    my $err = &is_nack($bank0);
    die $err."[$bank0]\n" if ($err);
    $bank0 =~ s/^00//;

    &send_command($portfh, "3130010FFF"); # read bank1
    my $bank1 = &recieve_msg($portfh);
    $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);
    $bank1 =~ s/^00//;

    my $uma = $bank0.$bank1;
    my $hex = unpack("H*", $uma);

    my $ascii;
    print "BnP | Blk |  0  1  2  3- 0  1  2  3 |    ASCII |";
    for (my $i = 0; $i<112; $i++) {
	printf "\n%03x | %03d | ", $i/4, $i/4 if ($i%8 == 0);
	print substr($hex, 2*$i, 2);
	if ($i%4 == 3 && $i%8 == 3) {
	    print "-";
	} else {
	    print " ";
	}
	if ($i%8 == 7) {
	    $ascii = substr($uma, ($i-7), 8);
	    $ascii =~ tr/\ -\~/\./c;
	    printf "| $ascii |";
	}
    }
    print "\n";
    &close_serial_port($portfh);
    return 0;
}

sub oper_clearuma {
    my $portfh = &open_serial_port($port);
    &send_command($portfh, "332000FFFF00000000"); # erase bank0
    my $bank0 = &recieve_msg($portfh);
    my $err = &is_nack($bank0);
    die $err."[$bank0]\n" if ($err);

    &send_command($portfh, "3320010FFF00000000"); # erase bank1
    my $bank1 = &recieve_msg($portfh);
    $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);

    print "done.\n";

    &close_serial_port($portfh);
    return 0;
}

sub oper_getuid {
    my $portfh = &open_serial_port($port);
    &send_command($portfh, "3520"); # erase bank0
    my $uid = &recieve_msg($portfh);
    my $err = &is_nack($uid);
    die $err."[$uid]\n" if ($err);

    $uid =~ s/^00//;
    print "$uid\n";

    &close_serial_port($portfh);
    return 0;

}



sub open_serial_port {
    # Open serial port and returns its file handler.
    # usage: &open_serial_port($device_file_of_serial_port);
    
#    my $port = $_[0];
        
#    open(PORTFH, "+<$port") || die "Can't open serial port.\n";
    
#    my $fnum = fileno(*PORTFH);    
#    my $term = POSIX::Termios->new;
#    $term->getattr($fnum);
#    $term->setospeed($rate);
#    $term->setispeed($rate);
#    $term->setcflag(CS8 | PARENB | CLOCAL | CREAD);

#    $term->setattr($fnum, TCSANOW) || die "Can't write settings of serial port.\n";
    
#    return *PORTFH;

    my $portobj = new Device::SerialPort($port) || die "Can't open serial port\n";
    
    $portobj->parity("even");
    $portobj->baudrate($rate);
    $portobj->databits(8);
    $portobj->stopbits(1);
    $portobj->write_settings;

    return $portobj;
}

sub oper_fillwrite {
    my $portfh = &open_serial_port($port);
    if ($option[0] ne 'hex' && $option[0] ne 'ascii') {
	&usage;
	exit(-1);
    }

    my $data;
    if ($option[0] eq 'ascii') {
	$data = uc(unpack("H*", $option[1]));
    } else {
	$data = uc($option[1]);
    }

    $data .= "0" while (length($data)%8!= 0);
    
    print "Data: $data\n";
    die "Too lage Data\n" if (length($data) > 128);

    my $pageselect = sprintf "%04X", (2**(length($data)/8)-1);
 
    my $cmd = "322000".$pageselect.$data;

    &send_command($portfh, $cmd);
    my $bank1 = &recieve_msg($portfh);
    my $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);
    &close_serial_port($portfh);

    print "done.\n";

    return 0;
}
		 

sub close_serial_port {
    my $portfh = $_[0];
    #close $_[0];
    undef $portfh;
}

sub send_command {
    my $portfh = $_[0];
    my $cmd = $_[1];
#    print $portfh $cmd."\r";
    $portfh->write($cmd."\r") || die "Can't send command";
}

sub recieve_msg {
    my $portfh = $_[0];
    my $in;
#    my $in = <$portfh>;
#    chomp($in);
    while(1) {
	my ($count, $char) = $portfh->read(1);
	if ($char eq "\r") {
	    return $in;
	}
	$in .= $char;
    }
}

sub is_nack {
    my $in_mesg = $_[0];
    my @code = qw(00 10 11 12 14 18 70 71 72 79 7A);
    my @error = (0, 'parity error', 'flaming error', 'overrun error', 'format error', 
		 'flame error(time out?)', 'communication error(noise?)', 
		 'write error(write protected or rewriting life over?)',
		 'tag absence error(no tag or far tag?)',
		 'command error', 'address error');

    $in_mesg =~ /(^..)/;
    my $in_code = $1;

    foreach my $i (0..(scalar(@code)-1)) {
	return $error[$i] if ($in_code eq $code[$i]);
    }
    return 'unintentional error(communication error?)';

}

sub usage {
    warn <<"EOT";
tagdeb - RFID tag debugging tool for OMRON V720-HMF01.

- usage
    $0 device_file_of_serial_port operation

- operations
    dumpuma:    Dump all user memory area.
    clearuma:   Write all user memory area zero.
    getuid:     Read UID(SNR, serial number) from tag.
    fillwrite ascii/hex "data":
                Write given data from first block.

information
    - Supports only I-CODE SLI(ISO15693) RFID tag.
    - Written by paina\@sfc.wide.ad.jp \& Auto-ID Lab. Japan
    - CreativeCommons Japan Attribution Licens
EOT
}
