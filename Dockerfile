FROM centos:7.9.2009

LABEL org.opencontainers.image.source="https://github.com/giovtorres/docker-centos7-slurm" \
      org.opencontainers.image.title="docker-centos7-slurm" \
      org.opencontainers.image.description="Slurm All-in-one Docker container on CentOS 7" \
      org.label-schema.docker.cmd="docker run -it -h slurmctl giovtorres/docker-centos7-slurm:latest" \
      maintainer="Giovanni Torres"

ENV PATH "/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

# Install common YUM dependency packages
RUN set -ex \
    && yum makecache fast \
    && yum -y update \
    && yum -y install epel-release \
    && yum -y install \
        autoconf \
        bash-completion \
        bzip2 \
        bzip2-devel \
        file \
        iproute \
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
        pkgconfig \
        psmisc \
        readline-devel \
        sqlite-devel \
        tcl-devel \
        tix-devel \
        tk \
        tk-devel \
        supervisor \
        wget \
        vim-enhanced \
        xz-devel \
        zlib-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

# Set Vim and Git defaults
RUN set -ex \
    && echo "syntax on"           >> "$HOME/.vimrc" \
    && echo "set tabstop=4"       >> "$HOME/.vimrc" \
    && echo "set softtabstop=4"   >> "$HOME/.vimrc" \
    && echo "set shiftwidth=4"    >> "$HOME/.vimrc" \
    && echo "set expandtab"       >> "$HOME/.vimrc" \
    && echo "set autoindent"      >> "$HOME/.vimrc" \
    && echo "set fileformat=unix" >> "$HOME/.vimrc" \
    && echo "set encoding=utf-8"  >> "$HOME/.vimrc" \
    && git config --global color.ui auto \
    && git config --global push.default simple

# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Install Python versions
ARG PYTHON_VERSIONS="3.6 3.7 3.8 3.9"
COPY files/install-python.sh /tmp
RUN set -ex \
    && for version in ${PYTHON_VERSIONS}; do /tmp/install-python.sh "$version"; done \
    && rm -f /tmp/install-python.sh

# Compile, build and install Slurm from Git source
ARG SLURM_TAG=slurm-20-02-0-1
RUN set -ex \
    && git clone https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && git checkout $SLURM_TAG \
    && ./configure --enable-front-end --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r slurm  \
    && useradd -r -g slurm slurm \
    && mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurm/{d,ctld} \
        /var/log/slurm \
        /var/run/slurmd \
    && chown -R slurm:slurm /var/spool/slurm \
        /var/log/slurm \
        /var/run/slurmd \
    && /sbin/create-munge-key
COPY files/slurm/slurm.conf /etc/slurm/slurm.conf
COPY files/slurm/gres.conf /etc/slurm/gres.conf
COPY files/slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY files/supervisord.conf /etc/

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurm", "/var/log/slurm"]

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
