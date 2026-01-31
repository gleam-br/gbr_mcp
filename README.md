[![Package Version](https://img.shields.io/hexpm/v/gbr_mcp)](https://hex.pm/packages/gbr_mcp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gbr_mcp/)

# 🧠 MCP Server/Client builder

MCP (Model Context Protocol) is an open-source standard for connecting AI
applications to external systems.

Using MCP, AI applications like Claude or ChatGPT can connect to data
sources (e.g. local files, databases), tools (e.g. search engines, calculators)
and workflows (e.g. specialized prompts)—enabling them to access key
information and perform tasks.

> Think of MCP like a USB-C port for AI applications.

Just as USB-C provides a standardized way to connect electronic devices,
MCP provides a standardized way to connect AI applications to external systems.

> more: https://modelcontextprotocol.io/docs/getting-started/intro

## 💡 Working in progress

- [ ] 🩺 Update MCP json schema to 2025-11-25: parser error
- [ ] 🔧 Client MCP comming soon...


## 🚀 Installing

```sh
gleam add gbr_mcp@1
```

## 🛠️ Usage

### 🧩 MCP JSON Schema Loading

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

### 📡 MCP JSON-RPC Server

- [Example: Wisp Mist Server with Hello Tools](./examples/mcp_hello_srv)
- [Example: Wisp Mist Server with Math Tools](./examples/mcp_hello_srv)
- More examples comming soon...

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
