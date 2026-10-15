///|
fn state_key(remaining : Array[Int32], inventory : Array[Int32]) -> String {
  let b = StringBuilder()
  for n in remaining {
    b.write_string(n.to_string())
    b.write_string(",")
  }
  b.write_string("|")
  for n in inventory {
    b.write_string(n.to_string())
    b.write_string(",")
  }
  b.to_string()
}

///|
fn objective_le(a : (Int32, Int32, Int32), b : (Int32, Int32, Int32)) -> Bool {
  a.0 < b.0 ||
  (a.0 == b.0 && a.1 < b.1) ||
  (a.0 == b.0 && a.1 == b.1 && a.2 <= b.2)
}

///|
fn index_patterns(
  p : Problem,
  patterns : Array[Pattern],
) -> Array[Array[Pattern]] {
  let result = Array::makei(p.demands.length(), _ => [])
  for a in patterns {
    for i, count in a.counts {
      if count > 0 {
        result[i].push(a)
      }
    }
  }
  for entries in result {
    entries.sort_by((a, b) => {
      let sa = p.stocks[a.stock]
      let sb = p.stocks[b.stock]
      let left = sa.cost.to_int64() * pattern_useful(p, b).to_int64()
      let right = sb.cost.to_int64() * pattern_useful(p, a).to_int64()
      if left != right {
        left.compare(right)
      } else if a.remaining != b.remaining {
        a.remaining.compare(b.remaining)
      } else {
        a.stock.compare(b.stock)
      }
    })
  }
  result
}
