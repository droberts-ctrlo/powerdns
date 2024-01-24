package Common::WebUI;

use Rex -base;

use Net::Address::IP::Local;

task install_dependencies => sub {
    pkg [qw/python3-dev git libmysqlclient-dev libsasl2-dev libldap2-dev libssl-dev libxml2-dev libxslt1-dev libxmlsec1-dev libffi-dev pkg-config apt-transport-https python3-venv build-essential curl python3-pip nginx/], ensure => "present";
};

task install_node => sub {
    run "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -";
    pkg 'nodejs', ensure => 'present';
    run 'npm install -g npm@latest';
    run 'npm install -g yarn';
};

task install_pdns_admin => sub {
    run 'git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /var/www/html/pdns';
};

task setup_venv => sub {
    cd '/var/www/html/pdns';
    append_or_amend_line "/var/www/html/pdns/requirements.txt",
        line => "pyyaml!=6.0.0,!=5.4.0,!=5.4.1",
        regexp => '^PyYAML==5.4';
    append_or_amend_line "/var/www/html/pdns/requirements.txt",
        line => "psycopg2-binary==",
        regexp => '^psycopg2==';
    run 'pip install --upgrade pip';
    run 'pip install -r requirements.txt';
};

task setup_admin => sub {
    append_or_amend_line "/var/www/html/pdns/powerdnsadmin/default_config.py",
        line => "SQLA_DB_PASSWORD = '5ecur3Pa55w0rd'",
        regexp => '^SQLA_DB_PASSWORD = \'changeme\'';
    cd '/var/www/html/pdns';
    run 'export FLASK_APP=./powerdnsadmin/__init__.py && flask db upgrade && yarn install --pure-lockfile && flask assets build';
};

task setup_api => sub {
    my $uuid = `uuidgen`;
    append_or_amend_line "/etc/powerdns/pdns.conf",
        line => "api=yes",
        regexp => '^# api=',
        on_change => sub { service "pdns" => "restart"; };
    append_or_amend_line "/etc/powerdns/pdns.conf",
        line => "api-key=" . $uuid,
        regexp => '^# api-key=',
        on_change => sub { service "pdns" => "restart"; };
    Rex::Logger::info("API key: $uuid");
};

task setup_nginx => sub {
    my $server = connection->server;
    $server = Net::Address::IP::Local->public_ipv4 if $server eq '<local>';
    file "/etc/nginx/conf.d/pdns-admin.conf",
        source => template("/files/pdns-admin.conf.tpl", serveraddress=>$server),
        owner   => "root",
        mode    => 644,
        on_change => sub { service "nginx" => "restart"; };
    file "/var/www/html/pdns",
        ensure  => "directory",
        owner   => "www-data",
        mode    => 755,
        on_change => sub { service "nginx" => "restart"; };
    Rex::Logger::info("WebUI: https://$server");
};

task setup_service => sub {
    file "/etc/systemd/system/pdnsadmin.service",
        source => "/files/pdnsadmin.service",
        owner   => "root",
        mode    => 644;
    file "/etc/systemd/system/pdnsadmin.socket",
        source => "/files/pdnsadmin.socket",
        owner   => "root",
        mode    => 644;
    file "/run/pdnsadmin",
        ensure  => "directory",
        owner   => "pdns",
        mode    => 755,
        recurse => 1;
    run 'echo "d /run/pdnsadmin 0755 pdns pdns -" >> /etc/tmpfiles.d/pdnsadmin.conf';
    file "/var/www/html/pdns/powerdnsadmin/",
        ensure  => "directory",
        owner   => "pdns",
        mode    => 755,
        recurse => 1;
    run 'systemctl daemon-reload';
    run 'systemctl enable --now pdnsadmin.service pdnsadmin.socket';
};