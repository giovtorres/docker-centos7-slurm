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
