# 算力中心技术栈地图

## 1. 机房与硬件层

| 模块 | 需要掌握 | 常见问题 |
|---|---|---|
| 服务器 | CPU 架构、NUMA、内存通道、PCIe 拓扑、BMC/IPMI、RAID/HBA | GPU 不识别、PCIe 降速、内存插错槽、BMC 无法远程 |
| GPU | NVIDIA Driver、CUDA、MIG、NVLink、NVSwitch、ECC、功耗墙 | 驱动版本不匹配、Xid 错误、显存碎片、GPU 利用率低 |
| 网络 | 25/100/200/400G 以太网、IB/RoCE、MTU、PFC/ECN、bond、VLAN | NCCL 卡住、吞吐低、丢包、RoCE 配置不一致 |
| 存储 | NVMe、本地盘、RAID、Ceph、Lustre、NFS、对象存储 | 小文件慢、元数据瓶颈、训练 checkpoint 写入慢 |
| 电力散热 | PDU、功耗、风道、温度、降频 | GPU clock 下降、节点随机重启 |

## 2. 操作系统层

建议主线：Ubuntu Server LTS。

必会能力：

- unattended / PXE / autoinstall 装机。
- systemd 服务、journalctl、udev、内核参数、sysctl。
- cgroup v2、namespace、overlayfs、iptables/nftables。
- 文件系统：ext4、xfs、zfs 基础，inode、mount options、quota。
- 性能工具：top、htop、pidstat、iostat、sar、perf、numactl、ethtool、nvidia-smi、dcgmi。

## 3. GPU 软件栈

从下到上：

```text
NVIDIA Driver -> CUDA Runtime/Toolkit -> cuDNN/NCCL/TensorRT
              -> NVIDIA Container Toolkit -> containerd/Docker
              -> Kubernetes Device Plugin / GPU Operator / Slurm GRES
              -> PyTorch / TensorFlow / JAX / Ray / vLLM / Triton
```

版本匹配要点：

- Driver 要覆盖 CUDA Runtime 的最低要求。
- 容器内 CUDA 版本可以与宿主机 CUDA Toolkit 不同，但必须被宿主机 Driver 支持。
- NCCL 问题优先看网络、拓扑、驱动、环境变量，而不是先怪框架。
- 多租户 GPU 优先评估 MIG、time-slicing、MPS、队列配额，不要直接裸放整卡。

## 4. 容器与镜像层

核心组件：

- containerd：Kubernetes 生产环境常见 CRI。
- Docker / Moby：开发、镜像构建、单机调试。
- nerdctl / crictl：containerd 调试。
- Harbor / registry：镜像仓库、权限、漏洞扫描、复制同步。
- BuildKit：高效构建镜像。

常见底层点：

- 镜像层和 overlayfs 可能导致大量小文件性能差。
- 容器能看到 GPU 的关键链路是 NVIDIA Driver + libnvidia-container + runtime 配置。
- Kubernetes 里看 Pod 不够，要会 `crictl ps`、`crictl inspect`、`ctr`。

## 5. 调度层：Kubernetes 与 Slurm

| 场景 | 更适合 |
|---|---|
| AI 平台、推理服务、多租户 Web/API、云原生组件 | Kubernetes |
| HPC 批处理、MPI、大作业队列、公平共享、裸机资源效率 | Slurm |
| AI 训练平台 | Kubernetes + Volcano/Kueue 或 Slurm，两者都常见 |
| 传统超算中心 | Slurm / OpenPBS |

Kubernetes 重点：

- kubeadm / containerd / CNI / CSI / Ingress / Gateway API。
- Node labels、taints/tolerations、affinity、priority、quota、limit range。
- GPU Device Plugin、GPU Operator、DCGM Exporter。
- 批作业扩展：Volcano、Kueue、Kubeflow Training Operator、Ray Operator。

Slurm 重点：

- slurmctld、slurmd、munge、slurmdbd。
- partition、account、QOS、GRES GPU、cgroup、fairshare。
- 作业生命周期：sbatch、srun、squeue、sacct、scancel。
- GPU 资源声明：`--gres=gpu:1`、`--gpus=1`。

## 6. 存储层

| 技术 | 用途 | 风险点 |
|---|---|---|
| 本地 NVMe | 数据缓存、临时训练数据、checkpoint staging | 节点故障丢数据 |
| NFS | 简单共享目录 | 大规模训练和小文件容易成为瓶颈 |
| Ceph | 对象、块、文件统一存储；K8s 里常配 Rook | 运维复杂，需要监控 OSD、PG、恢复流量 |
| Lustre | HPC 并行文件系统 | 元数据和网络依赖强，排障门槛高 |
| MinIO | S3 兼容对象存储 | 适合数据集和模型制品，不适合 POSIX 小文件热路径 |

## 7. 监控与可观测性

基础组合：

- Prometheus：指标采集。
- Grafana：仪表盘。
- Alertmanager：告警路由。
- node_exporter：CPU、内存、磁盘、网络。
- dcgm-exporter：GPU 指标。
- kube-state-metrics：Kubernetes 对象状态。
- Loki / Elasticsearch：日志。
- OpenTelemetry Collector：日志、指标、链路统一采集入口。

关键 GPU 指标：

- GPU utilization、memory utilization、FB memory used/free。
- temperature、power draw、SM clock、memory clock。
- ECC error、retired pages、Xid error。
- PCIe rx/tx、NVLink rx/tx。

## 8. 自动化与交付

推荐组合：

- Ansible：批量初始化节点、安装驱动、配置 systemd。
- Terraform：云资源、网络、磁盘、机器生命周期。
- Helm：Kubernetes 应用交付。
- GitOps：Argo CD / Flux。
- Packer：基础镜像。
- Warewulf / OpenHPC：HPC 裸金属集群快速交付。

## 9. 面试表达主线

可以把经验组织成三句话：

1. 我能从硬件拓扑、驱动、容器运行时、调度器一路定位 GPU 任务失败原因。
2. 我熟悉 Kubernetes 和 Slurm 两类算力调度系统，知道训练、推理、HPC 批处理的取舍。
3. 我能用监控和自动化把节点交付、巡检、故障恢复做成标准流程，而不是靠手工 SSH。

