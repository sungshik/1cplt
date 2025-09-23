module icplt::core::\data::semantics::JavaScript

import List;
import icplt::core::\data::\syntax::Abstract;

str toJavaScript(DATA_EXPRESSION _: err())
    = "(() =\> { throw new Error(); })()" ;
str toJavaScript(DATA_EXPRESSION _: var(x))
    = "runtime.state[\'<x>\']" ;
str toJavaScript(DATA_EXPRESSION _: val(UNDEFINED _))
    = "null" ;
str toJavaScript(DATA_EXPRESSION _: val(PID _: <r, k>))
    = "runtime.hosts[\'<k == 0 ? "<r>" : "<r>[<k>]">\']" ;
str toJavaScript(DATA_EXPRESSION _: val(NULL _))
    = "null" ;
str toJavaScript(DATA_EXPRESSION _: val(BOOLEAN b))
    = "<b>" ;
str toJavaScript(DATA_EXPRESSION _: val(NUMBER n))
    = "<n>" ;
str toJavaScript(DATA_EXPRESSION _: val(STRING s))
    = "\'<s>\'" ;
str toJavaScript(DATA_EXPRESSION _: val(ARRAY arr))
    = "[<intercalate(", ", [toJavaScript(val(vi)) | vi <- arr])>]" ;
str toJavaScript(DATA_EXPRESSION _: val(OBJECT obj))
    = "{<intercalate(", ", ["<k>: <toJavaScript(val(obj[k]))>" | k <- obj])>}";
str toJavaScript(DATA_EXPRESSION _: asc(e1, _))
    = toJavaScript(e1) ;
str toJavaScript(DATA_EXPRESSION _: app(f, args))
    = "[<intercalate(", ", [toJavaScript(ei) | ei <- args])>]"
    when f in {"array"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, args))
    = "{<intercalate(", ", [toJavaScript(ei) | ei <- args])>}"
    when f in {"object"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1]))
    = "runtime.constructor.<f>Of(<toJavaScript(e1)>.pid)"
    when f in {"role", "rank"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1]))
    = "<toJavaScript(e1)>.length"
    when f in {"length"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "<toJavaScript(e1)>.<toJavaScript(e2)[1..-1]>"
    when f in {"oaccess"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "<toJavaScript(e1)>.<f>(<toJavaScript(e2)>)"
    when f in {"concat", "slice"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2, e3]))
    = "<toJavaScript(e1)>.<f>(<toJavaScript(e2)>, <toJavaScript(e3)>)"
    when f in {"slice"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "<toJavaScript(e1)>[<toJavaScript(e2)>]"
    when f in {"aaccess"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1]))
    = "<f><toJavaScript(e1)>"
    when f in {"!", "+", "-"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "(<toJavaScript(e1)> <f> <toJavaScript(e2)>)"
    when f in {"**"} + {"*", "%"} + {"+", "-"} + {"\<", "\<=", "\>", "\>="} + {"==" , "!="} + {"&&"} + {"||", "??"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "(Math.floor(<toJavaScript(e1)> <f> <toJavaScript(e2)>))"
    when f in {"/"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2, e3]))
    = "(<toJavaScript(e1)> ? <toJavaScript(e2)> : <toJavaScript(e3)>)"
    when f in {"?:"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, args))
    = "(<intercalate(", ", [toJavaScript(vi) | vi <- args])>)"
    when f in {","} ;

str toJavaScript(DATA_EXPRESSION _: app("entry", [e1, e2]))
    = "<toJavaScript(e1)[1..-1]>: <toJavaScript(e2)>" ;
str toJavaScript(DATA_EXPRESSION _: app("spread", [e1]))
    = "...<toJavaScript(e1)>" ;

