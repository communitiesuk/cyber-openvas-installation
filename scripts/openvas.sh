set -x
usermod -aG root ubuntu

useradd -r -d /opt/gvm -c "GVM User" -s /bin/bash gvm
mkdir /opt/gvm
chown -R gvm:gvm /opt/gvm

apt-get update -y
apt install -y cmake pkg-config redis libhiredis-dev libpcap-dev libssh-gcrypt-dev libhiredis-dev libgpgme-dev libgnutls28-dev heimdal-dev libpopt-dev gcc-mingw-w64 libglib2.0-dev libgnutls28-dev gcc libglib2.0-dev libgnutls28-dev libpq-dev libical-dev libical-dev gnutls-bin doxygen bison libksba-dev openvas-cli postgresql-server-dev-12 pkg-config libical-dev xsltproc libmicrohttpd-dev libxml2-dev npm python3-setuptools python3-paramiko python3-lxml python3-defusedxml python3-dev gettext python3-polib xmltoman python3-pip dos2unix libunistring-dev

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update
apt install -y yarn

apt install -y postgresql postgresql-contrib postgresql-server-dev-all
apt install -y texlive-latex-extra --no-install-recommends
apt install -y texlive-fonts-recommended

dir=`pwd`

dos2unix $dir/postgres.sh
dos2unix $dir/git.sh
dos2unix $dir/git2.sh
dos2unix $dir/ospd.sh
dos2unix $dir/gvmd.sh

/bin/su -c "$dir/postgres.sh $dir" - postgres

systemctl restart postgresql
systemctl enable postgresql

/bin/su -c "$dir/git.sh" - gvm

###########################################

cp /tmp/gvm-source/openvas/config/redis-openvas.conf /etc/redis/
chown redis:redis /etc/redis/redis-openvas.conf

echo "db_address = /run/redis-openvas/redis.sock" > /opt/gvm/etc/openvas/openvas.conf

chown gvm:gvm /opt/gvm/etc/openvas/openvas.conf

usermod -aG redis gvm

echo "net.core.somaxconn = 1024" >> /etc/sysctl.conf

echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

sysctl -p

############################################

cat <<EOT >> /etc/systemd/system/disable_thp.service
[Unit]
Description=Disable Kernel Support for Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled &amp;&amp; echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable --now redis-server@openvas
echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/openvas" > /etc/sudoers.d/gvm
echo "gvm ALL = NOPASSWD: /opt/gvm/sbin/gsad" >> /etc/sudoers.d/gvm

echo "Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/gvm/sbin"" >> /etc/sudoers.d/gvm
echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin"' > /opt/gvm/.bash_profile

echo "export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig" >> /opt/gvm/.bash_profile
echo "export PYTHONPATH=/opt/gvm/lib/python3.8/site-packages" >> /opt/gvm/.bash_profile

echo "export LD_LIBRARY_PATH=/opt/gvm/lib/" >> /opt/gvm/.bash_profile

/bin/su -c "greenbone-nvt-sync" - gvm
/bin/su -c "openvas --update-vt-info" - gvm

#############################################
echo "/opt/gvm/lib" >> /etc/ld.so.conf.d/gvm.conf
ldconfig

dir=`pwd`

/bin/su -c "$dir/git2.sh" - gvm

/bin/su -c "$dir/ospd.sh" - gvm



cat <<EOT > /etc/systemd/system/openvas.service
[Unit]
Description=Control the OpenVAS service
After=redis.service
After=postgresql.service

[Service]
ExecStartPre=-rm -rf /opt/gvm/var/run/ospd-openvas.pid /opt/gvm/var/run/ospd.sock /opt/gvm/var/run/gvmd.sock
Type=simple
User=gvm
Group=gvm
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin
Environment=PYTHONPATH=/opt/gvm/lib/python3.8/site-packages
ExecStart=/usr/bin/python3 /opt/gvm/bin/ospd-openvas \
--pid-file /opt/gvm/var/run/ospd-openvas.pid \
--log-file /opt/gvm/var/log/gvm/ospd-openvas.log \
--lock-file-dir /opt/gvm/var/run -u /opt/gvm/var/run/ospd.sock
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl start openvas
systemctl enable openvas

cat <<EOT > /etc/systemd/system/gsa.service
[Unit]
Description=Control the OpenVAS GSA service
After=openvas.service

[Service]
Type=simple
User=gvm
Group=gvm
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin
Environment=PYTHONPATH=/opt/gvm/lib/python3.8/site-packages
ExecStart=/usr/bin/sudo /opt/gvm/sbin/gsad
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT

##########################

cat <<EOT > /etc/systemd/system/gsa.path
[Unit]
Description=Start the OpenVAS GSA service when gvmd.sock is available

[Path]
PathChanged=/opt/gvm/var/run/gvmd.sock
Unit=gsa.service

[Install]
WantedBy=multi-user.target
EOT


cat <<EOT > /etc/systemd/system/gvm.service
[Unit]
Description=Control the OpenVAS GVM service
After=openvas.service

[Service]
Type=simple
User=gvm
Group=gvm
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/gvm/bin:/opt/gvm/sbin:/opt/gvm/.local/bin
Environment=PYTHONPATH=/opt/gvm/lib/python3.8/site-packages
ExecStart=/opt/gvm/sbin/gvmd --osp-vt-update=/opt/gvm/var/run/ospd.sock
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT


cat <<EOT > /etc/systemd/system/gvm.path
[Unit]
Description=Start the OpenVAS GVM service when opsd.sock is available

[Path]
PathChanged=/opt/gvm/var/run/ospd.sock
Unit=gvm.service

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable --now gvm.path
systemctl enable --now gvm.service
systemctl enable --now gsa.path
systemctl enable --now gsa.service

sleep 45m

/bin/su -c "$dir/gvmd.sh" - gvm