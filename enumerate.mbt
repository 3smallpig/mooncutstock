///|
pub struct PatternSet {
  entries : Array[Pattern]
  complete : Bool
  visited : Int32
} derive(Debug)

///|
pub extend PatternSet with @debug.Debug::{to_repr}

///|
priv struct Enumeration {
  entries : Array[Pattern]
  limit : Int32
  mut visited : Int32
  mut complete : Bool
}

///|
fn enumerate_counts(
  p : Problem,
  si : Int32,
  at : Int32,
  capacity : Int32,
  counts : Array[Int32],
  pieces : Int32,
  e : Enumeration,
) -> Unit {
  if !e.complete {
    return
  }
  if e.visited >= e.limit {
    e.complete = false
    return
  }
  e.visited += 1
  if at == p.demands.length() {
    if pieces > 0 {
      match pattern(p, si, counts) {
        Ok(a) => e.entries.push(a)
        Err(_) => ()
      }
    }
    return
  }
  let d = p.demands[at]
  let max_count = if d.material == p.stocks[si].material {
    d.quantity.min(capacity / (d.length + p.kerf))
  } else {
    0
  }
  for n in 0..<=max_count {
    counts[at] = n
    enumerate_counts(
      p,
      si,
      at + 1,
      capacity - n * (d.length + p.kerf),
      counts,
      pieces + n,
      e,
    )
    if !e.complete {
      break
    }
  }
  counts[at] = 0
}

///|
/// Enumerates all nonempty feasible demand-count patterns, unless the visit budget ends.
pub fn enumerate_patterns(
  p : Problem,
  visit_limit~ : Int32 = 50000,
) -> Result[PatternSet, String] {
  if visit_limit < 1 || visit_limit > 1000000 {
    return Err("enumeration visit budget must be 1..1000000")
  }
  let e = Enumeration::{
    entries: [],
    limit: visit_limit,
    visited: 0,
    complete: true,
  }
  for si, s in p.stocks {
    if s.quantity != 0 {
      let counts = Array::make(p.demands.length(), 0)
      enumerate_counts(
        p,
        si,
        0,
        s.length - s.trim_start - s.trim_end,
        counts,
        0,
        e,
      )
    }
    if !e.complete {
      break
    }
  }
  Ok({ entries: e.entries, complete: e.complete, visited: e.visited, })
}

///|
pub fn PatternSet::patterns(self : PatternSet) -> Array[Pattern] {
  self.entries.map(copy_pattern)
}

///|
pub fn PatternSet::complete(self : PatternSet) -> Bool {
  self.complete
}

///|
pub fn PatternSet::visited(self : PatternSet) -> Int32 {
  self.visited
}
