///|
test "kerf and price scenarios are independent input snapshots" {
  let p = problem([demand("a", "m", 5, 2)], [stock("s", "m", 10, 3, -1)]).unwrap()
  let scenarios = kerf_scenarios(p, [0, 1, 6]).unwrap()
  assert_eq(scenarios[0].cost, Some(3))
  assert_eq(scenarios[1].cost, Some(6))
  assert_eq(scenarios[2].status, Infeasible)
  assert_eq(p.kerf(), 0)
  let q = with_costs(p, [8]).unwrap()
  assert_eq(audit(q, solve(q).unwrap().plan().unwrap()).unwrap().cost, 8)
  assert_true(with_costs(p, []) is Err(_))
  assert_true(with_inventory(p, [-2]) is Err(_))
  let plan = solve(p).unwrap().plan().unwrap()
  assert_eq(compare_plans(p, plan, plan).unwrap().ordering, 0)
}
