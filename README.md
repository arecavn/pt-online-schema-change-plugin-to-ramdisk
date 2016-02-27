# pt-online-schema-change-plugin-to-ramdisk
pt-online-schema-change plugin: create new table on ramdisk for MyISAM

Plugin for pt-online-schema-change, a tool alters a table’s structure without blocking reads or writes.
https://www.percona.com/doc/percona-toolkit/2.2/pt-online-schema-change.html

Usage:
  Only add following to pt_online_schema_change command: " --plugin path-to-this-script"
  Example: 
   pt-online-schema-change -hlocalhost -uU1 -p123 --alter='ADD column c1 int' D=db1,t=tbl1 --execute --socket=/var/lib/mysql/mysql.sock --plugin /path-to/pt-online-schema-change-plugin-to-ramdisk.pm
   
   This will add column c1 into table tbl1 and move tbl1 to Ramdisk.
   
