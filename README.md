# Slurm on CentOS 7 Docker Image

This is an all-in-one [Slurm](https://slurm.schedmd.com/) installation.  This
container runs the following processes:

* slurmd (The compute node daemon for Slurm)
* slurmctld (The central management daemon of Slurm)
* slurmdbd (Slurm database daemon)
* munged (Authentication service for creating and validating credentials)
* mariadb (MySQL compatible database)
* supervisord (A process control system)

## Usage

```
docker pull giovtorres/docker-centos7-slurm
docker run -it -h ernie giovtorres/docker-centos7-slurm
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

```
git clone https://github.com/giovtorres/docker-centos7-slurm
cd docker-centos7-slurm
docker build -t docker-centos7-slurm .
```

## Notes

I use this container to get access to the Slurm headers and libraries for
[PySlurm](https://github.com/PySlurm/pyslurm) development.

> **Important Note**: This image is used for testing and development.  It is
> not suited for any production use.

