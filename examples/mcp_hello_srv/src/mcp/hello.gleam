////
//// MCP Server: Hello Tools
////

import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{Some}
import gleam/string

import mist
import wisp
import wisp/wisp_mist

import gbr/json/rpc
import gbr/json/schema/domain
import gbr/json/schema/utils

import gbr/mcp
import gbr/mcp/effect
import gbr/mcp/gen/defs

/// Hello tool type.
///
pub type ToolHello {
  Welcome(String)
  World
}

/// Start hello mcp http server listen on 0.0.0.0:8080
///
pub fn start() {
  let context = Nil
  let secret_key_base = "my-screct-here"

  serve(_, context)
  |> wisp_mist.handler(secret_key_base)
  |> mist.new()
  |> mist.bind("0.0.0.0")
  |> mist.port(8080)
  |> mist.start()
}

// PRIVATE
//

/// Serve requests from http server
///
fn serve(request: Request(wisp.Connection), context: a) -> Response(wisp.Body) {
  use <- wisp.log_request(request)
  let Request(method:, ..) = request

  // log here
  echo request

  case wisp.path_segments(request), method {
    [], http.Get -> wisp.html_response("MCP Server [UP]", 200)

    ["mcp"], _any -> handle(request, context)
    _, _ -> wisp.not_found()
  }
}

/// Handle MCP JSON-RPC via http request.
///
/// - request: Gleam http request.
/// - context: Generic instance of server context.
///
fn handle(
  request: request.Request(wisp.Connection),
  _context: a,
) -> response.Response(wisp.Body) {
  let Request(method:, ..) = request
  case method {
    http.Delete -> wisp.no_content()
    http.Post -> {
      // decode input to a MCP request
      use mcp_request <- decode_json(request, mcp.request_decoder())

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
      |> handle_mcp(mcp_request, _)
      // encode the response and return it
      |> option.map(mcp.response_encode)
      |> option.map(json.to_string)
      |> option.map(wisp.json_response(_, 200))
      |> option.unwrap(wisp.response(202))
    }
    _ -> wisp.method_not_allowed([http.Post, http.Delete])
  }
}

fn handle_mcp(
  mcp_request: rpc.Request(mcp.ClientRequest, mcp.ClientNotification),
  server: mcp.Server(ToolHello, a),
) -> option.Option(rpc.Response(mcp.ServerResult)) {
  case mcp.handle_rpc(mcp_request, server) {
    effect.Done(result) -> result
    effect.CallTool(tool:, resume:) ->
      call_tool(tool)
      |> resume()
    effect.ReadResource(resource:, resume:) ->
      read_resource(resource) |> resume()
    effect.GetPrompt(prompt:, resume:) ->
      get_prompt(prompt)
      |> resume()
    effect.Complete(ref:, argument:, context:, resume:) ->
      complete(ref, argument, context)
      |> resume()
  }
}

fn decode_json(
  request: Request(wisp.Connection),
  decoder: decode.Decoder(a),
  then: fn(a) -> Response(wisp.Body),
) -> Response(wisp.Body) {
  use data <- wisp.require_json(request)

  case decode.run(data, decoder) {
    Ok(value) -> then(value)
    Error(reason) -> wisp.bad_request(string.inspect(reason))
  }
}

/// Call hello tool
///
fn call_tool(tool: ToolHello) -> Result(dict.Dict(String, utils.Any), String) {
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

fn read_resource(_resource: a) -> effect.ResourceContents {
  effect.TextContents(mime_type: "text/plain", text: "not implemented")
}

fn get_prompt(_prompt: a) -> List(b) {
  []
}

fn complete(_ref: a, _argument: b, _context: c) -> List(d) {
  []
}
