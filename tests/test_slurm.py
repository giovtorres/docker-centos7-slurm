import time

import pytest

@pytest.mark.parametrize("partition", ["normal", "debug"])
def test_partitions_are_up(host, partition):
    partition_status = host.check_output(f"scontrol -o show partition {partition}")
    assert "State=UP" in partition_status


def test_job_can_run(host):
    host.run('sbatch --wrap="hostname"')
    time.sleep(2)
    assert host.file("slurm-1.out").content_string == "slurmctl\n"

options = "JobID,JobName,Partition,Account,AllocCPUS,ReqMem,State,ExitCode,NodeList"
def test_job_can_run_on_partition(host):
    res = host.run('sinfo --long --Node')
    print(res.stdout)
    host.run('sbatch --wrap="hostname; sleep 5" --partition="debug"')
    res = host.run('squeue')
    print(res.stdout, res.stderr)
    time.sleep(10)
    out = host.run(f"sacct -j 1 -o {options}")
    print(out.stdout, out.stderr)
    assert host.file("slurm-1.out").content_string == "slurmctl\n"
