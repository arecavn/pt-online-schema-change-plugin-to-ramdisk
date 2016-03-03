##### pt_online_schema_change_plugin - Move ramdisk MyISAM table back to default dir
# NinhSTH
# 20160227
# Base on: https://github.com/percona/percona-toolkit/blob/43aaf2588d73614e8c115e5b40dd6903438a8e3a/t/pt-online-schema-change/samples/plugins/block_create_triggers.pm
# Usage: only add following to pt_online_schema_change command: " --plugin path-to-this-script"

package pt_online_schema_change_plugin;

use strict;
use warnings FATAL => 'all';
use File::Path qw(make_path);
use Data::Dump 'dump';

use English qw(-no_match_vars);
use constant PTDEBUG => $ENV{PTDEBUG} || 0;
use constant RAMDISK_DIR => "/dev/shm/mysql";

sub new {
   my ($class, %args) = @_;
   my $self = { %args };
   return bless $self, $class;
}

sub init {
   my ($self, %args) = @_;
   print "PLUGIN: init()\n";
   $self->{orig_tbl} = $args{orig_tbl};
}

sub after_alter_new_table {
   my $plugin_name = "PLUGIN: after_alter_new_table()";
   print "$plugin_name: START\n";

   my ($self, %args) = @_;
   my $new_tbl = $args{new_tbl};
   my $dbh     = $self->{cxn}->dbh;
   my $row = $dbh->selectrow_arrayref("SHOW CREATE TABLE $new_tbl->{name}");
   my $new_tbl_defaultdir = $row->[1];
   #dump $new_tbl;
   my $ramdisk_dir_db = RAMDISK_DIR."/$new_tbl->{db}/";
   my $dir_option = " DATA DIRECTORY='$ramdisk_dir_db' INDEX DIRECTORY='$ramdisk_dir_db'";
   if ((index($new_tbl_defaultdir, $dir_option) != -1 ) && (lc $new_tbl->{tbl_struct}->{engine} eq "myisam")) {
      print "$plugin_name: $new_tbl->{name} is on Ramdisk and is MyISAM: moving to default dir\n";
      $new_tbl_defaultdir =~ s/$dir_option//g;

      print "$plugin_name: DROP and CREATE new table on default dir\n $new_tbl_defaultdir\n\n";
      $dbh->do("DROP TABLE IF EXISTS $new_tbl->{name}");
      $dbh->do("$new_tbl_defaultdir");
   } else {
      print "$plugin_name: $new_tbl->{name} is not on Ramdisk or not MyISAM\n";
   }
   warn "$plugin_name: DONE\n";
}

1;

