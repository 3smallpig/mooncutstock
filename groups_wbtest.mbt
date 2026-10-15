///|
test "pattern bills compact and expand without losing exact demand" {
  let p = problem([demand("a", "m", 3, 4)], [stock("s", "m", 6, 1, -1)]).unwrap()
  let plan = solve(p).unwrap().plan().unwrap()
  let groups = group_patterns(p, plan).unwrap()
  assert_eq(groups.length(), 1)
  assert_eq(groups[0].repetitions, 2)
  assert_eq(audit(p, expand_groups(p, groups).unwrap()), audit(p, plan))
  groups[0].counts[0] = 0
  assert_true(expand_groups(p, groups) is Err(_))
}
