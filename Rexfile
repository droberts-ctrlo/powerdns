use lib './Common';

use Rex -base;

include qw/
    Common::PowerDNS
/;

user "vmuser";
private_key "multipass-ssh-key";
public_key "multipass-ssh-key.pub";
key_auth;

group nameservers => "nameserver1", "nameserver2";

task "get_ips", group => "nameservers", sub {
    Common::PowerDNS::get_ips();
};

task "pdns", group => "nameservers", sub {
    Common::PowerDNS::install_packages();
    Common::PowerDNS::create_mariadb_user();
    Common::PowerDNS::create_mariadb_tables();
    Common::PowerDNS::disable_resolved();
    Common::PowerDNS::setup_mysql_connection();
};

task "set_master", "nameserver1", sub {
    Common::PowerDNS::set_master();
};

task "set_slave", "nameserver2", sub {
    Common::PowerDNS::set_slave();
};

task "init", "nameserver1", sub {
    my $return = run 'pdnsutil create-zone replicated.dev';
    Rex::Logger::info($return);
    $return = run 'pdnsutil add-record replicated.dev @ NS nameserver1';
    Rex::Logger::info($return);
    $return = run 'pdnsutil add-record replicated.dev @ NS nameserver2';
    Rex::Logger::info($return);
    $return = run 'pdnsutil increase-serial replicated.dev';
    Rex::Logger::info($return);
    $return = run 'pdnsutil notify replicated.dev';
    Rex::Logger::info($return);
};

batch "get_ips", "full_install", "pdns", "set_master", "set_slave";