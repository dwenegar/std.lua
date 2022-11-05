# :moon: template.lua

An opinionated template for Lua projects.

This template uses:

- Lua 5.4
- LuaRocks for distribution
- Luacheck for linting
- Busted for testing
- LuaCov and Coveralls for calculating Lua code coverage
- LDoc for generating the documentation
- GitHub Actions for CI with three pre-defined workflows:
  - [build](https://github.com/dwenegar/template.lua/blob/main/.github/workflows/build.yml):
    build, test, and calculate the code coverage every time some code is pushed to the `main` branch
  - [docs](https://github.com/dwenegar/template.lua/blob/main/.github/workflows/docs.yml):
    generate the documentation and deploy it to the repository's GitHub Pages every time a version tag (x.y.z) is pushed
    to the repository
  - [lint](https://github.com/dwenegar/template.lua/blob/main/.github/workflows/lint.yml):
    run `luacheck` and lint the module's Lua code and its rockspec
- [git-cliff](https://github.com/orhun/git-cliff) for generating the changelog
- BSD 2 Clause licensing

## Usage

1. [Create](https://github.com/dwenegar/template.lua/generate) a new repository using this template.
2. Enable _Pages_ in the repository's settings and set _Source_ to `GitHub Actions`.
3. Clone the new repository locally.
4. From within the cloned repository, run `lua eng\init.lua` and follow the instructions.
5. Customize to your liking.
6. Commit and push all the changes.

### Publishing

Publishing the rock requires a [LuaRocks](https://luarocks.org) account and an
[API key](https://luarocks.org/settings/api-keys); the value of the API key is
expected in the environment variable `LUAROCKS_KEY`.
