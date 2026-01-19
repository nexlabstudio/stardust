---
title: API Documentation
description: Document REST APIs with interactive endpoint components.
---

# API Documentation

Create beautiful, interactive API documentation with dedicated components for endpoints, parameters, and responses.

## Basic API Endpoint

<Api method="GET" path="/users">
  Retrieve a list of all users.
</Api>

```markdown
<Api method="GET" path="/users">
  Retrieve a list of all users.
</Api>
```

## HTTP Methods

<Api method="GET" path="/users/{id}">
  Get a specific user by ID.
</Api>

<Api method="POST" path="/users">
  Create a new user.
</Api>

<Api method="PUT" path="/users/{id}">
  Update an existing user.
</Api>

<Api method="PATCH" path="/users/{id}">
  Partially update a user.
</Api>

<Api method="DELETE" path="/users/{id}">
  Delete a user.
</Api>

## Parameters

Document request parameters with `ParamField`:

<Api method="GET" path="/users">
  <ParamField name="page" type="integer" paramType="query">
    Page number for pagination.
  </ParamField>
  <ParamField name="limit" type="integer" paramType="query" default="20">
    Number of results per page.
  </ParamField>
  <ParamField name="search" type="string" paramType="query">
    Filter users by name or email.
  </ParamField>
</Api>

```markdown
<Api method="GET" path="/users">
  <ParamField name="page" type="integer" paramType="query">
    Page number for pagination.
  </ParamField>
  <ParamField name="limit" type="integer" paramType="query" default="20">
    Number of results per page.
  </ParamField>
  <ParamField name="search" type="string" paramType="query">
    Filter users by name or email.
  </ParamField>
</Api>
```

### Parameter Types

<Api method="POST" path="/users/{id}/avatar">
  <ParamField name="id" type="string" paramType="path" required>
    The unique user identifier.
  </ParamField>
  <ParamField name="Authorization" type="string" paramType="header" required>
    Bearer token for authentication.
  </ParamField>
  <ParamField name="file" type="binary" paramType="body" required>
    The avatar image file.
  </ParamField>
</Api>

## Response Fields

Document response structure with `ResponseField`:

<Api method="GET" path="/users/{id}">
  <ParamField name="id" type="string" paramType="path" required>
    User ID
  </ParamField>

  <ResponseField name="id" type="string">
    Unique user identifier.
  </ResponseField>
  <ResponseField name="email" type="string">
    User's email address.
  </ResponseField>
  <ResponseField name="name" type="string">
    User's display name.
  </ResponseField>
  <ResponseField name="created_at" type="string">
    ISO 8601 timestamp of account creation.
  </ResponseField>
  <ResponseField name="avatar_url" type="string" nullable>
    URL to user's avatar image, if set.
  </ResponseField>
</Api>

```markdown
<Api method="GET" path="/users/{id}">
  <ResponseField name="id" type="string">
    Unique user identifier.
  </ResponseField>
  <ResponseField name="email" type="string">
    User's email address.
  </ResponseField>
  <ResponseField name="avatar_url" type="string" nullable>
    URL to user's avatar image, if set.
  </ResponseField>
</Api>
```

## Complete API Example

<Api method="POST" path="/users" title="Create User" auth="Bearer Token">
  Creates a new user account in the system.

  <ParamField name="Authorization" type="string" paramType="header" required>
    Bearer token: `Bearer your-api-key`
  </ParamField>
  <ParamField name="email" type="string" paramType="body" required>
    User's email address. Must be unique.
  </ParamField>
  <ParamField name="name" type="string" paramType="body" required>
    User's display name (2-50 characters).
  </ParamField>
  <ParamField name="password" type="string" paramType="body" required>
    Password (minimum 8 characters).
  </ParamField>
  <ParamField name="role" type="string" paramType="body" default="user">
    User role: `admin`, `editor`, or `user`.
  </ParamField>

  <ResponseField name="id" type="string">
    Unique identifier for the created user.
  </ResponseField>
  <ResponseField name="email" type="string">
    The user's email address.
  </ResponseField>
  <ResponseField name="name" type="string">
    The user's display name.
  </ResponseField>
  <ResponseField name="role" type="string">
    The assigned user role.
  </ResponseField>
  <ResponseField name="created_at" type="string">
    ISO 8601 creation timestamp.
  </ResponseField>
</Api>

## Generic Fields

Use `Field` for general-purpose field documentation:

<Field name="pagination" type="object">
  All list endpoints return pagination metadata.
</Field>

<Field name="pagination.page" type="integer">
  Current page number (1-indexed).
</Field>

<Field name="pagination.total_pages" type="integer">
  Total number of pages available.
</Field>

<Field name="pagination.total_items" type="integer">
  Total number of items across all pages.
</Field>

```markdown
<Field name="pagination" type="object">
  All list endpoints return pagination metadata.
</Field>

<Field name="pagination.page" type="integer">
  Current page number (1-indexed).
</Field>
```

## OpenAPI Import

Generate API documentation automatically from OpenAPI/Swagger specs:

```bash
stardust openapi openapi.yaml -o docs/api
```

This creates markdown files for each endpoint with:
- Method and path
- Description from spec
- All parameters with types
- Response schemas
- Authentication requirements

See the [OpenAPI CLI Reference](/cli/openapi) for more options.

## Attributes Reference

### Api

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `method` | string | `"GET"` | HTTP method |
| `path` | string | `"/"` | API endpoint path |
| `title` | string | - | Optional endpoint title |
| `auth` | string | - | Authentication requirement |

### ParamField

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | required | Parameter name |
| `type` | string | `"string"` | Data type |
| `paramType` | string | `"query"` | Location: `query`, `path`, `header`, `body` |
| `required` | boolean | `false` | Whether required |
| `default` | string | - | Default value |

### ResponseField

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | required | Field name |
| `type` | string | `"any"` | Data type |
| `nullable` | boolean | `false` | Whether can be null |

### Field

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | required | Field name |
| `type` | string | `"any"` | Data type |
| `required` | boolean | `false` | Whether required |
| `default` | string | - | Default value |
| `deprecated` | boolean | `false` | Mark as deprecated |

## Best Practices

<Info>
- Group related endpoints together on the same page
- Always document required vs optional parameters
- Include example values in descriptions
- Document error responses and status codes
- Use consistent naming conventions
</Info>
