////
//// MCP Server: Hello Tools
////

import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option
import gleam/string

import mist
import wisp.{type Body, type Connection}
import wisp/wisp_mist

import gbr/json/rpc
import gbr/mcp
import gbr/mcp/effect

import mcp/hello/domain

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
fn serve(request: Request(Connection), context: a) -> Response(Body) {
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
  context: a,
) -> response.Response(wisp.Body) {
  let Request(method:, ..) = request
  case method {
    http.Delete -> wisp.no_content()
    http.Post -> {
      // decode input to a MCP request
      use mcp_request <- decode_json(request, mcp.request_decoder())

      // create an mcp server config.
      let server = domain.server(context)

      handle_mcp(mcp_request, server)
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
  server: mcp.Server(domain.Tool, a),
) -> option.Option(rpc.Response(mcp.ServerResult)) {
  case mcp.handle_rpc(mcp_request, server) {
    effect.Done(result) -> result
    effect.CallTool(tool:, resume:) ->
      domain.call_tool(tool)
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
  request: Request(Connection),
  decoder: decode.Decoder(a),
  then: fn(a) -> Response(Body),
) -> Response(Body) {
  use data <- wisp.require_json(request)

  case decode.run(data, decoder) {
    Ok(value) -> then(value)
    Error(reason) -> wisp.bad_request(string.inspect(reason))
  }
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
