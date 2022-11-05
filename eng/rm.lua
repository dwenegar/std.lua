local IS_WINDOWS = package.config:sub(1, 1) == '\\'

local function run(path)
  local cmd = IS_WINDOWS and 'cmd /c del /q %s' or 'rm -f %s'
  if IS_WINDOWS then
    path = path:gsub('/', '\\')
  end
  cmd = cmd:format(path)
  print(('Executing `%s`'):format(cmd))
  os.execute(cmd)
end

run(...)
