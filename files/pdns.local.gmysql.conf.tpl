# MySQL Configuration
#
# Launch gmysql backend
launch+=gmysql
# gmysql parameters
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=pda
gmysql-user=pda
gmysql-password=<%= $password %>
gmysql-dnssec=yes
# gmysql-socket=