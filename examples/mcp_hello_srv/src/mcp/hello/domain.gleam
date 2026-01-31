////
//// Hello tool domain type and functions.
////

import gleam/dict
import gleam/dynamic/decode
import gleam/option.{Some}

import gbr/json/schema/domain
import gbr/mcp
import gbr/mcp/gen/defs
import gbr/shared/utils

/// Hello tool type.
///
pub type Tool {
  Welcome(String)
  World
}

/// Get mcp hello server from context.
///
/// - context: A generic inbound data.
///
pub fn server(_context) {
  mcp.Server(
    implementation: defs.Implementation(
      name: "mcp_hello_srv",
      version: "0.1.0",
      title: Some("MCP: Hello Server"),
    ),
    tools: tools(),
    prompts: [],
    resources: [],
    resource_templates: [],
  )
}

/// Call hello tool
///
pub fn call_tool(tool) {
  case tool {
    World -> {
      dict.from_list([#("message", utils.String("Hello World by gleam-br"))])
      |> Ok()
    }
    Welcome(greetings) -> {
      dict.from_list([
        #(
          "message",
          utils.String("Hello " <> greetings <> ", welcome to gleam-br"),
        ),
      ])
      |> Ok()
    }
  }
}

// PRIVATE
//

/// Get list of hello tools
///
fn tools() {
  [
    utils.Tool(
      spec: utils.Spec(
        name: "world",
        title: "Hello World",
        description: "Say hello world by gleam-br",
        input: [],
        output: [domain.field("message", domain.string())],
      ),
      decoder: World
        |> decode.success(),
    ),
    utils.Tool(
      spec: utils.Spec(
        name: "welcome",
        title: "Hello welcome greetings",
        description: "Say hello to greetings welcome to glem-br",
        input: [
          domain.field("greetings", domain.string()),
        ],
        output: [domain.field("message", domain.string())],
      ),
      decoder: {
        use greetings <- decode.field("greetings", decode.string)

        Welcome(greetings)
        |> decode.success()
      },
    ),
  ]
}
