"""Unit tests for Slurm files and directories."""

import pytest


@pytest.mark.parametrize(
    "filepath", [
        "/var/spool/slurm/d",
        "/var/spool/slurm/ctld/clustername",
        "/var/run/slurmd/slurmctld.pid",
        "/var/run/slurmd/slurmd.pid",
        "/var/log/slurm/slurmctld.log",
        "/var/log/slurm/slurmd.log",
        "/var/log/slurm/slurmdbd.log",
    ]
)
def test_slurm_var_files(host, filepath):
    assert host.file(filepath).exists


@pytest.mark.parametrize(
    "filepath", [
        "/etc/slurm/gres.conf",
        "/etc/slurm/slurm.conf",
        "/etc/slurm/slurmdbd.conf",
    ]
)
def test_slurm_etc_files(host, filepath):
    assert host.file(filepath).exists
    assert host.file(filepath).user == "root"
    assert host.file(filepath).group == "root"


@pytest.mark.parametrize("partition", ["normal", "debug"])
def test_partitions_are_up(host, partition):
    partition_status = host.check_output(f"scontrol -o show partition {partition}")
    assert "State=UP" in partition_status
