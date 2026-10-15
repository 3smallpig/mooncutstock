///|
priv suberror CodecError {
  Invalid(String)
}

///|
fn parse_json(text : String) -> Json raise CodecError {
  if text.length() > 65536 {
    raise Invalid("JSON exceeds 65536 code units")
  }
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  for c in text.iter() {
    if quoted {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
    } else if c == '"' {
      quoted = true
    } else if c == '{' || c == '[' {
      depth += 1
      if depth > 8 {
        raise Invalid("JSON nesting exceeds eight containers")
      }
    } else if c == '}' || c == ']' {
      depth -= 1
    }
  }
  @json.parse(text[:]) catch {
    _ => raise Invalid("invalid JSON")
  }
}

///|
fn codec_fields(
  value : Json,
  allowed : Array[String],
) -> Map[String, Json] raise CodecError {
  guard value is Object(fields) else { raise Invalid("expected object") }
  for key, _ in fields {
    if !allowed.contains(key) {
      raise Invalid("unknown field: " + key)
    }
  }
  fields
}

///|
fn required(fields : Map[String, Json], key : String) -> Json raise CodecError {
  match fields.get(key) {
    Some(v) => v
    None => raise Invalid("missing field: " + key)
  }
}

///|
fn codec_string(value : Json) -> String raise CodecError {
  guard value is String(s) else { raise Invalid("expected string") }
  s
}

///|
fn codec_int(value : Json) -> Int raise CodecError {
  guard value is Number(x, ..) else { raise Invalid("expected integer") }
  if x != x || x < -1.0 || x > 1000000.0 {
    raise Invalid("integer outside -1..1000000")
  }
  let n = x.to_int()
  if n.to_double() != x {
    raise Invalid("fractional integer")
  }
  n
}

///|
fn codec_array(value : Json, limit : Int) -> Array[Json] raise CodecError {
  guard value is Array(items) else { raise Invalid("expected array") }
  if items.length() > limit {
    raise Invalid("array exceeds schema bound")
  }
  items
}

///|
fn demand_json(value : Json) -> Demand raise CodecError {
  let f = codec_fields(value, ["id", "material", "length", "quantity"])
  demand(
    codec_string(required(f, "id")),
    codec_string(required(f, "material")),
    codec_int(required(f, "length")),
    codec_int(required(f, "quantity")),
  )
}

///|
fn stock_json(value : Json) -> Stock raise CodecError {
  let f = codec_fields(value, [
    "id", "material", "length", "cost", "quantity", "trim_start", "trim_end",
  ])
  stock(
    codec_string(required(f, "id")),
    codec_string(required(f, "material")),
    codec_int(required(f, "length")),
    codec_int(required(f, "cost")),
    codec_int(required(f, "quantity")),
    trim_start=codec_int(required(f, "trim_start")),
    trim_end=codec_int(required(f, "trim_end")),
  )
}

///|
fn problem_json(value : Json) -> Problem raise CodecError {
  let f = codec_fields(value, [
    "schema", "demands", "stocks", "kerf", "min_remnant",
  ])
  if codec_string(required(f, "schema")) != "mooncutstock.problem/1" {
    raise Invalid("unsupported problem schema")
  }
  let ds = codec_array(required(f, "demands"), 12).map(demand_json)
  let ss = codec_array(required(f, "stocks"), 16).map(stock_json)
  match
    problem(
      ds,
      ss,
      kerf=codec_int(required(f, "kerf")),
      min_remnant=codec_int(required(f, "min_remnant")),
    ) {
    Ok(p) => p
    Err(e) => raise Invalid(e)
  }
}

///|
pub fn decode_problem(text : String) -> Result[Problem, String] {
  Ok(problem_json(parse_json(text))) catch {
    Invalid(e) => Err(e)
  }
}
