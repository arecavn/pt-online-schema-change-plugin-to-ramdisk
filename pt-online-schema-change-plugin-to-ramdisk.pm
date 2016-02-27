##### pt_online_schema_change_plugin - Move to ramdisk for MyISAM table
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
   my $new_tbl_ramdisk = $row->[1];
   #dump $new_tbl;
   my $dir_option = " DATA DIRECTORY='".RAMDISK_DIR."/$new_tbl->{db}/' INDEX DIRECTORY='".RAMDISK_DIR."/$new_tbl->{db}/'";
   if ((index($new_tbl_ramdisk, $dir_option) == -1) && (lc $new_tbl->{tbl_struct}->{engine} eq "myisam")) {
      print "$plugin_name: $new_tbl->{name} is not on Ramdisk and is MyISAM: moving to Ramdisk\n";

      make_path("$ramdisk_dir_db", {owner=>'mysql', group=>'mysql'});

      $new_tbl_ramdisk = $new_tbl_ramdisk . $dir_option;
      print "$plugin_name: DROP and CREATE new table on Ramdisk\n $new_tbl_ramdisk\n\n";
      $dbh->do("DROP TABLE IF EXISTS $new_tbl->{name}");
      $dbh->do("$new_tbl_ramdisk");
   } else {
      print "$plugin_name: $new_tbl->{name} is already on Ramdisk or not MyISAM\n";
   }
   warn "$plugin_name: DONE\n";
}

1;
