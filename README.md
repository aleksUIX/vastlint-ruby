# vastlint-ruby

High-performance, in-process VAST XML validation for Ruby backends.

This gem wraps the existing `vastlint-ffi` C API, which is backed by the same Rust core used by the CLI, Go binding, Erlang NIF, MCP server, and web validator. The intended use case is a DSP, SSP, ad server, or trafficking backend that needs to validate VAST XML and return structured linting results to a React or other web frontend.

## Why this shape

- No subprocess management in your Ruby app
- No network hop to an external validation service
- Stable JSON-compatible result shape for backend-to-frontend responses
- Same rule coverage and behavior as the rest of the vastlint ecosystem

## Install

RubyGems.org is not currently usable for new gem registrations, so the supported distribution target for this package is GitHub Packages.

Authenticate Bundler against GitHub Packages:

```sh
bundle config https://rubygems.pkg.github.com/aleksUIX USERNAME:TOKEN
```

Then add the package source in your application:

```ruby
source "https://rubygems.org"

source "https://rubygems.pkg.github.com/aleksUIX" do
  gem "vastlint"
end
```

Then install it:

```sh
bundle install
```

The gem expects a platform-matched `libvastlint` shared library.

For development in this monorepo, it will automatically try the sibling `vastlint/target/debug` and `vastlint/target/release` outputs.

For a distributable gem release, vendor the release libraries into `lib/vastlint/native/*` with:

```sh
./scripts/fetch-libs.sh v0.4.14
```

You can also point the gem at an explicit shared library path:

```sh
export VASTLINT_LIB_PATH=/absolute/path/to/libvastlint.dylib
```

If you need anonymous public installs without GitHub auth, GitHub Packages is the wrong host. In that case, use a different gem server such as Gemfury, Cloudsmith, or a private Gemstash instance.

## Usage

```ruby
require "vastlint"

result = Vastlint.validate(vast_xml)

if result.valid?
  puts "clean tag"
else
  puts result.summary.errors
  puts result.issues.first.message
end

puts result.to_json
```

### Rails controller example

```ruby
class VastValidationsController < ApplicationController
  def create
    result = Vastlint.validate(
      params.require(:xml),
      wrapper_depth: params[:wrapper_depth].to_i,
      max_wrapper_depth: params[:max_wrapper_depth].presence&.to_i || 5,
      rule_overrides: params[:rule_overrides]
    )

    render json: result.as_json
  rescue ArgumentError, Vastlint::Error => error
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
```

The response shape is stable and frontend-friendly:

```json
{
  "version": "4.2",
  "issues": [
    {
      "id": "VAST-2.0-inline-impression",
      "severity": "error",
      "message": "<InLine> must contain at least one <Impression>",
      "path": "/VAST/Ad[0]/InLine",
      "spec_ref": "IAB VAST 2.0 §2.2.1",
      "line": 4,
      "col": 3
    }
  ],
  "summary": {
    "errors": 1,
    "warnings": 0,
    "infos": 0,
    "valid": false
  }
}
```

## API

```ruby
Vastlint.validate(xml, wrapper_depth: 0, max_wrapper_depth: 5, rule_overrides: nil)
Vastlint.version
```

`rule_overrides` accepts a hash of rule IDs to levels:

```ruby
result = Vastlint.validate(
  vast_xml,
  rule_overrides: {
    "VAST-2.0-mediafile-https" => "error",
    "VAST-4.1-mezzanine-recommended" => "off"
  }
)
```

## Native library layout

Vendored release libraries belong at:

- `lib/vastlint/native/darwin_arm64/libvastlint.dylib`
- `lib/vastlint/native/darwin_amd64/libvastlint.dylib`
- `lib/vastlint/native/linux_arm64/libvastlint.so`
- `lib/vastlint/native/linux_amd64/libvastlint.so`

The shared libraries come from the `vastlint-ffi-*` tarballs attached to each `vastlint` GitHub Release.

## Publish

### From GitHub Actions

If this gem lives in its own GitHub repository, you do not need to add a separate publish token just to push to GitHub Packages. GitHub injects `GITHUB_TOKEN` automatically, and the workflow only needs `packages: write` permission.

The included workflow at `.github/workflows/publish-github-packages.yml`:

- derives the gem version from the tag or `lib/vastlint/version.rb`
- downloads the matching `vastlint-ffi-*` shared libraries from the main `aleksUIX/vastlint` release
- runs the Ruby tests
- builds the gem
- pushes it to `rubygems.pkg.github.com/<owner>` using `GITHUB_TOKEN`

That means the normal release path can be fully automated from CI.

### From a local machine

Publish to GitHub Packages with a classic personal access token that has `write:packages`.

```sh
export GITHUB_PACKAGES_OWNER=aleksUIX
export GITHUB_PACKAGES_TOKEN=YOUR_CLASSIC_PAT
./scripts/publish-github-packages.sh
```

The script:

- builds `vastlint-<version>.gem` if needed
- writes a temporary `~/.gem/credentials` with `:github: Bearer TOKEN`
- pushes to `https://rubygems.pkg.github.com/$GITHUB_PACKAGES_OWNER`

The publish script also accepts `GITHUB_TOKEN`, so the exact same script works inside GitHub Actions without adding a separate secret.

Install from the registry with:

```sh
gem install vastlint \
  --clear-sources \
  --source https://USERNAME:TOKEN@rubygems.pkg.github.com/aleksUIX/
```

## License

Apache 2.0.

