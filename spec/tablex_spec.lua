local tablex = require 'std.tablex'

local function apple() return {name='apple',color='red',price=200} end
local function banana() return {name='banana',color='yellow',price=50} end
local function orange() return {name='orange',color='orange',price=100} end
local function fixtures() return {apple(),banana(),orange()} end
local function fixtures2() return {x=1,y=2,z=3} end

describe("#tablex", function()
  describe("#update", function()
    it("should merge the given tables", function()
      local TestCases = {
        {{},{},{},{}},
        {{1},{2},{2},{1}},
        {{a=1,b=1}, {b=2}, {'b'}, {a=1,b=2}},
        {{a=1,b=1}, {a=2,b=3}, nil, {a=2,b=3}}
      }
      for _, tc in ipairs(TestCases) do
        local t1, t2, keys, expected = tc[1], tc[2], tc[3], tc[4]
        assert.same(expected, tablex.update(t1, t2, keys))
      end
    end)
  end)
  describe("#merge", function()
    it("should merge the given tables", function()
      local TestCases = {
        {{{},{}},{},0},
        {{{1},{}},{1},0},
        {{{1},{2}},{2},1},
        {{{1},{[2]=2}},{1,2},0},
        {{{a=1,b=1}, {2}, {c={}}},{a=1,b=1,2,c={}},0}
      }
      for _, tc in ipairs(TestCases) do
        local dupes = 0
        local args, expected, expected_dupes = tc[1], tc[2], tc[3]
        args[#args + 1] = function(_, _, new_value)
          dupes = dupes + 1
          return new_value
        end
        assert.same(expected, tablex.merge(table.unpack(args)))
        assert.are_equal(expected_dupes, dupes)
      end
    end)
  end)
  describe("remove_keys", function()
    it("should remove the given keys", function()
      local t = {}
      tablex.remove_keys(t, {})
      assert.same({}, t)

      t = {a=1, 'b'}
      tablex.remove_keys(t, {})
      assert.same({a=1, 'b'}, t)

      t = {a=1, 'b'}
      tablex.remove_keys(t, {1})
      assert.same({a=1}, t)

      t = {a=1, 'b'}
      tablex.remove_keys(t, {'a'})
      assert.same({'b'}, t)
    end)
  end)
  describe("clear", function()
    it("should clear a table", function()
      local t = {}
      tablex.clear(t)
      assert.is_nil(next(t))

      t = {a=1, "a"}
      tablex.clear(t)
      assert.is_nil(next(t))
    end)
  end)
  describe("values", function()
    it("should return an iterator over the table's values", function()
      local src = {1, 2, 3, 4, 5}
      local dst = {}
      for v in tablex.values(src) do
        dst[#dst + 1] = v
      end
      assert.same(src, dst)

      src = {a = 1, b = 2}
      dst = {}
      for v in tablex.values(src) do
        dst[v] = true
      end
      for _, v in pairs(src) do
        assert.is_not_nil(dst[v])
      end
    end)
  end)
  describe("with", function()
    it("should generate a table with the given generator", function()
      assert.same({}, tablex.with(0, function(i) return i end))
      assert.same({1,2,3}, tablex.with(3, function(i) return i, i end))
    end)
  end)
  describe("aggregate", function()
    it("should aggregate to a value", function()
      assert.are_equal(0, tablex.aggregate({}, 0, function(_, v, acc)
        return v + acc
      end))
      assert.are_equal(350, tablex.aggregate(fixtures(), 0, function(_, v, acc)
        return v.price + acc
      end))
    end)
  end)
  describe("all", function()
    it("should return true if the condition is true for all the key-value pairs of the table", function()
      assert.is_true(tablex.all(fixtures(), function() return true end))
      assert.is_true(tablex.all(fixtures(), function(_, v) return v.price > 0 end))
      assert.is_true(tablex.all(fixtures(), function(_, v) return v.price < 1000 end))
      assert.is_true(tablex.all(fixtures(), function(_, v) return v.name ~= 'pear' end))
    end)
    it("should return false if the condition is false for any of the  key-value pairs of the table", function()
      assert.is_false(tablex.all(fixtures(), function()return false end))
      assert.is_false(tablex.all(fixtures(), function(_, v) return v.price <= 0 end))
      assert.is_false(tablex.all(fixtures(), function(_, v) return v.price >= 1000 end))
      assert.is_false(tablex.all(fixtures(), function(_, v) return v.name ~= 'apple' end))
    end)
  end)
  describe("any", function()
    it("should return true if the condition is true for any the key-value pairs of the table", function()
      assert.is_true(tablex.any(fixtures(), function() return true end))
      assert.is_true(tablex.any(fixtures(), function(_, v) return v.price > 0 end))
      assert.is_true(tablex.any(fixtures(), function(_, v) return v.price < 1000 end))
      assert.is_true(tablex.any(fixtures(), function(_, v) return v.name ~= 'pear' end))
    end)
    it("should return false if the condition is false for all of the  key-value pairs of the table", function()
      assert.is_false(tablex.any(fixtures(), function()return false end))
      assert.is_false(tablex.any(fixtures(), function(_, v) return v.price <= 0 end))
      assert.is_false(tablex.any(fixtures(), function(_, v) return v.price >= 1000 end))
      assert.is_false(tablex.any(fixtures(), function(_, v) return v.name == 'pear' end))
    end)
  end)
  describe("sum", function()
    it("should return the sum of the elements of the table after the transform has been applied", function()
      assert.are_equal(0, tablex.sum({}))
      assert.are_equal(6, tablex.sum(fixtures2()))
      assert.are_equal(6, tablex.sum(fixtures2(), function(_, v) return v end))
    end)
    it("should report bad arguments", function()
      assert.error(function()
        tablex.sum({"not a number"})
      end)
    end)
  end)
  describe("group_by", function()
    it("should group elements by the given selector", function()
      assert.same({[1]={[1]=1,[2]=1},[3]={[3]=3,[4]=3},[5]={[5]=5,[6]=5}}, tablex.group_by({1,1,3,3,5,5}, function(_, v) return v end))
    end)
  end)
  describe("max", function()
    it("should return maximum element in the table", function()
      assert.is_nil(tablex.max({}))
      assert.same({3,3}, {tablex.max({1,2,3})})
    end)
    describe("max_by", function()
      it("should return maximum element in the table according to f", function()
        assert.is_nil(tablex.max_by({}, function(x)
          return x
        end))
        assert.same({1,apple()}, {tablex.max_by(fixtures(), function(x) return x.price end)})
      end)
    end)
    it("should report bad arguments", function()
      assert.error(function()
        tablex.max({{}, {}})
      end)
    end)
  end)
  describe("min", function()
    it("should return minimum element in the table", function()
      assert.is_nil(tablex.min({}))
      assert.same({1,1}, {tablex.min({1,2,3})})
    end)
    describe("min_by", function()
      it("should return minimum element in the table according to f", function()
        assert.is_nil(tablex.min_by({}, function(x)
          return x
        end))
        assert.same({2,banana()}, {tablex.min_by(fixtures(), function(x) return x.price end)})
      end)
    end)
    it("should report bad arguments", function()
      assert.error(function()
        tablex.min({{}, {}})
      end)
    end)
  end)
  describe("avg", function()
    it("should return the average of the elements of the table after the transform has been applied", function()
      assert.is_nil(tablex.avg({}))
      assert.are_equal(2, tablex.avg(fixtures2()))
      assert.are_equal(4, tablex.avg(fixtures2(), function(_, v) return 2 * v end))
    end)
    it("should report bad arguments", function()
      assert.error(function()
        tablex.avg({"not a number"})
      end)
    end)
  end)
  describe("fill", function()
    it("should fill the table with the right value", function()
      assert.same({1,1,1}, tablex.fill({1,2,3}, 1))
      assert.same({}, tablex.fill({1,2,3}))
    end)
  end)
  describe("eq", function()
    it("should return true when the tables are the same", function()
      local t = {}
      assert.is_true(tablex.eq(t, t))
      assert.is_true(tablex.eq({}, {}))
      assert.is_true(tablex.eq(fixtures(), fixtures()))
    end)
    it("should return false when the tables are not the same", function()
      assert.is_false(tablex.eq({}, nil))
      assert.is_false(tablex.eq(nil, {}))
      assert.is_false(tablex.eq({}, fixtures()))
      assert.is_false(tablex.eq({1}, {2}))
      assert.is_false(tablex.eq({a=1}, {a=2}))
      assert.is_false(tablex.eq({a=1}, {a="2"}))
      assert.is_false(tablex.eq({a=1}, {b=2}))
      assert.is_false(tablex.eq(fixtures(), fixtures2()))
    end)
  end)
  describe("is_empty", function()
    it("should return true if the table is empty", function()
      assert.is_true(tablex.is_empty({}))
    end)
    it("should return false if the table is not empty", function()
      assert.is_false(tablex.is_empty(fixtures()))
    end)
  end)
  describe("count", function()
    it("should count all the key-value pairs satisfying the given condition", function()
      assert.are_equal(3, tablex.count(fixtures(), function() return true end))
      assert.are_equal(3, tablex.count(fixtures(), function(_, v) return v.price > 0 end))
      assert.are_equal(0, tablex.count(fixtures(), function(_, v) return v.price < 0 end))
      assert.are_equal(1, tablex.count(fixtures(), function(_, v) return v.name == 'apple' end))
    end)
  end)
  describe("find", function()
    it("should return the key-value pair satisfying the given condition", function()
      local k, v = tablex.find(fixtures(), function(_, v)
        return v.name == 'apple'
      end)
      assert.is_false(k == nil)
      assert.is_false(v == nil)
    end)
  end)
  describe("contains_value", function()
    it("should return true if the value pair is in the table", function()
      assert.is_true(tablex.contains_value(fixtures(), 'apple', function(x, y)
        return x.name == y
      end))
    end)
    it("should return false if the value pair is in not the table", function()
      assert.is_false(tablex.contains_value(fixtures(), 'pear', function(x, y)
        return x.name == y
      end))
    end)
  end)
  describe("filter", function()
    it("should return all the key-value pairs satisfying the specified condition", function()
      assert.same({}, tablex.filter(fixtures(), function() return false end))
      assert.same(fixtures(), tablex.filter(fixtures(), function() return true end))
      assert.same({apple()}, tablex.filter(fixtures(), function(_, v)
        return v.name == 'apple'
      end))
    end)
  end)
  describe("map", function()
    it("should return the right values", function()
      assert.same({}, tablex.map({}, function() return true end))
      assert.same({a = 2}, tablex.map({a = 1}, function(k, v)
        return k, v * 2
      end))
    end)
  end)
  describe("remove_if", function()
    it("should remove a key-value pair satisfying the specified condition", function()
      assert.is_true(tablex.remove_if(fixtures(), function(_, v)
        return v.name == 'apple'
      end))
      assert.is_false(tablex.remove_if(fixtures(), function(_, v)
        return v.price > 1000
      end))
    end)
  end)
  describe("remove_all_if", function()
    it("should remove all the key-value pairs satisfying the specified condition", function()
      assert.are_equal(2, tablex.remove_all_if({a = 1, b = 2, c = 2, d = 4}, function(_, v)
        return v == 2
      end))
      assert.are_equal(0, tablex.remove_all_if({a = 1, b = 2, c = 2, d = 4}, function(_, v)
        return v == 5
      end))
    end)
  end)
  describe("copy", function()
    it("should copy all elements", function()
      assert.same(fixtures(), tablex.copy(fixtures(), {}))
      assert.same({a=1}, tablex.copy({a=1,b=2}, {}, {'a'}))
    end)
  end)
  describe("keys", function()
    it("should return the keys of the table", function()
      assert.same({"color","name","price"}, tablex.keys(apple(), true))
    end)
  end)
  describe("contains_key", function()
    it("should return true if the key is in the table", function()
      assert.is_true(tablex.contains_key(apple(), 'color'))
      assert.is_true(tablex.contains_key(apple(), 'name'))
      assert.is_true(tablex.contains_key(apple(), 'price'))
      assert.is_true(tablex.contains_key(apple(), 'color', function(x, y)
        return x == y
      end))
    end)
    it("should return false if the key is not in the table", function()
      assert.is_false(tablex.contains_key(apple(), 'not_a_key'))
      assert.is_false(tablex.contains_key(apple(), 'not_a_key', function(x, y)
        return x == y
      end))
    end)
  end)
  describe("each_pair", function()
    it("should iterate each pair of values", function()
      local t = {a='a', b='b', 1, 2, 3}
      local q = {}
      tablex.each_pair(t, function(k, v)
        assert.is_nil(q[k])
        q[k] = v
      end)
      assert.are_same(t, q)
    end)
  end)
  describe("to_string", function()
    it("should convert a table into a string", function()
      local s = tablex.to_string(apple())
      assert.not_nil(s:find("['color']='red'", 1, true))
      assert.not_nil(s:find("['name']='apple'", 1, true))
      assert.not_nil(s:find("['price']=200", 1, true))
    end)
    it("should convert a table into a string", function()
      local t = {}
      t.a = 1
      t.b = "'s'"
      t.c = {}
      t.c.a = {1, 2, 3}
      t.c.b = t.c
      t.c.c = print
      local s = tablex.to_string(t)
      assert.are_equal("{['a']=1,['b']=\"'s'\",['c']={['a']={[1]=1,[2]=2,[3]=3},['b']=<table>,['c']=<" .. tostring(print).. ">}}", s)
    end)
  end)
end)
