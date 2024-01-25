local time = require 'std.time'
local sleep = require 'std.sleep'

describe("#time", function()

  local function sample_time(name, sleep_time, k)
    it(name .. " should return increasing values, sleep_time=" .. sleep_time, function()
      local get_time = time[name]

      local t0 = get_time()
      local unslept = sleep.sleep(sleep_time)
      local t1 = get_time()

      assert.is_true(t1 >= t0)
      assert.is_true(unslept >= 0)
      -- accept values within 0.1% of the expected value
      assert.is_true(t1 - t0 + unslept * k >= (sleep_time * k) * 0.999)
    end)
  end

  for _, t in ipairs { 0.001, 0.01, 0.1} do
    sample_time('current', t, 1)
    sample_time('monotonic', t, 1)
    sample_time('perf_counter', t, 1)

    sample_time('current_ms', t, 1000)
    sample_time('monotonic_ms', t, 1000)
    sample_time('perf_counter_ms', t, 1000)

    sample_time('monotonic_ns', t, 1000 * 1000 * 1000)
    sample_time('perf_counter_ns', t, 1000 * 1000 * 1000)
  end
end)
