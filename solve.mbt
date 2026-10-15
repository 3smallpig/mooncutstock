///|
pub struct Solution {
  source : Problem
  status : Status
  plan : Plan?
  pattern_complete : Bool
  search_complete : Bool
  pattern_visits : Int
  pattern_count : Int
  work : Int
  pruned : Int
} derive(Debug)

///|
pub extend Solution with @debug.Debug::{to_repr}

///|
priv struct Search {
  p : Problem
  patterns : Array[Array[Pattern]]
  memo : Map[String, (Int, Int, Int)]
  mut pruned : Int
  remaining : Array[Int]
  inventory : Array[Int]
  path : Array[Pattern]
  limit : Int
  mut work : Int
  mut complete : Bool
  mut best : Plan?
  mut best_cost : Int
  mut best_length : Int
  mut best_bars : Int
}

///|
fn better_objective(cost : Int, length : Int, bars : Int, s : Search) -> Bool {
  s.best is None ||
  cost < s.best_cost ||
  (cost == s.best_cost && length < s.best_length) ||
  (cost == s.best_cost && length == s.best_length && bars < s.best_bars)
}

///|
fn search_visit(s : Search, cost : Int, length : Int) -> Unit {
  if !s.complete {
    return
  }
  if s.work >= s.limit {
    s.complete = false
    return
  }
  s.work += 1
  let mut first = -1
  for i, n in s.remaining {
    if n > 0 {
      first = i
      break
    }
  }
  if first < 0 {
    if better_objective(cost, length, s.path.length(), s) {
      s.best = Some(Plan::{ bars: s.path.copy(), })
      s.best_cost = cost
      s.best_length = length
      s.best_bars = s.path.length()
    }
    return
  }
  let bound = residual_bound(s.p, s.remaining, s.inventory)
  if !bound.possible {
    return
  }
  if s.best is Some(_) && cost + bound.cost > s.best_cost {
    return
  }
  let key = state_key(s.remaining, s.inventory)
  let objective = (cost, length, s.path.length())
  match s.memo.get(key) {
    Some(previous) =>
      if objective_le(previous, objective) {
        s.pruned += 1
        return
      }
    None => ()
  }
  if s.memo.length() < 50000 {
    s.memo[key] = objective
  }
  for a in s.patterns[first] {
    if s.work >= s.limit {
      s.complete = false
      return
    }
    s.work += 1
    if a.counts[first] == 0 || s.inventory[a.stock] == 0 {
      continue
    }
    let mut fits = true
    for i, n in a.counts {
      if n > s.remaining[i] {
        fits = false
        break
      }
    }
    if !fits {
      continue
    }
    let stock = s.p.stocks[a.stock]
    let next_cost = cost + stock.cost
    if s.best is Some(_) && next_cost > s.best_cost {
      continue
    }
    for i, n in a.counts {
      s.remaining[i] -= n
    }
    if s.inventory[a.stock] > 0 {
      s.inventory[a.stock] -= 1
    }
    s.path.push(a)
    search_visit(s, next_cost, length + stock.length)
    ignore(s.path.pop())
    if stock.quantity >= 0 {
      s.inventory[a.stock] += 1
    }
    for i, n in a.counts {
      s.remaining[i] += n
    }
    if !s.complete {
      return
    }
  }
}

///|
/// Minimize (purchase cost, purchased length, bar count) lexicographically.
/// A budget-limited result is never labeled Optimal or Infeasible.
pub fn solve(
  p : Problem,
  limits? : Limits = default_limits(),
) -> Result[Solution, String] {
  match validate_limits(limits) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let set = match enumerate_patterns(p, visit_limit=limits.patterns) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let seed = greedy(p)
  let totals = match seed {
    Some(plan) => Some(audit(p, plan).unwrap())
    None => None
  }
  let s = Search::{
    p,
    patterns: index_patterns(p, set.entries),
    memo: {},
    pruned: 0,
    remaining: p.demands.map(d => d.quantity),
    inventory: p.stocks.map(stock => stock.quantity),
    path: [],
    limit: limits.nodes,
    work: 0,
    complete: true,
    best: seed,
    best_cost: match totals {
      Some(t) => t.cost
      None => 0
    },
    best_length: match totals {
      Some(t) => t.purchased
      None => 0
    },
    best_bars: match totals {
      Some(t) => t.bars
      None => 0
    },
  }
  search_visit(s, 0, 0)
  let proven = set.complete && s.complete
  let status = match s.best {
    Some(_) => if proven { Optimal } else { FeasibleBudget }
    None => if proven { Infeasible } else { UnknownBudget }
  }
  Ok({
    source: p,
    status,
    plan: s.best,
    pattern_complete: set.complete,
    search_complete: s.complete,
    pattern_visits: set.visited,
    pattern_count: set.entries.length(),
    work: s.work,
    pruned: s.pruned,
  })
}

///|
pub fn Solution::status(self : Solution) -> Status {
  self.status
}

///|
pub fn Solution::plan(self : Solution) -> Plan? {
  self.plan.map(plan => Plan::{ bars: plan.bars.map(copy_pattern), })
}

///|
pub fn Solution::pattern_complete(self : Solution) -> Bool {
  self.pattern_complete
}

///|
pub fn Solution::search_complete(self : Solution) -> Bool {
  self.search_complete
}

///|
pub fn Solution::pattern_visits(self : Solution) -> Int {
  self.pattern_visits
}

///|
pub fn Solution::pattern_count(self : Solution) -> Int {
  self.pattern_count
}

///|
pub fn Solution::work(self : Solution) -> Int {
  self.work
}

///|
pub fn Solution::dominated_states(self : Solution) -> Int {
  self.pruned
}
