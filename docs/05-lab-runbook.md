# 算力中心实验与巡检 Runbook

## 1. Windows 本地管理工具

```powershell
$env:Path = "D:\ComputeCenterStack\tools\bin;$env:Path"
kubectl version --client
helm version
kind version
k9s version
terraform version
jq --version
yq --version
```

## 2. 本地 kind 实验集群

```powershell
kind create cluster --name compute-lab
kubectl cluster-info --context kind-compute-lab
kubectl get nodes
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kind delete cluster --name compute-lab
```

注意：kind 在 Windows 上依赖 Docker Desktop 或可用的 Docker daemon。没有 Docker 时，`kind create cluster` 会失败，这是正常依赖缺失。

## 3. Ubuntu 节点巡检

```bash
hostnamectl
uname -a
uptime
free -h
df -h
df -i
lsblk
lspci | grep -i nvidia
nvidia-smi
systemctl --failed
journalctl -p err -b --no-pager | tail -100
```

## 4. GPU 巡检

```bash
nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total,memory.used,utilization.gpu,temperature.gpu,power.draw --format=csv
nvidia-smi topo -m
dmesg -T | grep -i -E 'nvrm|xid|gpu|pcie' | tail -100
```

## 5. Kubernetes 巡检

```bash
kubectl get nodes -o wide
kubectl top nodes
kubectl get pods -A -o wide
kubectl get events -A --sort-by=.lastTimestamp | tail -50
kubectl get daemonset -A
kubectl get pv,pvc -A
```

GPU 检查：

```bash
kubectl describe node <node-name> | grep -i -A 8 'nvidia.com/gpu'
kubectl get pods -A | grep -i nvidia
```

## 6. Slurm 巡检

```bash
sinfo
scontrol show node
squeue
sdiag
sacct -S today --format=JobID,JobName,User,Partition,State,Elapsed,AllocTRES
```

## 7. 网络性能

```bash
iperf3 -s
iperf3 -c <server-ip> -P 8 -t 30
ethtool <iface>
ethtool -S <iface> | egrep 'err|drop|crc|timeout'
```

## 8. 存储性能

```bash
fio --name=seqread --filename=/data/fio.test --size=8G --rw=read --bs=1M --iodepth=32 --direct=1
fio --name=seqwrite --filename=/data/fio.test --size=8G --rw=write --bs=1M --iodepth=32 --direct=1
iostat -x 1
```

## 9. 典型故障定位模板

### Pod Pending

```bash
kubectl describe pod <pod> -n <ns>
kubectl describe node <node>
kubectl get quota -n <ns>
kubectl get events -n <ns> --sort-by=.lastTimestamp
```

看点：

- Insufficient cpu/memory/nvidia.com/gpu。
- taint 没有 toleration。
- PVC 未绑定。
- 镜像拉取失败。

### GPU 不可见

```bash
nvidia-smi
lsmod | grep nvidia
systemctl status nvidia-persistenced || true
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
kubectl get pods -A | grep -i nvidia
```

### 训练慢

```bash
nvidia-smi dmon -s pucvmet -d 1
iostat -x 1
pidstat -dru 1
iftop
```

判断：

- GPU 低、CPU 高：数据预处理瓶颈。
- GPU 低、磁盘高：数据读取瓶颈。
- 多机低效：NCCL/网络/拓扑。
- 显存满但算力低：batch、activation、通信等待、kernel launch 开销。

