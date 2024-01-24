package Common::PowerDNS;

use Rex -base;

task install_packages => sub {
    pkg [qw/pdns-server pdns-backend-mysql mariadb-server mariadb-client/], ensure => "present";
};

task create_mariadb_user => sub {
    run "mysql -e 'CREATE DATABASE IF NOT EXISTS pda;'";
    run "mysql -e 'GRANT ALL PRIVILEGES ON pda.* TO pda\@localhost IDENTIFIED BY \"5ecur3Pa55w0rd\";'";
    run "mysql -e 'FLUSH PRIVILEGES;'";
};

task create_mariadb_tables => sub {
    open SQL, "<./scripts/powerdns.sql" or die $!;

    while(<SQL>) {
        run "mysql pda -e '$_'";
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
    file "/etc/powerdns/pdns.d/pdns.local.gmysql.conf",
        source => "/files/pdns.local.gmysql.conf",
        owner   => "pdns",
        mode    => 640;
    append_or_amend_line '/etc/powerdns/pdns.d/pdns.local.gmysql.conf',
        line => "gmysql-password=5ecur3Pa55w0rd",
        regexp => '^gmysql-password=YOUR_PASSWORD_HERE',
        on_change => sub { service "pdns" => "restart"; };
};

1;