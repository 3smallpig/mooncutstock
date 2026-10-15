///|
test "foreign plans reject rather than indexing outside problem arrays" {
  let p = problem([demand("a", "m", 2, 1)], [stock("s", "m", 5, 1, 1)]).unwrap()
  let plan = plan_from_patterns(p, [pattern(p, 0, [1]).unwrap()]).unwrap()
  let empty = problem([], []).unwrap()
  assert_true(stock_usage(empty, plan) is Err(_))
  assert_true(demand_output(empty, plan) is Err(_))
  assert_eq(stock_usage(p, plan).unwrap(), [1])
}

///|
test "large impossible kerf does not overflow rational cost bound" {
  let p = problem([demand("a", "m", 1000000, 128)], [stock("s", "m", 1, 1000000, -1)], kerf=1000000).unwrap()
  assert_false(lower_bound(p).possible)
  assert_eq(solve(p).unwrap().status(), Infeasible)
}

///|
test "report labels reject controls and allow Unicode" {
  assert_true(problem([demand("bad\nlabel", "m", 1, 1)], []) is Err(_))
  assert_true(problem([], [stock("bad\u001b", "m", 2, 1, 1)]) is Err(_))
  assert_true(problem([demand("横梁", "木材", 1, 1)], []) is Ok(_))
}

