# Security and operational limits

No network, filesystem, shell or credential access occurs in the library. All
interchange is bounded before parsing and domain-validated. Labels reject ASCII
controls to avoid multiline/terminal-control report injection. Unicode bidi marks
are not rejected; treat labels as untrusted display text in a host UI. CSV exports
are data, not spreadsheet-formula-sanitized documents: a label beginning `=` may
be evaluated by spreadsheet software. Import as text, not executable formulas.

Budgets count algorithm work, not milliseconds or resident memory; worst-case
pattern/state arrays are substantial at maximum limits. Isolate untrusted solves
in a host worker with time/memory limits and lower budgets. Input validation is
not a replacement for host resource governance. Error strings may contain input
labels: escape them for HTML/logging. No SQL/HTML renderer is included.

Remnant cost 0 means purchase accounting only; handling, requalification and
machine constraints remain the caller's responsibility. Auditing proves only the
software's integer model, not physical safety. No machine actuation is supplied.

Report a reproducible security issue through the repository's issue tracker with
synthetic data. Never include credentials or private production/customer data.
