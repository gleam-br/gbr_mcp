////
//// 🧠 Model Context Protocol Server/Client builder.
////
//// MCP (Model Context Protocol) is an open-source standard for connecting AI
//// applications to external systems.
////
//// Using MCP, AI applications like Claude or ChatGPT can connect to data
//// sources (e.g. local files, databases), tools (e.g. search engines, calculators)
//// and workflows (e.g. specialized prompts)—enabling them to access key
//// information and perform tasks.
////
//// > Think of MCP like a USB-C port for AI applications.
////
//// Just as USB-C provides a standardized way to connect electronic devices,
//// MCP provides a standardized way to connect AI applications to external systems.
////
//// > more: https://modelcontextprotocol.io/docs/getting-started/intro
////

import gleam/dict
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result

import pollux
import pollux/reason

import gbr/shared/log
import gbr/shared/utils as u

import gbr/json/schema
import gbr/json/schema/domain

import gbr/mcp/effect
import gbr/mcp/gen/defs
import gbr/mcp/loader

// Alias
//

type Tool(t) =
  u.Tool(t, schema.ObjectSchema, schema.ObjectSchema)

/// MCP Server spec
///
pub type Server(tool, prompt) {
  Server(
    tools: List(Tool(tool)),
    prompts: List(#(defs.Prompt, decode.Decoder(prompt))),
    resources: List(defs.Resource),
    implementation: defs.Implementation,
    resource_templates: List(defs.ResourceTemplate),
  )
}

/// MCP Server results
///
pub type ServerResult {
  InitializeResult(defs.InitializeResult)
  PingResponse
  ListResourcesResult(defs.ListResourcesResult)
  ListResourceTemplatesResult(defs.ListResourceTemplatesResult)
  ReadResourceResult(defs.ReadResourceResult)
  ListPromptsResult(defs.ListPromptsResult)
  GetPromptResult(defs.GetPromptResult)
  ListToolsResult(defs.ListToolsResult)
  CallToolResult(defs.CallToolResult)
  CompleteResult(defs.CompleteResult)
}

/// Client request nofification
///
pub type ClientNotification {
  Cancelled(defs.CancelledNotification)
  Initialized(defs.InitializedNotification)
  Progress(defs.ProgressNotification)
  RootsListChanged(defs.RootsListChangedNotification)
}

/// Client request resource
///
pub type ClientRequest {
  Initialize(defs.InitializeRequest)
  Ping(defs.PingRequest)
  ListResources(defs.ListResourcesRequest)
  ListResourceTemplates(defs.ListResourceTemplatesRequest)
  ReadResource(defs.ReadResourceRequest)
  Subscribe(defs.SubscribeRequest)
  Unsubscribe(defs.UnsubscribeRequest)
  ListPrompts(defs.ListPromptsRequest)
  GetPrompt(defs.GetPromptRequest)
  ListTools(defs.ListToolsRequest)
  CallTool(defs.CallToolRequest)
  SetLevel(defs.SetLevelRequest)
  Complete(defs.CompleteRequest)
}

/// MCP JSON-RPC schema load from file and write in sources.
///
/// - Read file from `priv/` internal.
/// - Write code to file in `src/gbr/mcp/gen` internal.
///
pub fn load() {
  loader.main()
}

/// MCP JSON-RPC request decoder
///
pub fn request_decoder() {
  pollux.request_decoder(
    request_decoders(),
    notification_decoders(),
    Initialized(defs.InitializedNotification(None, dict.new())),
  )
}

/// MCP JSON-RPC request encode
///
pub fn request_encode(request) {
  pollux.request_encode(request, do_request_encode, do_notification_encode)
}

/// Handler request to server MCP via JSON-RPC
///
pub fn handle_rpc(request, server: Server(a, b)) {
  case request {
    pollux.Request(id:, value:, ..) ->
      case handle_request(value, server) {
        effect.Done(return) -> {
          pollux.response(id, return) |> Some |> effect.Done
        }
        effect.CallTool(tool, resume) ->
          effect.CallTool(tool, fn(reply) {
            pollux.response(id, resume(reply)) |> Some
          })
        effect.ReadResource(resource, resume) ->
          effect.ReadResource(resource, fn(reply) {
            pollux.response(id, resume(reply)) |> Some
          })
        effect.GetPrompt(prompt, resume) ->
          effect.GetPrompt(prompt, fn(reply) {
            pollux.response(id, resume(reply)) |> Some
          })
        effect.Complete(ref, argument, context, resume) ->
          effect.Complete(ref, argument, context, fn(reply) {
            pollux.response(id, resume(reply)) |> Some
          })
      }
    pollux.Notification(value:, ..) -> {
      let Nil = handle_notification(value, server)
      effect.Done(None)
    }
  }
}

/// Get tool by name in server MCP
///
pub fn get_tool_by_name(server, name) {
  let Server(tools:, ..) = server
  list.find(tools, fn(tool) {
    let u.Tool(spec: u.Spec(name: n, ..), ..) = tool
    case name == n {
      True -> True
      False -> False
    }
  })
}

/// Get prompt by name in server MCP
///
pub fn get_prompt_by_name(server, name) {
  let Server(prompts:, ..) = server
  list.find(prompts, fn(prompt) {
    let #(defs.Prompt(name: n, ..), _decoder) = prompt
    case name == n {
      True -> True
      False -> False
    }
  })
}

///
///
pub fn handle_request(of, server: Server(a, b)) {
  case of {
    Initialize(message) -> {
      initialize(message, server)
      |> InitializeResult
      |> Ok
      |> effect.Done
    }
    ListTools(message) -> {
      list_tools(message, server)
      |> ListToolsResult
      |> Ok
      |> effect.Done
    }
    CallTool(message) -> {
      case call_tool(message, server) {
        Ok(args) -> effect.CallTool(args, finish_call_tool)
        Error(reason) -> effect.Done(Error(reason))
      }
    }
    ListResources(message) -> {
      list_resources(message, server)
      |> ListResourcesResult
      |> Ok
      |> effect.Done
    }
    ListResourceTemplates(message) -> {
      list_resource_templates(message, server)
      |> ListResourceTemplatesResult
      |> Ok
      |> effect.Done
    }
    ReadResource(message) -> {
      case read_resource(message, server) {
        Ok(r) -> effect.ReadResource(r, finish_read_resource(r, _))
        Error(reason) -> effect.Done(Error(reason))
      }
    }
    // Subscription to resources
    Subscribe(_message) ->
      reason.method_not_available("resources/subscribe") |> Error |> effect.Done
    Unsubscribe(_message) ->
      reason.method_not_available("resources/unsubscribe")
      |> Error
      |> effect.Done
    ListPrompts(message) -> {
      list_prompts(message, server)
      |> ListPromptsResult
      |> Ok
      |> effect.Done
    }
    GetPrompt(message) -> {
      case get_prompt(message, server) {
        Ok(#(prompt, args)) ->
          effect.GetPrompt(args, finish_get_prompt(prompt, _))
        Error(reason) -> effect.Done(Error(reason))
      }
    }
    // Will this need to be an effect to allow autocompleting through resource templates
    Complete(message) -> complete(message)
    SetLevel(message) -> set_level(message) |> effect.Done
    Ping(_) -> PingResponse |> Ok |> effect.Done
  }
}

///
///
pub fn request_method(request) {
  case request {
    Initialize(_) -> "initialize"
    Ping(_) -> "ping"
    ListResources(_) -> "resources/list"
    ListResourceTemplates(_) -> "resources/templates/list"
    ReadResource(_) -> "resources/read"
    Subscribe(_) -> "resources/subscribe"
    Unsubscribe(_) -> "resources/unsubscribe"
    ListPrompts(_) -> "prompts/list"
    GetPrompt(_) -> "prompts/get"
    ListTools(_) -> "tools/list"
    CallTool(_) -> "tools/call"
    SetLevel(_) -> "logging/setLevel"
    Complete(_) -> "completion/complete"
  }
}

///
///
pub fn notification_method(notification) {
  case notification {
    Cancelled(_) -> "notifications/cancelled"
    Initialized(_) -> "notifications/initialized"
    Progress(_) -> "notifications/progress"
    RootsListChanged(_) -> "notifications/roots/list_changed"
  }
}

pub fn response_decoder(expected) {
  pollux.response_decoder(expected)
}

pub fn response_encode(response) {
  pollux.response_encode(response, do_response_encode)
}

// PRIVATE
//

fn to_api_definition(tool) {
  let u.Tool(spec:, ..) = tool
  defs.Tool(
    meta: None,
    annotations: None,
    description: Some(spec.description),
    input_schema: cast_schema(spec.input),
    name: spec.name,
    output_schema: Some(cast_schema(spec.output)),
    title: Some(spec.title),
  )
}

fn cast_schema(args) {
  let #(required, properties) =
    list.map_fold(args, [], fn(acc, arg) {
      let #(name, schema, required) = arg
      let assert domain.Inline(schema) = schema

      let acc = case required {
        True -> [name, ..acc]
        False -> acc
      }
      #(acc, #(name, domain.to_fields(schema)))
    })
  defs.AnonA5a007cd(
    type_: "object",
    properties: Some(dict.from_list(properties)),
    required: Some(required),
  )
}

fn do_response_encode(result) {
  case result {
    InitializeResult(m) -> defs.initialize_result_encode(m)
    PingResponse -> json.object([])
    ListResourcesResult(m) -> defs.list_resources_result_encode(m)
    ListResourceTemplatesResult(m) ->
      defs.list_resource_templates_result_encode(m)
    ReadResourceResult(m) -> defs.read_resource_result_encode(m)
    ListPromptsResult(m) -> defs.list_prompts_result_encode(m)
    GetPromptResult(m) -> defs.get_prompt_result_encode(m)
    ListToolsResult(m) -> defs.list_tools_result_encode(m)
    CallToolResult(m) -> defs.call_tool_result_encode(m)
    CompleteResult(m) -> defs.complete_result_encode(m)
  }
}

fn do_request_encode(request) {
  let method = request_method(request)
  let params = case request {
    Initialize(request) -> defs.initialize_request_encode(request)
    Ping(request) -> defs.ping_request_encode(request)
    ListResources(request) -> defs.list_resources_request_encode(request)
    ListResourceTemplates(request) ->
      defs.list_resource_templates_request_encode(request)
    ReadResource(request) -> defs.read_resource_request_encode(request)
    Subscribe(request) -> defs.subscribe_request_encode(request)
    Unsubscribe(request) -> defs.unsubscribe_request_encode(request)
    ListPrompts(request) -> defs.list_prompts_request_encode(request)
    GetPrompt(request) -> defs.get_prompt_request_encode(request)
    ListTools(request) -> defs.list_tools_request_encode(request)
    CallTool(request) -> defs.call_tool_request_encode(request)
    SetLevel(request) -> defs.set_level_request_encode(request)
    Complete(request) -> defs.complete_request_encode(request)
  }
  #(method, Some(params))
}

fn do_notification_encode(notification) {
  let method = notification_method(notification)
  let params = case notification {
    Cancelled(n) -> defs.cancelled_notification_encode(n)
    Initialized(n) -> defs.initialized_notification_encode(n)
    Progress(n) -> defs.progress_notification_encode(n)
    RootsListChanged(n) -> defs.roots_list_changed_notification_encode(n)
  }
  #(method, Some(params))
}

fn notification_decoders() {
  [
    #(
      "notifications/cancelled",
      defs.cancelled_notification_decoder() |> decode.map(Cancelled),
    ),
    #(
      "notifications/initialized",
      defs.initialized_notification_decoder() |> decode.map(Initialized),
    ),
    #(
      "notifications/progress",
      defs.progress_notification_decoder() |> decode.map(Progress),
    ),
    #(
      "notifications/roots/list_changed",
      defs.roots_list_changed_notification_decoder()
        |> decode.map(RootsListChanged),
    ),
  ]
}

