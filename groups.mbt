///|
pub(all) struct PatternGroup {
  stock_id : String
  counts : Array[Int]
  repetitions : Int
  remaining_each : Int
} derive(Debug)

///|
pub extend PatternGroup with @debug.Debug::{to_repr}

///|
/// A compact shop-floor bill of cutting patterns, in first-use order.
pub fn group_patterns(p : Problem, plan : Plan) -> Result[Array[PatternGroup], String] {
  match audit(p, plan) { Err(e) => return Err(e); Ok(_) => () }
  let result : Array[PatternGroup] = []
  for a in plan.bars {
    let id = p.stocks[a.stock].id
    let mut found = -1
    for i, g in result {
      if g.stock_id == id && g.counts == a.counts { found = i; break }
    }
    if found >= 0 {
      let g = result[found]
      result[found] = { ..g, repetitions: g.repetitions + 1 }
    } else {
      result.push({ stock_id: id, counts: a.counts.copy(), repetitions: 1, remaining_each: a.remaining })
    }
  }
  Ok(result)
}

///|
/// Read a compact pattern bill; the independent audit still requires exact fulfillment.
pub fn expand_groups(p : Problem, groups : Array[PatternGroup]) -> Result[Plan, String] {
  if groups.length() > 128 { return Err("too many pattern groups") }
  let bars : Array[Pattern] = []
  for g in groups {
    if g.repetitions < 1 || g.repetitions > 128 || bars.length() + g.repetitions > 128 {
      return Err("pattern repetitions outside plan bound")
    }
    let mut si = -1
    for i, s in p.stocks { if s.id == g.stock_id { si = i; break } }
    let a = match pattern(p, si, g.counts) { Err(e) => return Err(e); Ok(v) => v }
    if a.remaining != g.remaining_each { return Err("group remaining length mismatch") }
    for _ in 0..<g.repetitions { bars.push(copy_pattern(a)) }
  }
  plan_from_patterns(p, bars)
}
