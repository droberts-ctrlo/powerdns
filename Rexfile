use lib './Common';

use Rex -base;
use Rex::Commands::Host;

include qw/
    Common::PowerDNS
/;

user "vmuser";
private_key "multipass-ssh-key";
public_key "multipass-ssh-key.pub";
key_auth;

group nameservers => "nameserver1", "nameserver2";

task "pdns", sub {
    Common::PowerDNS::install_packages();
    Common::PowerDNS::create_mariadb_user();
    Common::PowerDNS::create_mariadb_tables();
    Common::PowerDNS::disable_resolved();
    Common::PowerDNS::setup_mysql_connection();
};
