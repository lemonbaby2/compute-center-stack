#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y munge slurm-wlm slurm-client slurmctld slurmd

sudo systemctl enable --now munge

HOSTNAME_SHORT="$(hostname -s)"
CPU_COUNT="$(nproc)"
MEM_MB="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"

sudo tee /etc/slurm/slurm.conf >/dev/null <<EOF
ClusterName=compute-lab
SlurmctldHost=$HOSTNAME_SHORT
MpiDefault=none
ProctrackType=proctrack/cgroup
ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmdSpoolDir=/var/lib/slurm/slurmd
SlurmUser=slurm
StateSaveLocation=/var/lib/slurm/slurmctld
TaskPlugin=task/cgroup
SchedulerType=sched/backfill
SelectType=select/cons_tres
AccountingStorageType=accounting_storage/none
NodeName=$HOSTNAME_SHORT CPUs=$CPU_COUNT RealMemory=$MEM_MB State=UNKNOWN
PartitionName=debug Nodes=$HOSTNAME_SHORT Default=YES MaxTime=INFINITE State=UP
EOF

sudo mkdir -p /var/lib/slurm/slurmd /var/lib/slurm/slurmctld
sudo chown -R slurm:slurm /var/lib/slurm
sudo systemctl enable --now slurmctld slurmd

sinfo

