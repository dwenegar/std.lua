describe("#i18n", function()
  insulate("add_bundle", function()
    local i18n = require 'std.i18n'
    it("should report invalid arguments", function()
      assert.error(function() i18n.add_bundle(nil) end, "bad argument #1 to 'add_bundle' (string expected, got nil)")
      assert.error(function() i18n.add_bundle({}) end, "bad argument #1 to 'add_bundle' (string expected, got table)")
      assert.error(function() i18n.add_bundle('spec', 'invalid') end, "bad argument #2 to 'add_bundle' (nil, 'error', 'silent', or 'nil' expected, got 'invalid')")
      assert.error(function() i18n.add_bundle('spec', {}) end, "bad argument #2 to 'add_bundle' (nil or string expected, got table)")
      assert.error(function() i18n.add_bundle('spec', ':nil', 1337) end, "bad argument #3 to 'add_bundle' (nil or string expected, got number)")
    end)
    it("should add a new bundle", function()
      assert.no_error(function() i18n.add_bundle('spec') end)
    end)
  end)
  insulate("add_bundle", function()
    local i18n = require 'std.i18n'
    it("should report duplicate bundles", function()
      assert.error(function()
        i18n.add_bundle('spec')
        i18n.add_bundle('spec')
      end, [[bundle "spec" already registered]])
    end)
  end)
  insulate("get_bundle", function()
    local i18n = require 'std.i18n'
    it("should report missing bundles", function()
      assert.error(function()
        i18n.get_bundle('missing')
      end, [[missing bundle "missing"]])
    end)
    it("should return the localization functions", function()
      local L, Ln
      assert.not_error(function()
        i18n.add_bundle('spec')
        L, Ln = i18n.get_bundle('spec')
      end)
      assert.is_not_nil(L)
      assert.is_not_nil(Ln)
    end)
  end)
  insulate("get_bundle", function()
    local i18n = require 'std.i18n'
    it("should return the localization functions (fallback to language)", function()
      local L, Ln
      assert.not_error(function()
        i18n.set_locale('en_US')
        i18n.add_bundle('spec')
        L, Ln = i18n.get_bundle('spec')
      end)
      assert.is_not_nil(L)
      assert.is_not_nil(Ln)
    end)
  end)
  insulate("get_bundle", function()
    local i18n = require 'std.i18n'
    it("should report loading errors", function()
      assert.error(function()
        i18n.add_bundle('missing')
        i18n.get_bundle('missing')
      end, [[missing locale "en" for bundle "missing"]])
    end)
  end)
end)