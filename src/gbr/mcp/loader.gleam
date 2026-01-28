////
//// MCP schema loader from url:
////
//// https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/schema/2024-11-05/schema.json
////

import gleam/dict
import gleam/dynamic/decode
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

// todo
//const const_mcp_schema_field = "$defs"

const const_mcp_schema_url = "https://github.com/modelcontextprotocol/modelcontextprotocol"
  <> "/blob/main/schema/"
  <> const_mcp_schema_date
  <> "/schema.json"

const const_mcp_file_path = "./priv/" <> const_mcp_schema_date <> "-schema.json"

const const_mcp_defs_output = "./src/gbr/mcp/defs.gleam"

pub fn main() {
  // TODO dynamic read mcp schema
  // download from `const_mcp_schema_url`
  // read content and load
  use content <- result.try(simplifile.read(const_mcp_file_path))

  load(content, const_mcp_schema_field, const_mcp_defs_output)
}

/// Load MCP schema from origin url and gen defs.gleam file.
///
/// - file_path
///
pub fn load(content, json_field, output) {
  let decoder =
    decode.field(
      json_field,
      decode.dict(decode.string, castor.decoder()),
      decode.success,
    )

  // TODO extract the constant value for each request type
  let assert Ok(definitions) = json.parse(content, decoder)
  let definitions =
    dict.map_values(definitions, fn(key, value) {
      case is_request(key) || is_notification(key) {
        True -> lift_params(value)
        False -> value
      }
    })

  let assert Ok(contents) =
    generator.gen_schema_file(definitions)
    |> generator.run_single_location("#/" <> json_field <> "/")

  let contents = "
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

  let assert Ok(Nil) = simplifile.write(output, contents)
}

// PRIVATE
//

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
