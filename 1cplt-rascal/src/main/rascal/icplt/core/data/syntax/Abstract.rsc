module icplt::core::\data::\syntax::Abstract
extend icplt::core::\util::\syntax::Abstract;

import Boolean;
import ParseTree;
import String;

import icplt::core::\data::\syntax::Concrete;

/*
 * Types
 */

data DATA_TYPE(loc src = |unknown:///|)
    = pid(ROLE r)
    | null()
    | boolean()
    | number()
    | string()
    | array(DATA_TYPE t)
    | object(map[str, DATA_TYPE] entries)
    | union(list[DATA_TYPE] types)
    ;

DATA_TYPE toAbstract(t: (DataType) `<Role r>`)
    = pid(toAbstract(r)) [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `null`)
    = null() [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `boolean`)
    = boolean() [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `number`)
    = number() [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `string`)
    = string() [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `<DataType t1>[]`)
    = array(toAbstract(t1)) [src = t.src] ;
DATA_TYPE toAbstract(t: (DataType) `{<{DataTypeEntry [;]}* entries> <Semi? _>}`)
    = object((() | it + toAbstract(entry) | entry <- entries)) [src = t.src] ;
DATA_TYPE toAbstract(_: (DataType) `(<DataType t1>)`)
    = toAbstract(t1) ;
DATA_TYPE toAbstract(t: (DataType) `<DataType t1> | <{DataType [|]}+ t234>`)
    = union([toAbstract(t1)] + [toAbstract(ti) | ti <- t234]) [src = t.src] ;

map[str, DATA_TYPE] toAbstract((DataTypeEntry) `<DataVariable x>: <DataType t>`)
    = (toAbstract(x): toAbstract(t)) ;

@autoName test bool _e6c034d7f37affa172871000709b26f5() = compare(toAbstract(parse(#DataType, "@alice")), pid("@alice")) ;
@autoName test bool _d9c976d5ed72c5282ddf84c790a1afe6() = compare(toAbstract(parse(#DataType, "null")), null()) ;
@autoName test bool _0a93b0b9c2d39a22932d9dd656993d89() = compare(toAbstract(parse(#DataType, "boolean")), boolean()) ;
@autoName test bool _373b4061a87dec183ffbb6a85d876170() = compare(toAbstract(parse(#DataType, "number")), number()) ;
@autoName test bool _0e6104dbfdda78c0112651dec61943be() = compare(toAbstract(parse(#DataType, "string")), string()) ;
@autoName test bool _27ac1aed2829c62b99d2d00561750185() = compare(toAbstract(parse(#DataType, "@alice[]")), array(pid("@alice"))) ;
@autoName test bool _381e655c36fd1ed03721f53f2eccc2dd() = compare(toAbstract(parse(#DataType, "{}")), object(())) ;
@autoName test bool _446785b9191c5c4293c88ed0f9857f05() = compare(toAbstract(parse(#DataType, "{x: null}")), object(("x": null()))) ;
@autoName test bool _2e1c61445f4038397e0d22f162f29cd5() = compare(toAbstract(parse(#DataType, "{x: boolean; y: number; z: string}")), object(("x": boolean(), "y": number(), "z": string()))) ;
@autoName test bool _7707b9f00e984888702d0e32b372c0e8() = compare(toAbstract(parse(#DataType, "{outer: {inner: {}}}")), object(("outer": object(("inner": object(())))))) ;
@autoName test bool _64b5dfe7b4ea53b881774785a582af59() = compare(toAbstract(parse(#DataType, "{outer: {inner: {};};}")), object(("outer": object(("inner": object(())))))) ;
@autoName test bool _a3498a9cc40a41ec7eeedcadb3d6fccd() = compare(toAbstract(parse(#DataType, "(null)")), null()) ;
@autoName test bool _1b9a8575f82b0797b479985ce99d440d() = compare(toAbstract(parse(#DataType, "number | boolean")), union([number(), boolean()])) ;
@autoName test bool _a98077492e88dc0eb9d1d1acb7b262a6() = compare(toAbstract(parse(#DataType, "number | boolean | string")), union([number(), boolean(), string()])) ;
@autoName test bool _f44673095724529aec4d2fed33950e04() = compare(toAbstract(parse(#DataType, "(number | boolean | string)[]")), array(union([number(), boolean(), string()]))) ;
@autoName test bool _8e403cf2c51b1ba423cd2280aa4a9d61() = compare(toAbstract(parse(#DataType, "number[] | boolean[] | string[]")), union([array(number()), array(boolean()), array(string())])) ;

str toStr(DATA_TYPE _: pid(r))
    = "<r>" ;
str toStr(DATA_TYPE _: null())
    = "null" ;
str toStr(DATA_TYPE _: boolean())
    = "boolean" ;
str toStr(DATA_TYPE _: number())
    = "number" ;
str toStr(DATA_TYPE _: string())
    = "string" ;
str toStr(DATA_TYPE _: array(t1))
    = "<parens(toStr(t1))>[]" ;
str toStr(DATA_TYPE _: object(entries))
    = "{<intercalate("; ", ["<k>: <toStr(entries[k])>" | k <- entries])>}" ;
str toStr(DATA_TYPE _: union(types))
    = intercalate(" | ", [toStr(t) | t <- types]) ;

private str parens(str s)
    = contains(s, " ") ? "(<s>)" : s ;

@autoName test bool _1bed5ae90f396bd132e7764db2a3db55() = toStr(pid("@alice")) == "@alice" ;
@autoName test bool _f787b28bb88a382139a33049e967d220() = toStr(null()) == "null" ;
@autoName test bool _61a689820a66fc089ed489d05f3ea59c() = toStr(boolean()) == "boolean" ;
@autoName test bool _217a5b39e204f39db3febea0a8db2767() = toStr(number()) == "number" ;
@autoName test bool _63a6c34e376f45f4fe884b4314d2dc14() = toStr(string()) == "string" ;
@autoName test bool _d6bcfc91038166dbd3fadfca07817055() = toStr(array(pid("@alice"))) == "@alice[]" ;
@autoName test bool _eed6512788df0ae2cdf870c2a1350ee0() = toStr(array(array(array(null())))) == "null[][][]" ;
@autoName test bool _afa3371e5656d43686ed56772c0c48d5() = toStr(object(("x": null(), "y": null()))) == "{x: null; y: null}" ;
@autoName test bool _f29974eafcd60605059702a554b169cd() = toStr(union([null(), boolean(), number()])) == "null | boolean | number" ;
@autoName test bool _3cb352107349c01faa33b4e37f7fc117() = toStr(array(union([null(), boolean(), number()]))) == "(null | boolean | number)[]" ;
@autoName test bool _b970153fc70d50d7cfc0daea360c28df() = toStr(union([array(null()), array(boolean()), array(number())])) == "null[] | boolean[] | number[]" ;

/*
 * Types: Roles
 */

alias ROLE = str;

ROLE toAbstract(r: (Role) _)
    = "<r>";

@autoName test bool _bd8e3680238a92336cfb4e26db3e37f4() = toAbstract(parse(#Role, "@alice")) == "@alice" ;

/*
 * Expressions
 */

data DATA_EXPRESSION(loc src = |unknown:///|)
    = err()
    | var(DATA_VARIABLE x)
    | val(DATA_VALUE v)
    | asc(DATA_EXPRESSION e1, DATA_TYPE t)
    | app(str f, list[DATA_EXPRESSION] args)
    ;

DATA_EXPRESSION toAbstract(e: (DataExpression) `self`)
    = var("self") [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataVariable x>`)
    = var(toAbstract(x)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataValue v>`)
    = val(toAbstract(v)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `[<{DataExpression ","}* args> <Comma? _>]`)
    = app("array", [toAbstract(arg) | arg <- args]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `{<{DataExpressionEntry ","}* args> <Comma? _>}`)
    = app("object", [toAbstract(arg) | arg <- args]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> as <DataType t1>`)
    = asc(toAbstract(e1), toAbstract(t1)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `(<DataExpression e1>)`)
    = toAbstract(e1) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<DataVariable x>`)
    = app("oaccess", [toAbstract(e1), val(toAbstract(x)) [src = x.src]]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<Nullary f>`)
    = app("<f>", [toAbstract(e1)]) [src = e.src];
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<Unary f>(<DataExpression e2>)`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<Binary f>(<DataExpression e2>, <DataExpression e3>)`)
    = app("<f>", [toAbstract(e1), toAbstract(e2), toAbstract(e3)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>[<DataExpression e2>]`)
    = app("aaccess", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<Prefix f> <DataExpression e1>`)
    = app("<f>", [toAbstract(e1)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <Exponentiation f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <Multiplication f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <Addition f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <LessThan f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <Equality f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <LogicalConjunction f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> <LogicalDisjunction f> <DataExpression e2>`)
    = app("<f>", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> ? <DataExpression e2> : <DataExpression e3>`)
    = app("?:", [toAbstract(e1), toAbstract(e2), toAbstract(e3)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>, <{DataExpression ","}+ rest>`)
    = app(",", [toAbstract(e1)] + [toAbstract(ei) | ei <- rest]) [src = e.src] ;

DATA_EXPRESSION toAbstract(e: (DataExpressionEntry) `<DataVariable x>: <DataExpression e1>`)
    = app("entry", [val(toAbstract(x)) [src = x.src], toAbstract(e1)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpressionEntry) `...<DataExpression e1>`)
    = app("spread", [toAbstract(e1)]) [src = e.src] ;

@autoName test bool _73f34d9fff1b685ffc2c92ade7fc240c() = compare(toAbstract(parse(#DataExpression, "self")), var("self")) ;
@autoName test bool _3b5a99b0722b1010fa672ae564f47ed1() = compare(toAbstract(parse(#DataExpression, "x")), var("x")) ;
@autoName test bool _f28075a7113ce1d991dd202adc8bb1d4() = compare(toAbstract(parse(#DataExpression, "5")), val(5)) ;
@autoName test bool _d73dabae8f033077a409a830d74db6da() = compare(toAbstract(parse(#DataExpression, "[]")), app("array", []));
@autoName test bool _610773a4f669c144d304b37f4038f29f() = compare(toAbstract(parse(#DataExpression, "[null]")), app("array", [val(NULL)]));
@autoName test bool _2e8e6f9b191b338369e0a6ddf1911799() = compare(toAbstract(parse(#DataExpression, "[true, 5, \"foo\"]")), app("array", [val(true), val(5), val("foo")]));
@autoName test bool _abf9b70ca937634f70fbf466ca0a55de() = compare(toAbstract(parse(#DataExpression, "[[[]]]")), app("array", [app("array", [app("array", [])])]));
@autoName test bool _8d9e29199132916b6b840b8e62756792() = compare(toAbstract(parse(#DataExpression, "{}")), app("object", []));
@autoName test bool _c3fdbe60ae17a63337963854e4ce0820() = compare(toAbstract(parse(#DataExpression, "{x: null}")), app("object", [app("entry", [val("x"), val(NULL)])]));
@autoName test bool _530518a70f95eb03edcf1d91d003a4da() = compare(toAbstract(parse(#DataExpression, "{x: true, y: 5, z: \"foo\"}")), app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])]));
@autoName test bool _16981e1fe0e50b52be014b752dcae728() = compare(toAbstract(parse(#DataExpression, "{outer: {inner: {}}}")), app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])]));
@autoName test bool _ad6d1c5ca8fb5154892e1eec22921edb() = compare(toAbstract(parse(#DataExpression, "{outer: {inner: {},},}")), app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])]));
@autoName test bool _56d44464ea9ce6b60502f98aa1b251bc() = compare(toAbstract(parse(#DataExpression, "{...{x: true, y: 5, z: \"foo\"}}")), app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])]));
@autoName test bool _c54bc9cd026420ad56e61b5f6495c978() = compare(toAbstract(parse(#DataExpression, "{x: false, ...{x: true, y: 5, z: \"foo\"}}")), app("object", [app("entry", [val("x"), val(false)]), app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])]));
@autoName test bool _d25e75c706753b27097998b2f8982269() = compare(toAbstract(parse(#DataExpression, "{...{x: true, y: 5, z: \"foo\"}, x: false}")), app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])]), app("entry", [val("x"), val(false)])]));
@autoName test bool _c39c33a4d2d9cdb8b12432b06ac65ce1() = compare(toAbstract(parse(#DataExpression, "5 as number")), asc(val(5), number())) ;
@autoName test bool _7b02dfcf7e6daba8fbd6c23fadf4e4a3() = compare(toAbstract(parse(#DataExpression, "(5)")), val(5)) ;
@autoName test bool _bcd43a547a8e2cee387d7d43d6e1b3b3() = compare(toAbstract(parse(#DataExpression, "{}.x")), app("oaccess", [app("object", []), val("x")])) ;
@autoName test bool _33a61f617080c0f88c26f728a1fed3ef() = compare(toAbstract(parse(#DataExpression, "@alice[5].role")), app("role", [val(<"@alice", 5>)])) ;
@autoName test bool _22dd1f8c67d01a32e878a6b5aa9df159() = compare(toAbstract(parse(#DataExpression, "@alice[5].rank")), app("rank", [val(<"@alice", 5>)])) ;
@autoName test bool _600f0dc1ec014a70c64c038c8d3e6a4a() = compare(toAbstract(parse(#DataExpression, "[].length")), app("length", [app("array", [])])) ;
@autoName test bool _a514539a6e7ad6d00e704e3bacb3b524() = compare(toAbstract(parse(#DataExpression, "[].concat([])")), app("concat", [app("array", []), app("array", [])])) ;
@autoName test bool _355ee94ded2debe464c0b101b390d20a() = compare(toAbstract(parse(#DataExpression, "[].slice(1)")), app("slice", [app("array", []), val(1)])) ;
@autoName test bool _dd8b5a69d3ed9de5625944a2c853028f() = compare(toAbstract(parse(#DataExpression, "[].slice(1, 3)")), app("slice", [app("array", []), val(1), val(3)])) ;
@autoName test bool _1688f76afcf9c0bf28fea8075ab841d3() = compare(toAbstract(parse(#DataExpression, "[][0]")), app("aaccess", [app("array", []), val(0)])) ;
@autoName test bool _0ebc5fa5150a5256633ff258ecca1fc1() = compare(toAbstract(parse(#DataExpression, "!true")), app("!", [val(true)])) ;
@autoName test bool _daf49fbc90c589f929a03dbbd0a0685a() = compare(toAbstract(parse(#DataExpression, "5 ** 6")), app("**", [val(5), val(6)])) ;
@autoName test bool _bf4f9d63fce32cdf03637f45bbeed78e() = compare(toAbstract(parse(#DataExpression, "5 ** 6 ** 7")), app("**", [val(5), app("**", [val(6), val(7)])])) ;
@autoName test bool _646b0ed8f9fe056280d33bec508f6701() = compare(toAbstract(parse(#DataExpression, "5 * 6")), app("*", [val(5), val(6)])) ;
@autoName test bool _647a0a02f6e4b230725dbbf2afed9149() = compare(toAbstract(parse(#DataExpression, "5 * 6 / 7")), app("/", [app("*", [val(5), val(6)]), val(7)])) ;
@autoName test bool _3634734edcd96f23cf6b1d06edf91e43() = compare(toAbstract(parse(#DataExpression, "5 + 6")), app("+", [val(5), val(6)])) ;
@autoName test bool _c57f539050c4aa03abfbdd2684170bc7() = compare(toAbstract(parse(#DataExpression, "5 + 6 - 7")), app("-", [app("+", [val(5), val(6)]), val(7)])) ;
@autoName test bool _e9087381ada4f5cb7b560392ee846f51() = compare(toAbstract(parse(#DataExpression, "5 \< 6")), app("\<", [val(5), val(6)])) ;
@autoName test bool _10b66abac1658b90932bcadb2afddd66() = compare(toAbstract(parse(#DataExpression, "5 == 6")), app("==", [val(5), val(6)])) ;
@autoName test bool _fa5a4fdf8b3aad9d98196f0647b69d31() = compare(toAbstract(parse(#DataExpression, "5 == 6 == false")), app("==", [app("==", [val(5), val(6)]), val(false)])) ;
@autoName test bool _b9b35eedead4c1130fde82e9d0556c97() = compare(toAbstract(parse(#DataExpression, "true && false")), app("&&", [val(true), val(false)])) ;
@autoName test bool _272a93482583ca29ad4fbb91aa633d1e() = compare(toAbstract(parse(#DataExpression, "true && false && false")), app("&&", [app("&&", [val(true), val(false)]), val(false)])) ;
@autoName test bool _55b991a51e64502e2ef91f7cb404e8a4() = compare(toAbstract(parse(#DataExpression, "true || false")), app("||", [val(true), val(false)])) ;
@autoName test bool _13ae9359be462d6093739bac4882f578() = compare(toAbstract(parse(#DataExpression, "true || false ?? false")), app("??", [app("||", [val(true), val(false)]), val(false)])) ;
@autoName test bool _9e04e9da4fb2c1ebe88df4cac2ffce47() = compare(toAbstract(parse(#DataExpression, "true ? false : false ? false : false")), app("?:", [val(true), val(false), app("?:", [val(false), val(false), val(false)])])) ;
@autoName test bool _4d39d3af47f316e5cce8ad0a2baf4d49() = compare(toAbstract(parse(#DataExpression, "5 + 6 == 7 + 8")), app("==", [app("+", [val(5), val(6)]), app("+", [val(7), val(8)])])) ;
@autoName test bool _c42cf77857349384a935d2eedf4611d5() = compare(toAbstract(parse(#DataExpression, "+5 + +6 == -7 - -8")), app("==", [app("+", [app("+", [val(5)]), app("+", [val(6)])]), app("-", [app("-", [val(7)]), app("-", [val(8)])])])) ;
@autoName test bool _7511ae5278ff87b6190f42b66b2f1f4c() = compare(toAbstract(parse(#DataExpression, "5, 6, 7")), app(",", [val(5), val(6), val(7)])) ;
@autoName test bool _6a1645ae9c410b56ae1a2155f0ec4df5() = compare(toAbstract(parse(#DataExpression, "(5, 6), 7")), app(",", [app(",", [val(5), val(6)]), val(7)])) ;

str toStr(DATA_EXPRESSION _: err())
    = "error" ;
str toStr(DATA_EXPRESSION _: var(x))
    = "<x>" ;
str toStr(DATA_EXPRESSION _: val(v)) {
    switch (v) {
        case PID _: <r, k>:
            return k == 0 ? "<r>" : "<r>[<k>]";
        case NULL _: _:
            return "null";
        case STRING s: _:
            return "\"<s>\"";
        case ARRAY a: _:
            return "[<intercalate(", ", [toStr(val(vi)) | vi <- a])>]";
        case OBJECT obj: _:
            return "{<intercalate(", ", ["<k>: <toStr(val(obj[k]))>" | k <- sort([*obj<0>])])>}";
        default:
            return "<v>";
    }
}
str toStr(DATA_EXPRESSION _: asc(e1, t))
    = "<toStr(e1)> as <toStr(t)>" ;
str toStr(DATA_EXPRESSION _: app(f, args))
    = "oaccess" == f
    ? "<toStr(args[0])>.<args[1].v>"
    : "<f>(<intercalate(", ", [toStr(arg) | arg <- args])>)" ;

@autoName test bool _316445d34c4db4cc504f8205ee83b07a() = toStr(var("x")) == "x" ;
@autoName test bool _cd6ce612e38a2423bf35edfd6bb18e44() = toStr(val(<"@alice", 0>)) == "@alice" ;
@autoName test bool _0954b4ecad838ab7088856dea1e4e2a8() = toStr(val(<"@alice", 5>)) == "@alice[5]" ;
@autoName test bool _022552671b43152ed15663fb6f487468() = toStr(val(NULL)) == "null" ;
@autoName test bool _2b33d3d631e1e3eb41230baaca897189() = toStr(val(true)) == "true" ;
@autoName test bool _eb8ec484d6e5f60a78dc2c0e4b9e7715() = toStr(asc(val(5), number())) == "5 as number" ;
@autoName test bool _ccdd6ba03cdd7e3e8e699335ee8d4870() = toStr(app("+", [val(5), val(6)])) == "+(5, 6)" ;

/*
 * Variables
 */

alias DATA_VARIABLE = str ;

DATA_VARIABLE toAbstract(x: (DataVariable) _)
    = "<x>" ;

@autoName test bool _4186d041fcfa5ab1f61d1055100231fa() = toAbstract(parse(#DataVariable, "x")) == "x" ;

/*
 * Values
 */

alias DATA_VALUE = value ;

DATA_VALUE toAbstract(v: (DataValue) _)
    = toAbstract(v.args[0]) ;

/*
 * Values: Pids
 */

alias PID = tuple[str r, int k] ;

PID toAbstract((Pid) `<Role r>`)
    = <toAbstract(r), 0> ;
PID toAbstract((Pid) `<Role r>[<Number k>]`)
    = <toAbstract(r), toAbstract(k)> ;

@autoName test bool _b1913042f35522a568697c28e54b23de() = toAbstract(parse(#Pid, "@alice")) == <"@alice", 0> ;
@autoName test bool _29cda6b45e6e49e01e59467e119e984e() = toAbstract(parse(#Pid, "@alice[5]")) == <"@alice", 5> ;

/*
 * Values: Null
 */

alias NULL = void() ;
void  NULL() {;}

NULL toAbstract((Null) _)
    = NULL ;

@autoName test bool _6d765d018544f285125bb2f5399f5929() = toAbstract(parse(#Null, "null")) == NULL ;

/*
 * Values: Booleans
 */

alias BOOLEAN = bool ;

BOOLEAN toAbstract(b: (Boolean) _)
    = fromString("<b>") ;

@autoName test bool _b6f76a6e3e1a7172ce71e7f2bb709574() = toAbstract(parse(#Boolean, "true")) == true ;
@autoName test bool _d0e15b26041f1b4a879003875662c325() = toAbstract(parse(#Boolean, "false")) == false ;

/*
 * Values: Numbers
 */

alias NUMBER = int ;

NUMBER toAbstract(n: (Number) _)
    = toInt("<n>") ;

@autoName test bool _d27dd5b943129bf07ab979b5db0f938e() = toAbstract(parse(#Number, "5")) == 5 ;

/*
 * Values: Strings
 */

alias STRING = str ;

STRING toAbstract(s: (String) _)
    = "<s>"[1..-1] ;

@autoName test bool _cf9ed0da356d0312b1b69be4326424c1() = toAbstract(parse(#String, "\"foo\"")) == "foo" ;

/*
 * Values: Arrays
 */

alias ARRAY = list[value] ;

/*
 * Values: Objects
 */

alias OBJECT = map[str, value] ;
