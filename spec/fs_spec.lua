-- describe("#fs", function()
--   local path = require 'std.path'
--   local fs = require 'std.fs'
--   describe("create_directory/remove_directory", function()
--     local filename = path.random_file_name()
--     it("should create a directory " .. filename, function()
--       local ok, err = fs.create_directory(filename)
--       assert.is_true(ok, err)
--     end)
--     it("should delete a directory " .. filename, function()
--       local ok, err = fs.remove_directory(filename)
--       assert.is_true(ok, err)
--     end)
--   end)
-- end)
