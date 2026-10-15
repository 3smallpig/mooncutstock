///|
fn same_problem(a : Problem, b : Problem) -> Bool {
  a.demands == b.demands && a.stocks == b.stocks && a.kerf == b.kerf && a.min_remnant == b.min_remnant
}

///|
fn cut_json(c : Cut) -> Json {
  Json::object({ "demand": Json(c.demand_id), "ordinal": Json(c.ordinal),
    "start": Json(c.start), "end": Json(c.end), "kerf_end": Json(c.kerf_end) })
}

///|
fn map_json(m : BarMap) -> Json {
  Json::object({ "bar": Json(m.bar), "stock": Json(m.stock_id),
    "usable_start": Json(m.usable_start), "usable_end": Json(m.usable_end),
    "cuts": Json::array(m.cuts.map(cut_json)), "remnant_start": Json(m.remnant_start),
    "remnant_end": Json(m.remnant_end), "reusable": Json(m.reusable) })
}

///|
/// Bind optimality claims to the exact problem that was solved.
pub fn encode_solution(p : Problem, s : Solution) -> Result[String, String] {
  if !same_problem(p, s.source) { return Err("solution belongs to a different problem") }
  let fields : Map[String, Json] = {
    "schema": Json("mooncutstock.solution/1"), "status": Json(status_name(s.status)),
    "pattern_complete": Json(s.pattern_complete), "search_complete": Json(s.search_complete),
    "pattern_visits": Json(s.pattern_visits), "patterns": Json(s.pattern_count),
    "search_work": Json(s.work), "dominated_states": Json(s.pruned),
    "cost_lower_bound": Json(lower_bound(p).cost),
  }
  match s.plan {
    None => { fields["plan"] = Json::null(); fields["totals"] = Json::null(); fields["cut_maps"] = Json::array([]) }
    Some(plan) => {
      let t = match audit(p, plan) { Err(e) => return Err(e); Ok(t) => t }
      fields["plan"] = Json::array(plan.bars.map(bar_json))
      fields["totals"] = totals_json(t)
      fields["cut_maps"] = Json::array(cutting_map(p, plan).unwrap().map(map_json))
    }
  }
  Ok(Json::object(fields).stringify())
}

///|
pub fn text_report(p : Problem, s : Solution) -> Result[String, String] {
  if !same_problem(p, s.source) { return Err("solution belongs to a different problem") }
  let out = StringBuilder()
  out.write_string("status: " + status_name(s.status) + "\n")
  out.write_string("patterns: " + s.pattern_count.to_string() + "; enumeration visits: " + s.pattern_visits.to_string() + "\n")
  out.write_string("search work: " + s.work.to_string() + "; dominated states: " + s.pruned.to_string() + "\n")
  match s.plan {
    None => out.write_string("no complete feasible plan found\n")
    Some(plan) => {
      let t = match audit(p, plan) { Err(e) => return Err(e); Ok(t) => t }
      out.write_string("cost: " + t.cost.to_string() + "; bars: " + t.bars.to_string() + "; pieces: " + t.pieces.to_string() + "\n")
      out.write_string("length: " + t.purchased.to_string() + " = useful " + t.useful.to_string() +
        " + kerf " + t.kerf_loss.to_string() + " + trims " + t.trim_loss.to_string() +
        " + reusable " + t.reusable.to_string() + " + scrap " + t.scrap.to_string() + "\n")
      for g in group_patterns(p, plan).unwrap() {
        out.write_string(g.stock_id + " x " + g.repetitions.to_string() + ":")
        for i, n in g.counts {
          if n > 0 { out.write_string(" " + p.demands[i].id + "=" + n.to_string()) }
        }
        out.write_string("; remainder=" + g.remaining_each.to_string() + "\n")
      }
    }
  }
  Ok(out.to_string())
}
