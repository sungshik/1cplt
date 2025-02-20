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

@autoName test bool _e4027c89195dca169cfbb62416d3c793() = compare(toAbstract(parse(#DataType, "Alice")), pid("Alice")) ;
@autoName test bool _d9c976d5ed72c5282ddf84c790a1afe6() = compare(toAbstract(parse(#DataType, "null")), null()) ;
@autoName test bool _0a93b0b9c2d39a22932d9dd656993d89() = compare(toAbstract(parse(#DataType, "boolean")), boolean()) ;
@autoName test bool _373b4061a87dec183ffbb6a85d876170() = compare(toAbstract(parse(#DataType, "number")), number()) ;
@autoName test bool _0e6104dbfdda78c0112651dec61943be() = compare(toAbstract(parse(#DataType, "string")), string()) ;
@autoName test bool _5607ca24fef95cb3831002e150aedfb1() = compare(toAbstract(parse(#DataType, "Alice[]")), array(pid("Alice"))) ;

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
    = "<toStr(t1)>[]" ;

@autoName test bool _fb052164acb12c42fa08d995f5b484f0() = toStr(pid("Alice")) == "Alice" ;
@autoName test bool _f787b28bb88a382139a33049e967d220() = toStr(null()) == "null" ;
@autoName test bool _61a689820a66fc089ed489d05f3ea59c() = toStr(boolean()) == "boolean" ;
@autoName test bool _217a5b39e204f39db3febea0a8db2767() = toStr(number()) == "number" ;
@autoName test bool _63a6c34e376f45f4fe884b4314d2dc14() = toStr(string()) == "string" ;
@autoName test bool _5ab6d8d20f90ebe5215f66fb8925b800() = toStr(array(pid("Alice"))) == "Alice[]" ;
@autoName test bool _eed6512788df0ae2cdf870c2a1350ee0() = toStr(array(array(array(null())))) == "null[][][]" ;

/*
 * Types: Roles
 */

alias ROLE = str;

ROLE toAbstract(r: (Role) _)
    = "<r>";

@autoName test bool _25edf7828fe83bf157da88c98fca6197() = toAbstract(parse(#Role, "Alice")) == "Alice" ;

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

DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataVariable x>`)
    = var(toAbstract(x)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataValue v>`)
    = val(toAbstract(v)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `[<{DataExpression ","}* args>]`)
    = app("array", [toAbstract(arg) | arg <- args]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1> as <DataType t1>`)
    = asc(toAbstract(e1), toAbstract(t1)) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `(<DataExpression e1>)`)
    = toAbstract(e1) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<Length _>`)
    = app("length", [toAbstract(e1)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `<DataExpression e1>.<Concat _>(<DataExpression e2>)`)
    = app("concat", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
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

@autoName test bool _3b5a99b0722b1010fa672ae564f47ed1() = compare(toAbstract(parse(#DataExpression, "x")), var("x")) ;
@autoName test bool _f28075a7113ce1d991dd202adc8bb1d4() = compare(toAbstract(parse(#DataExpression, "5")), val(5)) ;
@autoName test bool _d73dabae8f033077a409a830d74db6da() = compare(toAbstract(parse(#DataExpression, "[]")), app("array", []));
@autoName test bool _610773a4f669c144d304b37f4038f29f() = compare(toAbstract(parse(#DataExpression, "[null]")), app("array", [val(NULL)]));
@autoName test bool _2e8e6f9b191b338369e0a6ddf1911799() = compare(toAbstract(parse(#DataExpression, "[true, 5, \"foo\"]")), app("array", [val(true), val(5), val("foo")]));
@autoName test bool _abf9b70ca937634f70fbf466ca0a55de() = compare(toAbstract(parse(#DataExpression, "[[[]]]")), app("array", [app("array", [app("array", [])])]));
@autoName test bool _c39c33a4d2d9cdb8b12432b06ac65ce1() = compare(toAbstract(parse(#DataExpression, "5 as number")), asc(val(5), number())) ;
@autoName test bool _7b02dfcf7e6daba8fbd6c23fadf4e4a3() = compare(toAbstract(parse(#DataExpression, "(5)")), val(5)) ;
@autoName test bool _600f0dc1ec014a70c64c038c8d3e6a4a() = compare(toAbstract(parse(#DataExpression, "[].length")), app("length", [app("array", [])])) ;
@autoName test bool _a514539a6e7ad6d00e704e3bacb3b524() = compare(toAbstract(parse(#DataExpression, "[].concat([])")), app("concat", [app("array", []), app("array", [])])) ;
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
        default:
            return "<v>";
    }
}
str toStr(DATA_EXPRESSION _: asc(e1, t))
    = "<toStr(e1)> as <toStr(t)>" ;
str toStr(DATA_EXPRESSION _: app(f, args))
    = "<f>(<intercalate(", ", [toStr(arg) | arg <- args])>)" ;

@autoName test bool _316445d34c4db4cc504f8205ee83b07a() = toStr(var("x")) == "x" ;
@autoName test bool _492da7b22b5dd03e48c81b62560c61bc() = toStr(val(<"Alice", 0>)) == "Alice" ;
@autoName test bool _eb718d61e781e3b84bbce04425a0d90f() = toStr(val(<"Alice", 5>)) == "Alice[5]" ;
@autoName test bool _022552671b43152ed15663fb6f487468() = toStr(val(NULL)) == "null" ;
@autoName test bool _2b33d3d631e1e3eb41230baaca897189() = toStr(val(true)) == "true" ;
@autoName test bool _eb8ec484d6e5f60a78dc2c0e4b9e7715() = toStr(asc(val(5), number())) == "5 as number" ;
@autoName test bool _ccdd6ba03cdd7e3e8e699335ee8d4870() = toStr(app("+", [val(5), val(6)])) == "+(5, 6)" ;

/*
 * Variables
 */

alias DATA_VARIABLE = str ;

DATA_VARIABLE toAbstract(x: (DataVariable) _)
    = "<x>";

@autoName test bool _4186d041fcfa5ab1f61d1055100231fa() = toAbstract(parse(#DataVariable, "x")) == "x" ;

/*
 * Values
 */

alias DATA_VALUE = value ;

DATA_VALUE toAbstract(v: (DataValue) _)
    = toAbstract(v.args[0]);

/*
 * Values: Pids
 */

alias PID = tuple[str r, int k] ;

PID toAbstract((Pid) `<Role r>`)
    = <toAbstract(r), 0> ;
PID toAbstract((Pid) `<Role r>[<Number k>]`)
    = <toAbstract(r), toAbstract(k)> ;

@autoName test bool _c1fed0d78bd3e0cc0da4c42f5d6b50de() = toAbstract(parse(#Pid, "Alice")) == <"Alice", 0> ;
@autoName test bool _660402f4bfe9f0586e7ecbb8d9a75bff() = toAbstract(parse(#Pid, "Alice[5]")) == <"Alice", 5> ;

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

STRING toAbstract((String) `"<Print* content>"`)
    = "<content>" ;

@autoName test bool _cf9ed0da356d0312b1b69be4326424c1() = toAbstract(parse(#String, "\"foo\"")) == "foo" ;

/*
 * Values: Arrays
 */

alias ARRAY = list[value] ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

DATA_EXPRESSION toAbstract(e: (DataExpression) `isNil(<DataExpression e1>)`)
    = app("isNil", [toAbstract(e1)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `cons(<DataExpression e1>, <DataExpression e2>)`)
    = app("cons", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `headOrDefault(<DataExpression e1>, <DataExpression e2>)`)
    = app("headOrDefault", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;
DATA_EXPRESSION toAbstract(e: (DataExpression) `tailOrDefault(<DataExpression e1>, <DataExpression e2>)`)
    = app("tailOrDefault", [toAbstract(e1), toAbstract(e2)]) [src = e.src] ;

@autoName test bool _0ca6f8d33edee4408b792b07988f87be() = compare(toAbstract(parse(#DataExpression, "isNil([5, 6, 7])")), app("isNil", [app("array", [val(5), val(6), val(7)])])) ;
@autoName test bool _094d387f8c1cffaa6f4fea8f40dad0fc() = compare(toAbstract(parse(#DataExpression, "cons(5, [6, 7])")), app("cons", [val(5), app("array", [val(6), val(7)])])) ;
@autoName test bool _e8f01142b3255079374dea139f649d29() = compare(toAbstract(parse(#DataExpression, "headOrDefault([5, 6], 7)")), app("headOrDefault", [app("array", [val(5), val(6)]), val(7)])) ;
@autoName test bool _ec99c2c08d7a743970068040a771851b() = compare(toAbstract(parse(#DataExpression, "tailOrDefault([5, 6], [7])")), app("tailOrDefault", [app("array", [val(5), val(6)]), app("array", [val(7)])])) ;
