///|
test "material-separated cost and volume bounds" {
  let p = problem([demand("a", "m", 4, 3)], [stock("s", "m", 10, 5, -1)]).unwrap()
  let b = lower_bound(p)
  assert_eq(b.cost, 6)
  assert_eq(b.bars, 2)
  assert_true(b.possible)
  let q = problem(p.demands(), [stock("s", "m", 10, 5, 1)]).unwrap()
  assert_false(lower_bound(q).possible)
  assert_eq(solve(q).unwrap().status(), Infeasible)
  let free = problem(p.demands(), [stock("s", "m", 10, 0, -1)]).unwrap()
  assert_eq(lower_bound(free).cost, 0)
}
