package RFID::ISO15693::Tag;

use strict;
use warnings;
use Carp;

use RFID::Tag;
use Exporter;

use RFID::ISO15693::Tag::Bank;

our $VERSION = 0;
our @ISA = qw(RFID::Tag Exporter);

use constant TAGTYPE => 'iso15693';

use constant MIN_BANK_NO =>  0;
use constant MAX_BANK_NO => 15;

my %banks;

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

  $self->_init;

  return $self;
}

sub _init {
  my $self = shift;

  foreach my $bankno (MIN_BANK_NO..MAX_BANK_NO) {
    my $bank = new RFID::ISO15693::Tag::Bank;
    $self->bank($bankno => $bank);
  }
}

sub bank {
  my $self = shift;
  my %newbanks = @_;

  if (%newbanks) {
    foreach my $bankno (keys %newbanks) {
      unless ($bankno <= MAX_BANK_NO && $bankno >=MIN_BANK_NO) {
	carp "Invalid bank number (ignored)";
	delete $newbanks{$bankno};
      }
    }
    %banks = (%banks, %newbanks);
  }

  return %banks;
}

sub id {
  carp "Getting serial number (SNR or UID) is not supprted at".__PACKAGE__;
  return undef;
}

sub type {
  return TAGTYPE;
}

sub getall {
  my $self = shift;
  my $padding = shift || ' ';

  my $ret;
  foreach my $bankno (MIN_BANK_NO .. MAX_BANK_NO) {
    if ($banks{$bankno}) {
      $ret .= $banks{$bankno}->getall($padding);
    }
  }

  return $ret;
}

1;
