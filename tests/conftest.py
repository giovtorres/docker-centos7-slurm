"""Pytest fixtures."""

import subprocess
import time

import pytest
import testinfra


@pytest.fixture(scope="session")
def host(request):
    subprocess.check_call(
        ["docker", "build", "-t", "docker-centos7-slurm:test", "."]
    )

    docker_id = subprocess.check_output(
        ["docker", "run", "-d", "-it", "-h", "slurmctl", "docker-centos7-slurm:test"]
    ).decode().strip()

    time.sleep(15) # FIXME: needs to be dynamic

    yield testinfra.get_host(f"docker://{docker_id}")

    subprocess.check_call(
        ["docker", "rm", "-f", docker_id]
    )


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
