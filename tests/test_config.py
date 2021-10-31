"""Unit tests for Slurm files and directories."""

import pytest


@pytest.mark.parametrize(
    "filepath",
    [
        "/var/spool/slurmd",
        "/var/spool/slurmctld/clustername",
        "/var/run/slurm/slurmctld.pid",
        "/var/run/slurm/slurmd.pid",
        "/var/log/slurm/slurmctld.log",
        "/var/log/slurm/slurmd.log",
        "/var/log/slurm/slurmdbd.log",
    ],
)
def test_slurm_var_files(host, filepath):
    assert host.file(filepath).exists


@pytest.mark.parametrize(
    "filepath",
    [
        "/etc/slurm/gres.conf",
        "/etc/slurm/slurm.conf",
        "/etc/slurm/slurmdbd.conf",
    ],
)
def test_slurm_etc_file_owners(host, filepath):
    assert host.file(filepath).exists
    assert host.file(filepath).user == "slurm"
    assert host.file(filepath).group == "slurm"


def test_slurmdbd_permissions(host):
    assert host.file("/etc/slurm/slurmdbd.conf").mode == 0o600
