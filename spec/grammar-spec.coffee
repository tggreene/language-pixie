describe "Pixie grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-pixie")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.pixie")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.pixie"

  it "tokenizes semi-colon comments", ->
    {tokens} = grammar.tokenizeLine "; pixie"
    expect(tokens[0]).toEqual value: ";", scopes: ["source.pixie", "comment.line.semicolon.pixie", "punctuation.definition.comment.pixie"]
    expect(tokens[1]).toEqual value: " pixie", scopes: ["source.pixie", "comment.line.semicolon.pixie"]

  it "tokenizes shebang comments", ->
    {tokens} = grammar.tokenizeLine "#!/usr/bin/env pixie"
    expect(tokens[0]).toEqual value: "#!", scopes: ["source.pixie", "comment.line.semicolon.pixie", "punctuation.definition.comment.shebang.pixie"]
    expect(tokens[1]).toEqual value: "/usr/bin/env pixie", scopes: ["source.pixie", "comment.line.semicolon.pixie"]

  it "tokenizes strings", ->
    {tokens} = grammar.tokenizeLine '"foo bar"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.pixie", "string.quoted.double.pixie", "punctuation.definition.string.begin.pixie"]
    expect(tokens[1]).toEqual value: 'foo bar', scopes: ["source.pixie", "string.quoted.double.pixie"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.pixie", "string.quoted.double.pixie", "punctuation.definition.string.end.pixie"]

  it "tokenizes character escape sequences", ->
    {tokens} = grammar.tokenizeLine '"\\n"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.pixie", "string.quoted.double.pixie", "punctuation.definition.string.begin.pixie"]
    expect(tokens[1]).toEqual value: '\\n', scopes: ["source.pixie", "string.quoted.double.pixie", "constant.character.escape.pixie"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.pixie", "string.quoted.double.pixie", "punctuation.definition.string.end.pixie"]

  it "tokenizes regexes", ->
    {tokens} = grammar.tokenizeLine '#"foo"'
    expect(tokens[0]).toEqual value: '#"', scopes: ["source.pixie", "string.regexp.pixie"]
    expect(tokens[1]).toEqual value: 'foo', scopes: ["source.pixie", "string.regexp.pixie"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.pixie", "string.regexp.pixie"]

  it "tokenizes numerics", ->
    numbers =
      "constant.numeric.ratio.pixie": ["1/2", "123/456"]
      "constant.numeric.arbitrary-radix.pixie": ["2R1011", "16rDEADBEEF"]
      "constant.numeric.hexadecimal.pixie": ["0xDEADBEEF", "0XDEADBEEF"]
      "constant.numeric.octal.pixie": ["0123"]
      "constant.numeric.bigdecimal.pixie": ["123.456M"]
      "constant.numeric.double.pixie": ["123.45", "123.45e6", "123.45E6"]
      "constant.numeric.bigint.pixie": ["123N"]
      "constant.numeric.long.pixie": ["123", "12321"]

    for scope, nums of numbers
      for num in nums
        {tokens} = grammar.tokenizeLine num
        expect(tokens[0]).toEqual value: num, scopes: ["source.pixie", scope]

  it "tokenizes booleans", ->
    booleans =
      "constant.language.boolean.pixie": ["true", "false"]

    for scope, bools of booleans
      for bool in bools
        {tokens} = grammar.tokenizeLine bool
        expect(tokens[0]).toEqual value: bool, scopes: ["source.pixie", scope]

  it "tokenizes nil", ->
    {tokens} = grammar.tokenizeLine "nil"
    expect(tokens[0]).toEqual value: "nil", scopes: ["source.pixie", "constant.language.nil.pixie"]

  it "tokenizes keywords", ->
    tests =
      "meta.expression.pixie": ["(:foo)"]
      "meta.map.pixie": ["{:foo}"]
      "meta.vector.pixie": ["[:foo]"]
      "meta.quoted-expression.pixie": ["'(:foo)", "`(:foo)"]

    for metaScope, lines of tests
      for line in lines
        {tokens} = grammar.tokenizeLine line
        expect(tokens[1]).toEqual value: ":foo", scopes: ["source.pixie", metaScope, "constant.keyword.pixie"]

  it "tokenizes keyfns (keyword control)", ->
    keyfns = ["declare", "declare-", "ns", "in-ns", "import", "use", "require", "load", "compile", "def", "defn", "defn-", "defmacro"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.pixie", "meta.expression.pixie", "keyword.control.pixie"]

  it "tokenizes keyfns (storage control)", ->
    keyfns = ["if", "when", "for", "cond", "do", "let", "binding", "loop", "recur", "fn", "throw", "try", "catch", "finally", "case"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.pixie", "meta.expression.pixie", "storage.control.pixie"]

  it "tokenizes global definitions", ->
    {tokens} = grammar.tokenizeLine "(def foo 'bar)"
    expect(tokens[1]).toEqual value: "def", scopes: ["source.pixie", "meta.expression.pixie", "meta.definition.global.pixie", "keyword.control.pixie"]
    expect(tokens[3]).toEqual value: "foo", scopes: ["source.pixie", "meta.expression.pixie", "meta.definition.global.pixie", "entity.global.pixie"]

  it "tokenizes dynamic variables", ->
    mutables = ["*ns*", "*foo-bar*"]

    for mutable in mutables
      {tokens} = grammar.tokenizeLine mutable
      expect(tokens[0]).toEqual value: mutable, scopes: ["source.pixie", "meta.symbol.dynamic.pixie"]

  it "tokenizes metadata", ->
    {tokens} = grammar.tokenizeLine "^Foo"
    expect(tokens[0]).toEqual value: "^", scopes: ["source.pixie", "meta.metadata.simple.pixie"]
    expect(tokens[1]).toEqual value: "Foo", scopes: ["source.pixie", "meta.metadata.simple.pixie", "meta.symbol.pixie"]

    {tokens} = grammar.tokenizeLine "^{:foo true}"
    expect(tokens[0]).toEqual value: "^{", scopes: ["source.pixie", "meta.metadata.map.pixie", "punctuation.section.metadata.map.begin.pixie"]
    expect(tokens[1]).toEqual value: ":foo", scopes: ["source.pixie", "meta.metadata.map.pixie", "constant.keyword.pixie"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.pixie", "meta.metadata.map.pixie"]
    expect(tokens[3]).toEqual value: "true", scopes: ["source.pixie", "meta.metadata.map.pixie", "constant.language.boolean.pixie"]
    expect(tokens[4]).toEqual value: "}", scopes: ["source.pixie", "meta.metadata.map.pixie", "punctuation.section.metadata.map.end.trailing.pixie"]

  it "tokenizes functions", ->
    expressions = ["(foo)", "(foo 1 10)"]

    for expr in expressions
      {tokens} = grammar.tokenizeLine expr
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.pixie", "meta.expression.pixie", "entity.name.function.pixie"]

  it "tokenizes vars", ->
    {tokens} = grammar.tokenizeLine "(func #'foo)"
    expect(tokens[2]).toEqual value: " #", scopes: ["source.pixie", "meta.expression.pixie"]
    expect(tokens[3]).toEqual value: "'foo", scopes: ["source.pixie", "meta.expression.pixie", "meta.var.pixie"]

  it "tokenizes symbols", ->
    {tokens} = grammar.tokenizeLine "foo/bar"
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.pixie", "meta.symbol.namespace.pixie"]
    expect(tokens[1]).toEqual value: "/", scopes: ["source.pixie"]
    expect(tokens[2]).toEqual value: "bar", scopes: ["source.pixie", "meta.symbol.pixie"]

  it "tokenizes trailing whitespace", ->
    {tokens} = grammar.tokenizeLine "   \n"
    expect(tokens[0]).toEqual value: "   \n", scopes: ["source.pixie", "invalid.trailing-whitespace"]

  testMetaSection = (metaScope, puncScope, startsWith, endsWith) ->
    # Entire expression on one line.
    {tokens} = grammar.tokenizeLine "#{startsWith}foo, bar#{endsWith}"

    [start, mid..., end, after] = tokens

    expect(start).toEqual value: startsWith, scopes: ["source.pixie", "meta.#{metaScope}.pixie", "punctuation.section.#{puncScope}.begin.pixie"]
    expect(end).toEqual value: endsWith, scopes: ["source.pixie", "meta.#{metaScope}.pixie", "punctuation.section.#{puncScope}.end.trailing.pixie"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.pixie", "meta.#{metaScope}.pixie"]

    # Expression broken over multiple lines.
    tokens = grammar.tokenizeLines("#{startsWith}foo\n bar#{endsWith}")

    [start, mid..., after] = tokens[0]

    expect(start).toEqual value: startsWith, scopes: ["source.pixie", "meta.#{metaScope}.pixie", "punctuation.section.#{puncScope}.begin.pixie"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.pixie", "meta.#{metaScope}.pixie"]

    [mid..., end, after] = tokens[1]

    expect(end).toEqual value: endsWith, scopes: ["source.pixie", "meta.#{metaScope}.pixie", "punctuation.section.#{puncScope}.end.trailing.pixie"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.pixie", "meta.#{metaScope}.pixie"]

  it "tokenizes expressions", ->
    testMetaSection "expression", "expression", "(", ")"

  it "tokenizes quoted expressions", ->
    testMetaSection "quoted-expression", "expression", "'(", ")"
    testMetaSection "quoted-expression", "expression", "`(", ")"

  it "tokenizes vectors", ->
    testMetaSection "vector", "vector", "[", "]"

  it "tokenizes maps", ->
    testMetaSection "map", "map", "{", "}"

  it "tokenizes sets", ->
    testMetaSection "set", "set", "\#{", "}"

  it "tokenizes functions in nested sexp", ->
    {tokens} = grammar.tokenizeLine "((foo bar) baz)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.pixie", "meta.expression.pixie", "punctuation.section.expression.begin.pixie"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.pixie", "meta.expression.pixie", "meta.expression.pixie", "punctuation.section.expression.begin.pixie"]
    expect(tokens[2]).toEqual value: "foo", scopes: ["source.pixie", "meta.expression.pixie", "meta.expression.pixie", "entity.name.function.pixie"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.pixie", "meta.expression.pixie", "meta.expression.pixie"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.pixie", "meta.expression.pixie", "meta.expression.pixie", "meta.symbol.pixie"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.pixie", "meta.expression.pixie", "meta.expression.pixie", "punctuation.section.expression.end.pixie"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.pixie", "meta.expression.pixie"]
    expect(tokens[7]).toEqual value: "baz", scopes: ["source.pixie", "meta.expression.pixie", "meta.symbol.pixie"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.pixie", "meta.expression.pixie", "punctuation.section.expression.end.trailing.pixie"]

  it "tokenizes maps used as functions", ->
    {tokens} = grammar.tokenizeLine "({:foo bar} :foo)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.pixie", "meta.expression.pixie", "punctuation.section.expression.begin.pixie"]
    expect(tokens[1]).toEqual value: "{", scopes: ["source.pixie", "meta.expression.pixie", "meta.map.pixie", "punctuation.section.map.begin.pixie"]
    expect(tokens[2]).toEqual value: ":foo", scopes: ["source.pixie", "meta.expression.pixie", "meta.map.pixie", "constant.keyword.pixie"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.pixie", "meta.expression.pixie", "meta.map.pixie"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.pixie", "meta.expression.pixie", "meta.map.pixie", "meta.symbol.pixie"]
    expect(tokens[5]).toEqual value: "}", scopes: ["source.pixie", "meta.expression.pixie", "meta.map.pixie", "punctuation.section.map.end.pixie"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.pixie", "meta.expression.pixie"]
    expect(tokens[7]).toEqual value: ":foo", scopes: ["source.pixie", "meta.expression.pixie", "constant.keyword.pixie"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.pixie", "meta.expression.pixie", "punctuation.section.expression.end.trailing.pixie"]
