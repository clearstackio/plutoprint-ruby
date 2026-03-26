# Copilot Instructions for plutoprint-ruby

## Project Overview

plutoprint-ruby is a Ruby gem providing native C bindings for the PlutoBook rendering engine. It converts HTML, XML, SVG, and images to PDF/PNG without a browser.

## Architecture

The gem has a layered architecture:

- **Core** (`lib/plutoprint/`) — Plain Ruby. Always loaded. Book, PageSize, PageMargins, Configuration, OptionsHelper, HTMLPreprocessor, convenience methods, CLI.
- **Rack** (`lib/plutoprint/rack/`) — Rack middleware for .pdf/.png URL interception. Loaded explicitly or by the Railtie.
- **Rails** (`lib/plutoprint/rails/`) — Railtie for auto-registering middleware. Lazy-loaded via `defined?(::Rails)`.

Core must never depend on Rack or Rails. Rack layer depends only on core + rack gem. Rails layer depends on core + rack + rails.

## Key Patterns

- **Configuration:** `Plutoprint.configure` block, singleton pattern. Three-tier: gem defaults → initializer → per-request (`Plutoprint.set_options`).
- **Thread safety:** `dup._call(env)` in middleware. Per-request options stored in `request.env["plutoprint.options"]`. Global config is read-only during requests.
- **C extension:** `ext/plutoprint/` wraps PlutoBook C library. Ruby wrappers in `lib/plutoprint/` add keyword args, symbol resolution, and enum mappings.
- **Deep merge:** Options use deep merge for nested hashes (margins). Never mutate global config.

## Code Style

- **StandardRB** with strict defaults (no config file). Run `bundle exec standardrb`.
- No extra comments, docstrings, or type annotations unless logic is non-obvious.
- Follow existing patterns in the codebase.

## Testing

- **RSpec** for all tests. Run `bundle exec rspec`.
- Tests for Rack middleware require `require "plutoprint/rack/middleware"` explicitly.
- Rails railtie tests handle absence of Rails gracefully.
- C extension must be compiled first: `bundle exec rake compile`.

## Important Files

- `lib/plutoprint.rb` — Entry point. Loads core, adds module methods, conditionally loads Railtie.
- `lib/plutoprint/rack/middleware.rb` — The Rack middleware. Handles PDF/PNG interception, HTML preprocessing, options merging, PlutoBook conversion.
- `lib/plutoprint/options_helper.rb` — Resolves margins (unit strings → points), sizes, media types. `build_options` does three-tier merge.
- `ext/plutoprint/book.c` — C extension for Book. `load_html` accepts 4 args (html, style, script, base_url).

## Don'ts

- Don't add ActiveSupport or Rails dependencies to core files.
- Don't pass nil to C extension string parameters — coerce to `""`.
- Don't mutate `Plutoprint.configuration` during request handling.
- Don't use `defined?(::Rails::Railtie)` for detection — use `defined?(::Rails)` (load order).
