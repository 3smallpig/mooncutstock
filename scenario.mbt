///|
pub fn with_costs(p : Problem, costs : Array[Int]) -> Result[Problem, String] {
  if costs.length() != p.stocks.length() { return Err("cost vector dimension mismatch") }
  let stocks = p.stocks.mapi((i, s) => Stock::{ ..s, cost: costs[i] })
  problem(p.demands, stocks, kerf=p.kerf, min_remnant=p.min_remnant)
}

///|
pub fn with_inventory(p : Problem, quantities : Array[Int]) -> Result[Problem, String] {
  if quantities.length() != p.stocks.length() { return Err("inventory vector dimension mismatch") }
  let stocks = p.stocks.mapi((i, s) => Stock::{ ..s, quantity: quantities[i] })
  problem(p.demands, stocks, kerf=p.kerf, min_remnant=p.min_remnant)
}

///|
pub fn with_kerf(p : Problem, kerf : Int) -> Result[Problem, String] {
  problem(p.demands, p.stocks, kerf~, min_remnant=p.min_remnant)
}

///|
pub(all) struct Comparison {
  cost_delta : Int
  purchased_delta : Int
  bars_delta : Int
  ordering : Int
} derive(Debug, Eq)

///|
pub extend Comparison with @debug.Debug::{to_repr}

///|
pub extend Comparison with Eq::{equal, not_equal}

///|
/// Negative deltas mean the candidate improves on the baseline, for the same problem.
pub fn compare_plans(p : Problem, baseline : Plan, candidate : Plan) -> Result[Comparison, String] {
  let a = match audit(p, baseline) { Err(e) => return Err(e); Ok(t) => t }
  let b = match audit(p, candidate) { Err(e) => return Err(e); Ok(t) => t }
  let ordering = if b.cost != a.cost { b.cost.compare(a.cost) }
    else if b.purchased != a.purchased { b.purchased.compare(a.purchased) }
    else { b.bars.compare(a.bars) }
  Ok({ cost_delta: b.cost - a.cost, purchased_delta: b.purchased - a.purchased,
    bars_delta: b.bars - a.bars, ordering })
}

///|
pub(all) struct KerfScenario {
  kerf : Int
  status : Status
  cost : Int?
  purchased : Int?
  search_work : Int
} derive(Debug)

///|
pub extend KerfScenario with @debug.Debug::{to_repr}

///|
/// Each scenario uses an independent bounded solve; at most 16 scenarios per call.
pub fn kerf_scenarios(p : Problem, kerfs : Array[Int],
  limits~ : Limits = default_limits()) -> Result[Array[KerfScenario], String] {
  if kerfs.length() > 16 { return Err("at most 16 kerf scenarios") }
  match validate_limits(limits) { Err(e) => return Err(e); Ok(_) => () }
  // Validate the complete batch before spending any solver budget.
  for kerf in kerfs { if kerf < 0 || kerf > 1000000 { return Err("invalid kerf scenario") } }
  let result : Array[KerfScenario] = []
  for kerf in kerfs {
    let q = with_kerf(p, kerf).unwrap()
    let s = solve(q, limits~).unwrap()
    let t = s.plan.map(plan => audit(q, plan).unwrap())
    result.push({ kerf, status: s.status, cost: t.map(t => t.cost),
      purchased: t.map(t => t.purchased), search_work: s.work })
  }
  Ok(result)
}
