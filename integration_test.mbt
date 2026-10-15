///|
test "external API solves and transports a fully audited procurement" {
  let p = @mooncutstock.problem(
    [@mooncutstock.demand("beam", "wood", 40, 4)],
    [
      @mooncutstock.stock("short", "wood", 85, 7, 1),
      @mooncutstock.stock("long", "wood", 130, 12, -1),
    ],
    kerf=2,
    min_remnant=5,
  ).unwrap()
  let restored = @mooncutstock.decode_problem(@mooncutstock.encode_problem(p)).unwrap()
  let s = @mooncutstock.solve(restored).unwrap()
  assert_eq(s.status(), @mooncutstock.Optimal)
  let plan = s.plan().unwrap()
  let text = @mooncutstock.encode_plan(p, plan).unwrap()
  let imported = @mooncutstock.decode_plan(p, text).unwrap()
  assert_eq(@mooncutstock.audit(p, imported).unwrap().cost, 19)
  assert_eq(@mooncutstock.demand_output(p, imported).unwrap(), [4])
  assert_true(@mooncutstock.encode_solution(p, s) is Ok(_))
}

///|
test "external API keeps mutable output arrays detached" {
  let p = @mooncutstock.problem([@mooncutstock.demand("a", "m", 2, 2)], [
    @mooncutstock.stock("s", "m", 5, 1, -1),
  ]).unwrap()
  let s = @mooncutstock.solve(p).unwrap()
  let plan = s.plan().unwrap()
  let bars = plan.bars()
  let counts = bars[0].counts()
  counts[0] = 99
  assert_eq(@mooncutstock.audit(p, plan).unwrap().pieces, 2)
}
