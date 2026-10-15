///|
fn main raise {
  let p = @cutstock.problem(
    [@cutstock.demand("first", "cable", 40, 1)],
    [@cutstock.stock("roll", "cable", 100, 12, 1)],
    kerf=1,
    min_remnant=10,
  ).unwrap()
  let plan = @cutstock.solve(p).unwrap().plan().unwrap()
  let q = @cutstock.rollover(p, plan, [
    @cutstock.demand("second", "cable", 20, 2),
  ]).unwrap()
  let s = @cutstock.solve(q).unwrap()
  assert_eq(s.status(), @cutstock.Optimal)
  assert_eq(@cutstock.audit(q, s.plan().unwrap()).unwrap().cost, 0)
  println(@cutstock.text_report(q, s).unwrap())
}
