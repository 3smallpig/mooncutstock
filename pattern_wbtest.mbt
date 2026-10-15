///|
test "pattern geometry, kerf and material" {
  let p = problem(
    [demand("a", "oak", 3, 2)],
    [stock("s", "oak", 10, 2, -1, trim_start=1, trim_end=1)],
    kerf=1,
  ).unwrap()
  let v = [2]
  let a = pattern(p, 0, v).unwrap()
  v[0] = 0
  assert_eq(a.used(), 10)
  assert_eq(a.remaining(), 0)
  assert_eq(a.pieces(), 2)
  assert_true(pattern(p, 0, [0]) is Err(_))
  assert_true(pattern(p, 0, [3]) is Err(_))
  assert_true(pattern(p, -1, [1]) is Err(_))
  let q = problem([demand("a", "steel", 3, 1)], p.stocks()).unwrap()
  assert_true(pattern(q, 0, [1]) is Err(_))
}
