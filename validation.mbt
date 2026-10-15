///|
fn safe_label(value : String) -> Bool {
  value.length() > 0 && value.length() <= 128 &&
  !value.iter().any(c => c.to_int() < 32 || c.to_int() == 127)
}

///|
pub fn problem(demands : Array[Demand], stocks : Array[Stock],
  kerf~ : Int = 0, min_remnant~ : Int = 1) -> Result[Problem, String] {
  if demands.length() > 12 || stocks.length() > 16 {
    return Err("at most 12 demand types and 16 stock types")
  }
  if kerf < 0 || kerf > 1000000 || min_remnant < 1 || min_remnant > 1000000 {
    return Err("kerf must be 0..1000000; min_remnant 1..1000000")
  }
  let mut pieces = 0
  for i, d in demands {
    if !safe_label(d.id) || !safe_label(d.material) {
      return Err("demand id and material must have 1..128 code units without ASCII controls")
    }
    if d.length < 1 || d.length > 1000000 || d.quantity < 0 || d.quantity > 128 {
      return Err("demand length 1..1000000 and quantity 0..128 required")
    }
    pieces += d.quantity
    for j in 0..<i {
      if demands[j].id == d.id { return Err("duplicate demand id: " + d.id) }
    }
  }
  if pieces > 128 { return Err("at most 128 requested pieces") }
  for i, s in stocks {
    if !safe_label(s.id) || !safe_label(s.material) {
      return Err("stock id and material must have 1..128 code units without ASCII controls")
    }
    if s.length < 1 || s.length > 1000000 || s.cost < 0 || s.cost > 1000000 || s.quantity < -1 || s.quantity > 128 {
      return Err("stock length/cost/inventory outside bounded domain")
    }
    if s.trim_start < 0 || s.trim_end < 0 || s.trim_start > s.length || s.trim_end > s.length - s.trim_start {
      return Err("stock trims exceed length")
    }
    for j in 0..<i {
      if stocks[j].id == s.id { return Err("duplicate stock id: " + s.id) }
    }
  }
  Ok({ demands: demands.copy(), stocks: stocks.copy(), kerf, min_remnant })
}

///|
pub fn validate_limits(limits : Limits) -> Result[Unit, String] {
  if limits.patterns < 1 || limits.patterns > 1000000 || limits.nodes < 1 || limits.nodes > 1000000 {
    Err("pattern and search budgets must be 1..1000000")
  } else { Ok(()) }
}

///|
pub fn Problem::demands(self : Problem) -> Array[Demand] { self.demands.copy() }

///|
pub fn Problem::stocks(self : Problem) -> Array[Stock] { self.stocks.copy() }

///|
pub fn Problem::kerf(self : Problem) -> Int { self.kerf }

///|
pub fn Problem::min_remnant(self : Problem) -> Int { self.min_remnant }
