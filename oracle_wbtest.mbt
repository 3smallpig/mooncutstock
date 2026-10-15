///|
priv struct Oracle {
  p : Problem
  pieces : Array[Int]
  bins : Array[Int]
  loads : Array[Int]
  usage : Array[Int]
  mut best : (Int, Int, Int)?
}

///|
// Independent piece-to-bin exhaustive search. No cutting patterns, price bounds,
// greedy seed or solver memo tables are used by this oracle.
fn oracle_visit(o : Oracle, at : Int, cost : Int, length : Int) -> Unit {
  if at == o.pieces.length() {
    let value = (cost, length, o.bins.length())
    match o.best {
      None => o.best = Some(value)
      Some(old) =>
        if value.0 < old.0 ||
          (value.0 == old.0 && value.1 < old.1) ||
          (value.0 == old.0 && value.1 == old.1 && value.2 < old.2) {
          o.best = Some(value)
        }
    }
    return
  }
  let d = o.p.demands[o.pieces[at]]
  let width = d.length + o.p.kerf
  let existing = o.bins.length()
  for bi in 0..<existing {
    let stock = o.p.stocks[o.bins[bi]]
    if stock.material == d.material &&
      o.loads[bi] + width <= stock.length - stock.trim_end {
      o.loads[bi] += width
      oracle_visit(o, at + 1, cost, length)
      o.loads[bi] -= width
    }
  }
  for si, stock in o.p.stocks {
    if stock.material != d.material ||
      (stock.quantity >= 0 && o.usage[si] >= stock.quantity) ||
      width > stock.length - stock.trim_start - stock.trim_end {
      continue
    }
    o.bins.push(si)
    o.loads.push(stock.trim_start + width)
    o.usage[si] += 1
    oracle_visit(o, at + 1, cost + stock.cost, length + stock.length)
    o.usage[si] -= 1
    ignore(o.loads.pop())
    ignore(o.bins.pop())
  }
}

///|
fn oracle(p : Problem) -> (Int, Int, Int)? {
  let pieces : Array[Int] = []
  for i, d in p.demands {
    for _ in 0..<d.quantity {
      pieces.push(i)
    }
  }
  let o = Oracle::{
    p,
    pieces,
    bins: [],
    loads: [],
    usage: Array::make(p.stocks.length(), 0),
    best: None,
  }
  oracle_visit(o, 0, 0, 0)
  o.best
}

///|
test "160 heterogeneous cases agree with independent piece assignment oracle" {
  for seed in 0..<160 {
    let ds = [
      demand("a", "m", 1 + seed % 6, seed % 3 + 1),
      demand(
        "b",
        if seed % 5 == 0 {
          "n"
        } else {
          "m"
        },
        1 + seed * 3 % 7,
        seed / 3 % 3 + 1,
      ),
    ]
    let ss = [
      stock(
        "short",
        "m",
        6 + seed % 5,
        seed % 7,
        seed / 7 % 4 - 1,
        trim_start=seed % 2,
      ),
      stock(
        "long",
        if seed % 5 == 0 {
          "n"
        } else {
          "m"
        },
        9 + seed % 6,
        1 + seed * 5 % 9,
        -1,
        trim_end=seed / 2 % 2,
      ),
    ]
    let p = problem(ds, ss, kerf=seed % 3, min_remnant=2).unwrap()
    let expected = oracle(p)
    let result = solve(p).unwrap()
    match expected {
      None => assert_eq(result.status(), Infeasible)
      Some((cost, length, bars)) => {
        assert_eq(result.status(), Optimal)
        let t = audit(p, result.plan().unwrap()).unwrap()
        assert_eq((t.cost, t.purchased, t.bars), (cost, length, bars))
        assert_true(lower_bound(p).cost <= cost)
        let maps = cutting_map(p, result.plan().unwrap()).unwrap()
        assert_true(verify_cutting_map(p, result.plan().unwrap(), maps))
      }
    }
  }
}

///|
test "empty and zero-demand instances require no purchases" {
  for
    p in [
      problem([], []).unwrap(),
      problem([demand("a", "m", 2, 0)], []).unwrap(),
    ] {
    let r = solve(p).unwrap()
    assert_eq(r.status(), Optimal)
    assert_eq(audit(p, r.plan().unwrap()).unwrap().cost, 0)
  }
}
