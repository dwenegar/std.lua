--- Pattern-based rules for English word inflection.
-- A Lua port of Tom De Smedt's inflector for Python:
-- https://github.com/clips/pattern
-- It provides only pluralization and singularization on nouns and adjectives
--
-- -- @usage
-- local inflector = require 'std.inflector'
--
-- @module std.inflector
local M = {}

local array = require 'std.array'
local stringx = require 'std.stringx'
local re = require 'std.re'

local pairs = pairs
local ipairs = ipairs
local type = type
local tbl_unpack = table.unpack
local tbl_sort = table.sort

local _ENV = M

NOUN, ADJECTIVE = 'NOUN', 'ADJECTIVE'

do
  local rules = {}

  local function rule(must_match, article, must_not_match)
    if must_not_match and type(must_not_match) == 'string' then
      must_not_match = re.any_of(must_not_match)
    end
    if type(must_match) == 'string' then
      must_match = re.any_of(must_match)
    end

    rules[#rules + 1] = {must_match, article, must_not_match}
  end

  -- LuaFormatter off
  -- cspell: disable

  -- exceptions
  rule('euler', 'an')
  rule('hour', 'an')
  rule('heir', 'an')
  rule('honest', 'an')
  rule('hono', 'an')

  rule('^[FHLMNRSX][A-Z]', 'an', re.any_of('^FJO', '^[HLMNS]Y.', '^RY[EO]',
    '^SQU', '^F[LR]?[AEIOU]', '^[HL][AEIOU]', '^MN?[AEIOU]', '^N[AEIOU]',
    '^RH?[AEIOU]', '^S[CHKLMNPTVW]?[AEIOU]', '^X(YL)?[AEIOU]'))

  rule('^[aefhilmnorsx][.-]', 'an')
  rule('^[a-z][.-]', 'a' )
  -- consonants: a bear
  rule('^[^aeiouy]', 'a' )
  -- -eu like 'you': a european
  rule('^e[uw]', 'a' )
  --  -o like 'wa' : a one-liner
  rule('^onc?e', 'a' )
  --  -u like 'you': a university
  rule('^uni[^nmd]', 'a' )
  rule('^unimo', 'a' )
  --  -u like 'you': a uterus
  rule('^u[bcfhjkqrst][aeiou]', 'a' )
  -- vowels: an owl
  rule('^[aeiou]', 'an')
  -- y like 'i': an yclept, a year
  rule('^yb[lor]', 'an')
  rule('^ycl[ea]', 'an')-- y like 'i': an yclept, a year
  rule('^yfere', 'an')
  rule('^ygg', 'an')
  rule('^yp[ios]', 'an')
  rule('^yrou', 'an')
  rule('^ytt', 'an')
  -- guess 'a'
  rule('', 'a' )

  -- LuaFormatter on
  -- cspell: enable

  function definite_article()
    return 'the'
  end

  function undefinite_article(w)
    for _, e in ipairs(rules) do
      if #e == 2 or not e[3](w) then
        if e[1](w) then
          return e[2]
        end
      end
    end
  end

  function article(w, definite)
    return definite and definite_article() or undefinite_article(w)
  end

  function referenced(w, definite)
    return ('%s %s'):format(article(w, definite), w)
  end
end

local plural_prepositions
do
  local prepositions = array.to_set {
    'about', 'before', 'during', 'of', 'till', 'above', 'behind', 'except', 'off', 'to', 'across', 'below', 'for', 'on',
    'under', 'after', 'beneath', 'from', 'onto', 'until', 'among', 'beside', 'in', 'out', 'unto', 'around', 'besides',
    'into', 'over', 'upon', 'at', 'between', 'near', 'since', 'with', 'athwart', 'betwixt', 'beyond', 'but', 'by'
  }

  plural_prepositions = prepositions

  -- LuaFormatter off
  -- cspell: disable

  local rules = {
    -- 0) Indefinite articles and demonstratives.
    {
      { '^a$$', 'some', nil, false },
      { '^an$', 'some', nil, false },
      { '^this$', 'these', nil, false },
      { '^that$', 'those', nil, false },
      { '^any$', 'all', nil, false }
    },
    -- 1) Possessive adjectives.
    {
      { '^my$', 'our', nil, false },
      { '^your$', 'your', nil, false },
      { '^thy$', 'your', nil, false },
      { '^her$', 'their', nil, false },
      { '^his$', 'their', nil, false },
      { '^its$', 'their', nil, false },
      { '^their$', 'their', nil, false }
    },
    -- 2) Possessive pronouns.
    {
      { '^mine$', 'ours', nil, false },
      { '^yours$', 'yours', nil, false },
      { '^thine$', 'yours', nil, false },
      { '^her$', 'theirs', nil, false },
      { '^his$', 'theirs', nil, false },
      { '^its$', 'theirs', nil, false },
      { '^their$', 'theirs', nil, false }
    },
    -- 3) Personal pronouns.
    {
      { '^I$', 'we', nil, false },
      { '^me$', 'us', nil, false },
      { '^myself$', 'ourselves', nil, false },
      { '^you$', 'you', nil, false },
      { '^thee$', 'ye', nil, false },
      { '^thou$', 'ye', nil, false },
      { '^yourself$', 'yourself', nil, false },
      { '^thyself$', 'yourself', nil, false },
      { '^she$', 'they', nil, false },
      { '^he$', 'they', nil, false },
      { '^it$', 'they', nil, false },
      { '^they$', 'they', nil, false },
      { '^her$', 'them', nil, false },
      { '^him$', 'them', nil, false },
      { '^it$', 'them', nil, false },
      { '^them$', 'them', nil, false },
      { '^herself$', 'themselves', nil, false },
      { '^himself$', 'themselves', nil, false },
      { '^itself$', 'themselves', nil, false },
      { '^themself$', 'themselves', nil, false },
      { '^oneself$', 'oneselves', nil, false }
    },
    -- 4) Words that do not inflect.
    {
      { '$', '', 'uninflected', false },
      { '$', '', 'uncountable', false },
      { 's$', 's', 's-singular', false },
      { 'fish$', 'fish', nil, false },
      { '([- ])bass$', '%1bass', nil, false },
      { 'ois$', 'ois', nil, false },
      { 'sheep$', 'sheep', nil, false },
      { 'deer$', 'dee', nil, false },
      { 'pox$', 'pox', nil, false },
      { '([A-Z].*)ese$', '%1ese', nil, false },
      { 'itis$', 'itis', nil, false },
      { '(fruct)ose$', '%1ose', nil, false },
      { '(gluc)ose$', '%1ose', nil, false },
      { '(galact)ose$', '%1ose', nil, false },
      { '(lact)ose$', '%1ose', nil, false },
      { '(ket)ose$', '%1ose', nil, false },
      { '(malt)ose$', '%1ose', nil, false },
      { '(rib)ose$', '%1ose', nil, false },
      { '(sacchar)ose$', '%1ose', nil, false },
      { '(cellul)ose$', '%1ose', nil, false },
    },
    -- 5) Irregular plural forms{e.g., mongoose, oxen}.
    {
      { 'atlas$', 'atlantes', nil, true },
      { 'atlas$', 'atlases', nil, false },
      { 'beef$', 'beeves', nil, true },
      { 'brother$', 'brethren', nil, true },
      { 'child$', 'children', nil, false },
      { 'corpus$', 'corpora', nil, true },
      { 'corpus$', 'corpuses', nil, false },
      { '^cow$', 'kine', nil, true },
      { 'ephemeris$', 'ephemerides', nil, false },
      { 'ganglion$', 'ganglia', nil, true },
      { 'genie$', 'genii', nil, true },
      { 'genus$', 'genera', nil, false },
      { 'graffito$', 'graffiti', nil, false },
      { 'loaf$', 'loaves', nil, false },
      { 'money$', 'monies', nil, true },
      { 'mongoose$', 'mongooses', nil, false },
      { 'mythos$', 'mythoi', nil, false },
      { 'octopus$', 'octopodes', nil, true },
      { 'opus$', 'opera', nil, true },
      { 'opus$', 'opuses', nil, false },
      { '^ox$', 'oxen', nil, false },
      { 'penis$', 'penes', nil, true },
      { 'penis$', 'penises', nil, false },
      { 'soliloquy$', 'soliloquies', nil, false },
      { 'testis$', 'testes', nil, false },
      { 'trilby$', 'trilbys', nil, false },
      { 'turf$', 'turves', nil, true },
      { 'numen$', 'numena', nil, false },
      { 'occiput$', 'occipita', nil, true }
    },
    -- 6) Irregular inflections for common suffixes
    -- (e.g., synopses, mice, men).
    {
      { 'man$', 'men', nil, false },
      { 'person$', 'people', nil, false },
      { '([lm])ouse$', '%1ice', nil, false },
      { 'tooth$', 'teeth', nil, false },
      { 'goose$', 'geese', nil, false },
      { 'foot$', 'feet', nil, false },
      { 'zoon$', 'zoa', nil, false },
      { '([csx])is$', '%1es', nil, false }
    },
    -- 7) Fully assimilated classical inflections
    -- (e.g., vertebrae, codices).
    {
      { 'ex$', 'ices', 'ex-ices', false },
      { 'ex$', 'ices', 'ex-ices*', true },-- * = classical mode
      { 'um$', 'a', 'um-a', false },
      { 'um$', 'a', 'um-a*', true },
      { 'on$', 'a', 'on-a', false },
      { 'a$', 'ae', 'a-ae', false },
      { 'a$', 'ae', 'a-ae*', true }
    },
    -- 8) Classical variants of modern inflections
    -- (e.g., stigmata, soprani).
    {
      { 'trix$', 'trices', nil, true},
      { 'eau$', 'eaux', nil, true},
      { 'ieu$', 'ieu', nil, true},
      { '([iay])nx$', '%1nges', nil, true},
      { 'en$', 'ina', 'en-ina*', true},
      { 'a$', 'ata', 'a-ata*', true},
      { 'is$', 'ides', 'is-ides*', true},
      { 'us$', 'i', 'us-i*', true},
      { 'us$', 'us ', 'us-us*', true},
      { 'o$', 'i', 'o-i*', true},
      { '$', 'i', '-i*', true},
      { '$', 'im', '-im*', true}
    },
    -- 9) -ch, -sh and -ss take -es in the plural
    -- (e.g., churches, classes).
    {
      { '([cs])h$', '%1hes', nil, false },
      { 'ss$', 'sses', nil, false },
      { 'x$', 'xes', nil, false }
    },
    -- 10) -f or -fe sometimes take -ves in the plural
    -- (e.g, lives, wolves).
    {
      { '([aeo]l)f$', '%1ves', nil, false },
      { '([^d]ea)f$', '%1ves', nil, false },
      { 'arf$', 'arves', nil, false },
      { '([nlw]i)fe$', '%1ves', nil, false },
    },
    -- 11) -y takes -ys if preceded by a vowel, -ies otherwise
    -- (e.g., storeys, Marys, stories).
    {
      { '([aeiou])y$', '%1ys', nil, false },
      { '([A-Z].*)y$', '%1ys', nil, false },
      { 'y$', 'ies', nil, false }
    },
    -- 12) -o sometimes takes -os, -oes otherwise.
    -- -o is preceded by a vowel takes -os
    -- (e.g., lassos, potatoes, bamboos).
    {
      { 'o$', 'os', 'o-os', false },
      { '([aeiou])o$', '%1os', nil, false },
      { 'o$', 'oes', nil, false }
    },-- 13) Miltary stuff
    -- (e.g., Major Generals).
    {
      { 'l$', 'ls', 'general-generals', false },
    },
    -- 14) Assume that the plural takes -s
    -- (e.g., cats, programmes, ...).
    {
      { '$', 's', nil, false }
    }
  }

  local categories = {
    ['uninflected'] = {
       'bison', 'debris', 'headquarters', 'news', 'swine', 'bream', 'diabetes', 'herpes',
       'pincers', 'trout', 'breeches', 'djinn', 'high-jinks', 'pliers', 'tuna', 'britches',
       'eland', 'homework', 'proceedings', 'whiting', 'carp', 'elk', 'innings', 'rabies',
       'wildebeest', 'chassis', 'flounder', 'jackanapes', 'salmon', 'clippers', 'gallows',
       'mackerel', 'scissors', 'cod', 'graffiti', 'measles', 'series', 'contretemps', 'mews',
       'shears', 'corps', 'mumps', 'species'
     },
     ['uncountable'] = {
       'advice', 'fruit', 'ketchup', 'meat', 'sand', 'bread', 'furniture', 'knowledge',
       'mustard', 'software', 'butter', 'garbage', 'love', 'news', 'understanding',
       'cheese', 'gravel', 'luggage', 'progress', 'water', 'electricity', 'happiness',
       'mathematics', 'research', 'equipment', 'information', 'mayonnaise', 'rice'
     },
     ['s-singular'] = {
       'acropolis', 'caddis', 'dais', 'glottis', 'pathos', 'aegis', 'cannabis', 'digitalis',
       'ibis', 'pelvis', 'alias', 'canvas', 'epidermis', 'lens', 'polis', 'asbestos' ,
       'chaos', 'ethos', 'mantis', 'rhinoceros', 'bathos', 'cosmos', 'gas', 'marquis' ,
       'sassafras', 'bias', 'glottis', 'metropolis', 'trellis'
     },
     ['ex-ices'] = {
       'codex', 'murex', 'silex'
     },
     ['ex-ices*'] = {
       'apex', 'index', 'pontifex', 'vertex', 'cortex', 'latex', 'simplex', 'vortex'
     },
     ['um-a'] = {
       'agendum', 'candelabrum', 'desideratum', 'extremum', 'stratum', 'bacterium' ,
       'datum', 'erratum', 'ovum'
     },
     ['um-a*'] = {
       'aquarium', 'emporium', 'maximum', 'optimum', 'stadium', 'compendium', 'enconium' ,
       'medium', 'phylum', 'trapezium', 'consortium', 'gymnasium', 'memorandum', 'quantum',
       'ultimatum', 'cranium', 'honorarium', 'millenium', 'rostrum', 'vacuum', 'curriculum',
       'interregnum', 'minimum', 'spectrum', 'velum', 'dictum', 'lustrum', 'momentum', 'speculum'
     },
     ['on-a'] = {
       'aphelion', 'hyperbaton', 'perihelion', 'asyndeton', 'noumenon', 'phenomenon', 'criterion',
       'organon', 'prolegomenon'
     },
   ['a-ae'] = {
      'alga', 'alumna', 'vertebra'
    },
   ['a-ae*'] = {
      'abscissa', 'aurora', 'hyperbola', 'nebula', 'amoeba', 'formula', 'lacuna', 'nova',
      'antenna', 'hydra', 'medusa', 'parabola'
    },
   ['en-ina*'] = {
      'foramen', 'lumen', 'stamen'
    },
   ['a-ata*'] = {
      'anathema', 'dogma', 'gumma', 'miasma', 'stigma', 'bema', 'drama', 'lemma', 'schema',
      'stoma', 'carcinoma', 'edema', 'lymphoma', 'oedema', 'trauma', 'charisma', 'enema',
      'magma', 'sarcoma', 'diploma', 'enigma', 'melisma', 'soma',
    },
   ['is-ides*'] = {
      'clitoris', 'iris'
    },
   ['us-i*'] = {
      'focus', 'nimbus', 'succubus', 'fungus', 'nucleolus', 'torus', 'genius', 'radius',
      'umbilicus', 'incubus', 'stylus', 'uterus'
    },
   ['us-us*'] = {
      'apparatus', 'hiatus', 'plexus', 'status', 'cantus', 'impetus', 'prospectus',
      'coitus', 'nexus', 'sinus',
    },
   ['o-i*'] = {
      'alto', 'canto', 'crescendo', 'soprano', 'basso', 'contralto', 'solo', 'tempo'
    },
   ['-i*'] = {
      'afreet', 'afrit', 'efreet'
    },
   ['-im*'] = {
      'cherub', 'goy', 'seraph'
    },
   ['o-os'] = {
      'albino', 'dynamo', 'guano', 'lumbago', 'photo', 'archipelago', 'embryo', 'inferno',
      'magneto', 'pro', 'armadillo', 'fiasco', 'jumbo', 'manifesto', 'quarto', 'commando',
      'generalissimo', 'medico', 'rhino', 'ditto', 'ghetto', 'lingo', 'octavo', 'stylo'
    },
   ['general-generals'] = {
      'adjutant', 'brigadier', 'lieutenant', 'major', 'quartermaster'
    }
  }

  -- LuaFormatter on
  -- cspell: enable

  function pluralize(word, pos, classical, custom)
    pos = pos and pos or NOUN

    if custom and custom[word] then
      return custom[word]
    end

    local w
    if stringx.ends_with(word, '\'s') or stringx.ends_with(word, '\'') then
      w = stringx.trim_right(word, '\'s')
      w = pluralize(w, pos, classical, custom)
      return w .. (stringx.ends_with(w, 's') and '\'' or '\'s')
    end

    w = stringx.split((word:gsub('-', ' ')))
    if #w > 1 then
      if w[2] == 'general' and not categories['general-generals'][w[1]] then
        return word:gsub(w[1], pluralize(w[1], pos, classical, custom))
      elseif prepositions[w[2]] then
        return (word:gsub(w[1], pluralize(w[1], pos, classical, custom)))
      end
      return (word:gsub(w[#w], pluralize(w[#w], pos, classical, custom)))
    end

    local function pluralize(n)
      for i = 1, n do
        for _, e in ipairs(rules[i]) do
          local suffix, inflection, category, classic = tbl_unpack(e)
          if (not category or categories[category][word]) and (not classic or classical) then
            if word:find(suffix) then
              return (word:gsub(suffix, inflection))
            end
          end
        end
      end
      return word
    end
    if pos == ADJECTIVE then
      return pluralize(1)
    end
    return pluralize(#rules)
  end
end

do
  -- LuaFormatter off
  -- cspell: disable

  local rules = {
    { '(.)ae$', '%1a' },
    { '(.)itis$', '%1itis' },
    { '(.)eaux$', '%1eau' },
    { 'quizzes$', 'quiz' },
    { 'matrices$', 'matrix' },
    { 'apices$', 'apex' },
    { 'vertices$', 'vertex' },
    { 'indices$', 'index' },
    { 'oxen', 'ox' },
    { 'aliases$', 'alias' },
    { 'statuses$', 'status' },
    { 'octopi$', 'octopus' },
    { 'crises$', 'crisis' },
    { 'axes$', 'ax' },
    { 'testes$', 'testis' },
    { 'shoes$', 'shoe' },
    { 'oes$', 'oe' },
    { 'buses$', 'bus' },
    { '([lm])ice$', '%1ouse' },
    { 'xes$', 'x' },
    { 'ches$', 'ch' },
    { '(s[sh])es$', '%1' },
    { 'movies$', 'movie' },
    { '(.)ombies$', '%1ombie' },
    { 'series$', 'series' },
    { '([^aeiouy])ies$', '%1y' },
    { 'quies$', 'quy' },
    -- -f, -fe sometimes take -ves in the plural
    -- (e.g., lives, wolves).
    { '([aeo]l)ves$' , '%1f' },
    { '([^d]ea)ves$' , '%1f' },
    { 'arves$' , 'arf' },
    { 'erves$' , 'erve' },
    { '([nlw]i)ves$' , '%1fe' },
    { '([lr])ves$', '%1f' },
    { '([aeo])ves$' , '%1ve' },
    { 'sives$', 'sive' },
    { 'tives$', 'tive' },
    { 'hives$', 'hive' },
    { '([^f])ves$', '%1fe' },
    -- -ses suffixes.
    { 'analyses$', 'analysis' },
    { 'bases$', 'basis' },
    { 'diagnoses$', 'diagnosis' },
    { 'parentheses$', 'parenthesis' },
    { 'prognoses$', 'prognosis' },
    { 'synopses$', 'synopsis' },
    { 'theses$', 'thesis' },
    { '(.)opses$', '%1opsis' },
    { '(.)yses$', '%1ysis' },
    { '([hdronbp])oses$', '%1ose' },
    { 'closes', 'close' },
    { 'fructose$', 'fructose' },
    { 'glucose$', 'glucose' },
    { 'galactose$', 'galactose' },
    { 'lactose$', 'lactoose' },
    { 'ketose$', 'ketose' },
    { 'maltose$', 'maltose' },
    { 'ribose$', 'ribose' },
    { 'saccharose$', 'saccharose' },
    { 'cellulose$', 'cellulose' },
    { '(.)oses$', '%1osis' },
    -- -a
    { '([ti])a$', '%1um' },
    { 'news$', 'news' },
    { 's$', '' },
  }

  local uninflected = array.to_set {
    'bison', 'debris', 'headquarters', 'pincers', 'trout',
    'bream', 'diabetes', 'herpes', 'pliers', 'tuna', 'breeches', 'djinn', 'high-jinks',
    'proceedings', 'whiting', 'britches', 'eland', 'homework', 'rabies', 'wildebeest',
    'carp', 'elk', 'innings', 'salmon', 'chassis', 'flounder', 'jackanapes', 'scissors',
    'christmas', 'gallows', 'mackerel', 'series', 'clippers', 'georgia', 'measles', 'shears',
    'cod', 'graffiti', 'mews', 'species',	'contretemps', 'mumps', 'swine', 'corps', 'news',
    'swiss'
  }

  local uncountables = array.to_set {
    'advice', 'equipment', 'happiness', 'luggage', 'news', 'software',
    'bread', 'fruit', 'information', 'mathematics', 'progress', 'understanding', 'butter',
    'furniture', 'ketchup', 'mayonnaise', 'research', 'water', 'cheese', 'garbage', 'knowledge',
    'meat', 'rice', 'electricity', 'gravel', 'love', 'mustard', 'sand'
  }

  local ie = array.to_set {
    'alergie', 'cutie', 'hoagie', 'newbie', 'softie', 'veggie', 'auntie', 'doggie',
    'hottie', 'nightie', 'sortie', 'weenie', 'beanie', 'eyrie', 'indie', 'oldie', 'stoolie',
    'yuppie', 'birdie', 'freebie', 'junkie', 'pie', 'sweetie', 'zombie', 'bogie', 'goonie',
    'laddie', 'pixie', 'techie', 'bombie', 'groupie', 'laramie', 'quickie', 'tie', 'collie',
    'hankie', 'lingerie', 'reverie', 'toughie', 'cookie', 'hippie', 'meanie', 'rookie', 'valkyrie'
  }

  local irregulars = {
    ['atlantes$'] = 'atlas',
    ['atlases$'] = 'atlas',
    ['axes$'] = 'axe',
    ['beeves$'] = 'beef',
    ['brethren$$'] = 'brother',
    ['children$'] = 'child',
    ['corpora$'] = 'corpus',
    ['corpuses$'] = 'corpus',
    ['ephemerides$'] = 'ephemeris',
    ['feet$'] = 'foot',
    ['ganglia$'] = 'ganglion',
    ['geese$'] = 'goose',
    ['genera$'] = 'genus',
    ['genii$'] = 'genie',
    ['graffiti$'] = 'graffito',
    ['helves$'] = 'helve',
    ['kine$'] = 'cow',
    ['leaves$'] = 'leaf',
    ['loaves$'] = 'loaf',
    ['men$'] = 'man',
    ['mongooses$'] = 'mongoose',
    ['monies$'] = 'money',
    ['moves$'] = 'move',
    ['mythoi$'] = 'mythos',
    ['numena$'] = 'numen',
    ['occipita$'] = 'occiput',
    ['octopodes$'] = 'octopus',
    ['opera$'] = 'opus',
    ['opuses$'] = 'opus',
    ['our$'] = 'my',
    ['oxen$'] = 'ox',
    ['penes$'] = 'penis',
    ['penises$'] = 'penis',
    ['people$'] = 'person',
    ['sexes$'] = 'sex',
    ['soliloquies$'] = 'soliloquy',
    ['teeth$'] = 'tooth',
    ['testes$'] = 'testis',
    ['trilbys$'] = 'trilby',
    ['turves$'] = 'turf',
    ['zoa$'] = 'zoon'
  }

  -- LuaFormatter on
  -- cspell: enable

  function singularize(word, pos, custom)
    pos = pos or NOUN
    if custom and custom[word] then
      return custom[word]
    end

    local w = word:gsub('-', ' '):split(' ')
    if #w > 1 and plural_prepositions[w[1]] then
      return (word:gsub(w[1], singularize(w[1], pos, custom)))
    end
    if stringx.ends_with(word, '\'') then
      return singularize(word:sub(1, -2)) .. '\'s'
    end
    for x in pairs(uninflected) do
      if stringx.ends_with(word, x) then
        return word
      end
    end
    for x in pairs(uncountables) do
      if stringx.ends_with(word, x) then
        return word
      end
    end
    for x in pairs(ie) do
      if stringx.ends_with(word, x .. 's') then
        return x
      end
    end
    for x, singular in pairs(irregulars) do
      if word:find(x) then
        return (word:gsub(x, singular))
      end
    end
    for _, rule in ipairs(rules) do
      if word:find(rule[1]) then
        return (word:gsub(rule[1], rule[2]))
      end
    end
    return word
  end
end

local acronyms = {list = {}, patterns = {}}

function acronym(word)
  acronyms.patterns[word] = {('([A-Za-z%%d])%s'):format(word), ('^%s([A-Z%%d_])'):format(word)}
  acronyms.list[#acronyms.list + 1] = word
  tbl_sort(acronyms.list, function(w1, w2)
    return w1 > w2
  end)
end

function capitalize(s)
  return s:lower():gsub('^(.)', string.upper, 1)
end

function camelize(s, uppercase_first_letter)
  local function handle_acronyms(w)
    return acronyms.patterns[w] or capitalize(w)
  end
  s = s:gsub('^([a-z%d]*)', uppercase_first_letter and handle_acronyms or string.lower)
  s = s:gsub('_([a-z%d]*)', handle_acronyms)
  return s
end

function underscore(s)
  for _, acronym in ipairs(acronyms.list) do
    local patterns = acronyms.patterns[acronym]
    s = s:gsub(patterns[1], function(m)
      return ('%s_%s'):format(m, acronym:lower())
    end)
    s = s:gsub(patterns[2], function(m)
      return ('%s%s'):format(acronym:lower(), m)
    end)
  end
  s = s:gsub('([A-Z%d]+)([A-Z%d])', '%1_%2')
  s = s:gsub('([a-z%d])([A-Z])', '%1_%2')
  s = s:gsub('-', '_')
  s = s:lower()
  return s
end

function dasherize(s)
  return s:gsub('_', '-')
end

return M
