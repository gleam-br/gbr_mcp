////
//// MCP JSON-RPC to Gleam code generator
////

import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

import castor
import glance
import glance_printer

import oas/generator
import oas/generator/lookup as l
import oas/generator/schema

/// TODO
///
pub fn run_location(schema, location) -> Result(String, String) {
  generator.run_single_location(schema, location)
  |> result.map(header_content)
}

/// Generate schema file to TODO
///
pub fn gen_schema_file(schemas) -> l.Lookup(String) {
  use #(custom_types, type_aliases, functions) <- l.then(schema.generate(
    schemas,
  ))

  glance.Module(
    imports(),
    defs(custom_types),
    defs(type_aliases),
    [],
    defs(functions),
  )
  |> glance_printer.print
  |> l.Done
}

/// JSON-RPC schema from field name
///
/// - field: Field name from JSON-RPC decoder
///
pub fn json_schema_decoder(
  field,
) -> decode.Decoder(dict.Dict(String, castor.Schema)) {
  decode.field(
    field,
    decode.dict(decode.string, castor.decoder()),
    decode.success,
  )
}

/// JSON-RPC definitions map with lift values.
///
/// > Throw panic if not is definition JSON-RPC.
///
pub fn values_map(defs) {
  defs
  |> dict.map_values(fn(key, value) { values_lift(key, value) })
}

/// Lift key/value values from JSON-RPC definition.
///
pub fn values_lift(key, value) {
  case is_request(key) || is_notification(key) {
    True -> lift_params(value)
    False -> value
  }
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
        _, _, _ ->
          panic as "[ERR] Def. should be method: string and params: object"
      }
    _ -> panic as "[ERR] Def. should be request: object"
  }
}

fn imports() {
  [
    glance.Definition([], glance.Import("gleam/dict", None, [], [])),
    glance.Definition([], glance.Import("gleam/dynamic/decode", None, [], [])),
    glance.Definition([], glance.Import("gleam/json", None, [], [])),
    glance.Definition(
      [],
      glance.Import(
        "gleam/option",
        None,
        [glance.UnqualifiedImport("Option", None)],
        [glance.UnqualifiedImport("None", None)],
      ),
    ),
    glance.Definition([], glance.Import("gbr/shared/utils", None, [], [])),
  ]
}

fn defs(xs) {
  list.map(xs, glance.Definition([], _))
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
