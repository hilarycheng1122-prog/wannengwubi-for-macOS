# 万能五笔 for macOS

基于鼠须管 / Rime 的五笔 86 + 拼音混合输入方案。设计目标是五笔优先、仅输出简体中文、横向候选，并保持离线可用和可回滚。

## 当前状态

当前正式版本：`v1.0.1`（一体化安装包 + 通用联想 + 个人学习）。普通候选和联想候选默认统一为简体，按 `Control + Shift + T` 可主动切换为繁体；只有万能五笔自身完成的上屏才有资格触发联想，粘贴和外部文本变化不会触发。

## 普通用户安装

从 GitHub Releases 下载 `WanNengWubi-v1.0.1.pkg`，双击后按系统安装向导操作。安装包内含鼠须管和所需词库，不需要提前安装依赖，也不需要打开终端。

由于当前发布包没有 Apple Developer Installer 证书，macOS 首次可能阻止打开。请按下面步骤放行：

1. 先双击一次 `WanNengWubi-v1.0.1.pkg`，出现阻止提示后点击“好”或“完成”。
2. 打开“系统设置 → 隐私与安全性”。
3. 向下滚动到“安全性”，找到“已阻止打开 WanNengWubi…”提示。
4. 点击“仍要打开”，使用 Touch ID 或输入 Mac 登录密码。
5. 再点击一次“打开”，回到安装器继续安装。

如果没有看到“仍要打开”，请重新双击安装包触发一次提示，然后立即返回“隐私与安全性”查看。如果系统提示“将损坏你的电脑”或“检测到恶意软件”，不要继续安装，请把完整提示反馈给项目维护者。

安装器会自动备份已有 Rime 配置并保留个人学习数据库。安装后，通用数据库立即提供下一词候选；个人数据继续保存在 `~/Library/Rime/personal_predict.userdb`，不会上传。详细说明见 [傻瓜安装指南](docs/INSTALL.md)。

开发者仍可使用 `make install-universal-learning` 从源码安装。

- `config/rime/`：当前已经实际使用的输入方案与界面配置。
- `dictionaries/`：五笔 86 基础词库。词库属于数据，不与程序代码混在一起管理。
- `assets/`：红底黑色“万”品牌图标源。
- `packaging/macos/`：macOS 应用打包资料。单输入源清理仍标记为实验性，验证通过前不作为稳定发布。
- `features/prediction/`：离线词汇联想功能，默认关闭，不影响稳定版。
- `scripts/`：检查、安装配置、构建安装包和预测数据库的入口。

个人学习数据、部署产物、系统输入法列表和安装包均不提交到 Git。

## 常用命令

```bash
make check             # 检查配置和仓库卫生
make install-config    # 备份并安装稳定配置到 ~/Library/Rime
make prediction-alpha  # 下载并校验官方 Alpha 预测数据库
make install-prediction # 安装并启用可切换的离线联想配置
make install-universal-learning # 安装通用联想与个人学习混合模式
make reset-personal-learning # 备份并清空个人学习数据
make package           # 从锁定的鼠须管安装包构建本地 pkg
make prediction        # 从二元词频数据构建 predict.db
```

## 版本策略

- 项目使用语义化版本：`主版本.功能版本.修订版本`。
- `main` 始终保持稳定可用；每个新版本使用 `develop/vX.Y.Z` 分支，具体功能可再使用 `feat/...` 分支。
- 每个可安装版本打标签，例如 `v0.2.1`，并在 `CHANGELOG.md` 记录变化。
- 不复制整套源码作为版本备份；旧版本由 Git 标签、GitHub Release 和只读 worktree 保存。
- 上游鼠须管、Rime 和插件版本固定在 `upstream/versions.lock`，升级时单独提交。
- 大型 `pkg` 和预测数据库放 Release 或本地缓存，不直接放 Git 历史。

详细设计见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)、[docs/VERSIONING.md](docs/VERSIONING.md) 和 [docs/RELEASE.md](docs/RELEASE.md)。
