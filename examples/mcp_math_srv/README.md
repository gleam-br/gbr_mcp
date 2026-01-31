# MCP Server: Math Tools

An example MCP server with math tools.

## Build & Run

```sh
gleam build
gleam run
```

## Develop

Install easy [watchexec](https://github.com/watchexec/watchexec) and:

```sh
watchexec -r -e erl,mjs,gleam -- gleam run
```

## Testing

## Check server up

- Open your browser clicking [http://localhost:8080](http://localhost:8080).

## Sending requests

### Listing tools:
- URL: http://localhost:8080/mcp
- Method: POST
- Content-Type: application/json
- Body:
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "tools/list",
}
```
- Response:
```json
{
    "jsonrpc": "2.0",
    "id": "1",
    "result": {
        "tools": [
            {
                "description": "Generate a random number between two numbers",
                "inputSchema": {
                    "properties": {},
                    "required": [],
                    "type": "object"
                },
                "name": "random",
                "outputSchema": {
                    "properties": {
                        "number": {
                            "type": "integer",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "number"
                    ],
                    "type": "object"
                },
                "title": "Generate Random"
            },
            {
                "description": "Add two numbers",
                "inputSchema": {
                    "properties": {
                        "y": {
                            "type": "integer",
                            "nullable": false,
                            "deprecated": false
                        },
                        "x": {
                            "type": "integer",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "y",
                        "x"
                    ],
                    "type": "object"
                },
                "name": "add",
                "outputSchema": {
                    "properties": {
                        "sum": {
                            "type": "integer",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "sum"
                    ],
                    "type": "object"
                },
                "title": "Add"
            }
        ]
    }
}
```

### Call tool
- URL: http://localhost:8080/mcp
- Method: POST
- Content-Type: application/json
- Body:
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "tools/call",
  "params": {
    "name": "random"
  }
}
```
Response:
```json
{
  "jsonrpc":"2.0",
  "id":"2",
  "result": {
    "content":[{
      "type":"text",
      "text":"{\"number\":64}"
    }],
    "structuredContent": { "number": 64 },
    "isError": false
  }
}
```
