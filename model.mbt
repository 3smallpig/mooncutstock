///|
/// Integer units are caller-defined and must be consistent throughout a problem.
pub(all) struct Demand {
  id : String
  material : String
  length : Int
  quantity : Int
} derive(Debug, Eq)

///|
/// quantity=-1 means unlimited; all other inventory quantities are nonnegative.
pub(all) struct Stock {
  id : String
  material : String
  length : Int
  cost : Int
  quantity : Int
  trim_start : Int
  trim_end : Int
} derive(Debug, Eq)

///|
/// A validated owned snapshot. No mutable array is exposed to consumers.
pub struct Problem {
  demands : Array[Demand]
  stocks : Array[Stock]
  kerf : Int
  min_remnant : Int
} derive(Debug)

///|
pub struct Pattern {
  stock : Int
  counts : Array[Int]
  used : Int
  remaining : Int
} derive(Debug)

///|
pub struct Plan {
  bars : Array[Pattern]
} derive(Debug)

///|
pub(all) enum Status {
  Optimal
  FeasibleBudget
  Infeasible
  UnknownBudget
} derive(Debug, Eq)

///|
pub(all) struct Limits {
  patterns : Int
  nodes : Int
} derive(Debug, Eq)

///|
pub fn default_limits() -> Limits {
  { patterns: 50000, nodes: 200000 }
}

///|
pub fn demand(id : String, material : String, length : Int, quantity : Int) -> Demand {
  { id, material, length, quantity }
}

///|
pub fn stock(id : String, material : String, length : Int, cost : Int, quantity : Int,
  trim_start~ : Int = 0, trim_end~ : Int = 0) -> Stock {
  { id, material, length, cost, quantity, trim_start, trim_end }
}
