package Common::PowerDNS;

use Rex -base;

use Data::Dumper;

task get_ips => sub {
    my $net_info = run 'ip addr show ens3';
    set connection->server, $net_info =~ 'inet\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})';
};

task install_packages => sub {
    update_package_db;
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
        source => "files/pdns.local.gmysql.conf",
        owner   => "pdns",
        mode    => 640;
    append_or_amend_line '/etc/powerdns/pdns.d/pdns.local.gmysql.conf',
        line => "gmysql-password=5ecur3Pa55w0rd",
        regexp => '^gmysql-password=YOUR_PASSWORD_HERE',
        on_change => sub { service "pdns" => "restart"; };
};

task "set_master", sub {
    append_or_amend_line '/etc/powerdns/pdns.conf',
        line => "master=yes",
        regexp => '^(# )?master=no',
        on_change => sub { service "pdns" => "restart"; };
};

task "set_slave", sub {
    append_or_amend_line '/etc/powerdns/pdns.conf',
        line => "slave=yes",
        regexp => '^(# )?slave=no';
    append_or_amend_line '/etc/powerdns/pdns.conf',
        line => "slave-cycle-interval=60",
        regexp => '^(# )?slave-cycle-interval=60';
    my $nameserver = get("nameserver1",'');
    die ("Invalid nameserver setting") if $nameserver eq '';
    run "mysql pda -e < 'INSERT INTO supermasters VALUES (" . $nameserver . ", \'ns2.replecateme.dev\',\'admin\')'";
    service "pdns" => "restart";
};

1;