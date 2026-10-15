///|
test "validation bounds and duplicate identifiers" {
  assert_true(problem([demand("a", "wood", 1, 129)], []) is Err(_))
  assert_true(problem([demand("a", "wood", 0, 1)], []) is Err(_))
  assert_true(problem([demand("a", "wood", 1, 1), demand("a", "wood", 2, 1)], []) is Err(_))
  assert_true(problem([], [stock("s", "wood", 10, 1, -2)]) is Err(_))
  assert_true(problem([], [stock("s", "wood", 10, 1, 1, trim_start=8, trim_end=3)]) is Err(_))
  assert_true(validate_limits({patterns: 0, nodes: 1}) is Err(_))
}

///|
test "owned input and accessor arrays" {
  let ds = [demand("a", "wood", 3, 2)]
  let p = problem(ds, []).unwrap()
  ds[0] = demand("b", "wood", 5, 9)
  let exposed = p.demands()
  exposed[0] = demand("c", "wood", 6, 9)
  assert_eq(p.demands()[0].id, "a")
}
