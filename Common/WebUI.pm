package Common::WebUI;

use Rex -base;

use Net::Address::IP::Local;

task install_dependencies => sub {
    pkg [qw/python3-dev git libmysqlclient-dev libsasl2-dev libldap2-dev libssl-dev libxml2-dev libxslt1-dev libxmlsec1-dev libffi-dev pkg-config apt-transport-https python3-venv build-essential curl/], ensure => "present";
};

task install_node => sub {
    run 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash';
    run 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm';
    run 'nvm install --lts';
    run 'npm install -g npm@latest';
    run 'npm install -g yarn';
};

task install_pdns_admin => sub {
    run 'git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /var/www/html/pdns';
};

task setup_venv => sub {
    run 'cd /var/www/html/pdns';
    append_or_amend_line '/var/www/html/pdns/requirements.txt', line => 'pyyaml!=6.0.0,!=5.4.0,!=5.4.1', regexp => 'pyyaml==5.4';
    append_or_amend_line '/var/www/html/pdns/requirements.txt', line => 'psycopg2-binary', regexp => 'psycopg2';
    run 'virtualenv -p python3 flask';
    run 'source ./flask/bin/activate';
    run 'pip install --upgrade pip';
    run 'pip install -r requirements.txt';
    run 'deactivate';
};

task setup_admin => sub {
    run 'cd /var/www/html/pdns';
    append_or_amend_line '/var/www/html/pdns/powerdnsadmin/default_config.py', line => 'SQLA_DB_PASSWORD = \'5ecur3Pa55w0rd\'', regexp => 'SQLA_DB_PASSWORD = \'changeme\'';
    run 'source ./flask/bin/activate';
    run 'export FLASK_APP=powerdnsadmin/__init__.py';
    run 'flask db upgrade';
    run 'yarn install --pure-lockfile';
    run 'flask assets build';
    run 'deactivate';
};

task setup_api => sub {
    my $uuid = `uuidgen`;
    append_or_amend_line '/etc/powerdns/pdns.conf', line => 'api=yes', regexp => '^# api=$';
    append_or_amend_line '/etc/powerdns/pdns.conf', line => 'api-key=' . $uuid, regexp => '^# api-key=$';
    Rex::Logger::info("API key: $uuid");
    run "service pdns restart";
};

task setup_nginx => sub {
    my $server = connection->server;
    $server = Net::Address::IP::Local->public_ipv4 if $server eq '<local>';
    pkg 'nginx', ensure => 'present';
    file "/etc/nginx/conf.d/pdns-admin.conf",
        source => "files/pdns-admin.conf",
        owner   => "root",
        mode    => 644;
    append_or_amend_line '/etc/nginx/conf.d/pdns-admin.conf', line => $server . ';', regexp => 'server-address-1542;';
    file "/var/www/html/pdns",
        ensure  => "directory",
        owner   => "www-data",
        mode    => 755;
    run "service nginx restart";
    Rex::Logger::info("WebUI: https://$server");
};

task setup_service => sub {
    file "/etc/systemd/system/pdnsadmin.service",
        source => "files/pdnsadmin.service",
        owner   => "root",
        mode    => 644;
    file "/etc/systemd/system/pdnsadmin.socket",
        source => "files/pdnsadmin.socket",
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