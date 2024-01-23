package Common::Apt;
use Rex -base;
use Rex::Group();

task "autoremove" => sub {
    my $restart_required = run "apt-get autoremove -y";
};

task "upgrade_system" => sub {
    update_package_db;
    my $restart_required = run "apt-get upgrade -y";
};

1;
