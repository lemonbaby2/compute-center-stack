# 算力中心底层技术栈 · 从裸金属到调度

> 一份写给自己的算力中心 / GPU 集群 / AI 基础设施手册：把 BIOS、NUMA、驱动、容器、Kubernetes、Slurm、存储、监控这一整条线，串成一条能讲清、能排障、能复现的路径。

[![Docs](https://img.shields.io/badge/docs-5%20篇主线-2C6E9B)](docs/)
[![Scripts](https://img.shields.io/badge/scripts-4%20个可执行-8E6C3E)](scripts/)
[![OS](https://img.shields.io/badge/OS-Ubuntu%20%2B%20Windows-0078D4)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 这个仓库是什么

不是教程合集，也不是命令大全，而是**一条有顺序的学习与交付路径**。

多数资料的问题是：讲 Kubernetes 的不讲 GPU 直通，讲 CUDA 的不讲 cgroup 和 NUMA，讲存储的不讲 RDMA。可真实故障从来不长在一个层里——GPU 掉卡可能根因在 PCIe ACS，Slurm 排队异常可能根因在 cgroup v2 与 systemd 的交互。

这个仓库按"从下往上"的顺序组织，每一层都标出**故障会以什么形态表现出来**。

| 层 | 覆盖内容 |
|---|---|
| 硬件 | BIOS / BMC / RAID / NUMA / PCIe / NVLink / 网卡固件 |
| 系统 | Ubuntu 内核、驱动、systemd、cgroup、nftables、文件系统 |
| GPU 栈 | Driver / CUDA / NCCL / DCGM / MIG / GPUDirect RDMA |
| 容器 | containerd / Docker / CRI / OCI / 镜像仓库 |
| 调度 | Kubernetes / Slurm / 队列 / 多租户隔离 / 资源配额 |
| 存储 | Ceph / Lustre / NFS / 本地 NVMe / 对象存储 |
| 可观测 | Prometheus / Grafana / Alertmanager / 日志 / 审计 |
| 交付 | Ansible / Terraform / Helm / GitOps |

---

## 目录

| 路径 | 内容 |
|---|---|
| [`docs/01-tech-stack.md`](docs/01-tech-stack.md) | 算力中心完整技术栈地图 |
| [`docs/02-low-level-experience.md`](docs/02-low-level-experience.md) | 底层经验、排障思路、可复述的项目点 |
| [`docs/03-github-open-source-map.md`](docs/03-github-open-source-map.md) | 开源库、stars、用途、学习路线 |
| [`docs/04-installation-ubuntu.md`](docs/04-installation-ubuntu.md) | Ubuntu / GPU / Docker / containerd / Kubernetes / Slurm 安装命令 |
| [`docs/05-lab-runbook.md`](docs/05-lab-runbook.md) | 本地实验、集群巡检、常用命令 Runbook |
| [`scripts/bootstrap-ubuntu-gpu-node.sh`](scripts/bootstrap-ubuntu-gpu-node.sh) | Ubuntu GPU 节点基础初始化 |
| [`scripts/bootstrap-k8s-gpu-stack.sh`](scripts/bootstrap-k8s-gpu-stack.sh) | Kubernetes GPU 插件与监控组件 |
| [`scripts/bootstrap-slurm-single-node.sh`](scripts/bootstrap-slurm-single-node.sh) | Slurm 单节点实验环境 |
| [`scripts/install-windows-tools.ps1`](scripts/install-windows-tools.ps1) | Windows 便携工具安装 |
| [`scripts/sync-github-repos.ps1`](scripts/sync-github-repos.ps1) | 批量浅克隆开源仓库 |
| [`configs/`](configs/) | containerd、Slurm GRES、Prometheus GPU 抓取示例 |
| [`data/github-open-source-repos.csv`](data/github-open-source-repos.csv) | 开源仓库结构化清单 |

---

## 推荐顺序

1. 读 `docs/01-tech-stack.md` 建立全景图——先知道有哪些层，再往下钻。
2. 读 `docs/02-low-level-experience.md`，把"底层经验"变成能复述、能排障、能讲项目的表达。
3. Windows 上跑 `scripts/install-windows-tools.ps1`，得到本地管理工具。
4. Ubuntu GPU 节点按 `docs/04-installation-ubuntu.md` 与对应脚本逐段执行。
5. 用 `docs/05-lab-runbook.md` 做日常巡检与故障演练。

---

## 快速开始

### Windows 工具链

```powershell
# 便携安装 kubectl / helm / kind / k9s / terraform / jq / yq
powershell -ExecutionPolicy Bypass -File scripts/install-windows-tools.ps1

# 临时入 PATH
$env:Path = "$PWD\tools\bin;$env:Path"
kubectl version --client
helm version
```

> `tools/` 目录不入库（第三方二进制，体积大）。脚本会按需下载到本地。

### Ubuntu GPU 节点

```bash
bash scripts/bootstrap-ubuntu-gpu-node.sh    # 驱动 + CUDA + containerd + nvidia-container-toolkit
bash scripts/bootstrap-k8s-gpu-stack.sh      # device-plugin + gpu-operator + DCGM exporter
bash scripts/bootstrap-slurm-single-node.sh  # Slurm 单节点 + GRES 配置
```

### 同步开源仓库

```powershell
# 默认浅克隆 GPU / HPC / 监控 / 编排方向较轻的仓库
powershell -ExecutionPolicy Bypass -File scripts/sync-github-repos.ps1

# 全部清单但跳过超大仓库
powershell -ExecutionPolicy Bypass -File scripts/sync-github-repos.ps1 -All

# 含 Kubernetes / PyTorch / Ceph 等超大仓库
powershell -ExecutionPolicy Bypass -File scripts/sync-github-repos.ps1 -All -IncludeHuge
```

Slurm / Lustre 这类在 Windows 上无法稳定 checkout 的源码树会被跳过，请在 Ubuntu / WSL / Linux 节点 clone。

> `github/` 目录（约 440 MB 的第三方仓库 clone）同样不入库。用上面的脚本按需拉取，避免仓库臃肿与许可混淆。

---

## 关键判断

算力中心不是"只会 Kubernetes"或"只会 CUDA"。真正值钱的底层经验，是**能把相邻几层串起来定位问题**：

- GPU 利用率异常 → 先看 `power.draw` 与 `clocks.sm`，不要只信 `utilization.gpu`（在某些卡上会撒谎）
- 容器里看不到 GPU → 依次查 `nvidia-smi`（宿主）→ `nvidia-container-toolkit` 配置 → containerd runtime → Pod 的 `runtimeClass`
- 多卡训练慢 → 查 NUMA 亲和、PCIe 拓扑（`nvidia-smi topo -m`）、NCCL 日志里的 ring/tree 选择
- 调度排队异常 → 查 cgroup v2 与 systemd 的配额打架、GRES 声明与实际卡数是否一致
- 存储吞吐上不去 → 查 RDMA 是否真的走了 RoCE、MTU 是否一致、NVMe 队列深度

这些判断不在任何单一文档里，只能靠跨层经验积累——这个仓库就是为积累它们而写的。

---

## 许可

MIT，见 [LICENSE](LICENSE)。

`docs/03-github-open-source-map.md` 与 `data/github-open-source-repos.csv` 中列出的第三方项目版权归各自作者，本仓库仅作索引与评注，不复制其源码。
