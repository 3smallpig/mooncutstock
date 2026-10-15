///|
fn main {
  let args = @env.args()
  if args.length() <= 1 || args[1] == "help" {
    println(@cutstock.help_text())
  } else if args[1] == "demo" {
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
    if args.length() < 3 {
      abort("mooncutstock: missing input document argument")
    }
    let options = args[3:].to_owned()
    match @cutstock.run_command(args[1], args[2], args=options) {
      Ok(text) => println(text)
      Err(e) => abort("mooncutstock: " + e)
    }
  }
}
