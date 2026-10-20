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
  // Validate original syntax first: normalization must not legalize 01, 1., etc.
  let original = @json.parse(text[:]) catch {
    _ => raise Invalid("invalid JSON")
  }
  let normalized = exact_json_numbers(text)
  if normalized == text {
    original
  } else {
    @json.parse(normalized[:]) catch {
      _ => raise Invalid("invalid JSON")
    }
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
fn codec_int(value : Json) -> Int32 raise CodecError {
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
fn codec_array(value : Json, limit : Int32) -> Array[Json] raise CodecError {
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

///|
// All numbers in the interchange schemas are bounded integers. Check the source
// decimal, not a rounded Double; 1.0000000000000001 and 1e-400 are not integers.
// Input syntax was already checked by the standard parser.
fn exact_json_number(token : String) -> String raise CodecError {
  let chars = token.iter().to_array()
  let negative = chars[0] == '-'
  let mut at = if negative { 1 } else { 0 }
  let digits : Array[Int32] = []
  let mut fractional = 0
  let mut after_dot = false
  while at < chars.length() && chars[at] != 'e' && chars[at] != 'E' {
    if chars[at] == '.' {
      after_dot = true
    } else {
      digits.push(chars[at].to_int() - 48)
      if after_dot {
        fractional += 1
      }
    }
    at += 1
  }
  let mut exponent = 0
  if at < chars.length() {
    at += 1
    let minus = chars[at] == '-'
    if chars[at] == '-' || chars[at] == '+' {
      at += 1
    }
    while at < chars.length() {
      // Larger magnitudes cannot cancel a <=65536-unit mantissa. Saturation
      // prevents overflow even for a malicious exponent with thousands of digits.
      exponent = (exponent * 10 + chars[at].to_int() - 48).min(100000)
      at += 1
    }
    if minus {
      exponent = -exponent
    }
  }
  let mut first = 0
  while first < digits.length() && digits[first] == 0 {
    first += 1
  }
  if first == digits.length() {
    return "0"
  }
  let shift = exponent - fractional
  let mut end = digits.length()
  if shift < 0 {
    if -shift > end - first {
      raise Invalid("fractional integer")
    }
    for i in (end + shift)..<end {
      if digits[i] != 0 {
        raise Invalid("fractional integer")
      }
    }
    end += shift
  }
  let zeros = shift.max(0)
  if end - first + zeros > 10 {
    raise Invalid("JSON integer outside supported range")
  }
  let mut n = 0L
  for i in first..<end {
    n = n * 10L + digits[i].to_int64()
  }
  for _ in 0..<zeros {
    n *= 10L
  }
  if n > 2147483647L {
    raise Invalid("JSON integer outside supported range")
  }
  if negative {
    (-n).to_string()
  } else {
    n.to_string()
  }
}

///|
fn exact_json_numbers(text : String) -> String raise CodecError {
  let chars = text.iter().to_array()
  let out = StringBuilder()
  let mut quoted = false
  let mut escaped = false
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if quoted {
      out.write_char(c)
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        quoted = false
      }
    } else if c == '"' {
      quoted = true
      out.write_char(c)
    } else if c == '-' || (c >= '0' && c <= '9') {
      let token = StringBuilder()
      while i < chars.length() {
        let n = chars[i]
        if !((n >= '0' && n <= '9') ||
          n == '-' ||
          n == '+' ||
          n == '.' ||
          n == 'e' ||
          n == 'E') {
          break
        }
        token.write_char(n)
        i += 1
      }
      out.write_string(exact_json_number(token.to_string()))
      continue
    } else {
      out.write_char(c)
    }
    i += 1
  }
  out.to_string()
}
