////
//// MCP definitions helper type and functions
////

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}

import gbr/shared/utils

import gbr/json/schema/domain

import gbr/mcp/gen/defs

/// JSON-RPC request definition
///
pub type ReqDef =
  #(String, domain.Ref(domain.Schema), Bool)

/// JSON-RPC object definition
///
pub type ObjDef =
  List(ReqDef)

/// The specification for an MCP tool.
///
pub type Spec {
  Spec(
    name: String,
    title: String,
    description: String,
    input: ObjDef,
    output: ObjDef,
  )
}

/// The spec and decoder of an MCP tool.
///
/// Tools are defined with only a decoder because implementations of a tool
/// can be sync or async.
///
/// See `Effect` for implementing tool handling.
///
pub type Tool(t) {
  Tool(spec: Spec, decoder: decode.Decoder(t))
}

/// TODO
///
pub type Effect(return, tool, prompt) {
  Done(message: return)
  CallTool(
    tool: tool,
    resume: fn(Result(Dict(String, utils.Any), String)) -> return,
  )
  ReadResource(resource: defs.Resource, resume: fn(ResourceContents) -> return)
  GetPrompt(
    prompt: prompt,
    // There is no "is_error" field on GetPromptReply.
    resume: fn(List(defs.PromptMessage)) -> return,
  )
  Complete(
    ref: CompletionReference,
    argument: CompleteArgument,
    context: Dict(String, String),
    resume: fn(List(String)) -> return,
  )
}

/// TODO
///
pub type CompleteArgument {
  CompleteArgument(name: String, value: String)
}

/// TODO
///
pub type CompletionReference {
  PromptReference(name: String, title: Option(String))
  ResourceTemplateReference(uri: String)
}

/// TODO
///
pub type ResourceContents {
  TextContents(mime_type: String, text: String)
  BlobContents(mime_type: String, blob: BitArray)
}

/// Set title to definition.Tool
///
pub fn set_title(tool, title) {
  defs.Tool(..tool, title: Some(title))
}

/// Set description to definition.Tool
///
pub fn set_description(tool, description) {
  defs.Tool(..tool, description: Some(description))
}

pub fn to_api_definition(tool) {
  let Tool(spec:, ..) = tool
  defs.Tool(
    name: spec.name,
    title: Some(spec.title),
    description: Some(spec.description),
    input_schema: cast_schema(spec.input),
    output_schema: Some(cast_schema(spec.output)),
    meta: None,
    annotations: None,
  )
}

/// TODO
///
pub fn resource_contents_to_result(uri, contents) {
  case contents {
    TextContents(mime_type:, text:) ->
      defs.ReadResourceResult(meta: None, contents: [
        utils.Object(
          dict.from_list([
            #("uri", utils.String(uri)),
            #("text", utils.String(text)),
            #("mime_type", utils.String(mime_type)),
          ]),
        ),
      ])
    BlobContents(mime_type:, blob:) ->
      defs.ReadResourceResult(meta: None, contents: [
        utils.Object(
          dict.from_list([
            #("uri", utils.String(uri)),
            #("blob", utils.String(bit_array.base64_encode(blob, False))),
            #("mime_type", utils.String(mime_type)),
          ]),
        ),
      ])
  }
}

// PRIVATE
//

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

  let properties =
    properties
    |> dict.from_list()
    |> Some()

  defs.AnonA5a007cd(type_: "object", required: Some(required), properties:)
}
