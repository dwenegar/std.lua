describe("#i18n", function()
  insulate("set_classifier", function()
    local i18n = require 'std.i18n'
    it("should report bad arguments", function()
      assert.error(function() i18n.set_classifier(nil) end, "bad argument #1 to 'set_classifier' (string expected, got nil)")
      assert.error(function() i18n.set_classifier("xxx") end, "bad argument #2 to 'set_classifier' (function expected, got nil)")
      assert.error(function() i18n.set_classifier("xxx", function() end) end, "bad argument #1 to 'set_classifier' (invalid locale: xxx)")
    end)
    it("should set the classifier w/o errors", function()
      assert.no_error(function() i18n.set_classifier('en', function() end) end)
      assert.no_error(function() i18n.set_classifier('en_US', function() end) end)
    end)
  end)
  insulate("set_classifier", function()
    local i18n = require 'std.i18n'
    it("should report duplicated classifiers", function()
      assert.error(function()
        i18n.set_classifier('en', function() end)
        i18n.set_classifier('en', function() end)
      end, [[classifier "en" already registered]])
    end)
  end)
end)
