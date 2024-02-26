# Rex script to set up replicated PowerDNS server

## Files

- Common/MariaDB.pm - scripts for MariaDB
- Common/PowerDNS.pm - scripts for PowerDNS
- files/pdns.local.mysql.conf.tpl - Template for PowerDNS MySQL connection
- scripts/powerdns.sql - Script to set up PowerDNS MySQL tables
- cloud-init.yml - Init file for use with Multipass for testing defining the public key and user for SSH connection
- multipass-ssh-key.pub - Public key for use with Multipass for testing
- Rexfile - The actual Rexfile

