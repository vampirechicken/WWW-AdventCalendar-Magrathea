
use strict;
use warnings;

use Test::More ;
use Test::Exception;
use Test::Output;
use Test::Exit;
use File::Copy;
use File::Path;
use IO::Any;

use FindBin qw($Bin);
use lib "$Bin/..";


note("PreproccessPOD.pm");
use_ok('PreprocessPOD');
use_ok('HTML::Template');

note("PreproccessPOD::make_dir()");
my $test_dir = "/tmp/PreprocessPODtest$$";
PreprocessPOD::make_dir($test_dir);
ok( -d $test_dir, "$test_dir exists");

rmdir($test_dir);
ok(! -d $test_dir, "$test_dir has been removed");
 
# make_dir logs to STDOUT before exiting -test for exit, and test the log message 
stdout_like {
    exits_ok { PreprocessPOD::make_dir( '/foo' ) } "Can't create /foo, exited"
} qr/FATAL could not create \/foo: mkdir \/foo: Permission denied at/, "Logged reason: Permission denied creating /foo:$@";

my $year = 1977;

note("initialize_template()");
my $config;
my $template_dir    = "t/articles/templates/$year";
my $config_dir      = "t/config/$year";
foreach my $dir ( $template_dir, $config_dir )  {
  PreprocessPOD::make_dir($dir);
  ok( -d $dir, "$dir exists");
}

my $article_tmpl_name  = 'article.pod.tmpl';
my $config_tmpl_name   = 'advent.ini.tmpl';

note("initialize_template()");
my $test_template_dir    = "t/templates";
copy("$test_template_dir/$article_tmpl_name", $template_dir);
ok(-e "$test_template_dir/$article_tmpl_name", "article template copied form barn");

my $article_tmpl_file   = "$template_dir/$article_tmpl_name";
$config->{article_tmpl} = PreprocessPOD::initialize_template($article_tmpl_file, $year);
isa_ok( $config->{article_tmpl},'HTML::Template', "Template is instantiated as HTML::Template");

note("make_config_file()");
my $config_tmpl_file = "$test_template_dir/$config_tmpl_name";
my $config_file      = "$config_dir/advent.ini";
PreprocessPOD::make_config_file($config_tmpl_file, $config_file, $year);
ok(-e $config_file, "config template initialized");

#cleanup();
#note("initialize_year($year)");
#my $config = PreproccessPOD::initialize_year($year);


cleanup();
done_testing();

sub cleanup {
  note("END { cleanup }");
  ok(unlink("$article_tmpl_file"), "$article_tmpl_file removed");
  ok(unlink("$config_file"), "$config_file removed");

  foreach my $dir ( $template_dir, $config_dir )  {
    rmtree($dir);
    ok(! -d $dir, "$dir has been removed");
  }

}




