package RFID::ISO15693::Tag::Bank;

use strict;
use warnings;
use Carp;

#use RFID::ISO15693::Tag::Page;
##ページクラスはもうつかわないことにしたorz
##だってややこしいんだもん。。
##最小読み取り単位のバンクだけクラス化すりゃいいやもぅ。。。。

use constant BYTES_OF_CONTENT => 64;
use constant MIN_PAGE_NO =>       0;
use constant MAX_PAGE_NO =>      15;
use constant BYTES_OF_PAGE =>     4;

our $VERSION = 0;

#my %page;
my $content;

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

#  $self->_init;

  return $self;
}

#sub _init {
#  foreach my $pageno (0..15) {
#    my $page = new RFID::ISO15693::Tag::Page;
#    $pages{$pageno} = $page;
#  }
#}

#sub page {
#  my $self = shift;
#  my %newpages = @_;
#
#  if (%newpages) {
#    foreach my $pageno (keys %newpages) {
#      unless ($pageno <= 15 && $pageno >= 0) {
#	carp "Invalid page number (ignored)";
#	delete $newpages{$pageno};
#      }
#    }
#    %pages = (%pages, %newpages);
#  }
#  return %pages;
#}

#sub getall {
#  my $self = shift;
#  my $padding = shift || ' ';
#
#  my $ret;
#  foreach my $pageno (0..15) {
#    if ($pages{$pageno}) {
#      $ret .= $pages{$pageno}->content;
#    } else {
#      $ret .= $padding.$padding.$padding.$padding;
#    }
#  }
#
#  return $ret;
#}

sub content {
  my $self = shift;
  my $newcontent = @_;

  if ($newcontent) {
    if (length($newcontent) == BYTES_OF_CONTENT) {
      $content = $newcontent;
    } else {
      carp "Content of one bank must be ", BYTES_OF_CONTENT;
      return undef;
    }
  }
  if ($content) {
    return $content;
  } else {
    return undef;
  }
}

sub getpage {
  my $self = shift;
  my @pages = @_;

  my @ret;

  foreach my $page (@pages) {
    if ($page <= MAX_PAGE_NO && $page >= MIN_PAGE_NO) {
      push @ret, substr ($content, $page * BYTES_OF_PAGE, BYTES_OF_PAGE);
    } else {
      carp "Invalid page number (ignored)";
      push @ret, undef;
    }
  }

  return @ret;
}

1;
