# MoonCutStock

A pure MoonBit **heterogeneous one-dimensional cutting-stock procurement planner**.
Combine material-matched demands with finite or unlimited stock of different prices,
lengths and end trims; obtain auditable cutting instructions, inventory usage and
reusable remnants. No external runtime solver or third-party module is required.

Module: `3smallpig/mooncutstock@0.1.0` · MIT · participant/account: `3smallpig`.

## Install and integrate

```sh
moon new shop
cd shop
moon add 3smallpig/mooncutstock@0.1.0
```

Import `"3smallpig/mooncutstock" @cutstock` in your package's `moon.pkg`:

```moonbit
let p = @cutstock.problem(
  [@cutstock.demand("beam", "wood", 40, 4)],
  [@cutstock.stock("short", "wood", 85, 7, 1),
   @cutstock.stock("long", "wood", 130, 12, -1)],
  kerf=2, min_remnant=5,
).unwrap()
let s = @cutstock.solve(p).unwrap()
println(@cutstock.text_report(p, s).unwrap())
```

This instance yields purchase cost 19, 2 bars and exact fulfillment of 4 pieces.
`Solution::plan()` is optional: inspect status before unwrapping it. Public
constructors/decoders return `Result`; invalid geometry is not silently repaired.
Use `pkg.generated.mbti` for the complete public interface.

## Workflows

```sh
moon run examples/procurement
moon run examples/rollover
moon run examples/scenarios
moon run cmd/mooncutstock -- demo
moon run cmd/mooncutstock -- help
```

* Fabricators: optimize differently priced, trimmed bars; export count patterns
  and physical cut intervals. The procurement example costs 22 for 5 pieces.
* Cable/fabric inventory tools: consume finite rolls, recover qualifying remnants,
  and construct a validated next-batch problem. The rollover example purchases
  nothing in its second batch; handling costs are not included.
* Planning services: compare kerf, price and inventory scenarios using immutable
  problem snapshots and explicit completion status. The scenario example compares
  costs 20 and 40 when kerf changes from 0 to 2 length units.

CLI commands take **one inline document argument**, not a filename or stdin.
PowerShell example (single quotes protect the JSON document):

```powershell
$inputJson = '{"schema":"mooncutstock.problem/1","demands":[{"id":"a","material":"wood","length":40,"quantity":2}],"stocks":[{"id":"s","material":"wood","length":100,"cost":8,"quantity":-1,"trim_start":0,"trim_end":0}],"kerf":2,"min_remnant":5}'
moon run cmd/mooncutstock -- solve-json $inputJson --format=text --patterns=50000 --nodes=200000
```

`solve-json`, `solve-csv`, `normalize-json`, `normalize-csv`, `audit-json` are
available through the host-independent `run_command` API as well. Invalid CLI
input aborts with nonzero exit. CSV accepts `--kerf=N --min-remnant=N`; JSON
requires these in its document. Both solvers accept `--format=json|text`,
`--patterns=N` and `--nodes=N`. Duplicate/unknown options are rejected.

## Exact meaning of the model

* All lengths/costs are **integers in caller-chosen consistent units**; convert
  physical lengths and currency before calling. Materials compare as exact strings.
* Each piece consumes `length + kerf`, **including the final piece in a bar**.
  Both end trims are removed first. This conservative rule is not a machine model
  that waives the final cut. There is no overproduction or mixed-material bar.
* Minimize `(purchase cost, purchased stock length, bar count)` lexicographically.
  Remnant resale value is not part of this objective. Equal-objective layouts may
  differ. This is not merely fixed-bin feasibility or a 2D rectangle packer.
* Stock quantity `-1` means unlimited; `0` means unavailable. Remnants with length
  at least `min_remnant` become zero-purchase-cost stock; trims do not carry over.
* `audit` rebuilds count-vector geometry and verifies exact fulfillment, stock
  limits and conservation: purchased = useful + kerf + trim + reusable + scrap.
  `cutting_map` gives half-open piece/kerf/remainder coordinates. The map verifier
  compares regenerated maps, not a separate independent geometry implementation.

| Status | Interpretation |
|---|---|
| `Optimal` | Complete pattern enumeration and complete bounded search; optimum proved within this model |
| `FeasibleBudget` | Audited feasible incumbent, but enumeration/search budget prevented proof |
| `Infeasible` | Complete enumeration/search proved no plan within this model |
| `UnknownBudget` | No incumbent and no proof; **not** evidence of infeasibility |

Defaults: 50,000 enumeration visits, 200,000 search work units. Maximum each is
1,000,000. Candidate checks and state visits both count as search work. Pattern
budget limits recursive visits, not just output patterns. Memo table: 50,000
states. A work counter is not a time/memory guarantee; do not grant maximum limits
on an untrusted request without host-level isolation. The greedy seed can miss a
feasible solution; failure of that heuristic never proves infeasibility.

## Interchange and bounds

See [format specification](docs/formats.md), [architecture](docs/architecture.md)
and [security](SECURITY.md). Bounds: 12 demand types, 16 stock types, 128 total
pieces, stock inventory -1 or 0..128, length 1..1,000,000 and nonnegative cost up
to 1,000,000; kerf 0..1,000,000 and minimum remnant 1..1,000,000. Labels contain
1..128 UTF-16 code units and no ASCII control characters. End trims cannot exceed
stock length. Rollover fails if retained types plus remnants exceed these bounds.

Not provided: industrial-scale column generation, LP/MIP solver integration,
2D/3D nesting, scheduling, grain direction, tolerances, machine control, persistence,
HTTP service or GUI. This release is not a safety-certified manufacturing system.
Verify units, machine constraints and cut instructions before physical use.

## Build and verify

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
python scripts/audit.py
bash scripts/verify.sh wasm-gc
```

CI checks `wasm-gc`, `wasm`, `js`, `native` on Linux with a digest-pinned official
MoonBit snapshot. Initial development used the 20260920 development toolchain; release formatting
and validation use moon 0.1.20261012 / moonc v0.10.15+943464bfa. Cross-target CI is the authoritative clean-runner evidence.
28 test blocks include **160 deterministic independent exhaustive-oracle cases**,
comparing the full objective and infeasibility; they are not 160 extra test blocks.
There is no benchmark or formal verification claim.

## Provenance and competition

Original implementation assisted by an AI coding agent; no neighboring project
source was copied. It implements standard enumeration, greedy packing,
branch-and-bound and memoization ideas, not a newly invented optimization method.
See [references](docs/references.md), [AI disclosure](AI_USAGE.md),
[bounded semantic duplication review](docs/competition/duplicate-check.md) and
[changelog](CHANGELOG.md). Competition application and personal contact material
are deliberately **not part of this repository or package**.
