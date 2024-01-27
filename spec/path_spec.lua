-- cspell: disable
local path = require 'std.path'

local function P(x)
  return x and x:gsub("/", path.DIRSEP)
end

describe("#path", function()
  describe("DIRSEP", function()
    it("should be not nil", function()
      assert.not_nil(path.DIRSEP)
      assert.are_equal("string", type(path.DIRSEP))
      assert.are_equal(1, #path.DIRSEP)
    end)
  end)

  describe("PATHSEP", function()
    it("should be not nil", function()
      assert.not_nil(path.PATHSEP)
      assert.are_equal("string", type(path.PATHSEP))
      assert.are_equal(1, #path.PATHSEP)
    end)
  end)

  describe("ALTDIRSEP", function()
    it("should be not nil", function()
      assert.not_nil(path.ALTDIRSEP)
      assert.are_equal("string", type(path.ALTDIRSEP))
      assert.are_equal(1, #path.ALTDIRSEP)
    end)
  end)

  describe("canonicalize", function()
    it("should report bad arguments", function()
      assert.error(function() path.canonicalize(nil) end, "bad argument #1 to 'canonicalize' (string expected, got nil)")
      assert.error(function() path.canonicalize(true) end, "bad argument #1 to 'canonicalize' (string expected, got boolean)")
      assert.error(function() path.canonicalize({}) end, "bad argument #1 to 'canonicalize' (string expected, got table)")
    end)
  end)

  describe("combine", function()
    it("should report bad arguments", function()
      assert.error(function() path.combine("hoge", nil) end, "bad argument #2 to 'combine' (string expected, got nil)")
      assert.error(function() path.combine(true) end, "bad argument #1 to 'combine' (string expected, got boolean)")
      assert.error(function() path.combine({}) end, "bad argument #1 to 'combine' (string expected, got table)")
    end)

    it("should return nil if no parts are given", function()
      assert.is_nil(path.combine())
    end)

    it("should combine the parts", function()
      local cases = {
        {"", "", ""},
        {"/~", "/", "~"},
        {"/doge", "/", "/doge"},
        {"/doge", "hoge", "/doge"},
        {"hoge", "", "hoge"},
        {"hoge", "hoge", ""},
        {"hoge/doge", "hoge", "doge"},
      }
      for _, case in ipairs(cases) do
        local e, p1, p2 = case[1], case[2], case[3]
        assert.are_equal(P(e), path.combine(P(p1), P(p2)), P(p1) .. ' + ' .. P(p2) .. ' -> ' .. P(e))
      end
    end)
  end)

  describe("ends_with_separator", function()
    it("should report bad arguments", function()
      assert.error(function() path.ends_with_separator(nil) end, "bad argument #1 to 'ends_with_separator' (string expected, got nil)")
      assert.error(function() path.ends_with_separator(true) end, "bad argument #1 to 'ends_with_separator' (string expected, got boolean)")
    end)

    it("should return whether the path ends with a separator", function()
      local cases = {
        {"/", true},
        {"/folder/", true},
        {"//", true},
        {"folder", false},
        {"folder/", true},
        {"", false}
      }
      for _, case in ipairs(cases) do
        local p, e = case[1], case[2]
        assert.are_equal(e, path.ends_with_separator(p), p)
        assert.are_equal(e, path.ends_with_separator(P(p)), P(p))
      end
    end)

    it ("should return true if the path ends with a separator", function()
      assert.is_true(path.ends_with_separator("/"))
      assert.is_true(path.ends_with_separator(P"/"))
      assert.is_true(path.ends_with_separator("hoge/"))
      assert.is_true(path.ends_with_separator(P"hoge/"))
    end)

    it ("should return false if the path does not end with a separator", function()
      assert.is_false(path.ends_with_separator(""))
      assert.is_false(path.ends_with_separator("hoge"))
      assert.is_false(path.ends_with_separator(P"/hoge"))
    end)
  end)

  describe("ends_with", function()
    it("should report bad arguments", function()
      assert.error(function() path.ends_with(nil) end, "bad argument #1 to 'ends_with' (string expected, got nil)")
      assert.error(function() path.ends_with(true) end, "bad argument #1 to 'ends_with' (string expected, got boolean)")
    end)

    it ("should return true if the path ends with the given suffix", function()
      local cases = {
        {"hoge/", "", true},
        {"hoge/doge", "doge", true},
        {"hoge/doge", "doge/", true},
        {"hoge/doge", "hige", false},
      }
      for _, case in ipairs(cases) do
        local p, s, e = case[1], case[2], case[3]
        assert.are_equal(e, path.ends_with(P(p), P(s)), P(p))
      end
    end)
  end)

  describe("extension", function()
    it("should report bad arguments", function()
      assert.error(function() path.extension(nil) end, "bad argument #1 to 'extension' (string expected, got nil)")
      assert.error(function() path.extension(true) end, "bad argument #1 to 'extension' (string expected, got boolean)")
    end)

    it("should return nil if the path has no extension", function()
      assert.is_nil(path.extension("file"))
      assert.is_nil(path.extension("file."))
      assert.is_nil(path.extension(".dotfile"))
      assert.is_nil(path.extension("test/file"))
      assert.is_nil(path.extension("test\\file"))
      assert.is_nil(path.extension("test/.dotfile"))
      assert.is_nil(path.extension("test\\.dotfile."))
    end)

    it("should return the file extension", function()
      assert.are_equal("exe", path.extension("file.exe"))
      assert.are_equal("s", path.extension("file.s"))
      assert.are_equal("ext", path.extension("test/file.ext"))
      assert.are_equal("ext", path.extension("test\\file.ext"))
      assert.are_equal("e xe", path.extension("file.e xe"))
      assert.are_equal(" ", path.extension("file. "))
      assert.are_equal("ext", path.extension(" file.ext"))
      assert.are_equal("ext", path.extension("a.b.ext"))
    end)
  end)

  describe("set_extension", function()
    it("should report bad arguments", function()
      assert.error(function() path.set_extension(nil, "exe") end, "bad argument #1 to 'set_extension' (string expected, got nil)")
      assert.error(function() path.set_extension({}, "exe") end, "bad argument #1 to 'set_extension' (string expected, got table)")
      assert.error(function() path.set_extension("file", {}) end, "bad argument #2 to 'set_extension' (string expected, got table)")
    end)

    it("should return the empty string if path is empty", function()
      assert.are_equal("", path.set_extension("", ""))
      assert.are_equal("", path.set_extension("", "exe"))
    end)

    it("should remove the file extension if the new extension is nil", function()
      assert.are_equal("file", path.set_extension("file.exe", nil))
    end)

    it("should append an empty file extension if path has none", function()
      assert.are_equal("file", path.set_extension("file.exe", ""))
      assert.are_equal(".", path.set_extension(".", ""))
    end)

    it("should change the file extension", function()
      local cases = {
        {"", "", ""},
        {"file.exe", nil, "file"},
        {"file.exe", "", "file"},
        {"file", "exe", "file.exe"},
        {"file", ".exe", "file..exe"},
        {"file.txt", "exe", "file.exe"},
        {"file.txt", ".exe", "file..exe"},
        {"file.txt.bin", "exe", "file.txt.exe"},
        {"dir/file.t", "exe", "dir/file.exe"},
        {"dir/file.exe", "t", "dir/file.t"},
        {"dir/file", "exe", "dir/file.exe"}
      }
      for _, case in ipairs(cases) do
        local p, n, e = case[1], case[2], case[3]
        assert.are_equal(e, path.set_extension(p, n), p or "nil")
        assert.are_equal(P(e), path.set_extension(P(p), P(n)), P(p or "nil"))
      end
    end)
  end)

  describe("parent", function()
    it("should report bad arguments", function()
      assert.error(function() path.parent(nil) end, "bad argument #1 to 'parent' (string expected, got nil)")
      assert.error(function() path.parent(true) end, "bad argument #1 to 'parent' (string expected, got boolean)")
    end)

    it("should return `nil` as the parent", function()
      assert.is_nil(path.parent(P""))
      assert.is_nil(path.parent(P"/"))
      assert.is_nil(path.parent(P"."))
      assert.is_nil(path.parent(P".."))
    end)

    it("should return the parent", function()
      assert.are_equal("hoge", path.parent(P"hoge/doge"))
      assert.are_equal("hoge", path.parent(P"hoge//doge"))
      assert.are_equal(P"../..", path.parent(P"../../hoge.txt"))
    end)
  end)

  describe("file_name", function()
    it("should return nil if the path is empty", function()
      assert.is_nil(path.file_name(""))
    end)
    it("should return nil if path is a directory", function()
      assert.is_nil(path.file_name(P"hoge/doge/c.exe/"))
    end)

    it("should return the filename part of the path", function()
      assert.are_equal(".", path.file_name("."))
      assert.are_equal("..", path.file_name(".."))
      assert.are_equal("file", path.file_name("file"))
      assert.are_equal("file.", path.file_name("file."))
      assert.are_equal("file.exe", path.file_name("file.exe"))
      assert.are_equal(" . ", path.file_name(" . "))
      assert.are_equal(" .. ", path.file_name(" .. "))
      assert.are_equal("fi le", path.file_name("fi le"))
      assert.are_equal("file.exe", path.file_name(P"baz/file.exe"))
      assert.are_equal("c.exe", path.file_name(P"hoge/doge/c.exe"))
    end)
  end)

  describe("file_stem", function()
    it("should return nil if path is a directory", function()
      assert.is_nil(path.file_stem(P"hoge/doge/c.exe/"))
      assert.is_nil(path.file_stem(P"/"))
    end)

    it("should return the filename part of the path", function()
      assert.are_equal("file", path.file_stem("file"))
      assert.are_equal("file", path.file_stem("file.exe"))
      assert.are_equal("file", path.file_stem(P"hoge/doge/file.exe"))
    end)
  end)

  describe("root", function()
    it("should report bad arguments", function()
      assert.error(function() path.root(nil) end)
    end)

    it("should return nil if path is not rooted", function()
      assert.is_nil(path.root("file"))
      assert.is_nil(path.root("file.exe"))
    end)

    it("should return the root path", function()
      assert.are_equal(P"/", path.root(P"/"))
      assert.are_equal(P"/", path.root(P"/hoge"))
    end)
  end)

  describe("is_rooted", function()
    it("should report bad arguments", function()
      assert.error(function() path.is_rooted(nil) end)
    end)

    it("should return false if path is not rooted", function()
      assert.is_false(path.is_rooted("file"))
      assert.is_false(path.is_rooted("file.exe"))
    end)

    it("should return true if path is rooted", function()
      assert.is_true(path.is_rooted(P"/"))
      assert.is_true(path.is_rooted(P"/hoge"))
    end)
  end)

  describe("full_path", function()
    it("should expand the path (basic)", function()
      local cwd = path.full_path(".")
      assert.not_nil(cwd)
      assert.is_false(#cwd == 0)

      local root = path.root(cwd)
      assert.not_nil(root)
      assert.is_false(#root == 0)

      local file = path.file_name(cwd)
      assert.not_nil(file)
      assert.is_false(#file == 0)

      local cases = {
        {cwd, cwd},
        {cwd, "."},
        {path.parent(cwd), ".."},
        {cwd, path.combine(cwd, ".", ".", ".", ".")},
        {cwd, cwd .. P"///."},
        {cwd, path.combine(cwd, "..", file, ".", "..", file)},
        {root, path.combine(root, "hoge", "..")},
        {root, path.combine(root, ".")},
        {root, path.combine(root, "..")},
        {root, path.combine(root, "..", "..", "..", "..")},
        {root, root .. P"///"},
     }
      for _, x in ipairs(cases) do
        assert.are_equal(x[1], path.full_path(x[2]))
      end
    end)

    it("should expand the path (tilde)", function()
      local cwd = path.full_path(".")
      assert.not_nil(cwd)
      assert.is_false(#cwd == 0)
      local root = path.root(cwd)
      assert.not_nil(root)
      assert.is_false(#root == 0)
      local data = {
        {path.combine(cwd, "~"), "~"},
        {path.combine(root, "~"), path.combine(root, "~")},
     }
      for _, case in ipairs(data) do
        local e, p = case[1], case[2]
        assert.are_equal(e, path.full_path(p), p)
      end
    end)
  end)

  describe("random_file_name", function()
    it("should return different filenames", function()
      local names = {}
      for _ = 1, 100 do
        local name = path.random_file_name()
        assert.are_equal(11, #name)
        assert.is_nil(names[name])
        names[name] = true
      end
    end)
  end)

  describe("#trim_ending_separator", function()
    it("should reaise with bad arguments", function()
      assert.error(function() path.trim_ending_separator(nil) end)
    end)

    it("should remove the ending separator", function()
      local cases = {
        {"/hoge/", "/hoge"},
        {"hoge/", "hoge"},
        {"", ""},
        {"/", "/"},
      }
      for _, case in ipairs(cases) do
        local p, e = case[1], case[2]
          local trimmed = path.trim_ending_separator(p)
          assert.are_equal(e, trimmed, p)
          assert.are_equal(trimmed, path.trim_ending_separator(trimmed), p)
      end
    end)
  end)
end)
