#!/bin/bash
set -o errexit

PYTHON_VERSION="$1"

function cleanup ()
{
    yum clean all
    rm -rf /var/yum/cache
}

trap "cleanup" TERM EXIT

function install_python_26 ()
{
    wget https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz
    tar xzf Python-2.6.9.tgz
    pushd Python-2.6.9
    export CFLAGS="-D_GNU_SOURCE -fPIC -fwrapv"
    export CXXFLAGS="-D_GNU_SOURCE -fPIC -fwrapv"
    export OPT="-D_GNU_SOURCE -fPIC -fwrapv"
    export LINKCC="gcc"
    export CC="gcc"
    ./configure --enable-ipv6 --enable-unicode=ucs4 --enable-shared --with-system-ffi
    make install
    unset CFLAGS CXXFLAGS OPT LINKCC CC
    popd
    rm -rf Python-2.6.9
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/python-2.6.conf
    chmod 0644 /etc/ld.so.conf.d/python-2.6.conf
    /sbin/ldconfig
    wget https://bootstrap.pypa.io/2.6/get-pip.py
    /usr/local/bin/python2.6 get-pip.py
    rm -f get-pip.py Python-2.6.9.tgz

    pip2.6 install Cython nose
}

function centos_install_ius ()
{
    rpm -q ius-release || yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    rpm --import --verbose /etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7
}

printf "Installing Python %s\n" "${PYTHON_VERSION}"
yum makecache fast

case "${PYTHON_VERSION}" in
    2.6) install_python_26 ;;
    2.7) yum -y install python-{devel,pip} ;;
    3.4) yum -y install python34{,-devel,-pip} ;;
    3.5|3.6)
        centos_install_ius
        yum -y install python"${PYTHON_VERSION//.}"u{,-devel,-pip}
        ;;
    *)
        echo "Python version not supported!"
        exit 1
        ;;
esac

"pip${PYTHON_VERSION}" install Cython nose
