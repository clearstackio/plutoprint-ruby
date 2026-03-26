# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-26

### Added

- Native C bindings for the PlutoBook rendering engine
- `Plutoprint::Book` class with HTML, XML, URL, and image loading
- `Plutoprint::PageSize` and `Plutoprint::PageMargins` with preset symbols
- `Plutoprint::Canvas`, `ImageCanvas`, and `PDFCanvas` for advanced rendering
- Convenience methods: `html_to_pdf`, `html_to_png`, `url_to_pdf`, `url_to_png`
- `Plutoprint.configure` block for project-wide configuration
- Three-tier configuration: gem defaults, initializer, per-request overrides
- `Plutoprint.set_options(request, ...)` for controller-level overrides
- `Plutoprint::Rack::Middleware` for transparent PDF/PNG generation from `.pdf`/`.png` URLs
- `Plutoprint::Rails::Railtie` for automatic middleware registration in Rails
- `Plutoprint::HTMLPreprocessor` for absolutizing relative URLs
- `Plutoprint::OptionsHelper` with margin parsing (unit strings to points)
- `Plutoprint::ResourceFetcher` and `DefaultResourceFetcher` for custom resource loading
- CLI tool (`plutoprint convert`) via Thor
- Unit parsing (`Plutoprint.parse_length`) for pt, pc, in, cm, mm, px
- PDF metadata support (title, author, subject, keywords, creator, dates)
