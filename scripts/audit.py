"""Conservative source inventory; excludes tests, examples, CLI and generated files."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
rows = []
for p in sorted(root.glob("*.mbt")):
    if p.name.endswith(("_test.mbt", "_wbtest.mbt")):
        continue
    lines = p.read_text(encoding="utf-8-sig").splitlines()
    code = [s for s in lines if s.strip() and not s.lstrip().startswith("//")]
    substantive = [s for s in code if s.strip() not in ("{", "}", "},", ")", ");", "]", "],")]
    rows.append(dict(file=p.name, physical=len(lines), noncomment=len(code), substantive=len(substantive)))
result = {"files": rows, "totals": {k: sum(r[k] for r in rows) for k in ("physical", "noncomment", "substantive")}}
print(json.dumps(result, indent=2))
assert result["totals"]["substantive"] >= 1500
