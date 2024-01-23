local reader = require 'std.cli.reader'
local array = require 'std.array'

local Cases
do
  Cases = {
    {
      types = {'integer', 'i'},
      requires_arg = true,
      cases = {
        valid = {
          {0, '0'},
          {0, '+0'},
          {0, '-0'},
          {1, '1'},
          {1, '+1'},
          {-1, '-1'}
        },
        invalid = {
          {"invalid integer: 'invalid'", 'invalid'},
          {"invalid integer: '1.2'", '1.2'}
        }
      }
    },
    {
      types = {'number', 'float', 'n', 'f'},
      requires_arg = true,
      cases = {
        valid = {
          {0.0, '0'},
          {0.0, '+0'},
          {0.0, '-0'},
          {0.0, '0.0'},
          {0.0, '+0.0'},
          {0.0, '-0.0'},
          {1.2, '1.2'},
          {-1.2, '-1.2'},
          {1.0, '1'},
          {-1.0, '-1'},
          {1e10, '1e10'},
          {1e-10, '1e-10'},
          {1.25e10, '1.25e10'},
          {1.25e-10, '1.25e-10'}
        },
        invalid = {
          {"invalid number: 'invalid'", 'invalid'}
        }
      }
    },
    {
      types = {'char', 'c'},
      requires_arg = true,
      cases = {
        valid = {
          {'1', '1'}
        },
        invalid = {
          {"invalid char: 'too_long'", 'too_long'}
        }
      }
    },
    {
      types = {'flag', 'F'},
      requires_arg = false,
      cases = {
        valid = {
          {true}
        }
      }
    },
    {
      types = {'string', 's'},
      requires_arg = true,
      cases = {
        valid = {
          {'1', '1'},
          {'1', ' 1 '},
          {'1', '1 '},
          {'1', ' 1'},
          {'1', "'1'"},
          {' 1 ', "' 1 '"},
          {' 1 ', '\' 1 \''},
          {'a\ta', 'a\\ta'},
        }
      }
    },
    {
      types = {'boolean', 'bool', 'b'},
      requires_arg = true,
      cases = {
        valid = {
          {true,'1'},
          {true,'t'},
          {true,'T'},
          {true,'true'},
          {true,'TRUE'},
          {true,'True'},
          {true,'yes'},
          {true,'YES'},
          {true,'Yes'},
          {false,'0'},
          {false,'f'},
          {false,'F'},
          {false,'false'},
          {false,'FALSE'},
          {false,'False'},
          {false,'no'},
          {false,'NO'},
          {false,'No'}
        },
        invalid = {
          {"invalid boolean: 'invalid'", 'invalid'}
        }
      }
    }
  }

  -- tuples
  local cases = {
    ['string'] = 'xxx',
    ['number'] = 1.337,
    ['bool'] = true,
    ['integer'] = 1337,
    ['char'] = 'c'
  }

  for k1, v1 in pairs(cases) do
    for k2, v2 in pairs(cases) do
      Cases[#Cases + 1] = {
        types = {('%s=%s'):format(k1, k2)},
        requires_arg = true,
        cases = {
          valid = {
            {{v1, v2}, ('%s=%s'):format(v1, v2)}
          }
        }
      }
    end
  end

  -- list
  cases = {
    ['string'] = {'xxx', 'yyy'},
    ['number'] = {1.337, 7.331},
    ['bool'] = {true,false},
    ['integer'] = {1337, 7331},
    ['char'] = {'c','h'}
  }

  for k, v in pairs(cases) do
    Cases[#Cases + 1] = {
      types = {('[%s]'):format(k)},
      requires_arg = true,
      cases = {
        valid = {
          {v, table.concat(array.map(v, tostring), ',')}
        }
      }
    }
  end

  for k1, v1 in pairs(cases) do
    for k2, v2 in pairs(cases) do
      local expected = {}
      for _, x in ipairs(v1) do
        for _, y in ipairs(v2) do
          expected[#expected + 1] = {x, y}
        end
      end

      Cases[#Cases + 1] = {
        types = {('[%s=%s]'):format(k1, k2)},
        requires_arg = true,
        cases = {
          valid = {
            {expected, table.concat(array.map(expected, function(x)
              return ('%s=%s'):format(x[1], x[2])
            end), ',')}
          }
        }
      }
    end
  end
end

describe('#cli.reader', function()
  describe('create', function()
    for _, case in ipairs(Cases) do
      local readers = {}
      it(("should create a reader (%s)"):format(table.concat(case.types, ',')), function()
        for _, type in ipairs(case.types) do
          local r = reader.create(type)
          assert.is_not_nil(r, type)
          assert.are_equal(case.requires_arg, r.requires_arg, type)
          readers[#readers + 1] = {type = type, reader = r}
          for i = 2, #readers do
            assert.are_equal(readers[1].reader, readers[i].reader, readers[i].type)
          end
        end
      end)
    end
  end)

  describe("read", function()
    for _, case in ipairs(Cases) do
      it(("should correctly parse the input value (%s)"):format(case.types[1]), function()
        for _, valid_case in ipairs(case.cases.valid) do
          local expected, input = valid_case[1], valid_case[2]
          local r = reader.create(case.types[1])
          local value, err = r.read(input)
          assert.is_nil(err, input)
          assert.are_same(expected, value, input)
        end
      end)
      if case.cases.invalid then
        it(("should fail to parse the invalid value (%s)"):format(case.types[1]), function()
          for _, invalid_case in ipairs(case.cases.invalid) do
            local expected, input = invalid_case[1], invalid_case[2]
            local r = reader.create(case.types[1])
            local value, err = r.read(input)
            assert.is_nil(value, input)
            assert.are_same(expected, err, input)
          end
        end)
      end
    end
  end)
end)
