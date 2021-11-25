"""Spec tests for container image."""

import pytest

TINI_VERSION = "0.18.0"
PYTHON_VERSIONS = ["3.6", "3.7", "3.8", "3.9"]
SLURM_VERSION = "21.08.0"

MARIADB_PORT = 3306
SLURMCTLD_PORT = 6819
SLURMD_PORT = 6817
SLURMDBD_PORT = 6818
SLURMRESTD_PORT = 6820


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert TINI_VERSION in cmd.stdout


def test_slurm_user_group_exists(host):
    assert host.group("slurm").exists
    assert host.user("slurm").group == "slurm"


@pytest.mark.parametrize("version", PYTHON_VERSIONS)
def test_python_is_installed(host, version):
    cmd = host.run(f"python{version} --version")
    assert cmd.stdout.startswith(f"Python {version}")


def test_slurmd_version(host):
    cmd = host.run("scontrol show config | grep SLURM_VERSION")
    assert SLURM_VERSION in cmd.stdout


def test_mariadb_is_listening(host, Slow):
    Slow(lambda: host.socket(f"tcp://{MARIADB_PORT}").is_listening)


def test_slurmdbd_is_listening(host, Slow):
    Slow(lambda: host.socket(f"tcp://{SLURMDBD_PORT}").is_listening)


def test_slurmctld_is_listening(host, Slow):
    Slow(lambda: host.socket(f"tcp://{SLURMCTLD_PORT}").is_listening)


def test_slurmd_is_listening(host, Slow):
    Slow(lambda: host.socket(f"tcp://{SLURMD_PORT}").is_listening)

def test_slurmrestd_is_listening(host, Slow):
    Slow(lambda: host.socket(f"tcp://{SLURMRESTD_PORT}").is_listening)
