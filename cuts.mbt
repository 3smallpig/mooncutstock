///|
pub(all) struct Cut {
  demand_id : String
  ordinal : Int32
  start : Int32
  end : Int32
  kerf_end : Int32
} derive(Debug, Eq)

///|
pub extend Cut with @debug.Debug::{to_repr}

///|
pub extend Cut with Eq::{equal, not_equal}

///|
pub(all) struct BarMap {
  bar : Int32
  stock_id : String
  usable_start : Int32
  usable_end : Int32
  cuts : Array[Cut]
  remnant_start : Int32
  remnant_end : Int32
  reusable : Bool
} derive(Debug)

///|
pub extend BarMap with @debug.Debug::{to_repr}

///|
/// Half-open coordinates, in demand input order, with a kerf after every cut.
pub fn cutting_map(p : Problem, plan : Plan) -> Result[Array[BarMap], String] {
  match audit(p, plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let result : Array[BarMap] = []
  let ordinals = Array::make(p.demands.length(), 0)
  for bi, a in plan.bars {
    let s = p.stocks[a.stock]
    let mut cursor = s.trim_start
    let cuts : Array[Cut] = []
    for di, n in a.counts {
      for _ in 0..<n {
        ordinals[di] += 1
        let end = cursor + p.demands[di].length
        cuts.push({
          demand_id: p.demands[di].id,
          ordinal: ordinals[di],
          start: cursor,
          end,
          kerf_end: end + p.kerf,
        })
        cursor = end + p.kerf
      }
    }
    result.push({
      bar: bi,
      stock_id: s.id,
      usable_start: s.trim_start,
      usable_end: s.length - s.trim_end,
      cuts,
      remnant_start: cursor,
      remnant_end: s.length - s.trim_end,
      reusable: a.remaining >= p.min_remnant,
    })
  }
  Ok(result)
}

///|
/// Verify exported coordinates without trusting the planner's interval arithmetic.
pub fn verify_cutting_map(
  p : Problem,
  plan : Plan,
  maps : Array[BarMap],
) -> Bool {
  let expected = match cutting_map(p, plan) {
    Err(_) => return false
    Ok(v) => v
  }
  if maps.length() != expected.length() {
    return false
  }
  for i, a in maps {
    let e = expected[i]
    if a.bar != e.bar ||
      a.stock_id != e.stock_id ||
      a.usable_start != e.usable_start ||
      a.usable_end != e.usable_end ||
      a.cuts != e.cuts ||
      a.remnant_start != e.remnant_start ||
      a.remnant_end != e.remnant_end ||
      a.reusable != e.reusable {
      return false
    }
  }
  true
}
