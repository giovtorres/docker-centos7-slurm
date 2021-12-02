FROM centos:7.9.2009

LABEL org.opencontainers.image.source="https://github.com/drewsilcock/docker-centos7-slurm" \
    org.opencontainers.image.title="docker-centos7-slurm" \
    org.opencontainers.image.description="Slurm All-in-one Docker container on CentOS 7" \
    org.label-schema.docker.cmd="docker run -it -h slurmctl drewsilcock/docker-centos7-slurm:latest" \
    maintainer="Drew Silcock"

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
    http-parser-devel \
    json-c-devel \
    libyaml-devel \
    libjwt-devel \
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
ARG SLURM_TAG=slurm-21-08-0-1
RUN set -ex \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --prefix=/usr --sysconfdir=/etc/slurm \
    --with-mysql_config=/usr/bin --libdir=/usr/lib64 \
    --enable-slurmrestd --with-jwt \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m600 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r slurm -g 1001 \
    && useradd -r -g slurm -u 1001 -c "scheduler daemon" -s /bin/bash slurm \
    && groupadd -r slurmrestd -g 1002 \
    && useradd -r -g slurmrestd -u 1002 -c "REST daemon" -s /bin/bash slurmrestd \
    && mkdir -p /etc/sysconfig/slurm \
    /var/spool/slurmd \
    /var/spool/slurmctld \
    /var/log/slurm \
    /var/run/slurm \
    && chown -R slurm:slurm /var/spool/slurmd \
    /var/spool/slurmctld \
    /var/log/slurm \
    /var/run/slurm \
    && /sbin/create-munge-key
COPY --chown=slurm files/slurm/slurm.conf /etc/slurm/slurm.conf
COPY --chown=slurm files/slurm/gres.conf /etc/slurm/gres.conf
COPY --chown=slurm files/slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY --chown=slurm files/slurm/slurmrestd.conf /etc/slurm/slurmrestd.conf
COPY files/supervisord.conf /etc/

RUN setcap cap_setgid+ep /usr/sbin/slurmrestd
RUN chmod 0600 /etc/slurm/slurmdbd.conf

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurm", "/var/log/slurm"]

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
