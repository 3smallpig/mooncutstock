///|
fn positive(values : Array[Int]) -> Bool {
  for v in values { if v > 0 { return true } }
  false
}

///|
fn demand_order(p : Problem) -> Array[Int] {
  let order = Array::makei(p.demands.length(), i => i)
  order.sort_by((a, b) => {
    let cmp = p.demands[b].length.compare(p.demands[a].length)
    if cmp == 0 { a.compare(b) } else { cmp }
  })
  order
}

///|
fn greedy_bar(p : Problem, si : Int, remaining : Array[Int], order : Array[Int]) -> Pattern? {
  let s = p.stocks[si]
  let mut capacity = s.length - s.trim_start - s.trim_end
  let counts = Array::make(p.demands.length(), 0)
  for i in order {
    let d = p.demands[i]
    if d.material == s.material {
      let n = remaining[i].min(capacity / (d.length + p.kerf))
      counts[i] = n
      capacity -= n * (d.length + p.kerf)
    }
  }
  match pattern(p, si, counts) { Ok(a) => Some(a); Err(_) => None }
}

///|
fn pattern_useful(p : Problem, a : Pattern) -> Int {
  let mut n = 0
  for i, count in a.counts { n += p.demands[i].length * count }
  n
}

///|
fn prefer_greedy(p : Problem, a : Pattern, b : Pattern) -> Bool {
  let sa = p.stocks[a.stock]
  let sb = p.stocks[b.stock]
  let left = sa.cost.to_int64() * pattern_useful(p, b).to_int64()
  let right = sb.cost.to_int64() * pattern_useful(p, a).to_int64()
  if left != right { return left < right }
  let ua = pattern_useful(p, a)
  let ub = pattern_useful(p, b)
  if ua != ub { return ua > ub }
  if a.remaining != b.remaining { return a.remaining < b.remaining }
  a.stock < b.stock
}

///|
/// A deterministic feasible incumbent, not an optimality claim. None does not prove infeasibility.
pub fn greedy(p : Problem) -> Plan? {
  let remaining = p.demands.map(d => d.quantity)
  let inventory = p.stocks.map(s => s.quantity)
  let order = demand_order(p)
  let bars : Array[Pattern] = []
  while positive(remaining) {
    let mut best : Pattern? = None
    for si in 0..<p.stocks.length() {
      if inventory[si] != 0 {
        match greedy_bar(p, si, remaining, order) {
          None => ()
          Some(a) => match best {
            None => best = Some(a)
            Some(b) => if prefer_greedy(p, a, b) { best = Some(a) }
          }
        }
      }
    }
    let a = match best { None => return None; Some(a) => a }
    for i, count in a.counts { remaining[i] -= count }
    if inventory[a.stock] > 0 { inventory[a.stock] -= 1 }
    bars.push(a)
  }
  Some(Plan::{ bars })
}

