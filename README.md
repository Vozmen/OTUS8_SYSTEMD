# OTUS8_SYSTEMD
Homework

����� ��������� ����������� ��
yum install -y \
epel-release \
spawn-fcgi php php-cli mod_fcgid httpd

������ ���� � ������������� �������
vi  /etc/sysconfig/watchlog
# Configuration file for my watchlog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log

������ ���� ���� � ������ ���� �������� �����
echo "ALERT" > /var/log/watchlog.log

������ ���� ������� � ��� �� ���� ������ ����� ���� �������������
vi /opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
chmod +x /opt/watchlog.sh

������ ���� ��� �������
vi /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG

� ��� �������
vi /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target

������������ systemd
systemctl daemon-reload

�������� ��� ����� ������, ����� ������� tail -f /var/log/messages
[root@sysd ~]# tail -f /var/log/messages
Jun 16 07:28:53 localhost systemd-logind: Removed session 4.
Jun 16 07:28:53 localhost systemd: Removed slice User Slice of vagrant.
Jun 16 07:29:25 localhost systemd: Created slice User Slice of vagrant.
Jun 16 07:29:25 localhost systemd: Started Session 5 of user vagrant.
Jun 16 07:29:25 localhost systemd-logind: New session 5 of user vagrant.
Jun 16 07:32:53 localhost systemd: Reloading.
Jun 16 07:33:14 localhost systemd: Started Run watchlog script every 30 second.
Jun 16 07:34:37 localhost systemd: Starting My watchlog service...
Jun 16 07:34:37 localhost root: Thu Jun 16 07:34:37 UTC 2022: I found word, Master!
Jun 16 07:34:37 localhost systemd: Started My watchlog service.

���������������� ������ � /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"

������ ���� ����
vi /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target

�������� � ��������, ������ �������� ���������, �� ����������� ������ �������������� [/etc/systemd/system/spawn-fcgi.service:1] Assignment outside of section. Ignoring.
systemctl start spawn-fcgi
systemctl status spawn-fcgi

���������� httpd.service � /etc/systemd/system � ������� �������� %I � ������������ ���������
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target

������������ � ���������� httpd.service
cp httpd.service httpd@first.service
cp httpd@.service httpd@first.service
cp httpd@.service httpd@second.service

������� ��� ����� ���������
echo "OPTIONS=-f conf/first.conf" > /etc/sysconfig/httpd-first
echo "OPTIONS=-f conf/second.conf" > /etc/sysconfig/httpd-second

� ���������� /etc/httpd/conf ���������� ���� httpd.conf
cp httpd.conf first.conf
cp httpd.conf second.conf

�� ������ ������� ������ Pid � ������� ���� �������������
PidFile /var/run/httpd-second.pid
Listen 8080

�������� ��� ������, ������ �������
�������� ������ ��������, ��� ����� ��������� ������, ��� � ���� ������� � �������
ss -tnulp | grep httpd
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=3589,fd=4),("httpd",pid=3588,fd=4),("httpd",pid=3587,fd=4),("httpd",pid=3586,fd=4),("httpd",pid=3585,fd=4),("httpd",pid=3584,fd=4),("httpd",pid=3583,fd=4))
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=3576,fd=4),("httpd",pid=3575,fd=4),("httpd",pid=3574,fd=4),("httpd",pid=3573,fd=4),("httpd",pid=3572,fd=4),("httpd",pid=3571,fd=4),("httpd",pid=3570,fd=4))
[root@sysd conf]