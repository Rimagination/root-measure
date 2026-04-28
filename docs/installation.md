# Installation Guide / 安装指南

This document is for users or agents installing Root Measure into Codex Desktop.
The short version is: install the plugin, then run `release-check`. The long
version below exists because local Codex plugin installation has a few sharp
edges.

这份文档给需要把 Root Measure 安装到 Codex Desktop 的用户或 agent 使用。简短版是：
安装插件，然后运行 `release-check`。下面的长版是为了避免 local Codex 插件安装中的
几个常见坑。

## Recommended Prompt / 推荐安装提示词

```text
Install this Codex plugin and verify it with release-check:
https://github.com/Rimagination/root-measure
```

```text
请安装这个 Codex 插件，并用 release-check 验证：
https://github.com/Rimagination/root-measure
```

Ask Codex to report the plugin path, marketplace name, installed cache path, and
the final `release-check` status.

让 Codex 报告插件路径、marketplace 名称、安装缓存路径，以及最终的
`release-check` 状态。

## Expected Layout / 期望目录结构

For a home-local marketplace, the source layout should look like:

对 home-local marketplace，源目录通常应类似：

```text
<home>/
  .agents/
    plugins/
      marketplace.json
  plugins/
    root-measure/
      .codex-plugin/
        plugin.json
      bin/
        root-measure.cmd
      scripts/
      skills/
```

The marketplace entry should use a relative local source path:

marketplace 条目应使用相对 local source path：

```json
{
  "name": "root-measure",
  "source": {
    "source": "local",
    "path": "./plugins/root-measure"
  },
  "policy": {
    "installation": "AVAILABLE",
    "authentication": "ON_INSTALL"
  },
  "category": "Science"
}
```

After Codex installs the plugin, the installed copy lives in the Codex plugin
cache, not directly under `.codex/plugins/root-measure`:

Codex 安装后，插件副本位于 Codex plugin cache，而不是直接放在
`.codex/plugins/root-measure`：

```text
<CODEX_HOME>/plugins/cache/<marketplace-name>/root-measure/<version>/
```

Example:

示例：

```text
C:\Users\<you>\.codex\plugins\cache\local-plugins\root-measure\0.2.0-beta\
```

## Verification / 验证

Run from the source plugin or installed plugin:

可以从源插件或已安装插件运行：

```powershell
<plugin-root>\bin\root-measure.cmd doctor
<plugin-root>\bin\root-measure.cmd release-check
```

`doctor` checks the backend toolchain and wrapper commands.

`doctor` 检查后端工具链和 wrapper 命令。

`release-check` checks:

`release-check` 检查：

- `plugin.json` identity and strict UTF-8 encoding
- `plugin.json` 身份信息和严格 UTF-8 编码
- marketplace entry and strict UTF-8 encoding
- marketplace 条目和严格 UTF-8 编码
- PowerShell syntax
- PowerShell 语法
- `rv.exe` and `cvutil.dll` hashes
- `rv.exe` 和 `cvutil.dll` hash
- raw `rv.exe` passthrough
- raw `rv.exe` 参数透传
- reproducibility profile
- 复现 profile
- smoke measurement, inspect, and self-compare
- smoke 测量、inspect 和自比较

A successful install should end with:

成功安装应看到：

```text
"status": "pass"
```

## Known Install Pitfalls / 常见安装坑

### UTF-8 BOM in JSON / JSON 文件带 BOM

Codex's plugin loader expects strict JSON. A file that PowerShell can parse may
still fail inside Codex if it starts with a UTF-8 BOM.

Codex 的插件加载器按严格 JSON 解析。某个 JSON 文件即使 PowerShell 能解析，如果开头
带 UTF-8 BOM，Codex 里仍然可能失败。

Bad first bytes:

错误开头字节：

```text
EF BB BF 7B ...
```

Good first bytes:

正确开头字节：

```text
7B ...
```

The Codex log symptom is usually:

Codex 日志里的典型症状是：

```text
failed to parse plugin manifest: expected value at line 1 column 1
```

Root Measure's `release-check` now includes encoding checks to catch this before
publishing.

Root Measure 的 `release-check` 已加入编码检查，发布前会拦住这个问题。

### Wrong installed directory / 安装目录判断错

The install cache path is:

真实安装缓存路径是：

```text
<CODEX_HOME>/plugins/cache/<marketplace-name>/root-measure/<version>
```

Do not assume that an installed plugin is active just because this directory
exists:

不要仅因为下面这个目录存在就认为插件已按 Codex 规则安装成功：

```text
<CODEX_HOME>/plugins/root-measure
```

That path can be useful for manual testing, but Codex Desktop resolves installed
plugins through the cache layout.

那个路径可用于手工测试，但 Codex Desktop 解析已安装插件时走的是 cache 结构。

### Marketplace name drift / Marketplace 名称漂移

The plugin id includes the marketplace name, for example:

插件 id 包含 marketplace 名称，例如：

```text
root-measure@local-plugins
```

If the marketplace name changes, update `config.toml` and reinstall or re-enable
the plugin under the new id.

如果 marketplace 名称变化，需要同步更新 `config.toml`，并在新 id 下重新安装或启用。

### Backend not found / 找不到后端

The plugin is a Codex front door. It still needs the Root Measure backend project
that contains:

插件是 Codex 入口，仍然需要包含以下内容的 Root Measure 后端项目：

```text
scripts/Invoke-RootMeasure.ps1
tools/rve-toolchain/rv.exe
tools/rve-toolchain/cvutil.dll
```

If the backend is in a custom location, set:

如果后端在自定义位置，可以设置：

```powershell
$env:ROOT_MEASURE_ROOT = "D:\path\to\root-measure"
```

or pass:

或传入：

```powershell
<plugin-root>\bin\root-measure.cmd doctor --root-measure-root D:\path\to\root-measure
```

## Installer Checklist / 安装者检查清单

- Source directory contains `.codex-plugin/plugin.json`.
- 源目录包含 `.codex-plugin/plugin.json`。
- `plugin.json` and `marketplace.json` are UTF-8 without BOM.
- `plugin.json` 和 `marketplace.json` 是无 BOM 的 UTF-8。
- Marketplace entry uses `source.path: "./plugins/root-measure"`.
- marketplace 条目使用 `source.path: "./plugins/root-measure"`。
- Installed cache path is under `plugins/cache/<marketplace>/root-measure/<version>`.
- 已安装缓存路径位于 `plugins/cache/<marketplace>/root-measure/<version>`。
- `root-measure.cmd doctor` passes.
- `root-measure.cmd doctor` 通过。
- `root-measure.cmd release-check` passes.
- `root-measure.cmd release-check` 通过。
