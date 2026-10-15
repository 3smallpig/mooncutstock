///|
test "rollover consumes finite inventory and reuses bounded remnants" {
  let p = problem(
    [demand("a", "w", 3, 2)],
    [stock("s", "w", 10, 7, 1)],
    kerf=1,
    min_remnant=2,
  ).unwrap()
  let plan = solve(p).unwrap().plan().unwrap()
  let rs = remnants(p, plan).unwrap()
  assert_eq(rs[0].length, 2)
  let next = rollover(p, plan, [demand("b", "w", 1, 1)]).unwrap()
  let r = solve(next).unwrap()
  assert_eq(r.status(), Optimal)
  assert_eq(audit(next, r.plan().unwrap()).unwrap().cost, 0)
  assert_eq(p.stocks()[0].quantity, 1)
}
