////
////
////

import gleam/erlang/process

import mcp/hello

///
///
pub fn main() -> Nil {
  let assert Ok(_) = hello.start()
  process.sleep_forever()
}
