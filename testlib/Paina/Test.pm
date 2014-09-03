package Paina::Test;

use strict;
use warnings;
use Carp qw(cluck croak carp);
use Exporter;

our $VERSION = 0;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw($val1 $val2);

use constant HOGE=>"MUGA";


sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;

  return $self;
}

sub test {
  my $self = shift;
  print HOGE, "\n";
}
