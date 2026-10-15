///|
test "conservation and inventory are independent acceptance checks" {
  let p = problem(
    [demand("a", "w", 3, 2)],
    [stock("s", "w", 10, 7, 1)],
    kerf=1,
    min_remnant=3,
  ).unwrap()
  let a = pattern(p, 0, [2]).unwrap()
  let plan = plan_from_patterns(p, [a]).unwrap()
  let t = audit(p, plan).unwrap()
  assert_eq(t.cost, 7)
  assert_eq(t.useful, 6)
  assert_eq(t.kerf_loss, 2)
  assert_eq(t.scrap, 2)
  assert_eq(t.purchased, 10)
  assert_true(plan_from_patterns(p, [pattern(p, 0, [1]).unwrap()]) is Err(_))
  assert_true(plan_from_patterns(p, [a, a]) is Err(_))
  let forged = Pattern::{ stock: 0, counts: [2], used: 7, remaining: 3, }
  assert_true(plan_from_patterns(p, [forged]) is Err(_))
}
