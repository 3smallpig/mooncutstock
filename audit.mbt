///|
pub(all) struct Totals {
  cost : Int
  purchased : Int
  useful : Int
  kerf_loss : Int
  trim_loss : Int
  reusable : Int
  scrap : Int
  bars : Int
  pieces : Int
} derive(Debug, Eq)

///|
pub extend Totals with @debug.Debug::{to_repr}

///|
pub extend Totals with Eq::{equal, not_equal}

///|
/// Rebuild every pattern from count vectors, independently of cached geometry.
pub fn audit(p : Problem, plan : Plan) -> Result[Totals, String] {
  if plan.bars.length() > 128 {
    return Err("plan exceeds 128 bars")
  }
  let delivered = Array::make(p.demands.length(), 0)
  let inventory = Array::make(p.stocks.length(), 0)
  let mut cost = 0
  let mut purchased = 0
  let mut useful = 0
  let mut kerf_loss = 0
  let mut trim_loss = 0
  let mut reusable = 0
  let mut scrap = 0
  let mut pieces = 0
  for bar in plan.bars {
    let rebuilt = match pattern(p, bar.stock, bar.counts) {
      Err(e) => return Err(e)
      Ok(a) => a
    }
    if rebuilt.used != bar.used || rebuilt.remaining != bar.remaining {
      return Err("cached pattern geometry is inconsistent")
    }
    let s = p.stocks[bar.stock]
    inventory[bar.stock] += 1
    if s.quantity >= 0 && inventory[bar.stock] > s.quantity {
      return Err("stock inventory exceeded: " + s.id)
    }
    cost += s.cost
    purchased += s.length
    trim_loss += s.trim_start + s.trim_end
    for i, count in bar.counts {
      delivered[i] += count
      useful += count * p.demands[i].length
      kerf_loss += count * p.kerf
      pieces += count
    }
    if bar.remaining >= p.min_remnant {
      reusable += bar.remaining
    } else {
      scrap += bar.remaining
    }
  }
  for i, d in p.demands {
    if delivered[i] != d.quantity {
      return Err("demand not fulfilled exactly: " + d.id)
    }
  }
  if purchased != useful + kerf_loss + trim_loss + reusable + scrap {
    return Err("length conservation failed")
  }
  Ok({
    cost,
    purchased,
    useful,
    kerf_loss,
    trim_loss,
    reusable,
    scrap,
    bars: plan.bars.length(),
    pieces,
  })
}

///|
/// Import a complete plan; rejects overproduction, shortages and inventory violations.
pub fn plan_from_patterns(
  p : Problem,
  bars : Array[Pattern],
) -> Result[Plan, String] {
  let plan = Plan::{ bars: bars.map(copy_pattern), }
  match audit(p, plan) {
    Err(e) => Err(e)
    Ok(_) => Ok(plan)
  }
}

///|
pub fn stock_usage(p : Problem, plan : Plan) -> Result[Array[Int], String] {
  match audit(p, plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let result = Array::make(p.stocks.length(), 0)
  for bar in plan.bars {
    result[bar.stock] += 1
  }
  Ok(result)
}

///|
pub fn demand_output(p : Problem, plan : Plan) -> Result[Array[Int], String] {
  match audit(p, plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let result = Array::make(p.demands.length(), 0)
  for bar in plan.bars {
    for i, count in bar.counts {
      result[i] += count
    }
  }
  Ok(result)
}