fn request_decoders() {
  [
    #("initialize", defs.initialize_request_decoder() |> decode.map(Initialize)),
    #("ping", defs.ping_request_decoder() |> decode.map(Ping)),
    #(
      "resources/list",
      defs.list_resources_request_decoder() |> decode.map(ListResources),
    ),
    #(
      "resources/templates/list",
      defs.list_resource_templates_request_decoder()
        |> decode.map(ListResourceTemplates),
    ),
    #(
      "resources/read",
      defs.read_resource_request_decoder()
        |> decode.map(ReadResource),
    ),
    #(
      "resources/subscribe",
      defs.subscribe_request_decoder()
        |> decode.map(Subscribe),
    ),
    #(
      "resources/unsubscribe",
      defs.unsubscribe_request_decoder()
        |> decode.map(Unsubscribe),
    ),
    #(
      "prompts/list",
      defs.list_prompts_request_decoder() |> decode.map(ListPrompts),
    ),
    #("prompts/get", defs.get_prompt_request_decoder() |> decode.map(GetPrompt)),
    #("tools/list", defs.list_tools_request_decoder() |> decode.map(ListTools)),
    #("tools/call", defs.call_tool_request_decoder() |> decode.map(CallTool)),
    #(
      "logging/setLevel",
      defs.set_level_request_decoder() |> decode.map(SetLevel),
    ),
    #(
      "completion/complete",
      defs.complete_request_decoder() |> decode.map(Complete),
    ),
  ]
}

