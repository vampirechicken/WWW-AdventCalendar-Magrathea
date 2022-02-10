
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

my $test_year = 1977;

my %test_config = (
  barn_dir =>  "t/templates",
  articles =>  {
    template_dir  => "t/articles/templates/$test_year",
    template_name => "article.pod.tmpl",
  },
  config => {
    template_dir  => "t/config/$test_year",
    template_name => "advent.ini.tmpl",
  }
);

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
$test_dir = "/foo";
stdout_like {
    exits_ok { PreprocessPOD::make_dir( $test_dir ) } "Can't create $test_dir, exited"
} qr/FATAL could not create $test_dir: mkdir $test_dir: Permission denied at/, "Logged reason: Permission denied creating $test_dir: $@";

note("initialize_template()");
my $config;
my $template_dir    = $test_config{articles}{template_dir};
my $config_dir      = $test_config{config}{template_dir};
foreach my $dir ( $template_dir, $config_dir )  {
  PreprocessPOD::make_dir($dir);
  ok( -d $dir, "$dir exists");
}

note("initialize_template()");
copy("$test_config{barn_dir}/$test_config{articles}{template_name}", $test_config{articles}{template_dir});
ok(-e "$test_config{articles}{template_dir}/$test_config{articles}{template_name}", "article template copied from barn");

$config->{article_tmpl} = PreprocessPOD::initialize_template("$test_config{articles}{template_dir}/$test_config{articles}{template_name}", $test_year);
isa_ok( $config->{article_tmpl},'HTML::Template', "Template is instantiated as HTML::Template");

note("make_config_file()");
my $config_file      = "$test_config{config}{template_dir}/advent.ini";
PreprocessPOD::make_config_file("$test_config{barn_dir}/$test_config{config}{template_name}", $config_file, $test_year);
ok(-e $config_file, "config template initialized");

#cleanup();
#note("initialize_year($test_year)");
#my $config = PreproccessPOD::initialize_year($test_year);

cleanup();
done_testing();

sub cleanup {
  note("END { cleanup }");
  ok(unlink("$test_config{articles}{template_dir}/$test_config{articles}{template_name}"), 
               "$test_config{articles}{template_dir}/$test_config{articles}{template_name} file removed");

  my $config_file      = "$test_config{config}{template_dir}/advent.ini";
  ok(unlink("$config_file"), "$config_file removed");

  foreach my $dir ( $template_dir, $config_dir )  {
    rmtree($dir);
    ok(! -d $dir, "$dir has been removed");
  }
}

