///|
fn main raise {
  let p = @cutstock.problem([@cutstock.demand("part", "wood", 49, 4)], [
    @cutstock.stock("board", "wood", 100, 10, -1),
  ]).unwrap()
  let cases = @cutstock.kerf_scenarios(p, [0, 1, 2]).unwrap()
  assert_eq(cases[0].cost, Some(20))
  assert_eq(cases[2].cost, Some(40))
  for item in cases {
    println(
      "kerf=" +
      item.kerf.to_string() +
      " status=" +
      @cutstock.status_name(item.status),
    )
  }
  let scarce = @cutstock.with_inventory(p, [1]).unwrap()
  assert_eq(@cutstock.solve(scarce).unwrap().status(), @cutstock.Infeasible)
  let budgeted = @cutstock.solve(p, limits={ patterns: 1, nodes: 1, }).unwrap()
  assert_false(budgeted.status() == @cutstock.Optimal)
  println(@cutstock.text_report(p, budgeted).unwrap())
}
