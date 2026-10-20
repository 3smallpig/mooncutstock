///|
test "resource bounds validate containers and UTF16 labels" {
  let base = encode_problem(problem([], []).unwrap())
  let pad = StringBuilder()
  for _ in 0..<(65536 - base.length()) {
    pad.write_char(' ')
  }
  let at_limit = base + pad.to_string()
  assert_eq(at_limit.length(), 65536)
  assert_true(decode_problem(at_limit) is Ok(_))
  assert_true(decode_problem(at_limit + " ") is Err(_))
  assert_true(decode_csv(at_limit + " ") is Err(_))
  assert_true(decode_problem("[[[[[[[[[0]]]]]]]]]") is Err(_))
  let labels = StringBuilder()
  for _ in 0..<64 {
    labels.write_string("😀")
  }
  let label = labels.to_string()
  assert_eq(label.length(), 128)
  assert_true(problem([demand(label, "m", 1, 0)], []) is Ok(_))
  assert_true(problem([demand(label + "a", "m", 1, 0)], []) is Err(_))
  assert_true(problem([demand("bad\u007f", "m", 1, 0)], []) is Err(_))
  let ds = Array::makei(12, i => demand("d" + i.to_string(), "m", 1, 0))
  let ss = Array::makei(16, i => stock("s" + i.to_string(), "m", 10, 1, -1))
  assert_true(problem(ds, ss) is Ok(_))
  ds.push(demand("extra", "m", 1, 0))
  assert_true(problem(ds, ss) is Err(_))
  ds.pop() |> ignore
  ss.push(stock("extra", "m", 10, 1, -1))
  assert_true(problem(ds, ss) is Err(_))
  assert_true(
    problem([demand("a", "m", 1, 128), demand("b", "m", 1, 1)], []) is Err(_),
  )
  assert_true(validate_limits({ patterns: 1000001, nodes: 1, }) is Err(_))
  assert_true(validate_limits({ patterns: 1, nodes: 1000001, }) is Err(_))
}

///|
test "rollover bound fails atomically without discarding inventory" {
  let ss = Array::makei(16, i => stock("s" + i.to_string(), "m", 10, i, -1))
  let p = problem([demand("a", "m", 1, 1)], ss).unwrap()
  let plan = plan_from_patterns(p, [pattern(p, 0, [1]).unwrap()]).unwrap()
  assert_true(rollover(p, plan, [demand("b", "m", 1, 1)]) is Err(_))
  assert_eq(p.stocks(), ss)
  assert_eq(audit(p, plan).unwrap().pieces, 1)
  assert_eq(
    rollover(p, plan, [], keep_inventory=false).unwrap().stocks().length(),
    1,
  )
}
