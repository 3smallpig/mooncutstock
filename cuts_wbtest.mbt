///|
test "cut coordinates preserve trims kerf and ordinal numbering" {
  let p = problem([demand("a", "w", 3, 2)], [stock("s", "w", 12, 1, -1, trim_start=2, trim_end=1)], kerf=1).unwrap()
  let plan = solve(p).unwrap().plan().unwrap()
  let maps = cutting_map(p, plan).unwrap()
  assert_true(verify_cutting_map(p, plan, maps))
  assert_eq(maps[0].cuts[0].start, 2)
  assert_eq(maps[0].cuts[0].end, 5)
  assert_eq(maps[0].cuts[1].start, 6)
  assert_eq(maps[0].cuts[1].kerf_end, 10)
  assert_eq(maps[0].remnant_end, 11)
  assert_eq(maps[0].cuts[1].ordinal, 2)
  maps[0].cuts[0] = { demand_id: "a", ordinal: 1, start: 0, end: 3, kerf_end: 4 }
  assert_false(verify_cutting_map(p, plan, maps))
}
