# Architecture and correctness boundaries

`model`/`validation` own bounded snapshots; public array accessors copy. `pattern`
validates count vectors. `audit` independently rebuilds geometry and inventories.
`enumerate` performs capacity-pruned demand-count DFS for each available stock.
`greedy` orders pieces by descending length and chooses incremental feasible bins;
it seeds an incumbent without contributing to proof completeness.

`bounds` separates materials and combines volume bounds with the cheapest rational
cost/capacity bound. Available capacity includes finite stock inventory. Each
positive residual piece must fit some available stock before rational conversion.
Integer multiplication uses Int64; bounded complete-plan totals fit Int32.

`solve` picks the first positive residual demand and explores indexed patterns
containing it. Every feasible nonempty plan has a bar satisfying that demand, so
this branching is complete when all patterns and branches are visited. Residual
counts and finite remaining inventory define the state. Lexicographically no-worse
partial objectives dominate equivalent states; future feasible additions are the
same. Memoization stops adding entries after 50,000 states, without dropping search
branches. Cost pruning uses only a necessary lower bound. State/candidate work is
counted before performing it. Enumeration and search completeness are separate.

`cuts`, `groups`, `remnants` provide half-open cut maps, compact production bills
and explicit inventory transitions. `decode`, `encode`, `csv` implement bounded
interchange. `report` binds solutions to their source problem to avoid attaching
proof status to unrelated input. `scenario` validates whole scenario batches
before solving. `command` is a pure string-in/string-out host boundary; the executable
only obtains arguments and prints results. No library I/O or mutable global state.

## Verification layers

Tests cover bounded validation, mutation ownership, malformed interchange,
finite stock, materials, kerf/trims, exact output and conservation, rollover,
budget uncertainty, provenance mismatch and public downstream usage. The independent
oracle assigns individual pieces directly to bins and explores stock purchases;
it does not call the production pattern enumeration, bounds, greedy seed or memo.
160 deterministic small instances compare feasibility and all three objective
components. This provides bounded experimental evidence, not a mathematical proof
of the entire implementation. Map comparison reuses production regeneration and
is intentionally not described as an independent oracle.
