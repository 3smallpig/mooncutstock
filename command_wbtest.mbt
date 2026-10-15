///|
test "pure command host runs solve normalize audit and option failures" {
  let p = problem([demand("a", "m", 3, 2)], [stock("s", "m", 6, 2, -1)]).unwrap()
  let text = encode_problem(p)
  assert_true(run_command("solve-json", text).unwrap().contains("optimal"))
  assert_true(run_command("solve-json", text, args=["--format=text"]).unwrap().contains("cost: 2"))
  assert_eq(decode_problem(run_command("normalize-json", text).unwrap()).unwrap().demands(), p.demands())
  assert_true(run_command("solve-csv", encode_csv(p)).unwrap().contains("optimal"))
  for args in [["--nodes=0"], ["--nodes=1", "--nodes=2"], ["--bad=1"], ["--kerf=1"], ["--format=xml"]] {
    assert_true(run_command("solve-json", text, args~) is Err(_))
  }
  assert_true(run_command("oops", text) is Err(_))
  assert_true(run_command("help", "").unwrap().contains("Commands:"))
  let plan = solve(p).unwrap().plan().unwrap()
  let bundle = "{\"problem\":" + text + ",\"plan\":" + encode_plan(p, plan).unwrap() + "}"
  assert_true(run_command("audit-json", bundle).unwrap().contains("\"cost\":2"))
}
