# PlutoPrint Ruby

Ruby bindings for the [PlutoBook](https://github.com/plutoprint/plutobook) rendering engine. Convert HTML, XML, SVG, and images into high-quality PDFs and PNG images — without a browser.

PlutoPrint Ruby is a native C extension. No headless Chrome, no Node.js, no subprocess overhead.

> **Note:** PlutoPrint Ruby (`plutoprint-ruby`) is maintained by Ajaya Agrawalla / ClearStack Inc and is not affiliated with or endorsed by the PlutoBook project.

## Installation

**Prerequisites:** The PlutoBook C library must be installed on your system.

```bash
# macOS (Homebrew)
brew install plutobook

# Ubuntu/Debian
sudo apt-get install libplutobook-dev
```

Then add the gem:

```ruby
gem "plutoprint-ruby"
```

Or install directly:

```bash
gem install plutoprint-ruby
```

If PlutoBook is installed in a non-standard location:

```bash
gem install plutoprint-ruby -- --with-plutobook-dir=/path/to/plutobook
```

## Quick Start

### Plain Ruby

```ruby
require "plutoprint"

# HTML string to PDF file
Plutoprint.html_to_pdf("<h1>Hello World</h1>", "output.pdf")

# HTML string to PNG file
Plutoprint.html_to_png("<h1>Hello World</h1>", "output.png")

# URL to PDF
Plutoprint.url_to_pdf("https://example.com", "output.pdf")

# Output to a stream (StringIO, File, etc.)
io = StringIO.new
Plutoprint.html_to_pdf("<h1>Hello</h1>", io)
pdf_bytes = io.string
```

### With options

```ruby
Plutoprint.html_to_pdf(
  "<h1>Report</h1>",
  "report.pdf",
  size: :letter,
  margins: :wide,
  media: :print,
  user_style: "body { font-family: serif; }",
  title: "My Report",
  author: "Jane Doe"
)
```

## Configuration

Use `Plutoprint.configure` to set project-wide defaults. This works in any Ruby application — Rails, Sinatra, plain scripts.

```ruby
Plutoprint.configure do |config|
  config.use_pdf_middleware = true   # Enable .pdf URL interception (default: true)
  config.use_png_middleware = false  # Enable .png URL interception (default: false)
  config.root_url = nil             # Override base URL for asset resolution
  config.ignore_path = nil          # String, Regexp, or Proc to skip paths
  config.ignore_request = nil       # Proc receiving Rack::Request to skip requests

  config.options = {
    size: :letter,
    margins: {
      top: "0.75in",
      right: "0.75in",
      bottom: "0.75in",
      left: "0.75in"
    },
    media: :screen,
    user_style: "html { zoom: 0.8; }"
  }
end
```

### Options reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `size` | Symbol | `:a4` | Page size: `:a3`, `:a4`, `:a5`, `:b4`, `:b5`, `:letter`, `:legal`, `:ledger` |
| `margins` | Symbol or Hash | `:normal` | Preset (`:none`, `:narrow`, `:normal`, `:moderate`, `:wide`) or hash with sides |
| `media` | Symbol | `:print` | CSS media type: `:print` or `:screen` |
| `user_style` | String | `nil` | CSS injected before rendering |
| `user_script` | String | `nil` | JavaScript passed to PlutoBook |

**Margin hash** accepts unit strings (`"0.75in"`, `"19mm"`, `"54pt"`, `"2cm"`, `"100px"`) or numeric point values:

```ruby
{ top: "0.75in", right: "19mm", bottom: "54pt", left: "2cm" }
```

### Three-tier configuration

Options merge in order — each tier overrides the previous:

1. **Gem defaults** — `:a4`, `:normal` margins, `:print` media
2. **Initializer** — your `Plutoprint.configure` block
3. **Per-request** — controller-level overrides via `Plutoprint.set_options`

Deep merge is used for nested hashes like `margins`, so overriding one side preserves the others.

## Rack Middleware

For Sinatra, Hanami, Roda, or any Rack app, add the middleware explicitly:

```ruby
require "plutoprint"
require "plutoprint/rack/middleware"

use Plutoprint::Rack::Middleware
```

Any request ending in `.pdf` is intercepted: the extension is stripped, the HTML response is rendered normally, then converted to PDF and returned with `Content-Type: application/pdf`.

The same works for `.png` when `use_png_middleware` is enabled.

### Ignoring paths

```ruby
Plutoprint.configure do |config|
  # Skip paths starting with /admin
  config.ignore_path = "/admin"

  # Skip paths matching a pattern
  config.ignore_path = /\/api\//

  # Skip based on the full request
  config.ignore_request = ->(request) { request.params["skip_pdf"] }
end
```

## Rails Integration

Add the gem to your Gemfile:

```ruby
gem "plutoprint-ruby"
```

Create an initializer at `config/initializers/plutoprint.rb`:

```ruby
Plutoprint.configure do |config|
  config.use_pdf_middleware = true

  config.options = {
    size: :letter,
    margins: {
      top: "0.75in",
      right: "0.75in",
      bottom: "0.75in",
      left: "0.75in"
    },
    media: :screen,
    user_style: "html { zoom: 0.8; }"
  }
end
```

That's it. The Railtie auto-registers the middleware. No `config.middleware.use` needed.

### Detecting PDF mode in controllers

The middleware sets `request.env["plutoprint.middleware"]` to `true` when a `.pdf` request is being processed:

```ruby
class ReportsController < ApplicationController
  def show
    @pdf = request.env["plutoprint.middleware"]
    render layout: "print" if @pdf
  end
end
```

### Per-controller options

Override options for specific actions without affecting the global config:

```ruby
class ReportsController < ApplicationController
  before_action :set_landscape_pdf, only: [:wide_report]

  private

  def set_landscape_pdf
    Plutoprint.set_options(request, size: :a4, margins: {top: "0.5in"})
  end
end
```

This is thread-safe — options are stored in the request env (per-request, per-thread).

## Migrating from Grover

PlutoPrint can replace [Grover](https://github.com/Studiosity/grover) as your PDF engine. Key differences:

| Aspect | Grover | PlutoPrint |
|--------|--------|------------|
| Engine | Headless Chrome (Puppeteer) | PlutoBook (native C) |
| JS execution | Full browser JS | Limited |
| CSS support | Full Chrome CSS | CSS 2.1 + some CSS 3 |
| Memory | Heavy (Chrome process) | Lightweight |
| Startup | Slow (browser launch) | Instant |
| Dependencies | Node.js + Puppeteer | PlutoBook C library |

### Migration steps

1. Replace the gem in your Gemfile:

```ruby
# Remove:
gem "grover"

# Add:
gem "plutoprint-ruby"
```

2. Replace the initializer:

```ruby
# config/initializers/grover.rb → config/initializers/plutoprint.rb

# Before (Grover):
Grover.configure do |config|
  config.use_pdf_middleware = true
  config.options = {
    margin: { top: "0.75in", right: "0.75in", bottom: "0.75in", left: "0.75in" },
    scale: 0.8,
    emulate_media: "screen"
  }
end

# After (PlutoPrint):
Plutoprint.configure do |config|
  config.use_pdf_middleware = true
  config.options = {
    margins: { top: "0.75in", right: "0.75in", bottom: "0.75in", left: "0.75in" },
    media: :screen,
    user_style: "html { zoom: 0.8; }"
  }
end
```

3. Remove `require 'grover'` from `config/application.rb` (PlutoPrint's Railtie handles everything).

4. Remove any manual `config.middleware.use Grover::Middleware` lines.

5. Update controller PDF detection:

```ruby
# Before:
@pdf = request.env["Rack-Middleware-Grover"]

# After:
@pdf = request.env["plutoprint.middleware"]
```

6. Guard any `window.print()` JavaScript in print layouts — PlutoPrint doesn't execute JavaScript like Chrome does:

```erb
<% unless @pdf %>
<script>window.print();</script>
<% end %>
```

### What to watch for

- **CSS rendering:** PlutoPrint supports CSS 2.1 with some CSS 3. Complex flexbox/grid layouts may render differently. Simple table-based print layouts work well.
- **JavaScript:** PlutoPrint has limited JS support compared to Chrome. Guard browser-specific JS behind `unless @pdf`.
- **Scale:** Grover's `scale: 0.8` maps to PlutoPrint's `user_style: "html { zoom: 0.8; }"`.
- **Media type:** Grover's `emulate_media: "screen"` maps to PlutoPrint's `media: :screen`.

## CLI

PlutoPrint includes a command-line tool:

```bash
# HTML file to PDF
plutoprint convert input.html output.pdf

# With options
plutoprint convert input.html output.pdf --size letter --margins wide

# Custom margins
plutoprint convert input.html output.pdf --margin-top 0.75in --margin-right 0.5in

# To PNG
plutoprint convert input.html output.png --width 800 --height 600

# With custom CSS
plutoprint convert input.html output.pdf --user-style "body { color: navy; }"

# From URL
plutoprint convert https://example.com output.pdf

# Version info
plutoprint version
plutoprint info
```

## API Reference

### Convenience methods

```ruby
Plutoprint.html_to_pdf(html, output, size:, margins:, media:, user_style:, user_script:, **metadata)
Plutoprint.html_to_png(html, output, size:, margins:, media:, width:, height:, user_style:, user_script:)
Plutoprint.url_to_pdf(url, output, size:, margins:, media:, user_style:, user_script:, **metadata)
Plutoprint.url_to_png(url, output, size:, margins:, media:, width:, height:, user_style:, user_script:)
```

`output` can be a file path (String) or any IO-like object (StringIO, File).

### Book (advanced)

```ruby
book = Plutoprint::Book.new(size: :letter, margins: :normal, media: :print)
book.load_html(html, user_style, user_script, base_url)
book.load_url(url, user_style, user_script)

book.page_count
book.set_metadata(:title, "My Document")
book.set_metadata(:author, "Jane Doe")

book.write_to_pdf("output.pdf")
book.write_to_pdf_stream(io)
book.write_to_png("output.png", width, height)
book.write_to_png_stream(io, width, height)
```

### Page sizes

`:none`, `:a3`, `:a4`, `:a5`, `:b4`, `:b5`, `:letter`, `:legal`, `:ledger`

### Margin presets

| Preset | Top | Right | Bottom | Left |
|--------|-----|-------|--------|------|
| `:none` | 0 | 0 | 0 | 0 |
| `:narrow` | 0.5in | 0.5in | 0.5in | 0.5in |
| `:normal` | 1in | 1in | 1in | 1in |
| `:moderate` | 1in | 0.75in | 1in | 0.75in |
| `:wide` | 1in | 2in | 1in | 2in |

### PDF metadata

```ruby
book.set_metadata(:title, "Document Title")
book.set_metadata(:author, "Author Name")
book.set_metadata(:subject, "Subject")
book.set_metadata(:keywords, "ruby, pdf")
book.set_metadata(:creator, "PlutoPrint Ruby")
book.set_metadata(:creation_date, Time.now.iso8601)
book.set_metadata(:modification_date, Time.now.iso8601)
```

## Development

```bash
# Install dependencies
bundle install

# Compile the C extension
bundle exec rake compile

# Run tests
bundle exec rspec

# Run linter
bundle exec standardrb

# Run everything (compile + test + lint)
bundle exec rake
```

## Related Projects

- [plutoprint (Python)](https://github.com/niclaslindstedt/plutoprint) — Python bindings for PlutoBook, the inspiration for this Ruby gem's API design
- [Grover](https://github.com/Studiosity/grover) — HTML-to-PDF via headless Chrome; inspired this gem's configuration pattern, Rack middleware, and Rails integration approach

## License

MIT License. See [LICENSE](LICENSE) for details.