fn finish_call_tool(reply) {
  let result = case reply {
    Ok(reply) -> {
      let content =
        u.Object(reply)
        |> u.any_to_json
        |> json.to_string

      defs.CallToolResult(
        meta: None,
        structured_content: Some(reply),
        content: [
          text_content(content),
        ],
        is_error: Some(False),
      )
    }
    Error(reason) ->
      defs.CallToolResult(
        meta: None,
        structured_content: None,
        content: [
          text_content(reason),
        ],
        is_error: Some(True),
      )
  }
  Ok(CallToolResult(result))
}

fn finish_read_resource(resource, contents) {
  let defs.Resource(uri:, ..) = resource
  effect.resource_contents_to_result(uri, contents)
  |> ReadResourceResult
  |> Ok
}

fn finish_get_prompt(prompt, messages) {
  let defs.Prompt(description:, ..) = prompt

  let result = defs.GetPromptResult(meta: None, description:, messages:)
  Ok(GetPromptResult(result))
}

fn text_content(content) {
  u.Object(
    dict.from_list([
      #("type", u.String("text")),
      #("text", u.String(content)),
    ]),
  )
}

pub fn handle_notification(notification, _server) {
  case notification {
    Cancelled(_message) -> Nil
    Initialized(_message) -> Nil
    Progress(_message) -> Nil
    RootsListChanged(_message) -> Nil
  }
}

