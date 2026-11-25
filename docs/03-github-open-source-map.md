# GitHub 开源库地图

数据核验时间：2026-08-24。Stars 来自 GitHub API 当次查询，后续会变化。

## 核心开源库

| 方向 | 仓库 | Stars | 语言 | 用途 |
|---|---:|---:|---|---|
| 容器编排 | [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes) | 124936 | Go | 生产级容器调度与集群管理 |
| 容器生态 | [moby/moby](https://github.com/moby/moby) | 71990 | Go | Docker/Moby 容器生态基础 |
| 容器运行时 | [containerd/containerd](https://github.com/containerd/containerd) | 21152 | Go | Kubernetes 常用 CRI runtime |
| K8s 包管理 | [helm/helm](https://github.com/helm/helm) | 30169 | Go | Kubernetes 应用安装与升级 |
| GPU K8s | [NVIDIA/gpu-operator](https://github.com/NVIDIA/gpu-operator) | 2847 | Go | 自动化管理 K8s GPU 驱动、插件、监控组件 |
| GPU K8s | [NVIDIA/k8s-device-plugin](https://github.com/NVIDIA/k8s-device-plugin) | 3858 | Go | 将 NVIDIA GPU 暴露给 Kubernetes |
| GPU 监控 | [NVIDIA/dcgm-exporter](https://github.com/NVIDIA/dcgm-exporter) | 1838 | Go | GPU 指标导出到 Prometheus |
| 监控 | [prometheus/prometheus](https://github.com/prometheus/prometheus) | 65788 | Go | 指标采集和时序数据库 |
| 可视化 | [grafana/grafana](https://github.com/grafana/grafana) | 76368 | TypeScript | 监控大盘和告警展示 |
| HPC 调度 | [schedmd/slurm](https://github.com/SchedMD/slurm) | 4275 | C | HPC / AI 批处理调度器 |
| HPC 套件 | [openhpc/ohpc](https://github.com/openhpc/ohpc) | 999 | C | HPC 集群软件集成与打包 |
| 裸金属装机 | [warewulf/warewulf](https://github.com/warewulf/warewulf) | 659 | Go | 无盘/裸金属集群装机 |
| 分布式存储 | [ceph/ceph](https://github.com/ceph/ceph) | 16958 | C++ | 对象、块、文件统一存储 |
| K8s 存储 | [rook/rook](https://github.com/rook/rook) | 13608 | Go | Kubernetes 上编排 Ceph |
| 并行文件系统 | [lustre/lustre-release](https://github.com/lustre/lustre-release) | 321 | C | Lustre 开发镜像 |
| HPC 调度 | [openpbs/openpbs](https://github.com/openpbs/openpbs) | 804 | C | PBS 系批处理调度器 |
| IaC | [hashicorp/terraform](https://github.com/hashicorp/terraform) | 49523 | Go | 基础设施即代码 |
| 自动化 | [ansible/ansible](https://github.com/ansible/ansible) | 70443 | Python | 批量配置和自动化运维 |
| 日志/搜索 | [elastic/elasticsearch](https://github.com/elastic/elasticsearch) | 77855 | Java | 日志检索和搜索平台 |
| 可观测性 | [open-telemetry/opentelemetry-collector](https://github.com/open-telemetry/opentelemetry-collector) | 7447 | Go | 日志、指标、链路统一采集 |
| AI 平台 | [mlflow/mlflow](https://github.com/mlflow/mlflow) | 27634 | Python | 实验、模型、评估和部署管理 |
| 分布式计算 | [ray-project/ray](https://github.com/ray-project/ray) | 43587 | Python | AI 分布式运行时 |
| 并行计算 | [dask/dask](https://github.com/dask/dask) | 13895 | Python | Python 并行计算 |
| 大模型框架 | [NVIDIA/NeMo](https://github.com/NVIDIA/NeMo) | 18281 | Python | 大模型、多模态、语音训练框架 |
| 深度学习 | [pytorch/pytorch](https://github.com/pytorch/pytorch) | 102565 | Python | GPU 深度学习框架 |

## 学习路线

第一阶段：单节点 GPU

- Ubuntu、NVIDIA Driver、CUDA、Docker/containerd、NVIDIA Container Toolkit。
- 能跑通 `nvidia-smi`、CUDA 容器、PyTorch GPU 检测。

第二阶段：Kubernetes GPU

- kubeadm 或 kind/k3s 实验。
- NVIDIA Device Plugin、GPU Operator、DCGM Exporter。
- Pod 申请 GPU、命名空间配额、节点污点和亲和性。

第三阶段：HPC / Slurm

- Slurm 单节点实验。
- Munge、partition、GRES、sbatch、srun、sacct。
- 对比 Slurm 与 Kubernetes 的资源模型。

第四阶段：存储和网络

- NFS、Ceph/Rook、Lustre 概念。
- fio、iostat、iperf3、NCCL tests。
- 数据集小文件优化和 checkpoint 策略。

第五阶段：平台化

- Prometheus/Grafana/Alertmanager。
- Ansible 批量交付。
- Terraform 管理云资源。
- Ray、MLflow、Kubeflow/Volcano/Kueue 连接上层 AI 平台。

## Windows clone 注意事项

Slurm 和 Lustre 源码树中可能包含 Windows 保留设备名相关路径，直接 checkout 到 NTFS 会失败。建议在 Ubuntu、WSL Linux 文件系统、服务器节点或 Linux 容器里 clone：

```bash
git clone --depth 1 https://github.com/SchedMD/slurm.git
git clone --depth 1 https://github.com/lustre/lustre-release.git
```

## 需要关注的官方文档

- Kubernetes 文档：https://kubernetes.io/docs/home/
- Slurm 文档：https://slurm.schedmd.com/documentation.html
- NVIDIA GPU Operator 文档：https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html
- NVIDIA Container Toolkit 文档：https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
- Ceph 文档：https://docs.ceph.com/en/latest/
- OpenHPC：https://openhpc.community/
- Warewulf 文档：https://warewulf.org/docs/main/
