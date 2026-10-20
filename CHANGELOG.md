# Changelog

## 0.1.1 — 2026-10-20

* Validate JSON decimal integers from source digits before Double conversion; reject
  near-integers and underflow without rejecting valid integral scientific notation.
* Add complete Chinese installation/API/CLI documentation and precision/resource
  regression tests; preserve public API and v1 interchange compatibility.
* Pin CI to official compiler-version archives while retaining original SHA-256
  checks, rather than depending on the mutable latest download alias.
* Correct legacy-encoded Markdown punctuation and report the measured CLI invocation
  count instead of a hard-coded count.

## 0.1.0 — 2026-10-15

* Owned validated demand/stock model, material restrictions, finite inventory,
  end trims, conservative per-piece kerf and reusable remainder threshold.
* Bounded complete pattern enumeration, greedy incumbent, rational lower bounds,
  indexed memoized exact search and explicit four-way proof/budget status.
* Independent audit, cut coordinates, pattern bills and next-batch rollover.
* Bounded JSON/CSV codecs, reporting, scenario transforms and pure CLI dispatch.
* Three executable workflows; public API tests and 160-case exhaustive oracle.
