#!/usr/local/bin/perl

#
# tagd - RFID tag debugging tool for OMRON V720-HMF01.
#      - RFIDタグデバッグツール OMRON V720-HMF01 用
#
# 開発:       paina@sfc.wide.ad.jp / Auto-ID Lab. Japan
# ライセンス: CreativeCommons 日本版 "帰属" ライセンス
# 使用方法:   オプションなしで起動してください
#
# I-CODE SLI(ISO15693) タグのみサポートします
#

# load modules
use warnings;
use POSIX (":termios_h");

# config
$rate = '9600';      #bitrate
local $/ = "\r";      #Use CR for separator
($port, $operation, @option) = @ARGV;

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

&usage;
exit(-1);

sub oper_dumpuma {
    &open_serial_port($port);
    &send_command("313000FFFF"); # read bank0
    my $bank0 = &recieve_msg;
    $err = &is_nack($bank0);
    die $err."[$bank0]\n" if ($err);
    $bank0 =~ s/^00//;

    &send_command("3130010FFF"); # read bank1
    my $bank1 = &recieve_msg;
    $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);
    $bank1 =~ s/^00//;

    my $uma = $bank0.$bank1;
    $hex = unpack("H*", $uma);

    my $ascii;
    print "BnP | Blk |  0  1  2  3- 0  1  2  3 |    ASCII |";
    for ($i = 0; $i<112; $i++) {
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
    &close_serial_port;
    return 0;
}

sub oper_clearuma {
    &open_serial_port($port);
    &send_command("332000FFFF00000000"); # erase bank0
    my $bank0 = &recieve_msg;
    $err = &is_nack($bank0);
    die $err."[$bank0]\n" if ($err);

    &send_command("3320010FFF00000000"); # erase bank1
    my $bank1 = &recieve_msg;
    $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);

    print "done.\n";

    &close_serial_port;
    return 0;
}

sub oper_getuid {
    &open_serial_port($port);
    &send_command("3520"); # erase bank0
    my $uid = &recieve_msg;
    $err = &is_nack($uid);
    die $err."[$uid]\n" if ($err);

    $uid =~ s/^00//;
    print "$uid\n";


    &close_serial_port;
    return 0;

}



sub open_serial_port {
    # Open serial port and returns its file handler.
    # usage: &open_serial_port($device_file_of_serial_port);

    my $port = $_[0];

    open(SERIAL, "+<$port") || die "Can't open serial port.\n";

    my $fnum = fileno(SERIAL);
    my $term = POSIX::Termios->new;
    $term->getattr($fnum);
    $term->setospeed($rate);
    $term->setispeed($rate);
    $term->setcflag(CS8 | PARENB | CLOCAL | CREAD );
    $term->setattr($fnum, TCSANOW);# || die "Can't write settings of serial port.\n";

    $portfh = SERIAL;

    return SERIAL;
}

sub oper_fillwrite {
    &open_serial_port($port);
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

    &send_command($cmd);
    my $bank1 = &recieve_msg;
    $err = &is_nack($bank1);
    die $err."[$bank1]\n" if ($err);
    &close_serial_port;

    print "done.\n";

    return 0;
}


sub close_serial_port {
    close $portfh;
}

sub send_command {
    print $portfh $_[0]."\r";
}

sub recieve_msg {
    $in = <$portfh>;
    chomp($in);
    return $in;
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
