dir="/tmp/gvm-source"

if [[ ! -e $dir ]]; then
    mkdir $dir
elif [[ ! -d $dir ]]; then
    echo "$dir already exists but is not a directory" 1>&2
fi

cd /tmp/gvm-source

git clone -b gvm-libs-20.08 https://github.com/greenbone/gvm-libs.git
git clone https://github.com/greenbone/openvas-smb.git
git clone -b openvas-20.08 https://github.com/greenbone/openvas.git
git clone -b ospd-20.08 https://github.com/greenbone/ospd.git
git clone -b ospd-openvas-20.08  https://github.com/greenbone/ospd-openvas.git
git clone -b gvmd-20.08  https://github.com/greenbone/gvmd.git
git clone -b gsa-20.08 https://github.com/greenbone/gsa.git

export PKG_CONFIG_PATH=/opt/gvm/lib/pkgconfig:$PKG_CONFIG_PATH
cd gvm-libs
mkdir build 
cd build && cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm && make && make install

cd ../../openvas-smb/
mkdir build 
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm
make && make install

cd ../../openvas
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gvm
make && make install
