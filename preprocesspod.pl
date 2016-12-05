#!/usr/bin/env perl

use strict;
use warnings;

use feature ':5.14';

use HTTP::Tiny;
use HTML::Template;

use File::Path qw(make_path);
use IO::Any;
use Time::Piece;
use Data::Dumper;

my $advent_planet_uri = 'http://lenjaffe.com/AdventPlanet';

my $verbose = 0;  # status messages to STDERR if $verbose == 1
if ($ARGV[0] && $ARGV[0] eq '-v') {
  shift @ARGV;
  $verbose = 1;
  say STDERR "************************* VERBOSE MODE *********************************************";
}

my $usage = "$0 [-v] year [last_day]";

my $year = shift @ARGV;
die $usage unless $year;

my $last_day = shift @ARGV || 25;


my $config = initialize_year($year);
my $web    = HTTP::Tiny->new;
foreach my $day ( 1..${last_day} ) {
  $config->{article_tmpl}->param( DAY => $day );

  my $day02 = sprintf "%02d", $day;
  $config->{article_tmpl}->param( DAY02 => $day02 );

  my $basename = "$year-12-$day02" ;
  my $podname  = "${basename}.pod" ;
  my $prefile  = "$config->{pre_dir}/$podname";
  my $postfile = "$config->{post_dir}/$podname" ;

  make_prefile($prefile, $config, $verbose);
  preprocess($day, $year, $prefile, $postfile, $verbose);
}

sub initialize_year {
  my $year = shift;
  my $config;

  $config->{pre_dir}  = "articles/pre/$year";  # this is where the processed templates get written. It gets preprocessed into the @post_dir
  $config->{post_dir} = "articles/post/$year"; # these files are the souce for advcal
  my $config_dir      = "config/$year";
  my $template_dir    = "articles/templates/$year";
  foreach my $dir ( $template_dir, $config->{pre_dir}, $config->{post_dir}, $config_dir )  {
    make_dir($dir);
  }

  my $article_tmpl_name   = 'article.pod.tmpl';
  my $article_tmpl_file   = "$template_dir/$article_tmpl_name";
  $config->{article_tmpl} = initialize_template($article_tmpl_file, $year);

  my $config_tmpl_file = "$template_dir/advent.ini.tmpl";
  my $config_file      = "$config_dir/advent.ini";
  make_config_file($config_tmpl_file, $config_file, $year);

  return $config;
}

sub make_dir {
  my $dir = shift;
  return if -e -d $dir;
  make_path($dir, { mode => 0755 }) || die "could not create $dir: $!";
}

sub make_prefile {
  my $prefile = shift;
  my $config  = shift;
  my $verbose = shift;
  my $prefh = IO::Any->write($prefile) || die "Could not open the preprocess file for writing: $!";

  say STDERR "Creating $prefile" if $verbose;
  print $prefh $config->{article_tmpl}->output;
  close $prefh;
}


sub make_config_file {
  my ($tmpl_file, $config_file, $year) = @_;
  my $config_template = initialize_template($tmpl_file, $year);

  my $config_fh = IO::Any->write($config_file) or die "Could not write $config_file";
  print $config_fh $config_template->output;
  close $config_fh;
}

sub initialize_template {
  my ($tmpl_file, $year) = @_;

  my $template = HTML::Template->new(filename => $tmpl_file);
  $template->param( YEAR => $year );
  return $template;
}



my %last_post;
sub preprocess {
  my ($day, $year, $prefile, $postfile, $verbose) = @_;

  my $prefh = IO::Any->read($prefile);
  unless ($prefh) { warn "Could not open $prefile for reading: $!";
    return;
  }

  my $postfh = IO::Any->write($postfile);
  unless ($postfh) {
    warn "Could not open $postfile for writing: $!";
    return;
  }

  say STDERR "Preprocessing $prefile:" if $verbose;
  my @weekdays = ('Sunday', 'Monday','Tuesday','Wednesday','Thursday','Friday', 'Saturday');
  INPUTLINE:
  while (<$prefh>) {
    next INPUTLINE if /^\s*#/;
    unless ( /^\s*
           (
	           (?<day_range>(?<start_day>\d+)\s*-\s*(?<end_day>\d+)\s*:)
		         |
             (?<mst_fill>MST_FILL\s*:\s*)
           )?
	         \s*
	         L<(?<link>[^>]+)> /x ) {
       print $postfh $_;  #print the non-link lines
       next INPUTLINE;
    }
    my ($label, $url) = split(/\|/, $+{link});
    $last_post{$label}->{day} ||= 0;
    say STDERR sprintf("\tprocessing %32s: %s", $label, $url) if $verbose;

    if ($+{day_range}) {
      if ( $+{start_day} > $day || $day > $+{end_day} ) {
        say $postfh "${label}: is available from " .
	        sprintf("L<12/%02d|%s/%d/%d-12-%02d.html>", $+{start_day}, $advent_planet_uri, $year, $year, $+{start_day} )
                . '-' .	
	        sprintf("L<12/%02d|%s/%d/%d-12-%02d.html>", $+{end_day}, $advent_planet_uri, $year, $year, $+{end_day} );
        next INPUTLINE;
      }
    }

    my $response = $web->get($url);
    if ( $response->{status} != 200) {

      if ($+{mst_fill}) {
        if ( $last_post{$label}->{day} == 0 ) {
          say $postfh "${label}: has not published any articles yet. "
                    . "Please try again later.";
        }
        else {
          say $postfh "${label}: does not publish on weekends. So you're either ahead of the publication schedule, "
                    . "or the Day $day article has not been published yet. The last published article was "
                    . "L<$last_post{$label}->{label}|$last_post{$label}->{url}>. "
                    . "Please try again later.";
        }
      }
      else {
        say $postfh "${label}: appears to be unavailable on ${year}-12-" . sprintf("%02d - ", $day) . ". "
                    . "Please try again later.";
        my $content = substr($response->{content}, 0, 132);
        $content =~ s/\s+/ /gsm;
        my $err = sprintf("request for %s failed:\n\tstatus = %d\n\treason = %s\n\tcontent = %s\n", $url, $response->{status}, $response->{reason}, $content) if $verbose;
      }
      next INPUTLINE;
    }

    my $tag = $label;
    $last_post{$tag}->{day} += 1;
    $last_post{$tag}->{url} = $url;

    if ( $response->{content} =~ m!<title[^>]*>(?<title>.*?)</title>!s ) {
        $label .= ": $+{title}";
        $label =~ s/&laquo;/--/mg;
        $label =~ s/[|]/-/mg;
        $label =~ s/&#039;/'/mg;
        $label =~ s/\n/ /mg;
    }

    $last_post{$tag}->{label} = $label;
    say $postfh "L<$label|$url>";
  }

  close $prefh;
  close $postfh;
}

