package PreprocessPOD;

use warnings;
use strict;

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


sub initialize_template {
  my ($tmpl_file, $year) = @_;

  my $template = HTML::Template->new(filename => $tmpl_file);
  $template->param( YEAR => $year );
  return $template;
}

sub make_config_file {
  my ($tmpl_file, $config_file, $year) = @_;
  my $config_template = initialize_template($tmpl_file, $year);

  my $config_fh = IO::Any->write($config_file) or die "Could not write $config_file";
  print $config_fh $config_template->output;
  close $config_fh;
}


1;
