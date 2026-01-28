////
//// MCP schema loader from url:
////
//// https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/schema/2024-11-05/schema.json
////

import gleam/dict
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

import castor
import simplifile

import oas/generator

const const_mcp_schema_date = "2025-06-18"

// todo
//const const_mcp_schema_date = "2025-11-25"

const const_mcp_schema_field = "definitions"

// todo download from github mcp schema
//const const_mcp_schema_field = "$defs"
// const const_mcp_schema_url = "https://github.com/modelcontextprotocol/modelcontextprotocol"
//   <> "/blob/main/schema/"
//   <> const_mcp_schema_date
//   <> "/schema.json"

const const_mcp_file_path = "./priv/" <> const_mcp_schema_date <> "-schema.json"

const const_mcp_defs_output = "./src/gbr/mcp/defs.gleam"

pub fn main() {
  // TODO dynamic read mcp schema
  // download from `const_mcp_schema_url`
  // read content and load
  // pub fn load_url
  // pub fn load_url_write

  case
    load_file_write(
      const_mcp_file_path,
      const_mcp_schema_field,
      const_mcp_defs_output,
    )
  {
    Ok(Nil) -> io.println("> OK defs code in " <> const_mcp_defs_output)
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
  |> read_path()
  |> result.map(load(_, field))
  |> result.flatten()
  |> result.map(write_output(_, output))
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
  let decoder =
    decode.field(
      field,
      decode.dict(decode.string, castor.decoder()),
      decode.success,
    )

  // TODO extract the constant value for each request type
  let assert Ok(definitions) = json.parse(schema, decoder)
  let definitions =
    dict.map_values(definitions, fn(key, value) {
      case is_request(key) || is_notification(key) {
        True -> lift_params(value)
        False -> value
      }
    })

  generator.gen_schema_file(definitions)
  |> generator.run_single_location("#/" <> field <> "/")
  |> result.map(header_content)
}

// PRIVATE
//

fn read_path(path) {
  path
  |> simplifile.read()
  |> result.map_error(fn(err) {
    "Error reading " <> path <> ": " <> string.inspect(err)
  })
}

fn write_output(c, output) {
  simplifile.write(output, c)
  |> result.map_error(fn(err) {
    "Error writing " <> output <> ": " <> string.inspect(err)
  })
}

fn is_request(key) {
  case string.ends_with(key, "Request"), key {
    _, "ClientRequest" | _, "ServerRequest" | _, "JSONRPCRequest" -> False
    True, _ -> True
    False, _ -> False
  }
}

fn is_notification(key) {
  case string.ends_with(key, "Notification"), key {
    _, "ClientNotification" | _, "ServerNotification" | _, "JSONRPCNotification"
    -> False
    True, _ -> True
    False, _ -> False
  }
}

fn lift_params(value) {
  case value {
    castor.Object(properties: p, ..) ->
      case dict.size(p), dict.get(p, "method"), dict.get(p, "params") {
        2, Ok(castor.Inline(castor.String(..))), Ok(castor.Inline(params)) ->
          params
        _, _, _ -> panic as "method and params should be string and object"
      }
    _ -> panic as "Request should be an object"
  }
}

fn header_content(contents) {
  "// Licensed under the Lucid License (Individual Sovereignty & Non-Aggression)
// See LICENSE file in the root of the repository.
//......................=#%%*:...............................
//....................:#@%##@@+..............................
//....................=@%****%@#.............................
//...................:@@#+=+**#@@=...........................
//...................*@#*===+***@@#..........................
//..................-@@*=====+***%@%-........................
//..................@@*=---==++***#@@*:......................
//.................*@#=-::--==+++***#@@@@@@@@@@@@@@@%+:......
//................+@@-:.:::--=++++************######%@%:.....
//.............+#@@%-:...:::--=++++++************###%@@-.....
//........:*%@@@%+-:......::--==+++++++++++++++*###%@@*......
//....-#@@@@%*+=:.........:::--=+++++++++++++======@@*.......
//..+@@@#*++=::::::......::::::.:::::::::::::-===+@@+........
//.:@@#**+=====--::::..........:::::-++=-:::-===+@@=.........
//.:%@%%##**+++=-:...........::::::*%*+#%=:-===*@@-..........
//..:*@@@%##*+-:::::-#%%#=::::::::=%+:::++-===*@%-...........
//.....+@@@#==--:::-@*::+@=::-::++::::::::-===@%-............
//.......-%@@*====--%-:::-::=#++#%:::::::-===+@#:............
//.........:#@@#==-::::::::::-**=-=+++++++####@@=............
//............#@@*=-:::::::::-=+++++++++++*###%@#:...........
//.............-@%+=-::::::-+++++++++++++++*##%@@-...........
//.............:%@+=-::::-++++++++++++++++++###%@#...........
//.............:#@+=-::-=++++**########***++*##%@@=..........
//..............#@*==:-+++*#####################%@@..........
//..............*@*==-++*#####%%@@@@@@%%#########@@=.........
//..............+@*==+######%@@@#-:-*%@@@@@@%%##%@@-.........
//..............=@#=+#####%@@%=..........:=#@@@@@@-..........
//..............=@#=*##%@@@#:................................
//..............:%@*%%@@%=...................................
//...............:*%%%*:.....................................
//
//
//###########################################################
//# Code auto generate with love by Gleam BR in:
//# " <> timestamp.system_time()
  |> timestamp.to_rfc3339(duration.minutes(0)) <> "
//###########################################################
//
" <> contents
}