@autoName test bool _3a168ac41c4f5585298c072ab561f12d() = toJavaScript(err()) == "(() =\> { throw new Error(); })()" ;
@autoName test bool _971e27c337fcbdd783768da3ed08ee03() = toJavaScript(var("i")) == "runtime.state[\'i\']" ;
@autoName test bool _740915de22e3439704b907be0be5d813() = toJavaScript(val(<"@alice", 5>)) == "runtime.hosts[\'@alice[5]\']" ;
@autoName test bool _e4f2400af1a19e94148075116425454f() = toJavaScript(val(NULL)) == "null" ;
@autoName test bool _d0102c1eb54e003f2b8441f14488bee3() = toJavaScript(val(true)) == "true" ;
@autoName test bool _53bb0f4d46b3fa25d76c2409bc41c02c() = toJavaScript(val(false)) == "false" ;
@autoName test bool _b1f92e0935e70e2db4a6e6e0938cb452() = toJavaScript(val(5)) == "5" ;
@autoName test bool _166b2e6fdd1aec3be361324a73384a5c() = toJavaScript(val("foo")) == "\'foo\'" ;
@autoName test bool _f8b2d9f23b032f5396f5613d8036825d() = toJavaScript(val([5, 6, 7])) == "[5, 6, 7]" ;
@autoName test bool _5f0d564cd60672ae7a441108ddefd289() = toJavaScript(val(("x": true, "y": 5, "z": "foo"))) == "{x: true, y: 5, z: \'foo\'}" ;
@autoName test bool _16d3b513bb2553089a7819e207711daf() = toJavaScript(asc(val(5), number())) == "5" ;
@autoName test bool _4731282fd41a7997a3d274dc63e2f78d() = toJavaScript(app("array", [val(5), val(6), val(7)])) == "[5, 6, 7]" ;
@autoName test bool _b8830480975634be2fccc6a5c5cca67e() = toJavaScript(app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])) == "{x: true, y: 5, z: \'foo\'}" ;
@autoName test bool _5174471ba7fcb8714dd73f064f4b6a31() = toJavaScript(app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])) == "{...{x: true, y: 5, z: \'foo\'}}" ;
@autoName test bool _586ec1e4d0c6702cd75e9dd74b4dea5d() = toJavaScript(app("object", [app("entry", [val("x"), val(false)]), app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])) == "{x: false, ...{x: true, y: 5, z: \'foo\'}}" ;
@autoName test bool _1fc6fe64a33f2f7a12b52b9f9bd85c8b() = toJavaScript(app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])]), app("entry", [val("x"), val(false)])])) == "{...{x: true, y: 5, z: \'foo\'}, x: false}" ;
@autoName test bool _547fac212cb09a60378ba6aa08e5eac2() = toJavaScript(app("length", [app("array", [val(5)])])) == "[5].length" ;
@autoName test bool _646d3a20c64ee6348db2d50372087b49() = toJavaScript(app("oaccess", [app("object", []), val("x")])) == "{}.x" ;
@autoName test bool _34fa6e958aed4a2231511f5e08e04091() = toJavaScript(app("slice", [app("array", []), val(1)])) == "[].slice(1)" ;
@autoName test bool _86a44ff7d34cc5ddff7ffe470c2a89bd() = toJavaScript(app("slice", [app("array", []), val(1), val(3)])) == "[].slice(1, 3)" ;
@autoName test bool _691eddfe3bffbbad9229ccdd770c088a() = toJavaScript(app("aaccess", [app("array", []), val(0)])) == "[][0]" ;
@autoName test bool _d240053ddc2bfaf23c08c027c5fd3113() = toJavaScript(app("concat", [app("array", [val(5)]), app("array", [val(6), val(7)])])) == "[5].concat([6, 7])" ;
@autoName test bool _1d7d11c2eddad4eab8e1af6c0827e56f() = toJavaScript(app("!", [val(true)])) == "!true" ;
@autoName test bool _2528d4f9d99d3b67ea1df1defaebf8d3() = toJavaScript(app("**", [val(5), val(6)])) == "(5 ** 6)" ;
@autoName test bool _c12793d68277428f8e351e62936848d3() = toJavaScript(app("?:", [val(true), val(5), val(6)])) == "(true ? 5 : 6)" ;
@autoName test bool _b249df07c03c04f2083e2afa590da316() = toJavaScript(app(",", [val(true), val(5), val(6)])) == "(true, 5, 6)" ;
