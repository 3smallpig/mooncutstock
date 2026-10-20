# MoonCutStock

[English](README.md) | 简体中文

纯 MoonBit 的**异规格一维下料与采购规划库**，模块 `3smallpig/mooncutstock@0.1.1`，MIT 许可。
将不同材料、长度、价格及可用数量的原料与需求组合，输出可审计方案、半开区间切割坐标、库存用量及可复用余料；不依赖第三方求解器。

> 0.1.1 修复 JSON 小数经浮点舍入后被误判为整数的问题，补齐中文指南，并将 CI 固定到官方工具链版本归档；兼容既有 API 和 v1 格式。详见 [变更记录](CHANGELOG.md)。

## 用途、已实现能力与非目标

- 加工厂报价/切割清单：组合异价异长钢材、有限短料库存及长料采购，核算锯缝与端部裁切，输出切割坐标和重复模式清单。
- 线缆/卷材库存系统：规划首批需求，扣减有限库存，回收余料并作为下一批零采购成本原料；搬运及复检成本由调用方建模。
- 规划服务：替换价格/库存、比较方案与锯缝情景，在预算耗尽时明确区分“找到可行解”和“证明最优”。

已实现：有界模式枚举、贪心初解、分支定界及记忆化、精确需求与材料匹配、独立库存/长度审计、坐标与模式清单、余料接续、JSON/CSV 和命令行。
不提供：工业规模列生成/LP/MIP、二维/三维排样、排程、纹理/公差、机床控制、持久化、HTTP 服务或 GUI；没有性能优越性、形式化证明或工业安全认证声明。实物下料前须人工核对单位、设备约束及指令。

## 环境与安装

发布工具链为 `moon 0.1.20261012`、`moonc v0.10.15+943464bfa`。目标为 `wasm-gc`、`wasm`、`js`、`native`；JS 运行需要 Node.js，native 构建/运行需要兼容 C 工具链，Windows 需要 MSVC C++ Build Tools 及 Windows SDK。本次验收的 native 执行环境为 WSL Ubuntu 24.04 / GCC 13.3，Windows MSVC 环境未执行；不将 Linux 结果冒称 Windows 原生验证。

```sh
moon new shop
cd shop
moon add 3smallpig/mooncutstock@0.1.1
```

在示例包的 `moon.pkg` 中配置导入（可使用项目自带 `cmd/main` 包）：

```moonbit
import {
  "3smallpig/mooncutstock" @cutstock,
}
pkgtype(kind: "executable")
```

如开发时验证当前源码工作树，消费者的 `moon.mod` 声明同一模块依赖：

```toml
name = "local/cutstock-consumer"
version = "0.1.0"
import {
  "3smallpig/mooncutstock@0.1.1",
}
```

在消费者根目录另建 `moon.work`，通过工作区成员覆盖已发布模块（替换为本地源码绝对路径，Windows 用正斜线）：

```toml
members = [".", "C:/path/to/mooncutstock"]
```

包导入仍放在 `moon.pkg`。本地工作区配置只放消费者中，无须修改库根目录或已发布版本。

## 可运行快速开始

将下列内容写入该消费者示例包的 `main.mbt`，然后在消费者根目录执行 `moon run cmd/main --target wasm-gc`（若包在根目录则执行 `moon run . --target wasm-gc`）：

```moonbit
///|
fn main raise {
  let p = @cutstock.problem(
    [@cutstock.demand("beam", "wood", 40, 4)],
    [@cutstock.stock("short", "wood", 85, 7, 1),
     @cutstock.stock("long", "wood", 130, 12, -1)],
    kerf=2, min_remnant=5,
  ).unwrap()
  let s = @cutstock.solve(p).unwrap()
  assert_eq(s.status(), @cutstock.Optimal)
  let plan = s.plan().unwrap()
  let totals = @cutstock.audit(p, plan).unwrap()
  assert_eq(totals.cost, 19)
  assert_eq(totals.pieces, 4)
  println(@cutstock.text_report(p, s).unwrap())
}
```

本仓库自带三个完整可运行示例：

```sh
moon run examples/procurement --target wasm-gc
moon run examples/rollover --target wasm-gc
moon run examples/scenarios --target wasm-gc
```

采购示例成本为 22、完成五件；接续示例第一批回收 59 单位，第二批两件 20 的新增采购成本为 0；四件 49 的锯缝情景在锯缝 0/2 时成本为 20/40。数值来自断言，不是工业效果测量。

## API 与模型语义

- `problem` 校验并复制输入；`solve` 返回证明状态、完成标记与工作计数。
- `audit` 从决策计数重新核算库存、精确需求及长度守恒；`plan_from_patterns`、`decode_plan` 等入口同样审计。
- `cutting_map` 返回半开区间坐标；`verify_cutting_map` 重新生成同一坐标作比较，不是独立几何预言机。`group_patterns`/`expand_groups` 压缩/恢复模式清单。
- `remnants`/`remnant_stocks` 输出可复用余料；`rollover` 扣减库存并构造下一批问题，不改变输入对象。
- `with_costs`/`with_inventory`/`with_kerf` 创建情景；`kerf_scenarios` 最多 16 个情景；`compare_plans` 对同一问题按目标比较。
- `encode_problem`/`decode_problem`、`encode_plan`/`decode_plan` 提供数据交换；`encode_solution`/`text_report` 将结果绑定到原问题，不能把另一问题的最优状态套上来。

