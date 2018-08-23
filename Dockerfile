FROM centos:7

LABEL org.label-schema.vcs-url="https://github.com/giovtorres/docker-centos7-slurm" \
      org.label-schema.docker.cmd="docker run -it -h ernie giovtorres/docker-centos7-slurm:latest" \
      org.label-schema.name="docker-centos7-slurm" \
      org.label-schema.description="Slurm All-in-one Docker container on CentOS 7" \
      maintainer="Giovanni Torres"

ARG SLURM_TAG=slurm-17-11-9-2

RUN yum makecache fast \
    && yum -y install epel-release \
    && yum -y install \
        autoconf \
        bash-completion \
        bzip2 \
        bzip2-devel \
        file \
        gcc \
        gcc-c++ \
        gdbm-devel \
        git \
        glibc-devel \
        gmp-devel \
        libffi-devel \
        libGL-devel \
        libX11-devel \
        make \
        mariadb-server \
        mariadb-devel \
        munge \
        munge-devel \
        ncurses-devel \
        openssl-devel \
        openssl-libs \
        perl \
        pkconfig \
        psmisc \
        python-devel \
        python-pip \
        python34 \
        python34-devel \
        python34-pip \
        readline-devel \
        sqlite-devel \
        tcl-devel \
        tix-devel \
        tk \
        tk-devel \
        supervisor \
        wget \
        vim-enhanced \
        zlib-devel \
    && yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
    && yum -y install \
        python35u \
        python35u-devel \
        python35u-pip \
        python36u \
        python36u-devel \
        python36u-pip \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN set -x \
    && wget https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz \
    && tar xzf Python-2.6.9.tgz \
    && pushd Python-2.6.9 \
    && export CFLAGS="-D_GNU_SOURCE -fPIC -fwrapv" \
    && export CXXFLAGS="-D_GNU_SOURCE -fPIC -fwrapv" \
    && export OPT="-D_GNU_SOURCE -fPIC -fwrapv" \
    && export LINKCC="gcc" \
    && export CC="gcc" \
    && ./configure --enable-ipv6 --enable-unicode=ucs4 --enable-shared --with-system-ffi \
    && make install \
    && unset CFLAGS CXXFLAGS OPT LINKCC CC \
    && popd \
    && rm -rf Python-2.6.9 \
    && echo "/usr/local/lib" >> /etc/ld.so.conf.d/python-2.6.conf \
    && chmod 0644 /etc/ld.so.conf.d/python-2.6.conf \
    && /sbin/ldconfig \
    && wget https://bootstrap.pypa.io/2.6/get-pip.py \
    && /usr/local/bin/python2.6 get-pip.py \
    && rm -f get-pip.py Python-2.6.9.tgz

RUN pip2.6 install Cython nose \
    && pip2.7 install Cython nose \
    && pip3.4 install Cython nose \
    && pip3.5 install Cython nose \
    && pip3.6 install Cython nose

RUN set -x \
    && git clone https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && git checkout tags/$SLURM_TAG \
    && ./configure --enable-debug --enable-front-end --prefix=/usr \
       --sysconfdir=/etc/slurm --with-mysql_config=/usr/bin \
       --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurm.epilog.clean /etc/slurm/slurm.epilog.clean \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r slurm  \
    && useradd -r -g slurm slurm \
    && mkdir /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/lib/slurmd \
        /var/log/slurm \
    && chown slurm:root /var/spool/slurmd \
        /var/run/slurmd \
        /var/lib/slurmd \
        /var/log/slurm \
    && /sbin/create-munge-key

COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY supervisord.conf /etc/

VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurmd", "/var/log/slurm"]

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
