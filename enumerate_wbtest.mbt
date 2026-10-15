///|
test "bounded count-vector enumeration" {
  let p = problem([demand("a", "m", 2, 2), demand("b", "m", 3, 1)], [stock("s", "m", 5, 1, -1)]).unwrap()
  let all = enumerate_patterns(p).unwrap()
  assert_true(all.complete())
  assert_eq(all.patterns().length(), 4)
  for a in all.patterns() { assert_true(pattern(p, a.stock_index(), a.counts()) is Ok(_)) }
  let short = enumerate_patterns(p, visit_limit=1).unwrap()
  assert_false(short.complete())
  assert_eq(short.visited(), 1)
  assert_true(enumerate_patterns(p, visit_limit=0) is Err(_))
}
