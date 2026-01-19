---
title: Steps
description: Guide users through sequential processes with numbered step components.
---

# Steps

Steps provide a clear visual guide for sequential instructions, tutorials, and processes.

## Basic Steps

<Steps>
  <Step title="Install Stardust">
    Download and install Stardust using your preferred method.
  </Step>
  <Step title="Create a project">
    Run `stardust init my-docs` to create a new documentation project.
  </Step>
  <Step title="Start writing">
    Add markdown files to the `docs/` directory and start documenting.
  </Step>
</Steps>

```markdown
<Steps>
  <Step title="Install Stardust">
    Download and install Stardust using your preferred method.
  </Step>
  <Step title="Create a project">
    Run `stardust init my-docs` to create a new documentation project.
  </Step>
  <Step title="Start writing">
    Add markdown files to the `docs/` directory and start documenting.
  </Step>
</Steps>
```

## Steps with Code

Each step can contain code blocks and other rich content:

<Steps>
  <Step title="Clone the repository">
    ```bash
    git clone https://github.com/myorg/myproject.git
    cd myproject
    ```
  </Step>
  <Step title="Install dependencies">
    ```bash
    dart pub get
    ```
  </Step>
  <Step title="Run the application">
    ```bash
    dart run
    ```

    You should see:
    ```
    Server running on http://localhost:8080
    ```
  </Step>
  <Step title="Verify installation">
    Open your browser and navigate to [http://localhost:8080](http://localhost:8080).

    <Success>
    If you see the welcome page, you're all set!
    </Success>
  </Step>
</Steps>

## Steps with Multiple Content Types

<Steps>
  <Step title="Configure your database">
    Create a `config.yaml` file:

    ```yaml
    database:
      host: localhost
      port: 5432
      name: myapp
    ```

    <Warning>
    Never commit database credentials to version control.
    </Warning>
  </Step>
  <Step title="Run migrations">
    Apply database migrations:

    ```bash
    dart run migrate
    ```

    | Migration | Status |
    |-----------|--------|
    | 001_create_users | Applied |
    | 002_create_posts | Applied |
  </Step>
  <Step title="Seed test data">
    Optionally, seed the database with test data:

    ```bash
    dart run seed --env=development
    ```
  </Step>
</Steps>

## Deployment Tutorial Example

<Steps>
  <Step title="Build your site">
    Generate the production build:

    ```bash
    stardust build
    ```

    This creates a `dist/` directory with your static site.
  </Step>
  <Step title="Preview locally">
    Test the production build locally:

    ```bash
    cd dist
    python -m http.server 8000
    ```

    Open [http://localhost:8000](http://localhost:8000) to preview.
  </Step>
  <Step title="Deploy to GitHub Pages">
    Push the `dist/` directory to your `gh-pages` branch:

    ```bash
    git subtree push --prefix dist origin gh-pages
    ```

    Or use GitHub Actions for automatic deployments.
  </Step>
  <Step title="Configure custom domain (optional)">
    Add a `CNAME` file to `public/` with your domain:

    ```
    docs.myproject.com
    ```

    Then configure DNS with your domain registrar.
  </Step>
</Steps>

## Best Practices

<Info>
- Use clear, action-oriented titles ("Install dependencies" not "Dependencies")
- Keep each step focused on one action
- Include expected outcomes or verification steps
- Use callouts for important notes within steps
</Info>

## When to Use Steps

| Use Case | Example |
|----------|---------|
| Installation guides | Setting up a development environment |
| Tutorials | Building a feature step-by-step |
| Onboarding | Getting started with a product |
| Deployment | Publishing to production |
| Troubleshooting | Fixing a specific issue |
