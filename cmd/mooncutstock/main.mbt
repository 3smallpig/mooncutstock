///|
#cfg(target="js")
fn cli_prefix() -> Int32 {
  2
}

///|
#cfg(not(target="js"))
fn cli_prefix() -> Int32 {
  1
}

///|
fn main {
  let raw = @env.args()
  let start = cli_prefix().min(raw.length())
  let args = raw[start:].to_owned()
  if args.length() == 0 || args[0] == "help" {
    println(@cutstock.help_text())
  } else if args[0] == "demo" {
    let p = @cutstock.problem(
      [@cutstock.demand("beam", "wood", 40, 4)],
      [
        @cutstock.stock("short", "wood", 85, 7, 1),
        @cutstock.stock("long", "wood", 130, 12, -1),
      ],
      kerf=2,
      min_remnant=5,
    ).unwrap()
    println(@cutstock.text_report(p, @cutstock.solve(p).unwrap()).unwrap())
  } else {
    if args.length() < 2 {
      abort("mooncutstock: missing input document argument")
    }
    let options = args[2:].to_owned()
    match @cutstock.run_command(args[0], args[1], args=options) {
      Ok(text) => println(text)
      Err(e) => abort("mooncutstock: " + e)
    }
  }
}
