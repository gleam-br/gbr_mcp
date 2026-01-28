////
//// MCP JSON schema loader
////

import gleam/io
import gleam/json
import gleam/result
import gleam/string

import simplifile

import gbr/mcp/generator
import gbr/shared/error

//const const_mcp_schema_date = "2025-11-25" // new
const const_mcp_schema_date = "2025-06-18"

// const const_mcp_schema_field = "$defs" // new
const const_mcp_schema_field = "definitions"

const const_mcp_file_path = "./priv/" <> const_mcp_schema_date <> "-schema.json"

const const_mcp_defs_output = "./src/gbr/mcp/gen/defs.gleam"

// TODO: dynamic read mcp schema
// - download from `const_mcp_schema_url`
// - read content and load
// - pub fn load_url
// - pub fn load_url_write
//
// MCP json schema url
// const const_mcp_schema_url = "https://github.com/modelcontextprotocol/modelcontextprotocol"
//   <> "/blob/main/schema/"
//   <> const_mcp_schema_date
//   <> "/schema.json"

/// Run load MCP JSON-RPC schema from file in `priv/` and write to `src/gbr/mcp/gen`.
///
pub fn main() {
  case
    load_file_write(
      const_mcp_file_path,
      const_mcp_schema_field,
      const_mcp_defs_output,
    )
  {
    Ok(Nil) -> io.println("[OK] Write defs code in " <> const_mcp_defs_output)
    Error(err) -> io.println_error(err)
  }
}

/// Read file path content, load and write definitions gleam code in output.
///
/// - path: File path to mcp json schema.
/// - field: JSON schema field to load.
/// - output: File path output to gleam code.
///
pub fn load_file_write(
  path: String,
  field: String,
  output: String,
) -> Result(Nil, String) {
  path
  |> load_file(field)
  |> result.map(write_output(_, output))
  |> result.flatten()
}

/// Read file path content, load and write definitions gleam code in output.
///
/// - path: File path to mcp json schema.
/// - field: JSON schema field to load.
///
pub fn load_file(path: String, field: String) {
  path
  |> read_path()
  |> result.map(load(_, field))
  |> result.flatten()
}

/// Content load and write definitions gleam code in output.
///
/// - schema: MCP json schema content.
/// - field: JSON schema field to load.
/// - output: File path output to gleam code.
///
pub fn load_write(schema: String, field: String, output: String) {
  load(schema, field)
  |> result.map(fn(c) {
    simplifile.write(output, c)
    |> result.map_error(fn(err) {
      "Error writing " <> output <> ": " <> string.inspect(err)
    })
  })
  |> result.flatten()
}

/// Load MCP schema from origin url and gen defs.gleam file.
///
/// - schema: MCP json schema content.
/// - field: MCP schema field to load.
///
pub fn load(schema: String, field: String) -> Result(String, String) {
  let decode =
    field
    |> generator.json_schema_decoder()

  // MCP JSON-RPC definitions
  use definitions <- result.try(
    json.parse(schema, decode)
    |> result.map_error(error.json_to_string),
  )

  // MCP JSON-RPC definitions to gleam code
  definitions
  |> generator.values_map()
  |> generator.gen_schema_file()
  |> generator.run_location("#/" <> field <> "/")
}

// PRIVATE
//

fn read_path(path) {
  path
  |> simplifile.read()
  |> result.map_error(fn(err) {
    "[ERR] Reading " <> path <> ": " <> string.inspect(err)
  })
}

fn write_output(c, output) {
  simplifile.write(output, c)
  |> result.map_error(fn(err) {
    "[ERR] Writing " <> output <> ": " <> string.inspect(err)
  })
}
