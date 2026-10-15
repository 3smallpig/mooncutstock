"""Exercise actual inline-document CLI, not only in-process dispatch."""
import json, subprocess, sys

target = sys.argv[1] if len(sys.argv) > 1 else "wasm-gc"
def run(command, document, *options, ok=True):
    p = subprocess.run(["moon", "run", "cmd/mooncutstock", "--target", target,
                        "--", command, document, *options], capture_output=True, text=True, encoding="utf-8")
    assert (p.returncode == 0) == ok, (command, p.returncode, p.stdout, p.stderr)
    return p.stdout

problem = {"schema":"mooncutstock.problem/1", "demands":[{"id":"beam","material":"wood","length":40,"quantity":2}],
           "stocks":[{"id":"board","material":"wood","length":100,"quantity":-1,"cost":8,"trim_start":0,"trim_end":0}],
           "kerf":2,"min_remnant":5}
document = json.dumps(problem)
s = json.loads(run("solve-json", document))
assert s["status"] == "optimal" and s["totals"]["cost"] == 8
assert s["totals"]["pieces"] == 2 and s["cut_maps"][0]["remnant_start"] == 84
plan = {"schema":"mooncutstock.plan/1","bars":s["plan"]}
totals = json.loads(run("audit-json", json.dumps({"problem":problem,"plan":plan})))
assert totals == s["totals"]
assert json.loads(run("normalize-json", document)) == problem
csv = "kind,id,material,length,quantity,cost,trim_start,trim_end\ndemand,beam,wood,40,2,0,0,0\nstock,board,wood,100,-1,8,0,0\n"
cs = json.loads(run("solve-csv", csv, "--kerf=2", "--min-remnant=5"))
assert cs["totals"] == totals
assert json.loads(run("solve-json", document, "--patterns=1", "--nodes=1"))["status"] == "feasible-budget"
run("solve-json", "{}", ok=False)
run("solve-json", document, "--nodes=0", ok=False)
run("solve-json", document, "--kerf=0", ok=False)
print("9 actual CLI workflows passed:", target)