fn initialize(_message, server) {
  let Server(implementation:, ..) = server
  defs.InitializeResult(
    protocol_version: "2025-06-18",
    meta: None,
    instructions: None,
    capabilities: defs.ServerCapabilities(
      completions: Some(dict.new()),
      experimental: None,
      logging: Some(dict.new()),
      prompts: Some(defs.Anon405cc9c3(list_changed: Some(True))),
      tools: Some(defs.Anon405cc9c3(list_changed: Some(False))),
      resources: Some(defs.Anon3889ba9d(
        subscribe: Some(False),
        list_changed: Some(False),
      )),
    ),
    server_info: implementation,
  )
}

fn list_tools(_message, server) {
  let Server(tools:, ..) = server
  defs.ListToolsResult(
    meta: None,
    next_cursor: None,
    tools: list.map(tools, to_api_definition),
  )
}

fn call_tool(message, server) {
  let defs.CallToolRequest(name:, arguments:) = message
  case get_tool_by_name(server, name) {
    Ok(u.Tool(decoder:, ..)) -> {
      let arguments =
        arguments
        |> option.unwrap(dict.new())
        |> u.Object
        |> u.any_to_dynamic
      case decode.run(arguments, decoder) {
        Ok(args) -> Ok(args)
        Error(reason) -> Error(reason.invalid_arguments(name, reason))
      }
    }
    Error(Nil) -> Error(reason.unknown_tool(name))
  }
}

