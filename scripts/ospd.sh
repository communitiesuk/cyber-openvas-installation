export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH
mkdir -p /opt/gvm/lib/python3.8/site-packages/
export PYTHONPATH=/opt/gvm/lib/python3.8/site-packages
cd /tmp/gvm-source/ospd
python3 setup.py install --prefix=/opt/gvm
cd ../ospd-openvas
python3 setup.py install --prefix=/opt/gvm

