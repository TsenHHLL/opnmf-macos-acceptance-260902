# OPNMF GUI-260902 Apple Silicon 实机验收

此入口用于补齐 GitHub 托管 Mac 无显示器图形握手无法完成的 41 项 GUI 测试。

要求：

- Apple Silicon（M 系列）Mac；
- 登录着的 macOS 图形桌面会话，不要作为后台服务运行；
- MATLAB R2024b 原生 Apple Silicon 版本；
- Statistics and Machine Learning Toolbox；
- Java 11（建议 Amazon Corretto 11）；
- 至少 8 GB RAM，建议 16 GB。

执行：

```bash
cd /path/to/mac_ci_260902_ready
chmod +x run_on_real_mac.command
./run_on_real_mac.command
```

脚本会先核验 `GUI-260902.zip` 的 SHA256，然后新建 `real_mac_run_YYYYMMDD_HHMMSS` 目录并运行全套 257 项测试。它不会覆盖原包，也不会删除其他文件。验收证据写入新目录下的 `artifacts/real-arm64`。

只有出现 `ACCEPTANCE_PASSED.json`，并且 `test_summary.json` 显示 `257 Passed / 0 Failed / 0 Incomplete`，才可认定 Apple Silicon 实机全量验收通过。
