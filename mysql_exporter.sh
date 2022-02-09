#!/usr/bin/env bash

#TODO: Write the actual commands
read -p 'Enter admin user for mysql: ' -r ADMIN_USER
read -sp 'Enter the password for admin user: ' -r ADMIN_PASS
read -sp 'Enter the password for mysqld_exporter user' -r MYSQLD_PASS

#TODO: Find how to take password from user input when running the script.
"CREATE USER 'mysqld_exporter'@'localhost' IDENTIFIED BY ${MYSQLD_PASS} WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';
FLUSH PRIVILEGES;" >sql_create_user.sql

mysql --host=localhost --user="${ADMIN_USER}" --password="${ADMIN_PASS}" -e "source sql_create_user.sql"

echo "[client]
user=mysqld_exporter
password=${MYSQLD_PASS}
" >/etc/.mysqld_exporter.cnf

chown root:prometheus /etc/.mysqld_exporter.cnf

useradd -rs /bin/false mysqld_exporter
# Create systemd service file.
echo "[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=mysqld_exporter
Group=mysqld_exporter

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \\
--config.my-cnf /etc/.mysqld_exporter.cnf \\
--collect.global_status \\
--collect.info_schema.innodb_metrics \\
--collect.auto_increment.columns \\
--collect.info_schema.processlist \\
--collect.binlog_size \\
--collect.info_schema.tablestats \\
--collect.global_variables \\
--collect.info_schema.query_response_time \\
--collect.info_schema.userstats \\
--collect.info_schema.tables \\
--collect.perf_schema.tablelocks \\
--collect.perf_schema.file_events \\
--collect.perf_schema.eventswaits \\
--collect.perf_schema.indexiowaits \\
--collect.perf_schema.tableiowaits \\
--collect.slave_status \\
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target" >/etc/system/systemd/mysqld_exporter.service
