#!/usr/bin/env perl

use strict;
use warnings;
use lib '.';
use feature ':5.14';

use PreprocessPOD;

use HTTP::Tiny;
use HTML::Template;

use IO::Any;
use Time::Piece;
use Data::Dumper;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($PreprocessPOD::log4perl_config);

# TODO: get uri (etc.) from a config file or command line
my $advent_planet_uri = 'http://lenjaffe.com/AdventPlanet';

my $usage = "$0 year [last_day]";

my $year = shift @ARGV;
ERROR $usage unless $year;
die $usage unless $year;

my $last_day = shift @ARGV //  25;

my $config = PreprocessPOD::initialize_year($year);
my $web    = HTTP::Tiny->new;
foreach my $day ( 1..${last_day} ) {
  $config->{article_tmpl}->param( DAY => $day );

  my $day02 = sprintf "%02d", $day;
  $config->{article_tmpl}->param( DAY02 => $day02 );

  my $basename = "$year-12-$day02" ;
  my $podname  = "${basename}.pod" ;
  my $prefile  = "$config->{pre_dir}/$podname";
  my $postfile = "$config->{post_dir}/$podname" ;

  PreprocessPOD::make_prefile($prefile, $config);
  preprocess($day, $year, $prefile, $postfile);
}


sub card2ord {
  my $cardinal = shift;

  my %ordinal = (
     1 => "1st", 
     2 => "2nd", 
     3 => "3rd", 
     4 => "4th", 
     5 => "5th", 
     6 => "6th", 
     7 => "7th", 
     8 => "8th", 
     9 => "1st", 
     10 => "10th", 
     11 => "11th", 
     12 => "12th", 
     13 => "13th", 
     14 => "14th", 
     15 => "15th", 
     16 => "16th", 
     17 => "17th", 
     18 => "18th", 
     19 => "19th", 
     20 => "20th", 
     21 => "2125", 
     22 => "22nd", 
     23 => "23rd", 
     24 => "24th", 
     25 => "25th", 
  );

  return $ordinal{$cardinal};
}


my %last_post;
sub preprocess {
  my ($day, $year, $prefile, $postfile, $verbose) = @_;

  my $prefh = IO::Any->read($prefile);
  unless ($prefh) {
    WARN "Could not open $prefile for reading: $!";
    return;
  }

  my $postfh = IO::Any->write($postfile);
  unless ($postfh) {
    WARN "Could not open $postfile for writing: $!";
    return;
  }

  INFO "Preprocessing $prefile";
  my @weekdays = ('Sunday', 'Monday','Tuesday','Wednesday','Thursday','Friday', 'Saturday');
  INPUTLINE:
  while (<$prefh>) {
    next INPUTLINE if /^\s*#/;
    unless ( /^\s*
           (
             (?<day_range>(?<start_day>\d+)\s*-\s*(?<end_day>\d+)\s*:)
             |
             (?<mst_fill>MST_FILL\s*:)
             |
             (?<card2ord>card2ord:)
             |
             (?<nopre>NOPRE(PROCESS)?\s*:)
           )?
           \s*
         L<(?<link>[^>]+)> /x ) {
       print $postfh $_;  #print the non-link lines
       next INPUTLINE;
    }

    my ($label, $url) = split(/\|/, $+{link});
    $last_post{$label}->{day} ||= 0;
    INFO sprintf("Processing %s: %s", $label, $url);

    if ($+{day_range}) {
      if ( $+{start_day} > $day || $day > $+{end_day} ) {
        my $link_fmt = "L<12/%02d|%s/%d/%d-12-%02d.html>";
        my $range = sprintf("${link_fmt}-${link_fmt}",
                               $+{start_day}, $advent_planet_uri, $year, $year, $+{start_day},
                               $+{end_day},   $advent_planet_uri, $year, $year, $+{end_day} );
        say $postfh "${label}: is available ${range}";
        INFO "${label}: is available ${range}";
        next INPUTLINE;
      }
    }

    if ($+{nopre}) {
      INFO "No preprocessing for ${label}q";
    }
    else {

      if ($+{card2ord}) {
        # convert the day to it's ordinal value     - the day is at .*/DAY/
        my @splits = split(/\//, $url);
        $splits[-1] = card2ord($splits[-1]) ;
        $url = join('/', @splits);
        $url .= "/"; 
      }

      my $response = $web->get($url);
      if ( $response->{status} != 200) {

        if ($+{mst_fill}) {  # one-off for MST one year...
          if ( $last_post{$label}->{day} == 0 ) {
            say $postfh "${label}: has not published any articles yet. Please try again later.";
          }
          else {
            say $postfh "${label}: does not publish on weekends. So you're either ahead of the publication schedule, "
                      . "or the Day $day article has not been published yet. The last published article was "
                      . "L<$last_post{$label}->{label}|$last_post{$label}->{url}>. "
                      . "Please try again later.";
          }
        }
        else {
          say $postfh "${label}: appears to be unavailable on ${year}-12-" . sprintf("%02d", $day) . ". "
                      . "Please try again later.";
          my $content = substr($response->{content}, 0, 132);
          $content =~ s/\s+/ /gsm;
          WARN sprintf(qq(Request for %s failed), $url);
          WARN sprintf(qq({status = %d, reason = "%s", url = "%s", content = "%s"}), $response->{status}, $response->{reason}, $url, $content);
        }
        next INPUTLINE;
      }

      if ( $response->{content} =~ m!<title[^>]*>(?<title>.*?)</title>!s ) {
          $label .= ": $+{title}";
          $label =~ s/&laquo;/--/mg;
          $label =~ s|&raquo;|--|mg;
          $label =~ s/[|]/-/mg;
          $label =~ s/&#039;/'/mg;
          $label =~ s/&#39;/'/mg;
          $label =~ s/&#8211;/-/mg;
          $label =~ s/&#9670;/*/mg;
          $label =~ s/\n/ /mg;
          $label =~ s/[^\x00-\x7F]+//;
      }

      INFO sprintf(qq(Request for %s succeeded), $url);
      INFO sprintf(qq({status = %d, reason = "%s", url = "%s", title = "%s"}), $response->{status}, $response->{reason}, $url, $label);
    }

    my $tag = $label;
    $last_post{$tag}->{day} += 1;
    $last_post{$tag}->{url} = $url;

    $last_post{$tag}->{label} = $label;
    say $postfh "L<$label|$url>";
  }

  close $prefh;
  close $postfh;
}

