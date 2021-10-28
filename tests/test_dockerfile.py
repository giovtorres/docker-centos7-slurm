"""Spec tests for container image."""

import time

import pytest


@pytest.fixture
def Slow():
    def slow(check, timeout=30):
        timeout_at = time.time() + timeout

        while True:
            try:
                assert check()
            except AssertionError as e:
                if time.time() < timeout_at:
                    time.sleep(1)
                else:
                    raise e
            else:
                return
    return slow


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert "0.18.0" in cmd.stdout


def test_slurm_user_group_exists(host):
    assert host.group("slurm").exists
    assert host.user("slurm").group == "slurm"


@pytest.mark.parametrize("version", ["3.6", "3.7", "3.8"])
def test_python_is_installed(host, version):
    cmd = host.run(f"python{version} --version")
    assert cmd.stdout.startswith(f"Python {version}")


def test_mariadb_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://3306").is_listening)


@pytest.mark.parametrize("filename", ["slurm.conf", "slurmdbd.conf"])
def test_slurm_config_exists(host, filename):
    assert host.file(f"/etc/slurm/{filename}").exists
    assert host.file(f"/etc/slurm/{filename}").is_file


def test_slurmd_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6817").is_listening)


def test_slurmdbd_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6818").is_listening)


def test_slurmctld_is_listening(host, Slow):
    Slow(lambda: host.socket("tcp://6819").is_listening)


def test_slurmd_version(host):
    cmd = host.run("scontrol show config | grep SLURM_VERSION")
    assert "20.02.0" in cmd.stdout
