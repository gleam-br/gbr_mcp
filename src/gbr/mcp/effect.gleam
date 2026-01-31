////
//// MCP tool effects
////

import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/option.{type Option, None}

import gbr/shared/utils as u

import gbr/mcp/gen/defs

/// TODO
///
pub type Effect(return, tool, prompt) {
  Done(message: return)
  CallTool(
    tool: tool,
    resume: fn(Result(Dict(String, u.Any), String)) -> return,
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

pub type CompleteArgument {
  CompleteArgument(name: String, value: String)
}

pub type CompletionReference {
  PromptReference(name: String, title: Option(String))
  ResourceTemplateReference(uri: String)
}

pub type ResourceContents {
  TextContents(mime_type: String, text: String)
  BlobContents(mime_type: String, blob: BitArray)
}

pub fn resource_contents_to_result(uri, contents) {
  case contents {
    TextContents(mime_type:, text:) ->
      defs.ReadResourceResult(meta: None, contents: [
        u.Object(
          dict.from_list([
            #("uri", u.String(uri)),
            #("text", u.String(text)),
            #("mime_type", u.String(mime_type)),
          ]),
        ),
      ])
    BlobContents(mime_type:, blob:) ->
      defs.ReadResourceResult(meta: None, contents: [
        u.Object(
          dict.from_list([
            #("uri", u.String(uri)),
            #("blob", u.String(bit_array.base64_encode(blob, False))),
            #("mime_type", u.String(mime_type)),
          ]),
        ),
      ])
  }
}
