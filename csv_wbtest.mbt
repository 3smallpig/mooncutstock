///|
test "CSV quoting round trip and domain metadata" {
  let p = problem([demand("a,\"b", "木材", 3, 2)], [stock("s", "木材", 10, 7, -1)], kerf=1).unwrap()
  let q = decode_csv(encode_csv(p), kerf=p.kerf()).unwrap()
  assert_eq(p.demands(), q.demands())
  assert_eq(p.stocks(), q.stocks())
  assert_eq(solve(q).unwrap().status(), Optimal)
}

///|
test "CSV rejects malformed records rather than coercing values" {
  let header = "kind,id,material,length,quantity,cost,trim_start,trim_end\n"
  for body in ["stock,s,m,10,-2,1,0,0", "demand,a,m,3,2,1,0,0", "stock,s,m,10,1,1,0", "stock,\"s,m,10,1,1,0,0", "stock,\"s\"x,m,10,1,1,0,0"] {
    assert_true(decode_csv(header + body) is Err(_))
  }
  assert_true(decode_csv("bad header") is Err(_))
}
