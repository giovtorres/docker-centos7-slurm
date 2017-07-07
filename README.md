# Slurm on CentOS 7 Docker Image

[![Docker Build Status](https://img.shields.io/docker/build/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/)
[![Docker Automated build](https://img.shields.io/docker/automated/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/)
[![Docker Pulls](https://img.shields.io/docker/pulls/giovtorres/docker-centos7-slurm.svg)](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/)
[![](https://images.microbadger.com/badges/image/giovtorres/docker-centos7-slurm.svg)](https://microbadger.com/images/giovtorres/docker-centos7-slurm "Get your own image badge on microbadger.com")

This is an all-in-one [Slurm](https://slurm.schedmd.com/) installation.  This
container runs the following processes:

* slurmd (The compute node daemon for Slurm)
* slurmctld (The central management daemon of Slurm)
* slurmdbd (Slurm database daemon)
* munged (Authentication service for creating and validating credentials)
* mariadb (MySQL compatible database)
* supervisord (A process control system)

## Usage

There are multiple
[tags](https://hub.docker.com/r/giovtorres/docker-centos7-slurm/tags/)
available.  To use the latest available image, run:

```
docker pull giovtorres/docker-centos7-slurm:latest
docker run -it -h ernie giovtorres/docker-centos7-slurm:latest
```

The above command will drop you into a bash shell inside the container.
Supervisord is the process manager.  To view the status of all the processes,
run:

```
[root@ernie /]# supervisorctl status
munged                           RUNNING   pid 23, uptime 0:02:35
mysqld                           RUNNING   pid 24, uptime 0:02:35
slurmctld                        RUNNING   pid 25, uptime 0:02:35
slurmd                           RUNNING   pid 22, uptime 0:02:35
slurmdbd                         RUNNING   pid 26, uptime 0:02:35
```

In `slurm.conf`, the **ControlMachine** hostname is set to **ernie**. Since
this is an all-in-one installation, the hostname must match **ControlMachine**.
Therefore, you must pass the `-h ernie` to docker at run time so that the
hostnames match.

You can run the usual slurm commands:

```
[root@ernie /]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      5   idle c[1-5]
debug        up 5-00:00:00      5   idle c[6-10]
```

```
[root@ernie /]# scontrol show partition
PartitionName=normal
   AllowGroups=ALL AllowAccounts=ALL AllowQos=ALL
   AllocNodes=ALL Default=YES QoS=N/A
   DefaultTime=5-00:00:00 DisableRootJobs=NO ExclusiveUser=NO GraceTime=0 Hidden=NO
   MaxNodes=1 MaxTime=5-00:00:00 MinNodes=1 LLN=NO MaxCPUsPerNode=UNLIMITED
   Nodes=c[1-5]
   PriorityJobFactor=50 PriorityTier=50 RootOnly=NO ReqResv=NO OverSubscribe=NO PreemptMode=OFF
   State=UP TotalCPUs=5 TotalNodes=5 SelectTypeParameters=NONE
   DefMemPerCPU=500 MaxMemPerNode=UNLIMITED
```

## Building

There are multiple versions of Slurm available, each in its own tag.  To build
a specific version of Slurm, checkout the tag that matches that version and
build the Dockerfile:

```
git clone https://github.com/giovtorres/docker-centos7-slurm
git checkout 17.02.3
docker build -t docker-centos7-slurm .
```

## Using docker-compose

The included docker-compose file will run the cluster container in the
background.  The docker-compose file uses data volumes to store the slurm state
between container runs.  To start the cluster container, run: 

    docker-compose up -d

To execute commands in the container, use `docker exec`:

    docker exec dockercentos7slurm_slurm_1 sinfo
    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    normal*      up 5-00:00:00      5   idle c[1-5]
    debug        up 5-00:00:00      5   idle c[6-10]

    docker exec dockercentos7slurm_slurm_1 sbatch --wrap="sleep 10"
    Submitted batch job 27

    docker exec dockercentos7slurm_slurm_1 squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                27    normal     wrap     root  R       0:07      1 c1

To attach to the bash shell inside the running container, run:

    docker attach dockercentos7slurm_slurm_1

Press `Ctrl-p,Ctrl-q` to detach from the container without killing the bash
process and stopping the container.

To stop the cluster container, run:

    docker-compose down

## Notes

I use this container to get access to the Slurm headers and libraries for
[PySlurm](https://github.com/PySlurm/pyslurm) development.

> **Important Note**: This image is used for testing and development.  It is
> not suited for any production use.

