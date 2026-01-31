# MCP Server: Hello Tools

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
                "description": "Say hello world by gleam-br",
                "inputSchema": {
                    "properties": {},
                    "required": [],
                    "type": "object"
                },
                "name": "world",
                "outputSchema": {
                    "properties": {
                        "message": {
                            "type": "string",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "message"
                    ],
                    "type": "object"
                },
                "title": "Hello World"
            },
            {
                "description": "Say hello to greetings welcome to glem-br",
                "inputSchema": {
                    "properties": {
                        "greetings": {
                            "type": "string",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "greetings"
                    ],
                    "type": "object"
                },
                "name": "welcome",
                "outputSchema": {
                    "properties": {
                        "message": {
                            "type": "string",
                            "nullable": false,
                            "deprecated": false
                        }
                    },
                    "required": [
                        "message"
                    ],
                    "type": "object"
                },
                "title": "Hello welcome greetings"
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
    "name": "welcome",
    "arguments": { "greetings": "Paulo R. A. Sales" }
  }
}
```
Response:
```json
{
  "jsonrpc":"2.0",
  "id":"1",
  "result":{
    "content":[
      {
        "type":"text",
        "text": "{\"message\":\"Hello Paulo R. A. Sales, welcome to gleam-br\"}"
      }
    ],
    "isError":false,
    "structuredContent": {
      "message": "Hello Paulo, welcome to gleam-br"
    }
  }
}
```
