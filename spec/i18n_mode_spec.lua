describe("#i18n", function()
  insulate(":error", function()
    local L = require 'std.i18n' {
      name = 'spec', mode = 'error'
    }
    it("should report missing keys", function()
      assert.error(function() L("missing") end, [[missing key "missing"]])
    end)
  end)
  insulate(":silent", function()
    local L = require 'std.i18n' {
      name = 'spec', mode = 'silent'
    }
    it("should return the key if the string is missing", function()
      assert.are_equal("missing", L("missing"))
    end)
  end)
  insulate(":nil", function()
    local L = require 'std.i18n' {
      name = 'spec', mode = 'nil'
    }
    it("should return nil if the string is missing", function()
      assert.is_nil(L("missing"))
    end)
  end)
  insulate("nil", function()
    local L = require 'std.i18n' {
      name = 'spec'
    }
    it("should fallback to silent when not specified", function()
      assert.are_equal("missing", L("missing"))
    end)
  end)
end)
