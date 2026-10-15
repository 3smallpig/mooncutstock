///|
/// Each output piece consumes its length plus one kerf, including the final piece.
pub fn pattern(p : Problem, stock_index : Int, counts : Array[Int]) -> Result[Pattern, String] {
  if stock_index < 0 || stock_index >= p.stocks.length() || counts.length() != p.demands.length() {
    return Err("pattern stock index or count-vector dimension invalid")
  }
  let s = p.stocks[stock_index]
  let mut used = s.trim_start + s.trim_end
  let mut pieces = 0
  for i, count in counts {
    let d = p.demands[i]
    if count < 0 || count > d.quantity { return Err("pattern count exceeds demand") }
    if count > 0 && d.material != s.material { return Err("pattern material mismatch") }
    pieces += count
    used += count * (d.length + p.kerf)
  }
  if pieces == 0 { return Err("empty patterns are not cutting operations") }
  if used > s.length { return Err("pattern exceeds usable stock length") }
  Ok({ stock: stock_index, counts: counts.copy(), used, remaining: s.length - used })
}

///|
fn copy_pattern(p : Pattern) -> Pattern {
  { stock: p.stock, counts: p.counts.copy(), used: p.used, remaining: p.remaining }
}

///|
pub fn Pattern::stock_index(self : Pattern) -> Int { self.stock }

///|
pub fn Pattern::counts(self : Pattern) -> Array[Int] { self.counts.copy() }

///|
pub fn Pattern::used(self : Pattern) -> Int { self.used }

///|
pub fn Pattern::remaining(self : Pattern) -> Int { self.remaining }

///|
pub fn Pattern::pieces(self : Pattern) -> Int {
  let mut n = 0
  for count in self.counts { n += count }
  n
}

///|
pub fn empty_plan() -> Plan { { bars: [] } }

///|
pub fn Plan::bars(self : Plan) -> Array[Pattern] { self.bars.map(copy_pattern) }

///|
pub fn Plan::bar_count(self : Plan) -> Int { self.bars.length() }
