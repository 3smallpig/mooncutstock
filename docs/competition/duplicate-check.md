# Bounded semantic duplication review ¡ª 2026-10-15

## Decision and capability fingerprint

MoonCutStock is **heterogeneous 1D cutting-stock procurement with finite inventory,
material compatibility, per-piece kerf/end trims, lexicographic cost/length/bar
optimization, explicit bounded-proof status, audited cut coordinates, remnant
rollover and interchange**. It is not a renamed general packing wrapper. Standard
algorithms are used; no algorithmic novelty or ecosystem-wide uniqueness is claimed.

Three candidates were compared before implementation. Scores below are selection
judgments on a 1¨C5 scale, not benchmark measurements. Duplication is a veto even
when implementation value is high.

| Candidate | Reuse breadth | Gap clarity | Feasible scope | Verifiable quality | Decision |
|---|---:|---:|---:|---:|---|
| Fault-tree/reliability analytics | 4 | 1 | 4 | 4 | Reject: existing reliability/fault-tree API overlap |
| Physical dimensions/units | 5 | 1 | 4 | 4 | Reject: mature LunarUnits dimension model |
| Heterogeneous cutting-stock procurement | 4 | 4 | 4 | 5 | Select, subject to adjacent-project review below |

User groups: fabricator quoting/cut-list tools; finite roll/cable/fabric inventory
systems; services comparing prices, kerf and availability. All use the same reusable
planning/audit model rather than separate hard-coded demonstrations.

## Search scope

The installed competition guide workflow and permanent project registry were
consulted. MoonCakes CLI searches used limits of 100 and terms including cutting,
cutting-stock, kerf, packing, bin-packing, binpack, first-fit, knapsack, reliability,
fault, cut-set, bdd, boolean, dimension and units. GitHub repository and code search
included `bin_packing language:MoonBit`, `first_fit_decreasing language:MoonBit`,
`"cutting stock" language:MoonBit`, `fault_tree`, `birnbaum`, and
`minimal_cut_sets` (100 results per request; returned incomplete=false). The
awesome-moonbit README was inspected. Raw responses and source snapshots are kept
in the private delivery research directory, not mixed with the application.

The cutting-stock code-search hit was a Faker locale string rather than a solver.
These queries do not cover unpublished, newly unindexed or differently named
implementations, and broad search terms can truncate at the result limit.

## Evidence matrix: closest actual artifacts

| Project/version | Artifacts examined | Overlap | Meaningful separation / result |
|---|---|---|---|
| `wcx789ll/moon-reliability@0.3.3` | README, system_reliability and safety_analysis source/tests, repository tree | Fault-tree AND/OR/minimal cuts and reliability workflows | Reject reliability candidate, not a cutting procurement project |
| `oyjh0381/moonbdd@0.1.0` | README, public interface, repository tree | Generic Boolean decision diagrams | Additional neighbor for rejected Boolean/fault-tree candidate |
| `FrozenLemonTee/LunarUnits@0.1.9` | README, core/dimension source and tests, tree | Dimension arithmetic/type model | Reject physical-units candidate |
| `mjfmjf879/moonbit_constraint@0.1.0` (GitHub `moonbit-constraint`) | README/interface/tree; problem_library.mbt, manufacturing.mbt, allocation_models.mbt, knapsack.mbt and applications_test.mbt | Fixed-capacity bin feasibility, knapsack and job-shop machinery | Bin feasibility uses identical capacities; not priced heterogeneous stock procurement, cut geometry or remnant accounting |
| `YM-ai-nb/rectloom@0.1.0` | README/tree, pack_guillotine.mbt and rectloom_test.mbt | Packing and guillotine vocabulary | 2D rectangle shelf/skyline/guillotine geometry, not 1D finite-inventory procurement |
| `Juwan-Hwang/moon-certified@0.1.1` | README, tree and public interface | Generic knapsack/branch-bound primitives | Generic primitive boundary; source-depth review was not established, so do not claim exhaustive implementation comparison |

Repositories are under `https://github.com/<owner>/<repo>` using names above,
except moonbit_constraint's GitHub repository is hyphenated. The permanent registry
also excluded previously reserved quota, dispatch, quadratic programming and
transport projects: cutting stock's exact-demand bar composition, physical kerf
and inventory/purchase objective are different capabilities. The registry review
is not an independent public ecosystem index.

## Reverse review before release

Public entry points were checked against the fingerprint: owned bounded model,
pattern enumeration, exact bounded cost/length/count search, inventory audit,
cut intervals, pattern grouping, remnant rollover, strict interchange and host
command dispatch are implemented in production MoonBit files. Runnable examples
exercise three downstream workflows. This is not an existing solver port or a
wrapper around neighboring packages, and no inspected source was copied.

The bounded conclusion is **no direct same-scope implementation identified in the
examined evidence**, not ¡°first¡±, ¡°only¡± or a guarantee against later discoveries.
The selection must be reconsidered if direct matching prior work is reported.
