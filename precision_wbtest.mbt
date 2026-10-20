///|
test "JSON decimals are checked exactly before floating conversion" {
  let prefix = "{\"schema\":\"mooncutstock.problem/1\",\"demands\":[],\"stocks\":[],\"kerf\":"
  let suffix = ",\"min_remnant\":1}"
  for
    bad in [
      "1.0000000000000001", "0.99999999999999999", "1e-400", "-1e-400", "1000000.00000000001",
      "0.000000000000000000001",
    ] {
    assert_true(decode_problem(prefix + bad + suffix) is Err(_))
    assert_true(run_command("normalize-json", prefix + bad + suffix) is Err(_))
  }
  for
    (number, expected) in [
      ("1.0", 1),
      ("100e-2", 1),
      ("0.0100e2", 1),
      ("1e6", 1000000),
      ("-0.0", 0),
      ("0e9999999999999999999999999999999", 0),
      ("0e-9999999999999999999999999999999", 0),
    ] {
    assert_eq(
      decode_problem(prefix + number + suffix).unwrap().kerf(),
      expected,
    )
  }
  for bad in ["01", "1.", "+1", "1e", "--1", "1e+", "NaN", "1e100000"] {
    assert_true(decode_problem(prefix + bad + suffix) is Err(_))
  }
}

///|
test "plan totals cannot hide fractional values through Double equality" {
  let p = problem([demand("a1e-400\\\"木", "m", 1, 1)], [
    stock("s", "m", 10, 1, -1),
  ]).unwrap()
  let text = encode_plan(p, solve(p).unwrap().plan().unwrap()).unwrap()
  assert_true(
    decode_plan(
      p,
      text.replace(old="\"cost\":1", new="\"cost\":1.0000000000000001"),
    )
    is Err(_),
  )
  assert_true(
    decode_plan(
      p,
      text.replace(old="\"kerf_loss\":0", new="\"kerf_loss\":1e-400"),
    )
    is Err(_),
  )
  assert_eq(decode_problem(encode_problem(p)).unwrap().demands(), p.demands())
}
