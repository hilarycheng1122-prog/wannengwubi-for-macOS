# 离线词汇联想

当前安装的鼠须管已经包含 `librime-predict.dylib`，因此第一版不需要修改输入法核心代码，只需要：

1. 准备二元词频数据，格式为 `前词 后词<TAB>权重`，例如 `输入法 好用<TAB>120`。
2. 使用上游 `make_predict_data` 转成 `前词<TAB>后词<TAB>权重`。
3. 使用上游 `build_predict` 生成 `predict.db`。
4. 将数据库和本目录的 custom 配置安装到 Rime 用户目录，重新部署。

初版默认关闭联想，最多展示 5 项并只连续联想一次。这样能控制干扰，也便于和稳定版比较。

公开语料放 `corpus/public/` 并记录许可证；个人语料放 `corpus/private/`，不会进入 Git。生成的数据库放 `models/`，也不进入普通 Git 历史。

