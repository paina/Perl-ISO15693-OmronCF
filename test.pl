BEGIN {
  push @INC, "./testlib/";
}


use RFID::ISO15693::OmronCF::RW;
use Device::SerialPort;

$com = new Device::SerialPort ('/dev/com5');
$reader = new RFID::ISO15693::OmronCF::RW (Port => $com);

unless ($reader->diag) {
    die "diag fail." ;
} else {
    print "diag ok.\n";
}

my $tag = $reader->readtags(Bank => 0,
			    Mode => SINGLE_TRIGGER);

print ref($tag)."\n";

foreach $i (0..15) {
    print ref $banks{$i}, "\n";
}


my %banks = $tag->bank;

print $banks{0}->content;
