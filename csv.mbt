///|
fn csv_rows(text : String) -> Array[Array[String]] raise CodecError {
  if text.length() > 65536 {
    raise Invalid("CSV exceeds 65536 code units")
  }
  let chars = text.iter().to_array()
  let rows : Array[Array[String]] = []
  let mut row : Array[String] = []
  let mut cell = StringBuilder()
  let mut cell_size = 0
  let mut mode = 0 // 0=start, 1=unquoted, 2=quoted, 3=after closing quote
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if mode == 2 {
      if c == '"' {
        mode = 3
      } else {
        cell.write_char(c)
        cell_size += if c.to_int() > 65535 { 2 } else { 1 }
      }
    } else if mode == 3 && c == '"' {
      cell.write_char('"')
      cell_size += 1
      mode = 2
    } else if c == ',' || c == '\n' || c == '\r' {
      row.push(cell.to_string())
      cell = StringBuilder()
      cell_size = 0
      mode = 0
      if row.length() > 8 {
        raise Invalid("CSV has more than eight columns")
      }
      if c != ',' {
        rows.push(row)
        row = []
        if rows.length() > 29 {
          raise Invalid("CSV has more than 28 data rows")
        }
        if c == '\r' && i + 1 < chars.length() && chars[i + 1] == '\n' {
          i += 1
        }
      }
    } else if mode == 3 {
      raise Invalid("unexpected text after CSV closing quote")
    } else if c == '"' {
      if mode != 0 {
        raise Invalid("quote inside unquoted CSV field")
      }
      mode = 2
    } else {
      cell.write_char(c)
      cell_size += if c.to_int() > 65535 { 2 } else { 1 }
      mode = 1
    }
    if cell_size > 256 {
      raise Invalid("CSV field exceeds 256 code units")
    }
    i += 1
  }
  if mode == 2 {
    raise Invalid("unterminated CSV quote")
  }
  if mode != 0 || cell_size > 0 || row.length() > 0 {
    row.push(cell.to_string())
    rows.push(row)
  }
  if rows.length() > 29 {
    raise Invalid("CSV row bound exceeded")
  }
  rows
}

///|
fn csv_int(text : String) -> Int32 raise CodecError {
  if text == "-1" {
    return -1
  }
  if text.length() == 0 || text.length() > 7 {
    raise Invalid("invalid CSV integer")
  }
  let mut n = 0
  for c in text.iter() {
    if c < '0' || c > '9' {
      raise Invalid("invalid CSV decimal integer")
    }
    n = n * 10 + c.to_int() - 48
  }
  if n > 1000000 {
    raise Invalid("CSV integer outside bounded domain")
  }
  n
}

///|
fn csv_problem(
  text : String,
  kerf : Int32,
  min_remnant : Int32,
) -> Problem raise CodecError {
  let rows = csv_rows(text)
  let header = [
    "kind", "id", "material", "length", "quantity", "cost", "trim_start", "trim_end",
  ]
  if rows.length() == 0 || rows[0] != header {
    raise Invalid(
      "CSV header must be kind,id,material,length,quantity,cost,trim_start,trim_end",
    )
  }
  let ds : Array[Demand] = []
  let ss : Array[Stock] = []
  for i in 1..<rows.length() {
    let r = rows[i]
    if r.length() != 8 {
      raise Invalid("CSV row must contain eight fields")
    }
    let length = csv_int(r[3])
    let quantity = csv_int(r[4])
    let cost = csv_int(r[5])
    let start = csv_int(r[6])
    let end = csv_int(r[7])
    if r[0] == "demand" {
      if cost != 0 || start != 0 || end != 0 {
        raise Invalid("demand cost and trims must be zero")
      }
      ds.push(demand(r[1], r[2], length, quantity))
    } else if r[0] == "stock" {
      ss.push(
        stock(
          r[1],
          r[2],
          length,
          cost,
          quantity,
          trim_start=start,
          trim_end=end,
        ),
      )
    } else {
      raise Invalid("CSV kind must be demand or stock")
    }
  }
  match problem(ds, ss, kerf~, min_remnant~) {
    Ok(p) => p
    Err(e) => raise Invalid(e)
  }
}

///|
pub fn decode_csv(
  text : String,
  kerf~ : Int32 = 0,
  min_remnant~ : Int32 = 1,
) -> Result[Problem, String] {
  Ok(csv_problem(text, kerf, min_remnant)) catch {
    Invalid(e) => Err(e)
  }
}

///|
fn csv_quote(s : String) -> String {
  "\"" + s.replace(old="\"", new="\"\"") + "\""
}

///|
pub fn encode_csv(p : Problem) -> String {
  let b = StringBuilder()
  b.write_string(
    "kind,id,material,length,quantity,cost,trim_start,trim_end\r\n",
  )
  for d in p.demands {
    b.write_string(
      "demand," +
      csv_quote(d.id) +
      "," +
      csv_quote(d.material) +
      "," +
      d.length.to_string() +
      "," +
      d.quantity.to_string() +
      ",0,0,0\r\n",
    )
  }
  for s in p.stocks {
    b.write_string(
      "stock," +
      csv_quote(s.id) +
      "," +
      csv_quote(s.material) +
      "," +
      s.length.to_string() +
      "," +
      s.quantity.to_string() +
      "," +
      s.cost.to_string() +
      "," +
      s.trim_start.to_string() +
      "," +
      s.trim_end.to_string() +
      "\r\n",
    )
  }
  b.to_string()
}
