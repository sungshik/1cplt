module icplt::core::\data::semantics::JavaScript

import List;

import icplt::core::\data::\syntax::Abstract;

str toJavaScript(DATA_EXPRESSION _: err())
    = "(() =\> { throw new Error(); })()" ;
str toJavaScript(DATA_EXPRESSION _: var(x))
    = "state[\'<x>\']" ;

str toJavaScript(DATA_EXPRESSION _: val(PID _: <r, k>))
    = "Address.of(\'<r>[<k>]\')" ;
str toJavaScript(DATA_EXPRESSION _: val(NULL _))
    = "null" ;
str toJavaScript(DATA_EXPRESSION _: val(BOOLEAN b))
    = "<b>" ;
str toJavaScript(DATA_EXPRESSION _: val(NUMBER n))
    = "<n>" ;
str toJavaScript(DATA_EXPRESSION _: val(STRING s))
    = "\'<s>\'" ;
str toJavaScript(DATA_EXPRESSION _: val(ARRAY a))
    = "[<intercalate(", ", [toJavaScript(val(vi)) | vi <- a])>]" ;

str toJavaScript(DATA_EXPRESSION _: asc(e1, _))
    = toJavaScript(e1) ;

str toJavaScript(DATA_EXPRESSION _: app(f, args))
    = "[<intercalate(", ", [toJavaScript(vi) | vi <- args])>]" when f in {"array"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1]))
    = "<toJavaScript(e1)>.length" when f in {"length"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "<toJavaScript(e1)>.concat(<toJavaScript(e2)>)" when f in {"concat"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1]))
    = "<f><toJavaScript(e1)>" when f in {"!", "+", "-"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "(<toJavaScript(e1)> <f> <toJavaScript(e2)>)" when f in {"**"} + {"*", "%"} + {"+", "-"} + {"\<", "\<=", "\>", "\>="} + {"==" , "!="} + {"&&"} + {"||", "??"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2]))
    = "(Math.floor(<toJavaScript(e1)> <f> <toJavaScript(e2)>))" when f in {"/"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, [e1, e2, e3]))
    = "(<toJavaScript(e1)> ? <toJavaScript(e2)> : <toJavaScript(e3)>)" when f in {"?:"} ;
str toJavaScript(DATA_EXPRESSION _: app(f, args))
    = "(<intercalate(", ", [toJavaScript(vi) | vi <- args])>)" when f in {","} ;

@autoName test bool _3a168ac41c4f5585298c072ab561f12d() = toJavaScript(err()) == "(() =\> { throw new Error(); })()" ;
@autoName test bool _ca4627ee170964850d844da116667491() = toJavaScript(var("i")) == "state[\'i\']" ;
@autoName test bool _122dd5971ecf6b42851b1b4956f0232e() = toJavaScript(val(<"Alice", 5>)) == "Address.of(\'Alice[5]\')" ;
@autoName test bool _e4f2400af1a19e94148075116425454f() = toJavaScript(val(NULL)) == "null" ;
@autoName test bool _d0102c1eb54e003f2b8441f14488bee3() = toJavaScript(val(true)) == "true" ;
@autoName test bool _53bb0f4d46b3fa25d76c2409bc41c02c() = toJavaScript(val(false)) == "false" ;
@autoName test bool _b1f92e0935e70e2db4a6e6e0938cb452() = toJavaScript(val(5)) == "5" ;
@autoName test bool _166b2e6fdd1aec3be361324a73384a5c() = toJavaScript(val("foo")) == "\'foo\'" ;
@autoName test bool _f8b2d9f23b032f5396f5613d8036825d() = toJavaScript(val([5, 6, 7])) == "[5, 6, 7]" ;
@autoName test bool _16d3b513bb2553089a7819e207711daf() = toJavaScript(asc(val(5), number())) == "5" ;
@autoName test bool _4731282fd41a7997a3d274dc63e2f78d() = toJavaScript(app("array", [val(5), val(6), val(7)])) == "[5, 6, 7]" ;
@autoName test bool _547fac212cb09a60378ba6aa08e5eac2() = toJavaScript(app("length", [app("array", [val(5)])])) == "[5].length" ;
@autoName test bool _d240053ddc2bfaf23c08c027c5fd3113() = toJavaScript(app("concat", [app("array", [val(5)]), app("array", [val(6), val(7)])])) == "[5].concat([6, 7])" ;
@autoName test bool _1d7d11c2eddad4eab8e1af6c0827e56f() = toJavaScript(app("!", [val(true)])) == "!true" ;
@autoName test bool _2528d4f9d99d3b67ea1df1defaebf8d3() = toJavaScript(app("**", [val(5), val(6)])) == "(5 ** 6)" ;
@autoName test bool _c12793d68277428f8e351e62936848d3() = toJavaScript(app("?:", [val(true), val(5), val(6)])) == "(true ? 5 : 6)" ;
@autoName test bool _b249df07c03c04f2083e2afa590da316() = toJavaScript(app(",", [val(true), val(5), val(6)])) == "(true, 5, 6)" ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

str toJavaScript(DATA_EXPRESSION _: app("isNil", [e1]))
    = "(<toJavaScript(e1)>.length === 0)" ;
str toJavaScript(DATA_EXPRESSION _: app("cons", [e1, e2]))
    = "[<toJavaScript(e1)>].concat(<toJavaScript(e2)>)" ;
str toJavaScript(DATA_EXPRESSION _: app("headOrDefault", [e1, e2]))
    = "(<toJavaScript(e1)>[0] ?? <toJavaScript(e2)>)" ;
str toJavaScript(DATA_EXPRESSION _: app("tailOrDefault", [e1, e2]))
    = "(<toJavaScript(e1)>.length \> 0 ? <toJavaScript(e1)>.slice(1) : <toJavaScript(e2)>)" ;

@autoName test bool _024474a6d6678741f2af199480ee7ec7() = toJavaScript(app("isNil", [app("array", [val(5)])])) == "([5].length === 0)" ;
@autoName test bool _55d2166a9d68e00f86779895c9c86b21() = toJavaScript(app("cons", [val(5), app("array", [val(6), val(7)])])) == "[5].concat([6, 7])" ;
@autoName test bool _10938b32143ac9cfbb7c4cd2da9c53db() = toJavaScript(app("headOrDefault", [app("array", [val(6), val(7)]), val(5)])) == "([6, 7][0] ?? 5)" ;
@autoName test bool _a92bdba5c1d98f76ee1753644f6781f4() = toJavaScript(app("tailOrDefault", [app("array", [val(6), val(7)]), app("array", [val(5)])])) == "([6, 7].length \> 0 ? [6, 7].slice(1) : [5])" ;
