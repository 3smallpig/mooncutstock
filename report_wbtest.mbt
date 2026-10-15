///|
test "reports bind provenance and retain explicit budget status" {
  let p = problem([demand("a", "m", 3, 2)], [stock("s", "m", 6, 2, -1)]).unwrap()
  let s = solve(p).unwrap()
  assert_true(text_report(p, s).unwrap().contains("status: optimal"))
  let json = encode_solution(p, s).unwrap()
  assert_true(json.contains("mooncutstock.solution/1"))
  let other = problem(p.demands(), [stock("s", "m", 6, 9, -1)]).unwrap()
  assert_true(encode_solution(other, s) is Err(_))
  assert_true(text_report(other, s) is Err(_))
  let limited = solve(p, limits={ patterns: 1, nodes: 1, }).unwrap()
  assert_true(encode_solution(p, limited).unwrap().contains("feasible-budget"))
}
