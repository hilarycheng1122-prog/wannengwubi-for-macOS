# 版本与文件夹安排

## 推荐布局

```text
~/Documents/Codex/
├── WanNengWubi/                 # 当前开发目录，现为 0.5.0-alpha.4
├── WanNengWubi-v0.2.1/         # v0.2.1 只读参考目录（Git worktree）
└── WanNengWubi-v0.1.1/         # v0.1.1 只读参考目录（Git worktree）
```

两个目录共享同一个 Git 历史，不是两份互不相关的项目。不要在稳定版参考目录中开发。

项目内部按用途组织，不按版本重复源码：

```text
WanNengWubi/
├── config/rime/                 # 输入方案与界面配置
├── dictionaries/               # 基础词库
├── features/                    # 可独立启用的实验功能
├── assets/                      # 图标等品牌资源
├── packaging/macos/             # macOS 打包资料
├── scripts/                     # 安装、检查、构建入口
├── tests/                       # 回归测试
├── docs/                        # 架构、版本和发布说明
├── VERSION                      # 当前目录所处版本
└── CHANGELOG.md                 # 各版本变化
```

`dist/`、`.build/` 和 `vendor/cache/` 只保存本机构建或缓存，不进入 Git 历史。正式安装包验证通过后上传到对应的 GitHub Release。

## 版本角色

- `main`：最新稳定版本。
- `develop/v0.5.0`：当前新版本开发线。
- `v0.1.1`、`v0.2.1`：不可移动的历史版本标签。
- GitHub Releases：供人阅读的版本介绍和安装包入口。

## 发布新版本时

1. 完成功能与测试，执行 `make check`。
2. 将 `VERSION` 从 `X.Y.Z-dev` 改为 `X.Y.Z`。
3. 将 `CHANGELOG.md` 的“开发中”改为发布日期。
4. 合并到 `main`，创建标签 `vX.Y.Z`。
5. 推送分支和标签，创建 GitHub Release 介绍页。

历史版本需要修复时，从相应标签创建 `fix/vX.Y.x` 分支，不直接改动旧标签。
