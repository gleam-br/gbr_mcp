# 🧠 MCP Server/Client builder

[![Package Version](https://img.shields.io/hexpm/v/gbr_mcp)](https://hex.pm/packages/gbr_mcp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gbr_mcp/)

## Roadmap

- [ ] Update json schema to https://json-schema.org/draft/2020-12/schema
  - [ ] Lib `castor` not decode this draft, only https://json-schema.org/draft/draft-07/schema.
```sh
gleam add gbr_mcp@1
```
```gleam
import gbr/mcp/loader

pub fn main() -> Nil {
  let path = "./priv/2025-06-18-schema.json"
  let field = "definitions"
  let output = "./src/gbr/mcp/defs.gleam"

  case loader.load_file_write(path, field, output) {
    Ok(Nil) -> io.println("> Definitions write to " <> output)
    Error(err) -> io.println_error(err)
  }
}
```

Further documentation can be found at <https://hexdocs.pm/gbr_mcp>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
