local path = require 'std.path'

if path.DIRSEP ~= "\\" then return end

describe('#windows', function()
  describe('#path', function()
    describe("canonicalize", function()
      it("should return the canonicalized path", function()
        assert.are_equal("", path.canonicalize(""))
        assert.are_equal("foo", path.canonicalize("foo"))
      end)
    end)

    describe("combine", function()
      it("should combine the parts", function()
        assert.are_equal("T:", path.combine("", "T:"))
        assert.are_equal("T:\\foo", path.combine("T:", "foo"))
        assert.are_equal("\\goo", path.combine("T:", "foo", "\\goo"))
        assert.are_equal("\\", path.combine("", "\\"))
        assert.are_equal("\\\\?\\share\\foo", path.combine("\\\\?\\share", "foo"))
        assert.are_equal("\\\\?\\share\\/foo", path.combine("\\\\?\\share", "/foo"))
        assert.are_equal("\\\\?\\share\\foo", path.combine("/root", "\\\\?\\share", "foo"))
      end)
    end)

    describe("parent", function()
      it("should return the directory part of the path", function()
        local cases = {
          {"T:\\", nil},
          {"T:/", nil},
          {"T:", nil},
          {"dir\\\\baz", "dir"},
          {"dir//baz", "dir"},
          {"T:\\foo", "T:\\"},
          {"T:foo", "T:"}
        }
        for _, case in ipairs(cases) do
          local p, e = case[1], case[2]
          if e then
            assert.are_equal(e, path.parent(p), p)
          else
            assert.is_nil(path.parent(p), p)
          end
        end
      end)
    end)

    describe("file_name", function()
      it("should return nil if path is a volume", function()
        assert.is_nil(path.file_name("B:"))
      end)

      it("should return the filename part of the path", function()
        assert.are_equal(".", path.file_name("A:."))
        assert.are_equal("hoge", path.file_name("A:hoge"))
        assert.are_equal("hoge", path.file_name("A:/hoge"))
      end)
    end)

    describe("get_filename_we", function()
      it("should return nil if path is a directory", function()
        assert.is_nil(path.file_name("B:", true))
      end)
    end)

    describe("root", function()
      local cases = {
        windows = {
          {"\\\\?\\UNC\\test\\unc\\path\\to\\something", "\\\\?\\UNC\\test\\unc"},
          {"\\\\?\\UNC\\test\\unc", "\\\\?\\UNC\\test\\unc"},
          {"\\\\?\\UNC\\a\\b1", "\\\\?\\UNC\\a\\b1"},
          {"\\\\?\\UNC\\a\\b2\\", "\\\\?\\UNC\\a\\b2"},
          {"\\\\?\\T:\\foo\\bar.txt", "\\\\?\\T:\\"},
        },
        devices = {
          {"T:", "T:"},
          {"T:\\", "T:\\"},
          {"T:\\\\", "T:\\"},
          {"T:\\foo1", "T:\\"},
          {"T:\\\\foo2", "T:\\"},
        },
        unc = {
          {"\\\\test\\unc\\path\\to\\something", "\\\\test\\unc"},
          {"\\\\a\\b\\c\\d\\e", "\\\\a\\b"},
          {"\\\\a\\b\\", "\\\\a\\b"},
          {"\\\\a\\b", "\\\\a\\b"},
          {"\\\\test\\unc", "\\\\test\\unc"},
        }
      }

      it("should return the root path", function()
        for _, case in ipairs(cases.windows) do
          local p, e = case[1], case[2]
          assert.are_equal(e, path.root(p), p)
        end
      end)

      it("should return the root path", function()
        for _, case in ipairs(cases.unc) do
          local p, e = case[1], case[2]
          assert.are_equal(e, path.root(p), p)
        end
      end)

      it("should return the root path", function()
        for _, case in ipairs(cases.devices) do
          local p, e = case[1], case[2]
          assert.are_equal(e, path.root(p), p)
        end
      end)
    end)

    describe("full_path", function()
      it("should expand the path", function()
        local cases = {
          {"\\\\?\\T:\\ ", "\\\\?\\T:\\ "},
          {"\\\\?\\T:\\ \\ ", "\\\\?\\T:\\ \\ "},
          {"\\\\?\\T:\\ .", "\\\\?\\T:\\ ."},
          {"\\\\?\\T:\\ ..", "\\\\?\\T:\\ .."},
          {"\\\\?\\T:\\...", "\\\\?\\T:\\..."},
          {"\\\\?\\GLOBALROOT\\", "\\\\?\\GLOBALROOT\\"},
          {"\\\\?\\", "\\\\?\\"},
          {"\\\\?\\.", "\\\\?\\."},
          {"\\\\?\\..", "\\\\?\\.."},
          {"\\\\?\\\\", "\\\\?\\\\"},
          {"\\\\?\\T:\\\\", "\\\\?\\T:\\\\"},
          {"\\\\?\\T:\\.", "\\\\?\\T:\\."},
          {"\\\\?\\T:\\..", "\\\\?\\T:\\.."},
          {"\\\\?\\T:\\Foo1\\.", "\\\\?\\T:\\Foo1\\."},
          {"\\\\?\\T:\\Foo2\\..", "\\\\?\\T:\\Foo2\\.."},
          {"\\\\?\\UNC\\", "\\\\?\\UNC\\"},
          {"\\\\?\\UNC\\server1", "\\\\?\\UNC\\server1"},
          {"\\\\?\\UNC\\server2\\", "\\\\?\\UNC\\server2\\"},
          {"\\\\?\\UNC\\server3\\\\", "\\\\?\\UNC\\server3\\\\"},
          {"\\\\?\\UNC\\server4\\..", "\\\\?\\UNC\\server4\\.."},
          {"\\\\?\\UNC\\server5\\share\\.", "\\\\?\\UNC\\server5\\share\\."},
          {"\\\\?\\UNC\\server6\\share\\..", "\\\\?\\UNC\\server6\\share\\.."},
          {"\\\\?\\UNC\\a\\b\\\\", "\\\\?\\UNC\\a\\b\\\\"},
          {"\\\\.\\", "\\\\.\\"},
          {"\\\\.\\.", "\\\\.\\"},
          {"\\\\.\\..", "\\\\.\\"},
          {"\\\\.\\\\", "\\\\.\\"},
          {"\\\\.\\T:\\\\", "\\\\.\\T:\\"},
          {"\\\\.\\T:\\.", "\\\\.\\T:"},
          {"\\\\.\\T:\\..", "\\\\.\\"},
          {"\\\\.\\T:\\Foo1\\.", "\\\\.\\T:\\Foo1"},
          {"\\\\.\\T:\\Foo2\\..", "\\\\.\\T:"},
          {"T:", "T:\\"},
          {"T:a", "T:\\a"},
          {"T:a\\..", "T:\\"},
          {"T:..", "T:\\"},
          {"T:\\..", "T:\\"},
          {"T:a\\.\\b\\", "T:\\a\\b\\"},
        }
        local env = require 'std.env'
        local cwd = env.get_current_dir()
        local running_on_c = not not cwd:match('^C:')
        for _, x in ipairs(cases) do
          local p, e = x[1], x[2]
          if running_on_c then
            p, e = p:gsub('C:', 'T:'), e:gsub('C:', 'T')
          end
          assert.are_equal(e, path.full_path(p), p)
        end
      end)
    end)
  end)
end)
