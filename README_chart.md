# Helm Chart 仓库说明

本仓库用于存放 Helm Chart 软件包（`.tgz`），支持通过 GitLab Helm Package Registry 推送和安装 Chart。

---

## 1️⃣ 推送 Helm Chart 软件包

可以使用 `curl` 命令将本地打包好的 Chart 上传到 GitLab Helm 仓库。

```bash
curl --fail-with-body \
  --request POST \
  --form 'chart=@<chart_file>.tgz' \
  --user <username>:<access_token> \
  "http://<gitlab_host>/api/v4/projects/<project_id>/packages/helm/api/<channel>/charts"
```

### 需要替换的变量：

| 变量                 | 说明                                           |
| ------------------ | -------------------------------------------- |
| `<chart_file>.tgz` | 需要上传的 Chart 包文件，例如 `observability-1.0.0.tgz` |
| `<username>`       | GitLab 用户名或 deploy token 用户名                 |
| `<access_token>`   | GitLab Personal Access Token 或 deploy token  |
| `<gitlab_host>`    | GitLab 实例地址，例如 `192.168.1.63`                |
| `<project_id>`     | 项目 ID，例如 `76`                                |
| `<channel>`        | 发布通道，例如 `stable` 或 `devel`                   |

---

## 2️⃣ 添加 Helm 仓库源

上传成功后，可以在 Helm 客户端添加仓库源：

```bash
helm repo add <repo_name> "http://<gitlab_host>/api/v4/projects/<project_id>/packages/helm/<channel>" \
  --username <username> \
  --password <access_token>

helm repo update
```

### 需要替换的变量：

| 变量               | 说明                                          |
| ---------------- | ------------------------------------------- |
| `<repo_name>`    | 本地给仓库起的名字，例如 `myrepo`                       |
| `<gitlab_host>`  | GitLab 实例地址，例如 `192.168.1.63`               |
| `<project_id>`   | 项目 ID，例如 `76`                               |
| `<channel>`      | 发布通道，例如 `stable`                            |
| `<username>`     | GitLab 用户名或 deploy token 用户名                |
| `<access_token>` | GitLab Personal Access Token 或 deploy token |

---

## 3️⃣ 安装 Chart

### 方式 A：直接从 Helm 仓库安装

```bash
helm install <release_name> <repo_name>/<chart_name> -n <namespace>
```

示例：

```bash
helm install observability myrepo/observability -n ob
```

### 方式 B：从本地 `.tgz` 文件安装，并可覆盖 values

```bash
helm install <release_name> ./<chart_file>.tgz --set <key>=<value> -n <namespace>
```

示例：

```bash
helm install observability ./observability-1.0.0.tgz --set customer.lgtm.enabled=false -n ob
```

### 需要替换的变量：

| 变量                 | 说明                                          |
| ------------------ | ------------------------------------------- |
| `<release_name>`   | Helm Release 名称                             |
| `<chart_name>`     | Chart 名称，例如 `observability`                 |
| `<chart_file>.tgz` | 本地 Chart 包文件                                |
| `<key>`            | values.yaml 中的字段，例如 `customer.lgtm.enabled` |
| `<value>`          | 设置的值，例如 `true` 或 `false`                    |
| `<namespace>`      | Kubernetes 命名空间                             |

---

## 4️⃣ 小贴士

* GitLab Helm Package Registry 会自动管理 Chart 版本和索引（`index.yaml`），无需手动创建
* 上传新版本的 `.tgz` 后，可以直接在 Helm 客户端通过 `--version` 指定安装版本
* 如果需要上传多个 Chart，只需重复 `curl` 命令即可，GitLab 会区分不同 Chart 和版本

---

## 5️⃣ 实际使用示例

以下是基于你提供的环境的完整示例：

### 推送 Chart 到仓库
```bash
curl --fail-with-body \
  --request POST \
  --form 'chart=@observability-1.0.1.tgz' \
  --user wanghuhu:glpat-Yx3inEj9V-PJLu13vtwo \
  "http://192.168.1.63/api/v4/projects/65/packages/helm/api/stable/charts"
```

### 添加仓库源
```bash
helm repo add myrepo "http://192.168.1.63/api/v4/projects/65/packages/helm/stable" \
  --username wanghuhu \
  --password glpat-Yx3inEj9V-PJLu13vtwo
```

### 安装 Chart
```bash
helm install observability myrepo/observability -n ob
```

或从本地文件安装：
```bash
helm install observability ./observability-1.0.0.tgz --set customer.lgtm.enabled=false -n ob
```

---

## 6️⃣ 快速部署命令

### 云管侧部署
```bash
helm install observability myrepo/observability -n xnet \
  --set customer.dataservice.telegraf.enabled=false \
  --set customer.dataservice.influxdb2.enabled=true
```

### 边缘侧部署
```bash
helm install observability myrepo/observability -n xnet \
  --set customer.dataservice.telegraf.config.global_tags.output=http://192.168.22.180:31521

  如果需要设置 cluster,cluster_id可配置参数
  --set customer.dataservice.telegraf.config.global_tags.cluster=<cluster_name>
  --set customer.dataservice.telegraf.config.global_tags.cluster_id=<cluster_id>
```