fn list_resources(_cursor, server) {
  let Server(resources:, ..) = server
  defs.ListResourcesResult(meta: None, resources:, next_cursor: None)
}

fn list_resource_templates(_cursor, server) {
  let Server(resource_templates:, ..) = server
  defs.ListResourceTemplatesResult(
    meta: None,
    resource_templates:,
    next_cursor: None,
  )
}

fn read_resource(message, server) {
  let Server(resources:, ..) = server
  let defs.ReadResourceRequest(uri:) = message

  list.find_map(resources, fn(resource) {
    let defs.Resource(uri: u, ..) = resource
    case uri == u {
      True -> Ok(resource)
      False -> Error(Nil)
    }
  })
  |> result.replace_error(reason.resource_not_found(uri))
}

fn list_prompts(message, server) {
  let Server(prompts:, ..) = server
  let defs.ListPromptsRequest(cursor: _) = message

  let prompts = list.map(prompts, pair.first)
  defs.ListPromptsResult(meta: None, prompts:, next_cursor: None)
}

fn get_prompt(message, server) {
  let defs.GetPromptRequest(name:, arguments:) = message
  case get_prompt_by_name(server, name) {
    Ok(#(prompt, decoder)) -> {
      let arguments =
        arguments
        |> option.unwrap(dict.new())
        |> dict.map_values(fn(_k, v) { u.String(v) })
        |> u.Object
        |> u.any_to_dynamic
      case decode.run(arguments, decoder) {
        Ok(args) -> Ok(#(prompt, args))
        Error(reason) -> Error(reason.invalid_arguments(name, reason))
      }
    }
    Error(Nil) -> Error(reason.unknown_prompt(name))
  }
}

fn complete(message) {
  let defs.CompleteRequest(context:, argument:, ref:) = message

  let defs.Anon68f425dd(name:, value:) = argument
  let argument = effect.CompleteArgument(name:, value:)

  let context = case context {
    Some(defs.Anon4c2c4139(arguments: Some(previous))) -> previous
    _ -> dict.new()
  }
  let assert u.Object(properties) = ref
  let assert Ok(u.String(type_)) = dict.get(properties, "type")
  case type_ {
    "ref/resource" -> {
      let assert Ok(u.String(uri)) = dict.get(properties, "uri")
      let ref = effect.ResourceTemplateReference(uri)

      effect.Complete(ref:, argument:, context:, resume: finish_complete)
    }
    _ ->
      reason.method_not_available("completion/complete") |> Error |> effect.Done
  }
}

fn finish_complete(completion) {
  complete_results(completion)
  |> CompleteResult
  |> Ok
}

fn complete_results(values) {
  let total = list.length(values)
  let #(values, has_more) = case total > 100 {
    True -> #(list.take(values, 100), True)
    False -> #(values, False)
  }
  defs.AnonA60b75a3(values:, has_more: Some(has_more), total: Some(total))
  |> defs.CompleteResult(None, _)
}

fn set_level(message) {
  let defs.SetLevelRequest(level:) = message
  case log.from_string(level) {
    Ok(level) -> {
      io.println("client set log level: " <> log.to_string(level))
      // PingResponse is empty object
      Ok(PingResponse)
    }
    Error(Nil) -> Error(reason.invalid_log_level(level))
  }
}
