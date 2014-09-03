package RFID::ISO15693::OmronCF::RW;

use strict;
use warnings;
use Carp qw(cluck croak carp);

use RFID::Reader::Serial;
use Exporter;

use RFID::ISO15693::Tag;

our $VERSION = 0;
our @ISA = qw(RFID::Reader::Serial Exporter);

#our @ISA = qw(RFID::Reader RFID::Writer RFID::ISO15693::RW Exporter);

#our @EXPORT = qw(hoge);
#our @EXPORT_OK = qw(fuga);

#sub (@&); #プロトタイプ宣言

#sub readtags {
#  my $self = shift;
#  my $bank = $_[0];
#
#  my $cmd = "31$optb$bankbFFFF";
#  $self->_writebytes($cmd);
#  my $resp = $self->
#
#}

our @EXPORT = qw(SINGLE_TRIGGER
		 SINGLE_AUTO
		 SINGLE_REPEAT
		 FIFO_TRIGGER
		 FIFO_AUTO
		 FIFO_CONT
		 FIFO_REPEAT);



use constant BAUDRATE => 9600;
use constant DATABITS => 8;
use constant STOPBITS => 1;
use constant PARITY => 'even';
use constant HANDSHAKE => 'none';
use constant DEFAULT_TIMEOUT => 2000; #ms
use constant STREAMLINE_TIMEOUT => 50; #ms

use constant DELIM => "\r";

use constant SINGLE_TRIGGER => 0x0;
use constant SINGLE_AUTO    => 0x1;
use constant SINGLE_REPEAT  => 0x2;
use constant FIFO_TRIGGER   => 0x8;
use constant FIFO_AUTO      => 0x9;
use constant FIFO_CONT      => 0xA;
use constant FIFO_REPEAT    => 0xB;

use constant OPT_ISO15693   => 0x20;
#use constant ICODE1         => 0x00; #not in use
use constant OPT_HEX        => 0x00;
#use constant ASCII          => 0x10; #not in use

our $lasterr;

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

  my(%p)=@_;

  $self->{com} = $p{Port}
    or die __PACKAGE__."::new requires argument 'Port'\n";
  delete $p{Port};
  $self->{timeout} = $p{Timeout}||$p{timeout}||DEFAULT_TIMEOUT;
  $self->{databits}=DATABITS;
  $self->{stopbits}=STOPBITS;
  $self->{parity}=PARITY;
  $self->{handshake}=HANDSHAKE;
  $self->{baudrate}=$p{Baudrate}||$p{baudrate}||BAUDRATE;

  $self->_init(%p);
  $self;
}

sub diag {
  my $self = shift;
  my $teststr = @_ || "DIAGNOSTIC FROM RFID::ISO15693::OmronCF::RW";

  $self->_sendcmd("10$teststr");
  my $resp = $self->_getresp;

  if ($resp eq "00$teststr") {
    return 1;
  } else {
    return undef;
  }
}

sub readtags {
  my $self = shift;
  my %p = @_;

  my $bankno = $p{Bank} || 0;
  my $mode = $p{Mode} || SINGLE_TRIGGER;

  my $cmd;
  if ($mode == SINGLE_TRIGGER) {
    $cmd = "31".sprintf("%02X%02X", $mode + OPT_ISO15693 + OPT_HEX, $bankno)."FFFF";
  }

  if ($self->_sendcmd($cmd)) {
    my ($err, $body) = $self->_getresp;

    warn $body;

    unless ($err) {
      my $tag = new RFID::ISO15693::Tag;
      my $bank = new RFID::ISO15693::Tag::Bank;

      $bank->content($self->_h2a($body));
      $tag->bank($bankno => $bank);

      return $tag;
    } else {
      return undef;
    }
  } else {
    return undef;
  }
}

sub _sendcmd {
  my $self = shift;
  my $cmd = join('', @_, DELIM);

  my $sent_bytes = $self->_writebytes($cmd);

  if ($sent_bytes == length($cmd)) {
    return $sent_bytes;
  } else {
    return undef;
  }
}

sub _getack {
}

sub _getresp {
  my $self = shift;
  my $resp = $self->_readuntil(DELIM);

  $resp =~ /(..)(.*)/;
  my ($err, $body) = ($1, $2);

  unless ($err eq '00') {
    $lasterr = $err;
    return undef;
  } else {
    if (wantarray) {
      return undef, $body;
    } else {
      return $resp;
    }
  }
}

sub _h2a {
  my $self = shift;
  my $hex = shift;
  return pack("H*", $hex);
}

1;
