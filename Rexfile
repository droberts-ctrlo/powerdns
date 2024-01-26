use lib './Common';

use Rex -base;
use Rex::Commands::Host;

include qw/
    Common::PowerDNS
/;

user "root";
key_auth;

task "pdns", sub {
    Common::PowerDNS::install_packages();
    Common::PowerDNS::create_mariadb_user();
    Common::PowerDNS::create_mariadb_tables();
    Common::PowerDNS::disable_resolved();
    Common::PowerDNS::setup_mysql_connection();
};

task "create_zone", sub {
    say "Enter zone name";
    my $zone = <STDIN>;
    chomp $zone;
    say "Enter IP";
    my $ip = <STDIN>;
    chomp $ip;
    Common::PowerDNS::create_zone($ip, $zone);
}