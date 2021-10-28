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
