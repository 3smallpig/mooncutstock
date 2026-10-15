# References and source boundary

This is an original MIT-licensed implementation. Dependencies are MoonBit's own
standard core/debug/json/env facilities (env only in the CLI); no third-party
solver or ported code is bundled. Preserve upstream toolchain licenses when
redistributing the toolchain itself; it is not shipped in this repository.

Conceptual references (not copied implementations):

* Gilmore and Gomory, ¡°A Linear Programming Approach to the Cutting-Stock
  Problem¡±, Operations Research 9(6), 1961, DOI 10.1287/opre.9.6.849. Standard
  pattern-based cutting-stock background. This release does **not** implement
  their LP/column-generation algorithm.
* SCIP Optimization Suite cutting-stock example:
  https://scipopt.org/doc/html/PROBLEM__DESC.php ¡ª reference class of mature
  optimization systems, not an implemented dependency or performance baseline.
* MoonBit documentation: https://docs.moonbitlang.com/ ¡ª language/toolchain.

Neighboring MoonBit projects inspected for semantic duplication are listed in
`competition/duplicate-check.md`. They contributed no source code to this module.
No algorithm novelty, exhaustive ecosystem uniqueness, industrial performance
comparison or certification is claimed.
