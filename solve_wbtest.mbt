///|
test "exact procurement optimizes cost rather than number of bars" {
  let p = problem([demand("a", "m", 4, 2)], [
    stock("small", "m", 4, 2, -1),
    stock("large", "m", 8, 5, -1),
  ]).unwrap()
  let result = solve(p).unwrap()
  assert_eq(result.status(), Optimal)
  let t = audit(p, result.plan().unwrap()).unwrap()
  assert_eq(t.cost, 4)
  assert_eq(t.bars, 2)
}

///|
test "finite inventory can require a non-greedy feasible plan" {
  let p = problem([demand("short", "m", 3, 2), demand("long", "m", 5, 1)], [
    stock("six", "m", 6, 1, 1),
    stock("five", "m", 5, 2, 1),
  ]).unwrap()
  let result = solve(p).unwrap()
  assert_eq(result.status(), Optimal)
  assert_eq(audit(p, result.plan().unwrap()).unwrap().cost, 3)
}

///|
test "infeasibility and exhausted budgets are distinct" {
  let p = problem([demand("a", "m", 9, 1)], [stock("s", "m", 5, 1, -1)]).unwrap()
  assert_eq(solve(p).unwrap().status(), Infeasible)
  assert_eq(
    solve(p, limits={ patterns: 1, nodes: 1, }).unwrap().status(),
    UnknownBudget,
  )
  let q = problem([demand("a", "m", 2, 2)], [stock("s", "m", 5, 1, -1)]).unwrap()
  let result = solve(q, limits={ patterns: 1, nodes: 1, }).unwrap()
  assert_eq(result.status(), FeasibleBudget)
  assert_true(audit(q, result.plan().unwrap()) is Ok(_))
}
