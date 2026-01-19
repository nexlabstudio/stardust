---
title: OpenAPI Import
description: Generate API documentation from OpenAPI/Swagger specifications.
---

# OpenAPI Import

Automatically generate beautiful API documentation from your OpenAPI (Swagger) specifications.

## Quick Start

Convert an OpenAPI spec to Stardust documentation:

```bash
stardust openapi openapi.yaml -o docs/api
```

This creates markdown files for each endpoint with:
- Method and path
- Description
- Parameters with types
- Request/response schemas
- Authentication requirements

## Supported Formats

Stardust supports:

- **OpenAPI 3.0** and **3.1** (recommended)
- **Swagger 2.0**
- **YAML** and **JSON** formats

## Basic Usage

### From Local File

```bash
stardust openapi ./api/openapi.yaml -o docs/api
```

### From URL

```bash
stardust openapi https://api.example.com/openapi.json -o docs/api
```

## Output Structure

Given this OpenAPI spec:

```yaml
paths:
  /users:
    get:
      summary: List users
    post:
      summary: Create user
  /users/{id}:
    get:
      summary: Get user
    put:
      summary: Update user
    delete:
      summary: Delete user
```

Stardust generates:

```
docs/api/
├── index.md           # API overview
├── users/
│   ├── list.md        # GET /users
│   ├── create.md      # POST /users
│   ├── get.md         # GET /users/{id}
│   ├── update.md      # PUT /users/{id}
│   └── delete.md      # DELETE /users/{id}
```

## Generated Documentation

Each endpoint page includes:

<Api method="GET" path="/users/{id}">
  Get a user by their unique identifier.

  <ParamField name="id" type="string" paramType="path" required>
    The user's unique identifier.
  </ParamField>

  <ResponseField name="id" type="string">
    User ID.
  </ResponseField>
  <ResponseField name="email" type="string">
    User's email address.
  </ResponseField>
  <ResponseField name="name" type="string">
    User's display name.
  </ResponseField>
</Api>

## Command Options

```bash
stardust openapi <spec> [options]
```

| Option | Description |
|--------|-------------|
| `-o, --output <dir>` | Output directory (default: `docs/api`) |
| `--group-by <method>` | Group by `tag`, `path`, or `method` |
| `--include-schemas` | Generate pages for schema definitions |
| `--base-path <path>` | Base path prefix for all endpoints |

### Group by Tag

Organize endpoints by their OpenAPI tags:

```bash
stardust openapi openapi.yaml -o docs/api --group-by tag
```

Output:

```
docs/api/
├── index.md
├── users/           # "Users" tag
│   ├── list.md
│   └── create.md
├── orders/          # "Orders" tag
│   ├── list.md
│   └── create.md
```

## Sidebar Integration

Add the generated API docs to your sidebar:

```yaml
sidebar:
  - group: API Reference
    autogenerate:
      dir: api
```

Or manually list important endpoints:

```yaml
sidebar:
  - group: API Reference
    pages:
      - api/index
      - api/users/list
      - api/users/create
      - api/authentication
```

## Customizing Output

### Override Generated Pages

Edit the generated markdown files to add:
- Additional examples
- Custom descriptions
- Warnings or notes
- Code samples

<Warning>
Re-running `stardust openapi` will overwrite changes. Keep custom content in separate files or use the `--no-overwrite` flag.
</Warning>

### Add Authentication Docs

Create `docs/api/authentication.md` manually:

```markdown
---
title: Authentication
---

# Authentication

All API requests require authentication via Bearer token.

## Getting a Token

```bash
curl -X POST https://api.example.com/auth/token \
  -d '{"email": "user@example.com", "password": "secret"}'
```
```

## Continuous Integration

Regenerate API docs when your spec changes:

```yaml
# .github/workflows/docs.yml
- name: Generate API docs
  run: stardust openapi openapi.yaml -o docs/api

- name: Build site
  run: stardust build
```

## Example: Petstore API

```bash
# Generate from the classic Petstore example
stardust openapi https://petstore3.swagger.io/api/v3/openapi.json -o docs/api
```

## Tips

<Info>
- Keep your OpenAPI spec as the source of truth
- Add detailed descriptions in your spec—they become documentation
- Use tags to organize endpoints logically
- Include examples in your spec for richer documentation
</Info>
