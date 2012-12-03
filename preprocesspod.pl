#!/usr/bin/env perl

use strict;
use warnings;

use feature ':5.14';

use HTTP::Tiny;
use HTML::Template;

use File::Path qw(make_path);
use IO::Any;

my $verbose = 0;  # status messages to STDERR if $verbose == 1
if ($ARGV[0] && $ARGV[0] eq '-v') {
  shift @ARGV;
  $verbose = 1;
}

my $usage = "$0 [-v] year";

my $year = shift @ARGV;
die $usage unless $year;

my $config = initialize_year($year);
my $web    = HTTP::Tiny->new;
foreach my $day ( 1..24 ) {
  $config->{article_tmpl}->param( DAY => $day );

  my $day02 = sprintf "%02d", $day;
  $config->{article_tmpl}->param( DAY02 => $day02 );

  my $podname  = "$year-12-$day02.pod" ;
  my $prefile  = "$config->{pre_dir}/$podname";
  my $postfile = "$config->{post_dir}/$podname" ;

  make_prefile($prefile, $config, $verbose);
  preprocess($prefile, $postfile, $verbose);
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



sub preprocess {
  my ($prefile, $postfile, $verbose) = @_;

  my $prefh = IO::Any->read($prefile);
  unless ($prefh) {
    warn "Could not open $prefile for reading: $!";
    return;
  }

  my $postfh = IO::Any->write($postfile);
  unless ($postfh) {
    warn "Could not open $postfile for writing: $!";
    return;
  }

  say STDERR "Preprocessing $prefile:" if $verbose;
  while (<$prefh>) {
    unless (/L<(?<link>[^>]+)>/) {
       print $postfh $_;
       next;
    }
    my ($label, $url) = split(/\|/, $+{link});
    say STDERR sprintf("\tprocessing %32s: %s", $label, $url) if $verbose;

    my $response = $web->get($url);
    if ( $response->{status} != 200) {
       say $postfh "${label}: is unavailable.";
       next;
    }

    if ( $response->{content} =~ m!<title>(?<title>.*)</title>!s ) {
        $label .= ": $+{title}";
	$label =~ s/&laquo;/--/mg;
        $label =~ s/[|]/-/mg;
        $label =~ s/\n/ /mg;
    }

    say $postfh "L<$label|$url>";
  }

  close $prefh;
  close $postfh;
}
