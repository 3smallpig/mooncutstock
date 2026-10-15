///|
test "heterogeneous greedy honors finite material inventory" {
  let p = problem([demand("a", "wood", 4, 3), demand("b", "steel", 3, 1)], [
    stock("short", "wood", 5, 2, 1),
    stock("long", "wood", 10, 5, -1),
    stock("metal", "steel", 4, 1, 1),
  ]).unwrap()
  let plan = greedy(p).unwrap()
  assert_true(audit(p, plan) is Ok(_))
  assert_eq(demand_output(p, plan).unwrap(), [3, 1])
  assert_true(stock_usage(p, plan).unwrap()[0] <= 1)
  assert_true(
    greedy(problem([demand("a", "missing", 1, 1)], p.stocks()).unwrap()) is None,
  )
}
