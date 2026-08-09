# 第三方组件与许可证

- Squirrel（鼠须管）：GPL-3.0。若分发修改后的应用，应同时保留许可证并提供相应源码或明确的源码获取方式。
- librime：BSD-3-Clause。
- librime-predict：BSD-3-Clause。
- librime-octagram：GPL-3.0-only。
- `predict.db` Alpha 通用联想数据：来自 `rime/librime-predict` 的 `data-1.0` Release，由 essay + octagram 数据生成；下载地址和 SHA-256 固定在 `upstream/versions.lock`。数据库作为外部构建资源下载，不提交进普通 Git 历史；对外打包时随项目保留 GPL-3.0 和相关上游许可证说明。
- rime-wubi 输入方案：许可证原文见 `rime-wubi-LICENSE`。

本仓库不把个人输入历史或用户词频数据库作为开源数据发布。加入其他词库或语料前，必须在此文件记录来源、版本、许可证和处理方式。
