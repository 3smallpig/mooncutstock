///|
fn main raise {
  let p = @cutstock.problem(
    [
      @cutstock.demand("rail", "steel", 38, 3),
      @cutstock.demand("brace", "steel", 22, 2),
    ],
    [
      @cutstock.stock("short", "steel", 100, 8, 1, trim_start=2, trim_end=2),
      @cutstock.stock("long", "steel", 160, 14, -1, trim_start=3, trim_end=3),
    ],
    kerf=2,
    min_remnant=10,
  ).unwrap()
  let s = @cutstock.solve(p).unwrap()
  assert_eq(s.status(), @cutstock.Optimal)
  println(@cutstock.text_report(p, s).unwrap())
  let plan = s.plan().unwrap()
  let maps = @cutstock.cutting_map(p, plan).unwrap()
  assert_true(@cutstock.verify_cutting_map(p, plan, maps))
  println(@cutstock.encode_plan(p, plan).unwrap())
}
