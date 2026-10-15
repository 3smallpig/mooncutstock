# Interchange v1

All JSON is limited to 65,536 UTF-16 code units and eight nested containers before
parsing. Unknown object members are rejected; required members must be present.
Numeric values must be mathematically integral and inside each field's domain
(e.g. `1.0` is accepted as 1). Object duplicate keys follow the MoonBit core JSON
parser behavior; producers must send unique member names. No signature/canonical
JSON compatibility is claimed. Do not use raw incoming JSON as a cryptographic ID.

Problem: `schema="mooncutstock.problem/1"`, `demands`, `stocks`, `kerf`,
`min_remnant`. Demands require `id,material,length,quantity`; stocks require
`id,material,length,cost,quantity,trim_start,trim_end`. Trims are required even when
zero. Array lengths and domain constraints are validated by `problem`.

Plan: `schema="mooncutstock.plan/1"`, `bars` array of objects with zero-based
`stock` index and `counts` aligned to the problem's demand order; optional `totals`
are checked, never trusted. Imported plans must fulfill demand exactly and pass
audit. A plan has no independent problem identity; pass the correct problem.
A solution document uses `mooncutstock.solution/1` and includes status, enumeration
and search completion/work, optional audited plan/totals and cut maps. Solution
JSON is an output report, not an importable proof certificate.

`audit-json` takes `{ "problem": <problem object>, "plan": <plan object> }`
and returns audited totals. See `encode_problem`, `encode_plan`, `encode_solution`.

CSV header exactly:

```csv
kind,id,material,length,quantity,cost,trim_start,trim_end
demand,beam,wood,40,2,0,0,0
stock,board,wood,100,-1,8,0,0
```

Quoted fields, doubled quotes and CRLF/LF are supported. Demand cost/trims must be
zero. CSV integers use decimal digits (or exactly `-1` for unlimited stock);
whitespace is not silently trimmed. Maximum 29 rows including header, 8 columns,
256 code units per cell. Kerf/minimum remnant are external metadata provided to
`decode_csv` (default 0/1) or CLI options. `encode_csv` does not embed them; preserve
them separately when transporting a problem. `normalize-csv` consumes CSV and
`normalize-json` consumes JSON; neither command changes input format.
