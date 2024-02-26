package Common::PowerDNS;

use Rex -base;

task install_packages => sub {
    update_package_db;
    pkg "pdns-server", ensure => "present";
    pkg "pdns-backend-mysql", ensure=>"present";
};

task create_mariadb_user => sub {
    say "Please enter a password for the MariaDB user 'pda'";
    my $password = <STDIN>;
    chomp $password;
    run "mysql -e 'CREATE DATABASE IF NOT EXISTS pda;'";
    run "mysql -e 'GRANT ALL PRIVILEGES ON pda.* TO pda\@localhost IDENTIFIED BY \"$password\";'";
    run "mysql -e 'FLUSH PRIVILEGES;'";
};

task create_mariadb_tables => sub {
    say "Please enter the password for the MariaDB user 'pda'";
    my $password = <STDIN>;
    chomp $password;

    open SQL, "<./scripts/powerdns.sql" or die $!;

    while(<SQL>) {
        my $result = run "mysql pda --password=$password -e '$_'";
        Rex::Logger::info($result);
    }

    close SQL;
};

task disable_resolved => sub {
    service "systemd-resolved" => "stop";
    service "systemd-resolved" => "disable";
    rm "/etc/resolv.conf";
    run "echo \"nameserver 8.8.8.8\" | tee /etc/resolv.conf";
};

task setup_mysql_connection => sub {
    say "Please enter the password for the MariaDB user 'pda'";
    my $password = <STDIN>;
    chomp $password;
    file "/etc/powerdns/pdns.d/pdns.local.gmysql.conf",
        content => template("files/pdns.local.gmysql.conf.tpl", password => $password),
        owner   => "pdns",
        mode    => 640;
};
