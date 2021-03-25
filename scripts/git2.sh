export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH
cd /tmp/gvm-source/gvmd
mkdir build 
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm
make && make install

cd ../../gsa
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm
make && make install

greenbone-scapdata-sync
greenbone-certdata-sync
gvm-manage-certs -a

cat <<EOT > /opt/gvm/updatedefs.sh
echo "-------------------------------------------------------"
echo "------------------------- Starting Update -------------"
echo "-------------------------------------------------------"
greenbone-scapdata-sync
greenbone-certdata-sync
greenbone-nvt-sync
openvas --update-vt-info
greenbone-feed-sync --type GVMD_DATA
greenbone-feed-sync --type SCAP
greenbone-feed-sync --type CERT
echo "Completed update at " \`date\`
EOT

chmod +x /opt/gvm/updatedefs.sh
echo "@reboot /opt/gvm/updatedefs.sh >> /opt/gvm/var/log/gvm/update.log" | crontab -
echo "0 0 * * * /opt/gvm/updatedefs.sh >> /opt/gvm/var/log/gvm/update.log" | crontab -
