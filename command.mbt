///|
pub fn help_text() -> String {
  "MoonCutStock 0.1.0\n" +
  "Commands: solve-json, solve-csv, normalize-json, normalize-csv, audit-json\n" +
  "Options: --format=json|text --kerf=N --min-remnant=N --patterns=N --nodes=N\n" +
  "CSV kerf/remnant metadata comes from options. audit-json takes {problem,plan}.\n" +
  "Optimality is bounded: inspect status and completion flags.\n"
}

///|
priv struct Options {
  format : String
  kerf : Int
  min_remnant : Int
  limits : Limits
}

///|
fn command_options(args : Array[String]) -> Options raise CodecError {
  if args.length() > 5 {
    raise Invalid("at most five command options")
  }
  let mut format = "json"
  let mut kerf = 0
  let mut min_remnant = 1
  let mut patterns = 50000
  let mut nodes = 200000
  let seen : Map[String, Bool] = Map([])
  for arg in args {
    let pair = arg.split("=").map(v => v.to_owned()).to_array()
    if pair.length() != 2 {
      raise Invalid("options must use --key=value")
    }
    if seen.contains(pair[0]) {
      raise Invalid("duplicate command option")
    }
    seen[pair[0]] = true
    match pair[0] {
      "--format" => {
        format = pair[1]
        if format != "json" && format != "text" {
          raise Invalid("format must be json or text")
        }
      }
      "--kerf" => kerf = csv_int(pair[1])
      "--min-remnant" => min_remnant = csv_int(pair[1])
      "--patterns" => patterns = csv_int(pair[1])
      "--nodes" => nodes = csv_int(pair[1])
      _ => raise Invalid("unknown command option")
    }
  }
  let limits = Limits::{ patterns, nodes, }
  match validate_limits(limits) {
    Ok(_) => ()
    Err(e) => raise Invalid(e)
  }
  if kerf < 0 || min_remnant < 1 {
    raise Invalid("invalid kerf or remnant threshold")
  }
  { format, kerf, min_remnant, limits, }
}

///|
fn audit_bundle(input : String) -> String raise CodecError {
  let f = codec_fields(parse_json(input), ["problem", "plan"])
  let p = problem_json(required(f, "problem"))
  let plan = plan_json(p, required(f, "plan"))
  totals_json(audit(p, plan).unwrap()).stringify()
}

///|
fn execute(
  command : String,
  input : String,
  args : Array[String],
) -> String raise CodecError {
  if command == "help" {
    return help_text()
  }
  let options = command_options(args)
  if command == "audit-json" {
    if args.length() > 0 {
      raise Invalid("audit-json does not accept options")
    }
    return audit_bundle(input)
  }
  if !["solve-json", "solve-csv", "normalize-json", "normalize-csv"].contains(
      command,
    ) {
    raise Invalid("unknown command")
  }
  let csv = command == "solve-csv" || command == "normalize-csv"
  if !csv &&
    (
      args.any(a => a.has_prefix("--kerf=")) ||
      args.any(a => a.has_prefix("--min-remnant="))
    ) {
    raise Invalid("JSON kerf and min_remnant must come from the document")
  }
  let p = if csv {
    csv_problem(input, options.kerf, options.min_remnant)
  } else {
    problem_json(parse_json(input))
  }
  if command == "normalize-json" {
    return encode_problem(p)
  }
  if command == "normalize-csv" {
    return encode_csv(p)
  }
  let s = match solve(p, limits=options.limits) {
    Ok(s) => s
    Err(e) => raise Invalid(e)
  }
  let text = if options.format == "text" {
    text_report(p, s)
  } else {
    encode_solution(p, s)
  }
  match text {
    Ok(v) => v
    Err(e) => raise Invalid(e)
  }
}

///|
/// Pure command boundary for embedding in native, web, CI or editor hosts.
pub fn run_command(
  command : String,
  input : String,
  args? : Array[String] = [],
) -> Result[String, String] {
  if input.length() > 65536 {
    return Err("command input exceeds 65536 code units")
  }
  if command.length() > 32 || args.any(a => a.length() > 64) {
    return Err("command arguments too long")
  }
  Ok(execute(command, input, args)) catch {
    Invalid(e) => Err(e)
  }
}
