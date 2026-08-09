# 离线词汇联想

当前安装的鼠须管已经包含 `librime-predict.dylib`，因此第一版不需要修改输入法核心代码。

## Alpha 1

先使用上游 `data-1.0` 的预发布 `predict.db` 验证链路。该数据库由 essay + octagram 生成，只用于本机测试，不随项目发布。预测候选先通过 `t2s.json` 统一为简体；开启万能五笔的繁体模式后，再由现有 `s2t.json` 转为繁体。

```bash
make prediction-alpha
make install-prediction
```

数据来源、版本与 SHA-256 固定在 `upstream/versions.lock`。

- Alpha 测试版默认开启联想，避免快捷键被当前应用或 macOS 截获而无法验证。
- `Control + Shift + P` 切换联想开关。
- 每次最多显示 7 项，正好占一页（上游实现存在一次追加后再判断的行为，因此配置值设为 6）。
- 最多连续联想 1 次。

切换一次输入方案或重启鼠须管后，上屏“今天”，应出现“的 / 是 / 我”等联想候选。

## 自建模型

正式模型需要：

1. 准备二元词频数据，格式为 `前词 后词<TAB>权重`，例如 `输入法 好用<TAB>120`。
2. 使用上游 `make_predict_data` 转成 `前词<TAB>后词<TAB>权重`。
3. 使用上游 `build_predict` 生成 `predict.db`。
4. 将数据库和本目录的 custom 配置安装到 Rime 用户目录，重新部署。

公开语料放 `corpus/public/` 并记录许可证；个人语料放 `corpus/private/`，不会进入 Git。生成的数据库放 `models/`，也不进入普通 Git 历史。

## 验收重点

- 正在输入编码时不得插入预测候选，五笔首选顺序保持不变。
- 简体模式下预测词为简体，繁体模式下预测词为繁体。
- 关闭联想后不显示预测候选。
- 数据库缺失时安装脚本应阻止启用，不让输入法加载无效配置。
