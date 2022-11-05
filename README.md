# std.lua

[![Build](https://img.shields.io/github/workflow/status/dwenegar/std.lua/Build?label=Build)](https://github.com/dwenegar/std.lua/actions/workflows/build.yml)
[![Coverage](https://coveralls.io/repos/github/dwenegar/std.lua/badge.svg?branch=main)](https://coveralls.io/github/dwenegar/std.lua?branch=main)
[![Docs](https://img.shields.io/github/workflow/status/dwenegar/std.lua/Docs?label=API%20Reference)](https://dwenegar.github.io/std.lua/)
[![License](https://img.shields.io/github/license/dwenegar/std.lua?label=License)](LICENSE.txt)
[![Version](https://img.shields.io/github/v/tag/dwenegar/std.lua?label=Version&logo=semver&sort=semver)](CHANGELOG.md)

A Lua standard library.

## Usage

Add the following dependency to your rockspec:

```lua
dependencies = {
  'dwenegar/std.lua <= 0.1.0'
}
```

Use the module in your code:

```lua
local std = require 'std'
```

## Versioning

`std.lua` is versioned according to [Semantic Versioning](https://semver.org/).

## License

`std.lua` is distributed under the [BSD-2-Clause license](LICENSE.txt).
