# Slurm on CentOS 7 Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/drewsilcockstfc/docker-centos7-slurm.svg)](https://hub.docker.com/r/drewsilcockstfc/docker-centos7-slurm/)

This is an all-in-one [Slurm](https://slurm.schedmd.com/) installation.  This
container runs the following processes:

* slurmd (The compute node daemon for Slurm)
* slurmctld (The central management daemon of Slurm)
* slurmdbd (Slurm database daemon)
* slurmrestd (Slurm REST API)
* munged (Authentication service for creating and validating credentials)
* mariadb (MySQL compatible database)
* supervisord (A process control system)

It also has the following Python versions installed, including the
corresponding -devel and -pip packages:

* Python 3.6
* Python 3.7
* Python 3.8
* Python 3.9

## Usage

There are multiple
[tags](https://hub.docker.com/r/drewsilcockstfc/docker-centos7-slurm/tags/)
available.  To use the latest available image, run:

```shell
docker pull drewsilcockstfc/docker-centos7-slurm:latest
docker run -it -h slurmctl drewsilcockstfc/docker-centos7-slurm:latest
```

The above command will drop you into a bash shell inside the container. Tini
is responsible for `init` and supervisord is the process control system . To
view the status of all the processes, run:

```shell
[root@slurmctl /]# supervisorctl status
munged                           RUNNING   pid 23, uptime 0:02:35
mysqld                           RUNNING   pid 24, uptime 0:02:35
slurmctld                        RUNNING   pid 25, uptime 0:02:35
slurmd                           RUNNING   pid 22, uptime 0:02:35
slurmdbd                         RUNNING   pid 26, uptime 0:02:35
slurmrestd                       RUNNING   pid 27, uptime 0:02:35
```

In `slurm.conf`, the **ControlMachine** hostname is set to **slurmctl**. Since
this is an all-in-one installation, the hostname must match **ControlMachine**.
Therefore, you must pass the `-h slurmctl` to docker at run time so that the
hostnames match.

You can run the usual Slurm commands:

```shell
[root@slurmctl /]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      5   idle c[1-5]
debug        up 5-00:00:00      5   idle c[6-10]
```

```shell
[root@slurmctl /]# scontrol show partition normal
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

### Using Existing Tags

There are multiple versions of Slurm available, each with its own tag.  To build
a specific version of Slurm, checkout the tag that matches that version and
build the Dockerfile:

```shell
git clone https://github.com/drewsilcock/docker-centos7-slurm
git checkout <tag>
docker build -t docker-centos7-slurm .
```

### Using Build Args

You can use docker's `--build-arg` option to customize the version of Slurm
and the version(s) of Python at build time.

To specify the version of Slurm, assign a valid Slurm tag to the `SLURM_TAG`
build argument:

```shell
docker build --build-arg SLURM_TAG="slurm-19-05-1-2" -t docker-centos7-slurm:19.05.1-2
```

To specify the version(s) of Python to include in the container, specify a
space-delimited string of Python versions using the `PYTHON_VERSIONS` build
argument:

```shell
docker build --build-arg PYTHON_VERSIONS="3.6 3.7" -t docker-centos7-slurm:py3
```

## Using docker-compose

The included docker-compose file will run the cluster container in the
background.  The docker-compose file uses data volumes to store the slurm state
between container runs.  To start the cluster container, run:

```shell
docker-compose up -d
```

To execute commands in the container, use `docker exec`:

```shell
docker exec dockercentos7slurm_slurm_1 sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      5   idle c[1-5]
debug        up 5-00:00:00      5   idle c[6-10]

docker exec dockercentos7slurm_slurm_1 sbatch --wrap="sleep 10"
Submitted batch job 27

docker exec dockercentos7slurm_slurm_1 squeue
            JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            27    normal     wrap     root  R       0:07      1 c1
```

To attach to the bash shell inside the running container, run:

```shell
docker attach dockercentos7slurm_slurm_1
```

Press `Ctrl-p,Ctrl-q` to detach from the container without killing the bash
process and stopping the container.

To stop the cluster container, run:

```shell
docker-compose down
```

## Testing Locally

[Testinfra](https://testinfra.readthedocs.io/en/latest/index.html) is used to
build and run a Docker container test fixture. Run the tests with
[pytest](https://docs.pytest.org/en/latest/):

```shell
pytest -v
```
