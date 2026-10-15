///|
fn encode_demand(d : Demand) -> Json {
  Json::object({ "id": Json(d.id), "material": Json(d.material),
    "length": Json(d.length), "quantity": Json(d.quantity) })
}

///|
fn encode_stock(s : Stock) -> Json {
  Json::object({ "id": Json(s.id), "material": Json(s.material),
    "length": Json(s.length), "cost": Json(s.cost), "quantity": Json(s.quantity),
    "trim_start": Json(s.trim_start), "trim_end": Json(s.trim_end) })
}

///|
pub fn encode_problem(p : Problem) -> String {
  Json::object({ "schema": Json("mooncutstock.problem/1"),
    "demands": Json::array(p.demands.map(encode_demand)),
    "stocks": Json::array(p.stocks.map(encode_stock)),
    "kerf": Json(p.kerf), "min_remnant": Json(p.min_remnant) }).stringify()
}

///|
pub fn status_name(status : Status) -> String {
  match status {
    Optimal => "optimal"
    FeasibleBudget => "feasible-budget"
    Infeasible => "infeasible"
    UnknownBudget => "unknown-budget"
  }
}

///|
fn totals_json(t : Totals) -> Json {
  Json::object({ "cost": Json(t.cost), "purchased": Json(t.purchased),
    "useful": Json(t.useful), "kerf_loss": Json(t.kerf_loss), "trim_loss": Json(t.trim_loss),
    "reusable": Json(t.reusable), "scrap": Json(t.scrap), "bars": Json(t.bars), "pieces": Json(t.pieces) })
}

///|
fn bar_json(a : Pattern) -> Json {
  Json::object({ "stock": Json(a.stock), "counts": Json(a.counts) })
}

///|
/// External plan format stores only source decisions; cached geometry is never trusted.
pub fn encode_plan(p : Problem, plan : Plan) -> Result[String, String] {
  let totals = match audit(p, plan) { Err(e) => return Err(e); Ok(t) => t }
  Ok(Json::object({ "schema": Json("mooncutstock.plan/1"),
    "bars": Json::array(plan.bars.map(bar_json)), "totals": totals_json(totals) }).stringify())
}

///|
fn plan_json(p : Problem, value : Json) -> Plan raise CodecError {
  let f = codec_fields(value, ["schema", "bars", "totals"])
  if codec_string(required(f, "schema")) != "mooncutstock.plan/1" { raise Invalid("unsupported plan schema") }
  let bars = codec_array(required(f, "bars"), 128).map(v => {
    let f = codec_fields(v, ["stock", "counts"])
    let counts = codec_array(required(f, "counts"), 12).map(codec_int)
    match pattern(p, codec_int(required(f, "stock")), counts) {
      Ok(a) => a
      Err(e) => raise Invalid(e)
    }
  })
  let plan = match plan_from_patterns(p, bars) { Ok(v) => v; Err(e) => raise Invalid(e) }
  // Totals are optional, but when supplied every field must match independent audit.
  match f.get("totals") {
    None => ()
    Some(t) => {
      let fields = codec_fields(t, ["cost", "purchased", "useful", "kerf_loss", "trim_loss", "reusable", "scrap", "bars", "pieces"])
      let actual = audit(p, plan).unwrap()
      let expected = match totals_json(actual) { Object(v) => v; _ => abort("internal totals object") }
      for key, value in expected {
        // Larger totals than 1e6 are valid, so compare JSON values rather than bounded input integers.
        if required(fields, key) != value { raise Invalid("plan total mismatch: " + key) }
      }
    }
  }
  plan
}

///|
pub fn decode_plan(p : Problem, text : String) -> Result[Plan, String] {
  try { Ok(plan_json(p, parse_json(text))) } catch { Invalid(e) => Err(e) }
}
