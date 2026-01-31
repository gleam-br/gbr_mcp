////
//// Math tool domain type and functions.
////

import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/option.{Some}
import gleam/result

import gbr/json/schema/domain
import gbr/mcp
import gbr/mcp/gen/defs
import gbr/shared/utils

/// Math tool type.
///
pub type Tool {
  Random
  Add(Int, Int)
}

/// Get mcp math server from context.
///
/// - context: A generic inbound data.
///
pub fn server(_context) {
  mcp.Server(
    implementation: defs.Implementation(
      name: "mcp_math_srv",
      version: "0.1.0",
      title: Some("MCP: Math Server"),
    ),
    tools: tools(),
    prompts: [],
    resources: [],
    resource_templates: [],
  )
}

/// Call math tool
///
pub fn call_tool(tool) {
  case tool {
    Random -> {
      use number <- result.map(random())
      dict.from_list([#("number", utils.Integer(number))])
    }
    Add(x, y) -> {
      use number <- result.map(add(x, y))
      dict.from_list([#("number", utils.Integer(number))])
    }
  }
}

// PRIVATE
//

/// Get list of math tools
///
fn tools() {
  [
    utils.Tool(
      spec: utils.Spec(
        name: "random",
        title: "Generate Random",
        description: "Generate a random number between two numbers",
        input: [],
        output: [domain.field("number", domain.integer())],
      ),
      decoder: decode.success(Random),
    ),
    utils.Tool(
      spec: utils.Spec(
        name: "add",
        title: "Add",
        description: "Add two numbers",
        input: [
          domain.field("x", domain.integer()),
          domain.field("y", domain.integer()),
        ],
        output: [domain.field("sum", domain.integer())],
      ),
      decoder: {
        use x <- decode.field("x", decode.int)
        use y <- decode.field("y", decode.int)
        decode.success(Add(x, y))
      },
    ),
  ]
}

fn random() {
  Ok(int.random(100))
}

fn add(x, y) {
  Ok(x + y)
}
