"""Spec tests for container image."""

import pytest


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert "0.18.0" in cmd.stdout


def test_slurm_user_group_exists(host):
    assert host.group("slurm").exists
    assert host.user("slurm").group == "slurm"


@pytest.mark.parametrize("version", ["3.6", "3.7", "3.8", "3.9"])
def test_python_is_installed(host, version):
    cmd = host.run(f"python{version} --version")
    assert cmd.stdout.startswith(f"Python {version}")


def test_slurmd_version(host):
    cmd = host.run("scontrol show config | grep SLURM_VERSION")
    assert "20.11.8" in cmd.stdout


def test_mariadb_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://3306").is_listening)


def test_slurmdbd_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6818").is_listening)


def test_slurmctld_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6819").is_listening)


def test_slurmd_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6817").is_listening)
