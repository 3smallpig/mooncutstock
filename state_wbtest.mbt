///|
test "state key includes finite inventory and lexicographic dominance" {
  assert_false(state_key([1, 2], [1, -1]) == state_key([1, 2], [0, -1]))
  assert_true(objective_le((1, 100, 2), (2, 1, 1)))
  assert_true(objective_le((1, 10, 2), (1, 11, 1)))
  assert_false(objective_le((1, 10, 3), (1, 10, 2)))
  let p = problem([demand("a", "m", 2, 3), demand("b", "m", 3, 3)], [stock("s", "m", 6, 1, -1)]).unwrap()
  let r = solve(p).unwrap()
  assert_eq(r.status(), Optimal)
  assert_eq(audit(p, r.plan().unwrap()).unwrap().cost, 3)
}
