////
////
////

import gleam/erlang/process

import mcp/math

///
///
pub fn main() -> Nil {
  let assert Ok(_) = math.start()
  process.sleep_forever()
}
