local IS_CI = not not os.getenv('GITHUB_ACTIONS')

describe("#sleep", function()
  local sleep = require 'std.sleep'
  local stopwatch = require 'std.stopwatch'

  if not IS_CI then
    it("should return immediately (s)", function()
      local sw = stopwatch.start()
      sleep.sleep(-1)
      local dt = sw:get_elapsed_time_ns()
      assert.is_true(dt < 1000)
    end)
    it("should return immediately (ms)", function()
      local sw = stopwatch.start()
      sleep.sleep_ms(-1)
      local dt = sw:get_elapsed_time_ns()
      assert.is_true(dt < 1000)
    end)
  end
  it("should sleep for the specified amount of time (s)", function()
    local sw = stopwatch.start()
    sleep.sleep(0.25)
    local dt = sw:get_elapsed_time()
    assert.is_true(dt >= 0.25)
  end)
  it("should sleep for the specified amount of time (ms)", function()
    local sw = stopwatch.start()
    sleep.sleep_ms(250)
    local dt = sw:get_elapsed_time_ms()
    assert.is_true(dt >= 250)
  end)
end)