所有长度/成本用一致的整数单位，材料按字符串精确匹配。每件消耗 **长度 + 锯缝，最后一件也算锯缝**；先扣两端裁切，不允许超产或混料。目标按 `(采购成本, 购入原料总长, 根数)` 字典序最小化，不计余料转售收益。
库存 `-1` 为无限，`0` 为不可用；长度达到 `min_remnant` 的余料转为零采购成本库存，不继承原料裁切。长度守恒为：购入 = 成品 + 锯缝 + 端裁 + 可复用余料 + 废料。

| 状态 | 含义 |
|---|---|
| `Optimal` | 枚举与搜索均完成，模型内最优已证 |
| `FeasibleBudget` | 有已审计可行解，预算不足以证明最优 |
| `Infeasible` | 完整枚举与搜索证明模型内无解 |
| `UnknownBudget` | 尚无可行解且预算耗尽，不能解释为无解 |

## CLI 与交换格式

以下 PowerShell 示例在本仓库根目录运行，输入为单个内联参数，不读文件或 stdin：

```powershell
$inputJson = '{"schema":"mooncutstock.problem/1","demands":[{"id":"a","material":"wood","length":40,"quantity":2}],"stocks":[{"id":"s","material":"wood","length":100,"cost":8,"quantity":-1,"trim_start":0,"trim_end":0}],"kerf":2,"min_remnant":5}'
moon run cmd/mooncutstock --target wasm-gc -- solve-json $inputJson --format=text --patterns=50000 --nodes=200000
```

命令有 `solve-json`、`solve-csv`、`normalize-json`、`normalize-csv`、`audit-json`，也可通过纯函数 `run_command` 嵌入。非法 CLI 输入非零退出；未知/重复选项拒绝。
JSON 的锯缝/余料阈值必须写在文档中；CSV 用 `--kerf=N --min-remnant=N`。两种求解命令可用 `--format=json|text`、`--patterns=N`、`--nodes=N`。`audit-json` 接受 `{problem,plan}`，不接受选项。
`normalize-json` 仍输出问题 JSON，`normalize-csv` 仍输出 CSV，不是格式转换命令。

JSON schema/必需字段详见 [格式说明](docs/formats.md)：问题为 `mooncutstock.problem/1`，方案为 `mooncutstock.plan/1`，解为 `mooncutstock.solution/1`（仅报告，非导入证明证书）。未知字段拒绝，重复键沿用标准解析器行为，生产者应发送唯一键，不作签名/规范 JSON 保证。整数允许 `1.0`、`1e2` 等精确整数字面量，本地修订拒绝浮点舍入才变为整数的非整数值。

CSV 表头固定为：

```csv
kind,id,material,length,quantity,cost,trim_start,trim_end
demand,beam,wood,40,2,0,0,0
stock,board,wood,100,-1,8,0,0
```

支持引号、双引号转义和 CRLF/LF；需求成本/裁切必须为零，整数不自动去空格。最多含表头 29 行、每行 8 列、每字段 256 个 UTF-16 单元。CSV 不保存锯缝/余料阈值，传输时必须另存元数据。

## 上界、资源与验证

12 类需求、16 类原料、总需求 128 件；数量 0..128（原料另允许 -1）；长度 1..1,000,000，成本/锯缝 0..1,000,000，余料阈值 1..1,000,000。标签 1..128 个 UTF-16 单元且无 ASCII 控制字符；两端裁切总长不得超过原料。接续后超出原料类型上限会明确失败，不静默丢弃。
JSON/CSV 输入最多 65,536 个 UTF-16 单元，JSON 最深八个容器。默认枚举 50,000 访问、搜索 200,000 工作单位；两者各最多 1,000,000。搜索计数含状态和候选检查；记忆表最多 50,000 状态。预算计数不是时间或内存保证，不可信任务需宿主隔离和限制。贪心失败不证明无解。

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
python scripts/audit.py
python scripts/check_cli.py wasm-gc
bash scripts/verify.sh wasm-gc
```

Linux CI 覆盖四后端的严格检查、测试、构建、示例和真实 CLI，但仅证明其对应提交。当前有 32 个测试块，其中包含 160 个独立逐件穷举案例（不是另外 160 个测试块）；0.1.1 增加精确整数和资源/状态边界回归。外部独立验收证据保存在仓库外报告。没有性能跑分或完整正确性证明承诺。

## 许可、归属与 AI 使用

采用 [MIT](LICENSE)。原创实现，仅依赖 MoonBit 标准核心；参考标准模式枚举、贪心、分支定界、记忆化及 Gilmore–Gomory 的问题建模背景，未实现其列生成，不复制相邻项目。详见 [参考边界](docs/references.md)、[AI 披露](AI_USAGE.md)、[架构](docs/architecture.md)、[安全](SECURITY.md) 和 [有界语义查重](docs/competition/duplicate-check.md)。AI 代理参与研究、实现、测试和文档；责任与限制未被测试数量取代。
私有申报书和联系资料不在仓库/发布包中；本地验收不等于官方通过，也不代为报名。
