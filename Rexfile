#Need cpanminus libio-pty-perl libxml-simple-perl libdevel-caller-perl to install Rex
use lib './Common';

use Rex -base;

include qw/
    Common::PowerDNS
    Common::WebUI
/;

user "vmuser";
private_key "multipass-ssh-key";
public_key "multipass-ssh-key.pub";
key_auth;

group nameservers => "nameserver1";

task "pdns", group => "nameservers", sub {
    update_package_db;
    Common::PowerDNS::install_packages();
    Common::PowerDNS::create_mariadb_user();
    Common::PowerDNS::create_mariadb_tables();
    Common::PowerDNS::disable_resolved();
    Common::PowerDNS::setup_mysql_connection();
};

task "webui", group => "nameservers", sub {
    Common::WebUI::install_dependencies();
    Common::WebUI::install_node();
    Common::WebUI::install_pdns_admin();
    Common::WebUI::setup_venv();
    Common::WebUI::setup_admin();
    Common::WebUI::setup_api();
    Common::WebUI::setup_nginx();
    Common::WebUI::setup_service();
};