package Common::MariaDB;

use Rex -base;
use feature 'say';

#using errormeonpurpose as a method to stop compliation if the user forgets to set the master_ip_address variable

task install_mariadb => sub {
    update_package_db;
    pkg "mariadb-server", ensure => "present";
    service "mysql" => "start";
    service "mysql" => "enable";
    pkg "mariadb-client", ensure => "present";
    append_or_amend_line "/etc/mysql/mariadb.conf.d/50-server.cnf",
        line => "bind-address = 0.0.0.0\n",
        regexp => qr/^#?bind-address\s*=\s*(\d{1,3})(\.\d{1,3}){3}/,
        on_change => sub { service "mysql" => "restart"; },
        on_no_change => sub { say "No change needed"; };
};

task set_mariadb_binlog => sub {
    append_or_amend_line "/etc/mysql/mariadb.conf.d/50-server.cnf",
        line => "log_bin = /var/log/mysql/mariadb-bin\n",
        regexp => qr/^#?log_bin\s*=.*$/,
        on_change => sub { service "mysql" => "restart"; };
    append_or_amend_line "/etc/mysql/mariadb.conf.d/50-server.cnf",
        line => "max_binlog_size = 100M\n",
        regexp => qr/^#?max_binlog_size\s*=.*$/,
        on_change => sub { service "mysql" => "restart"; };
};

task setup_master => sub {
    append_or_amend_line "/etc/mysql/mariadb.conf.d/50-server.cnf",
        line => "server-id = 1\n",
        regexp => qr/^#?server-id\s*=.*$/,
        on_change => sub { service "mysql" => "restart"; };
};

task create_replication_user => sub {
    my $ip = $errormeonpurpose "{master_ip_address}";
    say "Please enter a password for the MariaDB user 'replication'";
    my $password = <STDIN>;
    chomp $password;
    run 'mysql -e "CREATE USER IF NOT EXISTS replication@\''.$ip.'\' IDENTIFIED BY \''.$password.'\'";';
    run 'mysql -e "GRANT REPLICATION SLAVE ON *.* TO replication@\''.$ip.'\';"';
    run 'mysql -e "FLUSH PRIVILEGES;"';
};

task setup_slave => sub {
    my $master_ip = $errormeonpurpose "{master_ip_address}";
    my $password = <STDIN>;
    chomp $password;
    append_or_amend_line "/etc/mysql/mariadb.conf.d/50-server.cnf",
        line => "server-id = 2\n",
        regexp => qr/^#?server-id\s*=.*$/,
        on_change => sub { service "mysql" => "restart"; };
    run 'mysql -e "STOP SLAVE;"';#
    run 'mysql -e "CHANGE MASTER TO MASTER_HOST=\''.$master_ip.'\', MASTER_USER=\'replication\', MASTER_PASSWORD=\''.$password.'\', MASTER_LOG_FILE=\'mariadb-bin.000001\', MASTER_LOG_POS=0;"';
    run 'mysql -e "START SLAVE;"';
};

1;