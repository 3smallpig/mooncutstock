///|
pub(all) struct Remnant {
  source_bar : Int
  source_stock : String
  material : String
  length : Int
  start : Int
  end : Int
} derive(Debug, Eq)

///|
pub extend Remnant with @debug.Debug::{to_repr}

///|
pub extend Remnant with Eq::{equal, not_equal}

///|
pub fn remnants(p : Problem, plan : Plan) -> Result[Array[Remnant], String] {
  let maps = match cutting_map(p, plan) { Err(e) => return Err(e); Ok(m) => m }
  let result : Array[Remnant] = []
  for i, m in maps {
    if m.reusable {
      result.push({ source_bar: i, source_stock: m.stock_id,
        material: p.stocks[plan.bars[i].stock].material,
        length: m.remnant_end - m.remnant_start, start: m.remnant_start, end: m.remnant_end })
    }
  }
  Ok(result)
}

///|
/// Aggregate equivalent remnants as zero-purchase-cost inventory with no inherited trims.
/// Caller chooses whether and how handling/requalification costs should be added.
pub fn remnant_stocks(p : Problem, plan : Plan) -> Result[Array[Stock], String] {
  let entries = match remnants(p, plan) { Err(e) => return Err(e); Ok(v) => v }
  let result : Array[Stock] = []
  for r in entries {
    let mut existing = -1
    for i, s in result {
      if s.material == r.material && s.length == r.length { existing = i; break }
    }
    if existing >= 0 {
      let s = result[existing]
      result[existing] = { ..s, quantity: s.quantity + 1 }
    } else {
      result.push(stock("remnant-" + result.length().to_string(), r.material, r.length, 0, 1))
    }
  }
  Ok(result)
}

///|
/// Inventory transition is local data only; it never modifies the input problem.
/// Fails rather than silently dropping stock types if the next problem exceeds bounds.
pub fn rollover(p : Problem, plan : Plan, next_demands : Array[Demand],
  keep_inventory~ : Bool = true) -> Result[Problem, String] {
  match audit(p, plan) { Err(e) => return Err(e); Ok(_) => () }
  let result : Array[Stock] = []
  let usage = stock_usage(p, plan)
  if keep_inventory {
    for i, s in p.stocks {
      let quantity = if s.quantity < 0 { -1 } else { s.quantity - usage[i] }
      if quantity != 0 { result.push({ ..s, quantity }) }
    }
  }
  let recovered = match remnant_stocks(p, plan) { Err(e) => return Err(e); Ok(v) => v }
  for r in recovered {
    let mut id = r.id
    let mut suffix = 0
    while result.any(s => s.id == id) {
      suffix += 1
      id = r.id + "-" + suffix.to_string()
    }
    result.push({ ..r, id })
  }
  problem(next_demands, result, kerf=p.kerf, min_remnant=p.min_remnant)
}
