local path = require 'std.path'

if path.DIRSEP == "\\" then return end

describe("#unix", function()
  describe("#path", function()
    describe("root()", function()
      it("should return the root path (unix)", function()
        local cases = {
          "/../../.././tmp/..",
          "/../../../",
          "/../../../tmp/bar/..",
          "/../.././././bar/../../../",
          "/../../././tmp/..",
          "/../../tmp/../../",
          "/../../tmp/bar/..",
          "/../tmp/../..",
          "/././../../../../",
          "/././../../../",
          "/./././bar/../../../",
          "/",
          "/bar",
          "/bar/././././../../..",
          "/bar/tmp",
          "/tmp/..",
          "/tmp/../../../../../bar",
          "/tmp/../../../bar",
          "/tmp/../bar/../..",
          "/tmp/bar",
          "/tmp/bar/.."
        }
        for _, case in ipairs(cases) do
          assert.are_equal("/", path.root(case), case)
        end
      end)
    end)

    describe("file_name()", function()
      it("should return the filename part of the path", function()
        assert.are_equal("A:.", path.file_name("A:."))
        assert.are_equal("B:.", path.file_name("B:."))
      end)
    end)

    describe("full_path", function()
      it("should report bad arguments", function()
        assert.error(function() path.full_path(nil) end)
        assert.error(function() path.full_path("/ho\0ge") end)
      end)

      it("should expand the path (whitespace)", function()
        local cwd = path.full_path(".")
        assert.are_equal("/ / ", path.full_path("/ // "))
        assert.are_equal(path.combine(cwd, "    "), path.full_path("    "))
        assert.are_equal(path.combine(cwd, "\r\n"), path.full_path("\r\n"))
      end)

      it("should expand the path (basic)", function()
        local cases = {
          {"/home/git", "/home/git", "/home/git"},
          {"", "/home/git", "/home/git"},
          {"..", "/home/git", "/home"},
          {"/home/git/././././././", "/home/git", "/home/git/"},
          {"/home/git///.", "/home/git", "/home/git"},
          {"/home/git/../git/./../git", "/home/git", "/home/git"},
          {"/home/git/somedir/..", "/home/git", "/home/git"},
          {"/home/git/./", "/home/git", "/home/git/"},
          {"/home/../../../../..", "/home/git", "/"},
          {"/home///", "/home/git", "/home/"},
          {"tmp", "/home/git", "/home/git/tmp"},
          {"tmp/bar/..", "/home/git", "/home/git/tmp"},
          {"tmp/..", "/home/git", "/home/git"},
          {"tmp/./bar/../", "/home/git", "/home/git/tmp/"},
          {"tmp/bar/../../", "/home/git", "/home/git/"},
          {"tmp/bar/../next/../", "/home/git", "/home/git/tmp/"},
          {"tmp/bar/next", "/home/git", "/home/git/tmp/bar/next"},

          {"/tmp/bar", "/home/git", "/tmp/bar"},
          {"/bar", "/home/git", "/bar"},
          {"/tmp/..", "/home/git", "/"},
          {"/tmp/bar/..", "/home/git", "/tmp"},
          {"/tmp/..", "/home/git", "/"},
          {"/", "/home/git", "/"},

          {"/tmp/../../../bar", "/home/git", "/bar"},
          {"/bar/././././../../..", "/home/git", "/"},
          {"/../../tmp/../../", "/home/git", "/"},
          {"/../../tmp/bar/..", "/home/git", "/tmp"},
          {"/tmp/..", "/home/git", "/"},
          {"/././../../../../", "/home/git", "/"},

          {"/tmp/../../../../../bar", "/home/git", "/bar"},
          {"/./././bar/../../../", "/home/git", "/"},
          {"/tmp/..", "/home/git", "/"},
          {"/../../tmp/bar/..", "/home/git", "/tmp"},
          {"/tmp/..", "/home/git", "/"},
          {"../../../", "/home/git", "/"},

          {"../.././././bar/../../../", "/home/git", "/"},
          {"../../.././tmp/..", "/home/git", "/"},
          {"../../../tmp/bar/..", "/home/git", "/tmp"},
          {"../../././tmp/..", "/home/git", "/"},
          {"././../../../", "/home/git", "/"},
          {"../tmp/../..", "/home", "/"},
        }
        for _, case in ipairs(cases) do
          local p, q, e = case[1], case[2], case[3]
          assert.are_equal(e, path.full_path(p, q), p)
        end
      end)
    end)
  end)
end)
