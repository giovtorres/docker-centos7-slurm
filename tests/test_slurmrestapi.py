import os
import time
import json
import urllib.request
from http import HTTPStatus
from http.client import HTTPResponse

import pytest
from testinfra.backend.base import CommandResult


@pytest.fixture(scope="module", params=("slurm", "root"))
def fetch_user_and_auth_token(request, host) -> (str, str):
    token_output: CommandResult = host.run("scontrol token username=%s", request.param)
    if not token_output.succeeded:
        pytest.fail(f"token generate error for user: {request.param}\n", pytrace=False)
    return token_output.stdout.strip().lstrip("SLURM_JWT="), request.param


@pytest.fixture(scope="module")
def api_version(host, container_ip, fetch_user_and_auth_token) -> str:
    jwt_token, username = fetch_user_and_auth_token

    request_obj = urllib.request.Request(
        f"http://{container_ip}:6820/openapi",
        headers={"X-SLURM-USER-TOKEN": jwt_token, "X-SLURM-USER-NAME": username},
    )
    response: HTTPResponse = urllib.request.urlopen(request_obj)
    if response.status != HTTPStatus.OK:
        pytest.fail(f"request openapi endpoint error get status code: {response.status}\n", pytrace=False)
    if not response.headers["Content-Type"].lower().startswith("application/json"):
        pytest.fail(f"response type is not valid JSON format\n", pytrace=False)
    # https://github.com/SchedMD/slurm/tree/slurm-21.08/src/plugins/openapi -> specific OpenAPI plugins -> openapi.json
    version: str = json.loads(response.read())["info"]["version"]
    # 0.0.37 or dbv0.0.37, only get 0.0.37
    return version.lstrip("dbv")


def test_unauthorized(container_ip):
    with pytest.raises(urllib.request.HTTPError, match="401: UNAUTHORIZED"):
        urllib.request.urlopen(f"http://{container_ip}:6820/openapi")


def test_slurm_ping(host, container_ip, fetch_user_and_auth_token, api_version):
    jwt_token, username = fetch_user_and_auth_token

    request_obj = urllib.request.Request(
        f"http://{container_ip}:6820/slurm/v{api_version}/ping",
        headers={"X-SLURM-USER-TOKEN": jwt_token, "X-SLURM-USER-NAME": username},
    )
    response: HTTPResponse = urllib.request.urlopen(request_obj)
    assert response.status == HTTPStatus.OK
    assert response.headers["Content-Type"].lower().startswith("application/json")
    # errors is empty list that means response is normal
    assert not json.loads(response.read())["errors"]


def test_submit_job(host, container_ip, fetch_user_and_auth_token, api_version):
    jwt_token, username = fetch_user_and_auth_token

    standard_output = os.path.join("/tmp", f"{username}-job.stdout")
    payload = json.dumps(
        {
            "script": "#!/bin/bash\nhostname",
            "job": {
                "standard_output": standard_output,
                "name": f"job-{username}",
                "environment": {"PATH": os.getenv("PATH", "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin")},
            },
        },
        separators=(",", ":"),
    )
    request_obj = urllib.request.Request(
        f"http://{container_ip}:6820/slurm/v{api_version}/job/submit",
        data=payload.encode("utf-8"),
        method="POST",
        headers={"X-SLURM-USER-TOKEN": jwt_token, "X-SLURM-USER-NAME": username, "Content-Type": "application/json"},
    )
    response: HTTPResponse = urllib.request.urlopen(request_obj)
    assert response.status == HTTPStatus.OK
    json_data = json.loads(response.read())

    job_state, max_timeout, total_cost = "", 10, 0
    while job_state != "COMPLETED":
        if total_cost > max_timeout:
            pytest.fail("The job takes too long to completed")

        time.sleep(1)
        total_cost = total_cost + 1

        request_obj = urllib.request.Request(
            f"http://{container_ip}:6820/slurm/v0.0.37/job/{json_data['job_id']}",
            headers={"X-SLURM-USER-TOKEN": jwt_token, "X-SLURM-USER-NAME": username},
        )
        response: HTTPResponse = urllib.request.urlopen(request_obj)
        assert response.status == HTTPStatus.OK
        job_state = json.loads(response.read())["jobs"][0]["job_state"]

    assert host.run(f"cat {standard_output}").stdout.strip() == host.run("echo $HOSTNAME").stdout.strip()


def test_slurmdb_jobs(host, container_ip, fetch_user_and_auth_token, api_version):
    jwt_token, username = fetch_user_and_auth_token

    request_obj = urllib.request.Request(
        f"http://{container_ip}:6820/slurmdb/v{api_version}/jobs",
        headers={"X-SLURM-USER-TOKEN": jwt_token, "X-SLURM-USER-NAME": username},
    )
    response: HTTPResponse = urllib.request.urlopen(request_obj)
    assert response.status == HTTPStatus.OK
    assert len(json.loads(response.read())["jobs"]) >= 1
