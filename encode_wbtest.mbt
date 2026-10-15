///|
test "problem and plan interchange round trip" {
  let p = problem([demand("comma,quote\"", "木材", 3, 2)], [stock("s", "木材", 10, 7, 1)], kerf=1).unwrap()
  let q = decode_problem(encode_problem(p)).unwrap()
  assert_eq(q.demands(), p.demands())
  assert_eq(q.stocks(), p.stocks())
  let plan = solve(q).unwrap().plan().unwrap()
  let text = encode_plan(q, plan).unwrap()
  let imported = decode_plan(q, text).unwrap()
  assert_eq(audit(q, plan), audit(q, imported))
  assert_true(decode_plan(q, text.replace(old="\"cost\":7", new="\"cost\":8")) is Err(_))
  assert_true(decode_plan(q, "{\"schema\":\"mooncutstock.plan/1\",\"bars\":[]}") is Err(_))
}
