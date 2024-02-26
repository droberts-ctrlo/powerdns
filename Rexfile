use lib './Common';

use Rex -base;
use Rex::Commands::Host;

include qw/
    Common::PowerDNS
    Common::MariaDB
/;

user "root";
key_auth;
group nameservers => "nameserver[1..2]";

task "setup_pdns", group => "nameservers", sub {
    Common::PowerDNS::install_packages();
    Common::PowerDNS::disable_resolved();
    Common::PowerDNS::setup_mysql_connection();
    Common::PowerDNS::create_mariadb_user();
    Common::PowerDNS::create_mariadb_tables();
};

task "install_mariadb" => group=>"nameservers",sub {
    Common::MariaDB::install_mariadb();
};

task "setup_master" => "nameserver1", sub {
    Common::MariaDB::setup_master();
    Common::MariaDB::set_mariadb_binlog();
    Common::MariaDB::create_replication_user();
};

task "setup_slave" => "nameserver2", sub {
    Common::MariaDB::set_mariadb_binlog();
    Common::MariaDB::setup_slave();
};

batch "run_setup" => "install_mariadb", "setup_master", "setup_slave", "setup_pdns";