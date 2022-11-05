project = 'std.lua'
description = 'A Lua standard library'
dir = '../site'
file = {
  '../src',
  '../csrc'
}
topics = {
  '../docs'
}
examples = {
  '../examples'
}
format = 'markdown'
not_luadoc = true
no_lua_ref = true
convert_opt = true
sort = true
sort_modules = true
no_space_before_args = true
merge = true
backtick_references = false
use_markdown_titles = true
style = '.'
template = '.'
custom_tags = {
  {'remark', title = 'Remarks'}
}
