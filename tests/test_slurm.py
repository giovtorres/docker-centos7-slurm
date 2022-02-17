import time

import pytest

@pytest.mark.parametrize("partition", ["normal", "debug"])
def test_partitions_are_up(host, partition):
    partition_status = host.check_output(f"scontrol -o show partition {partition}")
    assert "State=UP" in partition_status


@pytest.mark.parametrize("partition", ["normal", "debug"])
def test_job_can_run(host, partition):
    res = host.run(f'sbatch --parsable --wrap="hostname" --partition={partition}')
    jobid = res.stdout.strip()
    time.sleep(2)
    assert host.file(f"slurm-{jobid}.out").content_string == "slurmctl\n"
