import subprocess
import time

import pytest
import testinfra


@pytest.fixture(scope="session")
def host(request):
    test_image = "docker-centos7-slurm:spec-test"
    subprocess.check_call(["docker", "build", "-t", test_image, "."])
    docker_id = subprocess.check_output(
        ["docker", "run", "-d", "-it", "-h", "ernie", test_image]
    ).decode().strip()
    yield testinfra.get_host("docker://" + docker_id)
    subprocess.check_call(["docker", "rm", "-f", docker_id])


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
    cmd = host.run("tini --version")
    assert "0.18.0" in cmd.stdout


def test_slurm_user_group_exists(host):
    assert host.group("slurm").exists
    assert host.user("slurm").group == "slurm"


@pytest.mark.parametrize("version, semver", [
    ("3.6", "3.6.8"),
    ("3.7", "3.7.5"),
    ("3.8", "3.8.0")
])
def test_python_is_installed(host, version, semver):
    cmd = host.run(f"python{version} --version")
    assert semver in cmd.stdout


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
    assert "19.05.4" in cmd.stdout
