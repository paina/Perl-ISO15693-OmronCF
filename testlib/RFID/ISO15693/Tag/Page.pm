package RFID::ISO15693::Tag::Page;

use strict;
use warnings;
use Carp;

our $VERSION = 0;

my $content;

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

  return $self;
}

sub content {
  my $self = shift;

  my $newcontent = @_;

  if ($newcontent) {
    unless (length($newcontent) == 4) {
      carp "Content of one page must be 4 bytes";
      return undef;
    }
    $content = $newcontent;
  }
  return $content;
}

sub contenthex {
  my $self = shift;

  my $newcontenthex = @_;
  my $newcontent = pack("H*", $newcontenthex) if ($newcontenthex);

  my $ret = unpack("H*", $self->content($newcontent));

  if ($ret){
    return undef;
  } else {
    return $ret;
  }
}

1;
