local inflector = require 'std.inflector'

describe('#inflector', function()

  describe('definite_article', function()
    it('should return "the"', function()
      assert.equal(inflector.definite_article(), 'the')
    end)
  end)

  describe('undefinite_article', function()
    local cases = {
      {'hour', 'an'},
      {'FBI', 'an'},
      {'bear', 'a'},
      {'one-liner', 'a'},
      {'european', 'a'},
      {'university', 'a'},
      {'uterus', 'a'},
      {'owl', 'an'},
      {'yclepy', 'an'},
      {'year', 'a'}
    }
    for _, case in ipairs(cases) do
      local word, expected = case[1], case[2]
      it(('should return %q for %q'):format(expected, word), function()
        assert.equal(expected, inflector.undefinite_article(word))
      end)
    end
  end)

  describe('pluralize', function()
    local cases = {
      {'part-of-speech', 'parts-of-speech'},
      {'child', 'children'},
      {'dog\'s', 'dogs\''},
      {'wolf', 'wolves'},
      {'bear', 'bears'},
      {'kitchen knife', 'kitchen knives'},
      {'octopus', 'octopodes', true},
      {'octopus', 'octopuses'},
      {'matrix', 'matrices', true},
      {'matrix', 'matrixes'},
      {'my', 'my', false, inflector.ADJECTIVE}
    }
    for _, case in ipairs(cases) do
      local word, expected, classical, pos = case[1], case[2], case[3], case[4]
      it(('should return %q for %q'):format(expected, word), function()
        assert.equal(expected, inflector.pluralize(word, pos, classical))
      end)
    end
  end)

end)
