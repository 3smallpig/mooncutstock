///|
test "strict JSON problem input validates numeric and field types" {
  let text = "{\"schema\":\"mooncutstock.problem/1\",\"demands\":[{\"id\":\"a\",\"material\":\"m\",\"length\":3,\"quantity\":1}],\"stocks\":[],\"kerf\":0,\"min_remnant\":1}"
  assert_eq(decode_problem(text).unwrap().demands()[0].length, 3)
  assert_true(decode_problem(text.replace(old="3,", new="3.5,")) is Err(_))
  assert_true(
    decode_problem(text.replace(old="\"kerf\"", new="\"typo\"")) is Err(_),
  )
  assert_true(decode_problem("null") is Err(_))
  assert_true(decode_problem("[") is Err(_))
  assert_true(decode_problem("[[[[[[[[[0]]]]]]]]]") is Err(_))
}
