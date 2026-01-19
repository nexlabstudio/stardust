---
title: stardust openapi
description: Generate API documentation from OpenAPI/Swagger specifications.
---

# stardust openapi

Generate Stardust documentation from OpenAPI (Swagger) specifications.

## Usage

```bash
stardust openapi <spec> [options]
```

Where `<spec>` is a path to a local file or a URL to an OpenAPI specification.

## Examples

### From Local File

```bash
stardust openapi ./api/openapi.yaml -o docs/api
```

### From URL

```bash
stardust openapi https://api.example.com/openapi.json -o docs/api
```

### With Options

```bash
stardust openapi openapi.yaml \
  --output docs/api \
  --group-by tag \
  --include-schemas
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `-o, --output <dir>` | `docs/api` | Output directory for generated files |
| `--group-by <method>` | `path` | Group endpoints by: `tag`, `path`, or `method` |
| `--include-schemas` | `false` | Generate pages for schema definitions |
| `--base-path <path>` | - | Prefix for all endpoint paths |
| `--no-overwrite` | `false` | Don't overwrite existing files |

## Supported Specifications

| Format | Versions |
|--------|----------|
| OpenAPI | 3.0, 3.1 |
| Swagger | 2.0 |

Both YAML and JSON files are supported.

## Output Organization

### Group by Path (default)

```bash
stardust openapi openapi.yaml --group-by path
```

```
docs/api/
├── index.md
├── users/
│   ├── list.md       # GET /users
│   ├── create.md     # POST /users
│   └── get.md        # GET /users/{id}
└── orders/
    ├── list.md       # GET /orders
    └── create.md     # POST /orders
```

### Group by Tag

```bash
stardust openapi openapi.yaml --group-by tag
```

Organizes by the `tags` defined in your OpenAPI spec:

```
docs/api/
├── index.md
├── user-management/  # "User Management" tag
│   ├── list-users.md
│   └── create-user.md
└── orders/           # "Orders" tag
    └── create-order.md
```

### Group by Method

```bash
stardust openapi openapi.yaml --group-by method
```

```
docs/api/
├── index.md
├── get/
│   ├── users.md
│   └── orders.md
├── post/
│   ├── users.md
│   └── orders.md
└── delete/
    └── users.md
```

## Generated Content

Each endpoint page includes:

- HTTP method and path
- Description from spec
- Parameters (path, query, header, body)
- Request body schema
- Response schemas
- Authentication requirements
- Example requests/responses (if in spec)

### Example Generated Page

```markdown
---
title: Get User
description: Retrieve a user by ID
---

# Get User

<Api method="GET" path="/users/{id}" auth="Bearer Token">
  Retrieve a user by their unique identifier.

  <ParamField name="id" type="string" paramType="path" required>
    The user's unique identifier.
  </ParamField>

  <ResponseField name="id" type="string">
    User ID.
  </ResponseField>
  <ResponseField name="email" type="string">
    User's email address.
  </ResponseField>
</Api>
```

## Including Schemas

Generate pages for reusable schemas:

```bash
stardust openapi openapi.yaml --include-schemas
```

Creates additional pages in `docs/api/schemas/`:

```
docs/api/
├── index.md
├── users/
│   └── ...
└── schemas/
    ├── User.md
    ├── Order.md
    └── Error.md
```

## Preserving Custom Content

Use `--no-overwrite` to keep manual edits:

```bash
stardust openapi openapi.yaml --no-overwrite
```

This skips files that already exist, letting you:
- Add custom examples
- Include additional notes
- Modify descriptions

<Warning>
Without `--no-overwrite`, running the command again will replace all generated files.
</Warning>

## Workflow

<Steps>
  <Step title="Generate initial docs">
    ```bash
    stardust openapi openapi.yaml -o docs/api
    ```
  </Step>
  <Step title="Add to sidebar">
    ```yaml
    sidebar:
      - group: API Reference
        autogenerate:
          dir: api
    ```
  </Step>
  <Step title="Customize as needed">
    Edit generated files to add examples, notes, or additional context.
  </Step>
  <Step title="Regenerate when spec changes">
    ```bash
    stardust openapi openapi.yaml -o docs/api --no-overwrite
    ```
  </Step>
</Steps>

## Troubleshooting

### Invalid Specification

If you get parsing errors:
- Validate your spec at [editor.swagger.io](https://editor.swagger.io)
- Check for syntax errors in YAML/JSON
- Ensure required fields are present

### Missing Endpoints

If endpoints are missing:
- Check if they have the `deprecated: true` flag
- Verify paths are properly defined
- Look for specification validation warnings

### URL Access Issues

If fetching from URL fails:
- Check the URL is accessible
- Verify no authentication is required
- Try downloading the file locally first
