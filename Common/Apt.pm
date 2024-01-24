package Common::Apt;
use Rex -base;
use Rex::Group();

task "autoremove" => sub {
    run "apt-get autoremove -y";
};

task "upgrade_system" => sub {
    run "apt-get upgrade -y";
};

1;
