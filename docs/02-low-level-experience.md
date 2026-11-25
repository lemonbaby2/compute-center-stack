# 算力中心底层经验整理

## 1. 一条 GPU 任务从提交到运行的链路

```text
用户提交任务
-> 调度器判断资源、队列、配额、亲和性
-> 节点 kubelet/slurmd 接收任务
-> containerd 或本地进程拉起 workload
-> NVIDIA runtime 注入 GPU 设备和驱动库
-> 进程加载 CUDA/NCCL/cuDNN
-> 数据从存储和网络进入 GPU
-> 指标进入 Prometheus/Grafana
```

排障时按这个链路从外到内查：

- 调度层：任务为什么 Pending？资源、污点、配额、队列、亲和性。
- 容器层：镜像能否拉取？entrypoint 是否正常？runtime class 是否正确？
- GPU 层：`nvidia-smi`、driver、CUDA runtime、device plugin、MIG。
- 网络层：DNS、CNI、MTU、NCCL、IB/RoCE。
- 存储层：数据集路径、权限、吞吐、inode、NFS/Ceph/Lustre 状态。

## 2. GPU 故障处理经验

常用命令：

```bash
nvidia-smi
nvidia-smi topo -m
nvidia-smi -q -d ECC,POWER,TEMPERATURE,CLOCK,PCIE
dmesg -T | grep -i -E 'nvrm|xid|pcie|gpu'
journalctl -k -p warning
dcgmi diag -r 2
```

常见判断：

- `nvidia-smi` 不存在：驱动未装、PATH 不对、内核模块没加载。
- `nvidia-smi` 报 driver/library mismatch：驱动升级后未重启，或库版本污染。
- Kubernetes Pod 看不到 GPU：device plugin 未运行、runtime 配置缺失、节点没打 GPU label。
- 训练慢但 GPU 利用率低：数据加载、网络、存储、batch size、CPU 预处理是第一批怀疑点。
- NCCL 卡住：优先查网卡、MTU、IB/RoCE、NCCL 环境变量和多机互通。

## 3. Kubernetes GPU 经验

排障命令：

```bash
kubectl get nodes -o wide
kubectl describe node <node>
kubectl get pods -A -o wide
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl get ds -A | grep -i nvidia
kubectl get events -A --sort-by=.lastTimestamp
```

关键对象：

- Node label：区分 GPU 型号、网络、机房、存储能力。
- Taint：保护 GPU 节点不跑普通工作负载。
- ResourceQuota：控制每个租户可用 GPU/CPU/内存。
- PriorityClass：抢占和保障关键任务。
- RuntimeClass：隔离不同运行时。
- Device Plugin：把 GPU 以 extended resource 暴露给 kubelet。

GPU Pod 示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
  restartPolicy: Never
  containers:
    - name: cuda
      image: nvidia/cuda:12.8.0-base-ubuntu24.04
      command: ["nvidia-smi"]
      resources:
        limits:
          nvidia.com/gpu: 1
```

## 4. Slurm 经验

基础命令：

```bash
sinfo
scontrol show node
squeue -u "$USER"
sbatch train.sh
srun --gres=gpu:1 --pty bash
sacct -j <jobid> --format=JobID,JobName,State,Elapsed,AllocTRES
scancel <jobid>
```

GPU 作业脚本：

```bash
#!/usr/bin/env bash
#SBATCH -J gpu-smoke
#SBATCH -p gpu
#SBATCH --gres=gpu:1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -t 00:10:00

set -euo pipefail
nvidia-smi
python - <<'PY'
import torch
print(torch.cuda.is_available())
print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "no gpu")
PY
```

## 5. 网络与 NCCL 经验

常用命令：

```bash
ip addr
ip route
ethtool <iface>
ethtool -S <iface> | egrep 'err|drop|timeout|crc'
ibstat
ibv_devinfo
rdma link
nccl-tests/build/all_reduce_perf -b 8 -e 8G -f 2 -g 1
```

关键环境变量：

```bash
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0
export NCCL_IB_DISABLE=0
export NCCL_NET_GDR_LEVEL=2
```

判断方向：

- 单机快、多机慢：网络、NCCL、拓扑、交换机配置。
- 小 batch 慢：通信占比高，可能不是 GPU 算力瓶颈。
- RoCE 场景：PFC、ECN、MTU、DSCP、交换机队列要一致。

## 6. 存储经验

常用命令：

```bash
df -h
df -i
lsblk
iostat -x 1
fio --name=readtest --filename=/data/fio.test --size=4G --rw=read --bs=1M --iodepth=32
mount | column -t
```

经验判断：

- 训练数据大量小文件：优先做 tar/webdataset/LMDB/parquet，而不是让 NFS 硬扛。
- checkpoint 慢：本地 NVMe 临时落盘，再异步上传对象存储。
- Ceph 慢：看 PG 状态、OSD 延迟、恢复流量、网络瓶颈。
- Lustre 慢：看 MDT/MDS 压力、stripe 配置和客户端 mount 参数。

## 7. 简历/面试项目表达

项目名称：GPU 算力中心基础设施交付与运维体系

可写职责：

- 规划 Ubuntu GPU 节点基础镜像，完成 NVIDIA Driver、CUDA、containerd、NVIDIA Container Toolkit 标准化安装。
- 基于 Kubernetes GPU Operator / Device Plugin 暴露 GPU 资源，配置节点标签、污点、资源配额和监控告警。
- 基于 Slurm 搭建批处理实验队列，支持 `sbatch/srun` GPU 作业提交和作业审计。
- 接入 Prometheus、Grafana、DCGM Exporter、node_exporter，建设 GPU 利用率、显存、温度、功耗、Xid 错误告警。
- 编写 Ansible/脚本自动化节点巡检，覆盖驱动、网卡、磁盘、GPU、systemd 服务、容器运行时。

可量化指标：

- 节点初始化从手工数小时缩短到脚本化 20-40 分钟。
- GPU 异常定位路径从“逐台 SSH”变成监控告警 + Runbook。
- 多租户任务通过 namespace/resource quota/partition/QOS 进行隔离。

