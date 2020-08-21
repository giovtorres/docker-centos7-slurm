FROM centos:7.7.1908

ENV PATH "/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"
ARG SBT_VERSION=1.3.13
ARG SLURM_VERSION=19-05-4-1

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
        dpkg \
        dpkg-devel \
        file \
        freeglut \
        freeglut-devel \
        iproute \
        gcc \
        gcc-c++ \
        gdbm-devel \
        git \
        glibc-devel \
        gmp-devel \
        gstreamer \
        gstreamer-devel \
        gstreamer-python \
        gstreamer-python-devel \
        gstreamer-plugins-base \
        gstreamer-plugins-base-devel \
        gtk+ \
        gtk+-devel \
        gtk2 \
        gtk2-devel \
        java-1.8.0-openjdk-devel \
        libjpeg-turbo \
        libjpeg-turbo-devel \
        libffi-devel \
        libGL-devel \
        libnotify \
        libnotify-devel \
        libpng \
        libpng-devel \
        libSM \
        libSM-devel \
        libtiff \
        libtiff-devel \
        libX11-devel \
        libXtst \
        libXtst-devel \
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
        readline-devel \
        SDL \
        SDL-devel \
        sqlite-devel \
        tcl-devel \
        tix-devel \
        tk \
        tk-devel \
        supervisor \
        vim-enhanced \
        webkitgtk \
        webkitgtk-devel \
        webkitgtk \
        webkitgtk-devel \
        wget \
        wxGTK \
        wxGTK-devel \
        wxGTK3 \
        wxGTK3-devel \
        xz-devel \
        zlib-devel \
    && wget http://dl.bintray.com/sbt/rpm/sbt-$SBT_VERSION.rpm \
    && yum install -y sbt-$SBT_VERSION.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum

# Install Python 3.7
COPY files/install-python.sh /tmp
#ARG PYTHON_VERSIONS="2.7 3.5 3.6 3.7 3.8"
ARG PYTHON_VERSIONS="3.7"
RUN set -ex \
    && for version in ${PYTHON_VERSIONS}; do /tmp/install-python.sh "$version"; done \
    && rm -f /tmp/install-python.sh

# Fetch sbt artifacts
RUN sbt about

# Compile, build and install Slurm from Git source
ARG SLURM_TAG=slurm-$SLURM_VERSION
RUN set -ex \
    && git clone https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && git checkout tags/$SLURM_TAG \
    && ./configure --enable-debug --enable-front-end --prefix=/usr \
       --sysconfdir=/etc/slurm --with-mysql_config=/usr/bin \
       --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
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

# Copy Slurm configuration files into the container
COPY files/slurm/slurm.conf /etc/slurm/slurm.conf
COPY files/slurm/gres.conf /etc/slurm/gres.conf
COPY files/slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY files/supervisord.conf /etc/

# Mark externally mounted volumes
VOLUME ["/var/lib/mysql", "/var/lib/slurmd", "/var/spool/slurmd", "/var/log/slurm"]

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Add Tini
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

# Set the display
ENV DISPLAY=host.docker.internal:0

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
