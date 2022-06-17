#Soft install
yum install -y \
epel-release \
php \
php-cli \
mod_fcgid \
httpd \
spawn-fcgi

#Create config file
cat << EOF > /etc/sysconfig/watchlog
WORD=\"ALERT\"
LOG=/var/log/watchlog.log
EOF

#Create log file
echo "ALERT" > /var/log/watchlog.log

#Create script
cat << EOF > /opt/watchlog.sh
#!/bin/bash
WORD=\$1
LOG=\$2
DATE=\`date\`
if grep \$WORD \$LOG &> /dev/null
then
logger "\$DATE: I found word, Master!"
else
exit 0
fi
EOF

#Full rights to script
chmod +x /opt/watchlog.sh

#Create watchlog.service
cat << EOF > /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh \$WORD \$LOG
EOF

#Create watchlog.timer
cat << EOF > /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF

#Reload systemd
systemctl daemon-reload

#Start service
systemctl start watchlog.timer
systemctl start watchlog.service

#Change spawn-fcgi
cat << EOF > /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s \$SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
EOF

#Make unit file
cat << EOF > /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

#Copy&Change httpd.service
cat << EOF >  /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd \$OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd \$OPTIONS -k graceful
ExecStop=/bin/kill -WINCH \${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

#Rename&Copy httpd.service
cp /etc/systemd/system/httpd.service /etc/systemd/system/httpd@service
cp /etc/systemd/system/httpd@.service /etc/systemd/system/httpd@first.service
cp /etc/systemd/system/httpd@.service /etc/systemd/system/httpd@second.service

#Add environment files
echo "OPTIONS=-f conf/first.conf" > /etc/sysconfig/httpd-first
echo "OPTIONS=-f conf/second.conf" > /etc/sysconfig/httpd-second

#Download first.conf&second.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf

¬о втором добавил запись Pid и изменил порт прослушивани€
PidFile /var/run/httpd-second.pid
Listen 8080

#Start services
systemctl start httpd@first
systemctl start httpd@second

ѕроверка портов показала, что порты слушаютс€ разные, как и было указано в конфиге
ss -tnulp | grep httpd