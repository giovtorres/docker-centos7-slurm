import subprocess

import pytest
import testinfra


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert "0.18.0" in cmd.stdout


def test_slurm_user_group_exists(host):
    assert host.group("slurm").exists
    assert host.user("slurm").group == "slurm"


@pytest.mark.parametrize("filename", ["slurm.conf", "slurmdbd.conf"])
def test_slurm_config_exists(host, filename):
    assert host.file(f"/etc/slurm/{filename}").exists
    assert host.file(f"/etc/slurm/{filename}").is_file


@pytest.mark.parametrize("version, semver", [
    ("3.5", "3.5.6"),
    ("3.6", "3.6.8"),
    ("3.7", "3.7.5"),
    ("3.8", "3.8.0")
])
def test_python_is_installed(host, version, semver):
    cmd = host.run(f"python{version} --version")
    assert semver in cmd.stdout

def test_mariadb_is_listening(host):
    assert host.socket("tcp://3306").is_listening

