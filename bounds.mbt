///|
pub(all) struct Bound {
  cost : Int
  bars : Int
  possible : Bool
} derive(Debug, Eq)

///|
pub extend Bound with @debug.Debug::{to_repr}

///|
pub extend Bound with Eq::{equal, not_equal}

///|
fn ceil_ratio(numerator : Int64, denominator : Int64) -> Int {
  ((numerator + denominator - 1L) / denominator).to_int()
}

///|
fn residual_bound(
  p : Problem,
  remaining : Array[Int],
  inventory : Array[Int],
) -> Bound {
  // Each positive residual piece must fit some still available matching stock.
  // This also bounds the rational cost below 128 * maximum stock price.
  for i, d in p.demands {
    if remaining[i] == 0 {
      continue
    }
    let mut fits = false
    for si, s in p.stocks {
      if s.material == d.material &&
        inventory[si] != 0 &&
        s.length - s.trim_start - s.trim_end >= d.length + p.kerf {
        fits = true
        break
      }
    }
    if !fits {
      return { cost: 0, bars: 0, possible: false, }
    }
  }
  let mut cost = 0
  let mut bars = 0
  for i, d in p.demands {
    let mut seen = false
    for j in 0..<i {
      if p.demands[j].material == d.material {
        seen = true
        break
      }
    }
    if seen {
      continue
    }
    let mut required = 0
    for j, other in p.demands {
      if other.material == d.material {
        required += remaining[j] * (other.length + p.kerf)
      }
    }
    if required == 0 {
      continue
    }
    let mut best_cost = 0
    let mut best_capacity = 0
    let mut max_capacity = 0
    let mut available = 0L
    let mut unlimited = false
    for si, s in p.stocks {
      let capacity = s.length - s.trim_start - s.trim_end
      if s.material != d.material || inventory[si] == 0 || capacity == 0 {
        continue
      }
      max_capacity = max_capacity.max(capacity)
      if inventory[si] < 0 {
        unlimited = true
      } else {
        available += inventory[si].to_int64() * capacity.to_int64()
      }
      if best_capacity == 0 ||
        s.cost.to_int64() * best_capacity.to_int64() <
        best_cost.to_int64() * capacity.to_int64() {
        best_cost = s.cost
        best_capacity = capacity
      }
    }
    if max_capacity == 0 || (!unlimited && available < required.to_int64()) {
      return { cost, bars, possible: false, }
    }
    cost += ceil_ratio(
      required.to_int64() * best_cost.to_int64(),
      best_capacity.to_int64(),
    )
    bars += ceil_ratio(required.to_int64(), max_capacity.to_int64())
  }
  { cost, bars, possible: true, }
}

///|
/// Necessary volume/rational-price bounds, not a promise that a feasible plan exists.
pub fn lower_bound(p : Problem) -> Bound {
  residual_bound(
    p,
    p.demands.map(d => d.quantity),
    p.stocks.map(s => s.quantity),
  )
}
