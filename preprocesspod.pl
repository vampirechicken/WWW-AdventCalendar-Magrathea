#!/usr/bin/env perl

use strict;
use warnings;

use feature ':5.14';

use HTTP::Tiny;
use HTML::Template;

use IO::Any;


my $verbose = 0;  # status messages to STDERR if $verbose == 1
if ($ARGV[0] && $ARGV[0] eq '-v') {
  shift @ARGV;
  $verbose = 1;
}

my $usage = "$0 [-v] year";

my $year = shift @ARGV;
die $usage unless $year;

my $template_dir      = "articles/templates/$year";
unless (-e $template_dir && -d _) {
   die "$template_dir is not a directory";
}

my $article_tmpl_name = 'article.pod.tmpl';
my $article_tmpl_file = "$template_dir/$article_tmpl_name";
my $article_tmpl      = initialize_template($article_tmpl_file, $year);

my $pre_dir  = "articles/pre/$year";  # this is where the processed templates get written. It gets preprocessed into the @post_dir
my $post_dir = "articles/post/$year"; # these files are the souce for advcal


my $config_tmpl_file = "$template_dir/advent.ini.tmpl";
my $config_dir       = "config/$year";

foreach my $dir ( $pre_dir, $post_dir, $config_dir )  {
  unless (-e $dir && -d _) {
     die "$dir is not a directory";
  }
}

my $config_file      = "$config_dir/advent.ini";
make_config_file($config_tmpl_file, $config_file, $year);

my $web = HTTP::Tiny->new;
foreach my $day ( 1..24 ) {
  $article_tmpl->param( DAY => $day );

  my $day02 = sprintf "%02d", $day;
  $article_tmpl->param( DAY02 => $day02 );

  my $podfile  = "$year-12-$day02.pod" ;

  my $prefile  = "$pre_dir/$podfile";
  make_prefile($prefile, $verbose);

  my $postfile = "$post_dir/$podfile" ;
  preprocess($prefile, $postfile, $verbose);
}


sub make_prefile {
  my $prefile = shift;
  my $verbose = shift;
  my $prefh = IO::Any->write($prefile) || die "Could not open the preprocess file for writing: $!";

  say STDERR "Creating $prefile" if $verbose;
  print $prefh $article_tmpl->output;
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
       say $postfh "${label}: unavailable";
       next;
    }
  
    if ( $response->{content} =~ m!<title>(?<title>.*)</title>!s ) {
        $label .= ": $+{title}"; 
        $label =~ s/[|]/-/mg;
        $label =~ s/\n/ /mg;
    }

    say $postfh "L<$label|$url>";
  }

  close $prefh;
  close $postfh;
}



