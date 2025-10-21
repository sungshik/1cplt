module icplt::core::\data::\semantics::Dynamic

import List;
import util::Math;

import icplt::core::\data::\syntax::Abstract;

/*
 * States
 */

data DATA_STATE = state(map[DATA_VARIABLE, DATA_EXPRESSION] phi) ;

DATA_STATE s1 = state(()) ;
DATA_STATE s2 = state(("i": val(5), "j": val(6))) ;

DATA_STATE toState(DATA_EXPRESSION e) {
    DATA_EXPRESSION toExpression(/b[0-9]*/) = val(false);
    DATA_EXPRESSION toExpression(/n[0-9]*/) = val(0);
    DATA_EXPRESSION toExpression(/s[0-9]*/) = val("");
    return state((x: toExpression(x) | /var(x: /[bns][0-9]*/) := e));
}

/*
 * Normalization
 */

tuple[DATA_STATE, DATA_EXPRESSION] normalize(tuple[DATA_STATE, DATA_EXPRESSION] se) {
    return solve (se) {
        se = reduce(se);
    }
}

@autoName test bool _447a7338c314c42a2abb6ec1bce08d30() = normalize(<s2, app("?:", [app("!", [val(false)]), app("-", [var("i")]), app("-", [var("j")])])>) == <s2, val(-5)> ;
@autoName test bool _decd159ea168593ee1aa9134d93f9932() = normalize(<s2, app("?:", [app("!", [val(false)]), app("-", [app("/", [var("i"), val(1)])]), app("-", [app("%", [var("j"), val(1)])])])>) == <s2, val(-5)> ;
@autoName test bool _a6969f9e19e055efa6af94bd1bf6ed7a() = normalize(<s2, app("?:", [app("!", [val(false)]), app("-", [app("/", [var("i"), val(0)])]), app("-", [app("%", [var("j"), val(1)])])])>) == <s2, err()> ;
@autoName test bool _e60e4c8e8027ded4cfd8ead0d40ebedf() = normalize(<s2, app("?:", [app("!", [val(false)]), app("-", [app("/", [var("i"), val(1)])]), app("-", [app("%", [var("j"), val(0)])])])>) == <s2, err()> ;
@autoName test bool _6f16b496f82be10e27c8219718e5fea4() = normalize(<s1, app("object", [app("entry", [val("x"), val(NULL)])])>) == <s1, val(("x": NULL))> ;
@autoName test bool _c3d318778296d2fd863e88994c294c33() = normalize(<s1, app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])>) == <s1, val(("x": true, "y": 5, "z": "foo"))> ;
@autoName test bool _5b604471f3eb4583721c78a9217cdc90() = normalize(<s1, app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])])>) == <s1, val(("outer": ("inner": ())))> ;
@autoName test bool _7c32b3b689fdb0dbc2e44a6c4d635ba6() = normalize(<s1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])>) == <s1, val(("x": true, "y": 5, "z": "foo"))> ;
@autoName test bool _8ad52b6e00f87ffd6498e7163a72a3e3() = normalize(<s1, app("object", [app("entry", [val("x"), val(false)]), app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])>) == <s1, val(("x": true, "y": 5, "z": "foo"))> ;
@autoName test bool _91946b1aba0ac9307de46787b3bb6891() = normalize(<s1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])]), app("entry", [val("x"), val(false)])])>) == <s1, val(("x": false, "y": 5, "z": "foo"))> ;

/*
 * Reduction
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION e: err()>)
    = <s, e> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: var(x)>)
    = <s, s.phi[x]> when x in s.phi ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION e: val(_)>)
    = <s, e> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: asc(d1, _)>)
    = <s, d1> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app(f, [*before, arg, *after])>)
    = <s, app(f, [*before, reduce(<s, arg>)<1>, *after])> when
        (true | it && d == reduce(<s, d>)<1> | d <- before) ,
        arg != reduce(<s, arg>)<1> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app(f, [*_, err(), *_])>)
    = <s, err()> ;

@autoName test bool _bd4cd3b8a0c8aa511302569b3f729d41() = reduce(<s2, err()>) == <s2, err()> ;
@autoName test bool _14197c21606b13642b0ef7cee4a0b1d4() = reduce(<s2, var("i")>) == <s2, val(5)> ;
@autoName test bool _1798e516c7695a48a65dd2738b9be312() = reduce(<s2, var("j")>) == <s2, val(6)> ;
@autoName test bool _3fb617b72fa8b2207ab1a0ce355a886c() = reduce(<s2, val(5)>) == <s2, val(5)> ;
@autoName test bool _263a53cfbd3e7ccea5022699bdb40a44() = reduce(<s2, asc(val(5), number())>) == <s2, val(5)> ;
@autoName test bool _c24c3bd6f829a3055450851ef1cec6c3() = reduce(<s2, app("?:", [app("!", [val(false)]), app("-", [var("i")]), app("-", [var("j")])])>) == <s2, app("?:", [val(true), app("-", [var("i")]), app("-", [var("j")])])> ;
@autoName test bool _caa7c61b5d45b4a369756e6b2fc1e55e() = reduce(<s2, app("?:", [val(true), app("-", [var("i")]), app("-", [var("j")])])>) == <s2, app("?:", [val(true), app("-", [val(5)]), app("-", [var("j")])])> ;
@autoName test bool _2de495d169d9d4d8afebc49db159f34f() = reduce(<s2, app("?:", [val(true), app("-", [val(5)]), app("-", [var("j")])])>) == <s2, app("?:", [val(true), val(-5), app("-", [var("j")])])> ;
@autoName test bool _39b2f4fff74191491440b538520806eb() = reduce(<s2, app("?:", [val(true), val(-5), app("-", [var("j")])])>) == <s2, app("?:", [val(true), val(-5), app("-", [val(6)])])> ;
@autoName test bool _f0a82188f430c41efc4fe824e0d9cc6b() = reduce(<s2, app("?:", [val(true), val(-5), app("-", [val(6)])])>) == <s2, app("?:", [val(true), val(-5), val(-6)])> ;
@autoName test bool _889a4d7272f0c81ed55a995cd5815733() = reduce(<s2, app("?:", [val(true), val(-5), val(-6)])>) == <s2, val(-5)> ;
@autoName test bool _a217c44f515e3029c46681c8e94a7fa5() = reduce(<s2, app("?:", [err(), val(5), val(6)])>) == <s2, err()> ;
@autoName test bool _35dff4e626c348106969164501d6ed5f() = reduce(<s2, app("?:", [val(true), err(), val(6)])>) == <s2, err()> ;
@autoName test bool _7383077709d1eac0724f20ded44d5565() = reduce(<s2, app("?:", [val(true), val(5), err()])>) == <s2, err()> ;

/*
 * Reduction: Any
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("??", [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(NULL _ !:= v1 ? v1 : v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("?:", [val(BOOLEAN b), val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(b ? v1 : v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app(",", args)>)
    = <s, args[-1]> when !any(ei <- args, !(ei is val)) ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("oaccess", [val(OBJECT obj), val(DATA_VALUE v)])>)
    = <s, val(obj[v])> when v in obj ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("aaccess", [val(ARRAY arr), val(NUMBER n)])>)
    = <s, val(arr[n])> when 0 <= n && n < size(arr) ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("aaccess", [val(ARRAY arr), val(NUMBER n)])>)
    = <s, val(NULL)> when n < 0 || size(arr) <= n ;

@autoName test bool _abe2873c55f423a575fa750dee664e9f() = reduce(<s1, app("??", [val(5), val(6)])>) == <s1, val(5)> ;
@autoName test bool _3f7eee43ea3f6bde29d2ec4afd92802b() = reduce(<s1, app("??", [val(NULL), val(6)])>) == <s1, val(6)> ;
@autoName test bool _fd487c3fd6dc64d22935a553202b928a() = reduce(<s1, app("?:", [val(true), val(5), val(6)])>) == <s1, val(5)> ;
@autoName test bool _dff9883b4ce25ad258d6451448d64782() = reduce(<s1, app("?:", [val(false), val(5), val(6)])>) == <s1, val(6)> ;
@autoName test bool _02060a9fda16491bedee98e800aab62f() = reduce(<s1, app(",", [val(5), val(6), val(7)])>) == <s1, val(7)> ;
@autoName test bool _7a494eea2c186e81ca9dc4e2ff375e60() = reduce(<s1, app("oaccess", [val(("x": true, "y": 5, "z": "foo")), val("x")])>) == <s1, val(true)> ;
@autoName test bool _654b6e56a73dada03c719b06d6838ef4() = reduce(<s1, app("oaccess", [val(("x": true, "y": 5, "z": "foo")), val("y")])>) == <s1, val(5)> ;
@autoName test bool _1960c2758afd740a923abb064d65dda5() = reduce(<s1, app("oaccess", [val(("x": true, "y": 5, "z": "foo")), val("z")])>) == <s1, val("foo")> ;
@autoName test bool _f6dc6b620ef3bf02dc32ae9360e753ce() = reduce(<s1, app("aaccess", [val([5, 6, 7]), val(0)])>) == <s1, val(5)> ;
@autoName test bool _1e126e6368bade5609f5b7fa3d7b12fd() = reduce(<s1, app("aaccess", [val([5, 6, 7]), val(1)])>) == <s1, val(6)> ;
@autoName test bool _fa4fc4104370dd5c77fbfe8f2ee0fc9f() = reduce(<s1, app("aaccess", [val([5, 6, 7]), val(2)])>) == <s1, val(7)> ;
@autoName test bool _5c31ca5e3f0d8d25dcbcb0560a337e10() = reduce(<s1, app("aaccess", [val([5, 6, 7]), val(3)])>) == <s1, val(NULL)> ;
@autoName test bool _d778e388fe7427517e1c2e8fce04363d() = reduce(<s1, app("aaccess", [val([5, 6, 7]), val(-1)])>) == <s1, val(NULL)> ;

/*
 * Reduction: Undefined
 */

/*
 * Reduction: Pids
 */

/*
 * Reduction: Null
 */

/*
 * Reduction: Booleans
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("\<",  [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 < v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("\<=", [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 <= v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("\>",  [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 > v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("\>=", [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 >= v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("==",  [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 == v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("!=",  [val(DATA_VALUE v1), val(DATA_VALUE v2)])>)
    = <s, val(v1 != v2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("!",   [val(BOOLEAN b)])>)
    = <s, val(!b)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("&&",  [val(BOOLEAN b1), val(BOOLEAN b2)])>)
    = <s, val(b1 && b2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("||",  [val(BOOLEAN b1), val(BOOLEAN b2)])>)
    = <s, val(b1 || b2)> ;

@autoName test bool _4074a950288540cd3f25a9bd28c14bd9() = reduce(<s1, app("\<", [val(5), val(6)])>) == <s1, val(true)> ;
@autoName test bool _4293cc5f5270caaddc332ad134100047() = reduce(<s1, app("\<", [val(6), val(6)])>) == <s1, val(false)> ;
@autoName test bool _32d9e53c1cfe563fbc638d7101fd2eec() = reduce(<s1, app("\<", [val(7), val(6)])>) == <s1, val(false)> ;
@autoName test bool _f37fc328ae0ea6df40d3fb0b6dee9e13() = reduce(<s1, app("\<=", [val(5), val(6)])>) == <s1, val(true)> ;
@autoName test bool _5f28010a7ed5345a0f865693ac3be91d() = reduce(<s1, app("\<=", [val(6), val(6)])>) == <s1, val(true)> ;
@autoName test bool _4b0592495096b4b5f5b3ab4106d3e32e() = reduce(<s1, app("\<=", [val(7), val(6)])>) == <s1, val(false)> ;
@autoName test bool _357dd883c48b18156eaf2ef439d81248() = reduce(<s1, app("\>", [val(6), val(5)])>) == <s1, val(true)> ;
@autoName test bool _2d0bb4ae63ea9352dfb858b49a9aa829() = reduce(<s1, app("\>", [val(6), val(6)])>) == <s1, val(false)> ;
@autoName test bool _af3eefc238ee0d4080aee1df25351ff2() = reduce(<s1, app("\>", [val(6), val(7)])>) == <s1, val(false)> ;
@autoName test bool _a121f03245f6f633c50d4698a2187c96() = reduce(<s1, app("\>=", [val(6), val(5)])>) == <s1, val(true)> ;
@autoName test bool _e4b3789b79fa04fdfc2c28013bfec7a4() = reduce(<s1, app("\>=", [val(6), val(6)])>) == <s1, val(true)> ;
@autoName test bool _c5e5aacf587e1b76007564ec36d418a6() = reduce(<s1, app("\>=", [val(6), val(7)])>) == <s1, val(false)> ;
@autoName test bool _6137f3b663f15dbb732e30c150c6e0fa() = reduce(<s1, app("==", [val(5), val(6)])>) == <s1, val(false)> ;
@autoName test bool _41ac529a967d6a7e0cf95582acd6d897() = reduce(<s1, app("==", [val(6), val(6)])>) == <s1, val(true)> ;
@autoName test bool _c5b84c8665f7f3c73efab351e7e19ce3() = reduce(<s1, app("!=", [val(5), val(6)])>) == <s1, val(true)> ;
@autoName test bool _4704cc5f5cda58739d19fe55f9dd79a9() = reduce(<s1, app("!=", [val(6), val(6)])>) == <s1, val(false)> ;
@autoName test bool _cb31a628a8a54a305fd84ad0d9717091() = reduce(<s1, app("!", [val(true)])>) == <s1, val(false)> ;
@autoName test bool _4545f0e841442d8718521216dc022546() = reduce(<s1, app("!", [val(false)])>) == <s1, val(true)> ;
@autoName test bool _636969ac6389008140a43c0fdcdb16de() = reduce(<s1, app("&&", [val(true), val(true)])>) == <s1, val(true)> ;
@autoName test bool _f74bb5758adea1ab00b4de6262612d7d() = reduce(<s1, app("&&", [val(true), val(false)])>) == <s1, val(false)> ;
@autoName test bool _9da6ee49ad740cf7ffdb5948046f7ec3() = reduce(<s1, app("&&", [val(false), val(true)])>) == <s1, val(false)> ;
@autoName test bool _d1b7a48fda6997b0d2828bc2e1382891() = reduce(<s1, app("&&", [val(false), val(false)])>) == <s1, val(false)> ;
@autoName test bool _55748d47e16a524359d64d1c49ad5702() = reduce(<s1, app("||", [val(true), val(true)])>) == <s1, val(true)> ;
@autoName test bool _87ce9ab3ed50f935a63695fd24d5ec55() = reduce(<s1, app("||", [val(true), val(false)])>) == <s1, val(true)> ;
@autoName test bool _0491279c0e860e17baf916b1308e2fa0() = reduce(<s1, app("||", [val(false), val(true)])>) == <s1, val(true)> ;
@autoName test bool _1ad7c8a6d0442ccb47c0b0c2f6e65bf7() = reduce(<s1, app("||", [val(false), val(false)])>) == <s1, val(false)> ;

/*
 * Reduction: Numbers
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("rank", [val(<_, NUMBER k>)])>)
    = <s, val(k)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("length", [val(ARRAY arr)])>)
    = <s, val(size(arr))> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("+",  [val(NUMBER n)])>)
    = <s, val(n)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("-",  [val(NUMBER n)])>)
    = <s, val(-n)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("+",  [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, val(n1 + n2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("-",  [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, val(n1 - n2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("*",  [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, val(n1 * n2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("/",  [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, n2 != 0 ? val(n1 / n2) : err()> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("%",  [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, n2 != 0 ? val(n1 % n2) : err()> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("**", [val(NUMBER n1), val(NUMBER n2)])>)
    = <s, val(toInt(pow(n1, n2)))> ;

@autoName test bool _a9b20f21a17962d2037c9f5e28eebc94() = reduce(<s1, app("rank", [val(<"@alice", 5>)])>) == <s1, val(5)> ;
@autoName test bool _9d249a84f43b0f1e6aa1e7bedaac9ee6() = reduce(<s1, app("length", [val([])])>) == <s1, val(0)> ;
@autoName test bool _2104f961ab8297119621da333c6b36e3() = reduce(<s1, app("length", [val([5, 6, 7])])>) == <s1, val(3)> ;
@autoName test bool _40f15e0f733b0921e7be813872d53923() = reduce(<s1, app("+", [val(5)])>) == <s1, val(5)> ;
@autoName test bool _7769cd3dfdfe822ebfca93ce942c8ac1() = reduce(<s1, app("+", [val(-5)])>) == <s1, val(-5)> ;
@autoName test bool _420c4b3be17687416d55a64d0df1d5e9() = reduce(<s1, app("-", [val(5)])>) == <s1, val(-5)> ;
@autoName test bool _6f0c88db00a5d769ee87aad5c3f8900a() = reduce(<s1, app("-", [val(-5)])>) == <s1, val(5)> ;
@autoName test bool _5ab0ebe9c6bfc45d479b652fe189e366() = reduce(<s1, app("+", [val(5), val(6)])>) == <s1, val(11)> ;
@autoName test bool _8e2630e6982a8a6c641577f7f571da84() = reduce(<s1, app("-", [val(5), val(6)])>) == <s1, val(-1)> ;
@autoName test bool _2079c42d555602c28a4b8ed97379aa39() = reduce(<s1, app("*", [val(5), val(6)])>) == <s1, val(30)> ;
@autoName test bool _b6f2423876951d9cd774a58aef607c2a() = reduce(<s1, app("/", [val(5), val(6)])>) == <s1, val(0)> ;
@autoName test bool _7e44c8b100f8c7bbc52649e01510e42f() = reduce(<s1, app("/", [val(5), val(0)])>) == <s1, err()> ;
@autoName test bool _d0d95ba4b68498e88513c0b1752840bc() = reduce(<s1, app("%", [val(5), val(6)])>) == <s1, val(5)> ;
@autoName test bool _d7c5ead1aa8fe20665fa5659df94d102() = reduce(<s1, app("%", [val(11), val(6)])>) == <s1, val(5)> ;
@autoName test bool _0e34c421df793230c5a200ba621770f0() = reduce(<s1, app("%", [val(5), val(0)])>) == <s1, err()> ;
@autoName test bool _1c0b348311851f82e1b9fd32e89e78e5() = reduce(<s1, app("**", [val(5), val(6)])>) == <s1, val(15625)> ;

/*
 * Reduction: Strings
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("role", [val(<STRING r, _>)])>)
    = <s, val(r)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("+", [val(STRING s1), val(STRING s2)])>)
    = <s, val(s1 + s2)> ;

@autoName test bool _70d711bf69fce215f646ed4002a7d513() = reduce(<s1, app("role", [val(<"@alice", 5>)])>) == <s1, val("@alice")> ;
@autoName test bool _8ba91f37db765fbee1bbfbfa62c83bd6() = reduce(<s1, app("+", [val("foo"), val("bar")])>) == <s1, val("foobar")> ;
@autoName test bool _33a73e4b66fdb115ea776605009dd3d8() = reduce(<s1, app("+", [val("foo"), val("")])>) == <s1, val("foo")> ;
@autoName test bool _16b9db69d83650a63ba88e104a41a57a() = reduce(<s1, app("+", [val(""), val("bar")])>) == <s1, val("bar")> ;

/*
 * Reduction: Arrays
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("array", args)>)
    = <s, val([v | val(v) <- args])> when !any(arg <- args, !(arg is val));
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("concat", [val(ARRAY arr1), val(ARRAY arr2)])>)
    = <s, val(arr1 + arr2)> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("slice", [val(ARRAY arr), val(NUMBER n1)])>)
    = <s, val(slice(arr, n1, size(arr)))> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("slice", [val(ARRAY arr), val(NUMBER n1), val(NUMBER n2)])>)
    = <s, val(slice(arr, n1, n2))> ;

private list[value] slice(list[value] l, int begin, int end) {
    length = size(l);

    if (begin < -length) {
        begin = 0; // Inside
    } else if (-length <= begin && begin < 0) {
        begin += length; // Inside
    } else if (0 <= begin && begin < length) {
        ; // Inside
    } else if (length <= begin) {
        ; // Outside
    }

    if (end < -length) {
        end = 0; // Inside
    } else if (-length <= end && end < 0) {
        end += length; // Inside
    } else if (0 <= end && end < length) {
        ; // Inside
    } else if (length <= end) {
        ; // Outside
    }

    return begin < end ? l[begin..end] : [];
}

@autoName test bool _b983cb0aac3304d3ddd3e05de68b0315() = reduce(<s1, app("array", [])>) == <s1, val([])> ;
@autoName test bool _f8ff5932d2e9881e94b4421ddfa133db() = reduce(<s1, app("array", [val(5), val(6), val(7)])>) == <s1, val([5, 6, 7])> ;
@autoName test bool _966f4858ff915860cadf4d8f085d5595() = reduce(<s1, app("concat", [val([5, 6]), val([7])])>) == <s1, val([5, 6, 7])> ;
@autoName test bool _fc4b1f646afa332cbe69ba93dd0d5e37() = reduce(<s1, app("concat", [val([5, 6]), val([])])>) == <s1, val([5, 6])> ;
@autoName test bool _2d9914ad1a010b5d6a65f3c03ba0f158() = reduce(<s1, app("concat", [val([]), val([7])])>) == <s1, val([7])> ;
@autoName test bool _0226fc3abb3b7f6b85a95d956375bae9() = reduce(<s1, app("concat", [val([]), val([])])>) == <s1, val([])> ;
@autoName test bool _464a3b35c74a3a53bf92e5e7cb136fe6() = reduce(<s1, app("slice", [val([]), val(1)])>) == <s1, val([])> ;
@autoName test bool _83c911dcb9fab63c6e5e95307f5b7531() = reduce(<s1, app("slice", [val([]), val(1), val(2)])>) == <s1, val([])> ;
@autoName test bool _314807614235b08e2b53a5972f829023() = reduce(<s1, app("slice", [val(["ant", "bison", "camel", "duck", "elephant"]), val(2)])>) == <s1, val(["camel", "duck", "elephant"])> ;
@autoName test bool _44f6cd163bdeb4cf1f4d0627fc6d08cf() = reduce(<s1, app("slice", [val(["ant", "bison", "camel", "duck", "elephant"]), val(2), val(4)])>) == <s1, val(["camel", "duck"])> ;
@autoName test bool _a76cc1f5bb3803478d33d60ee5dca819() = reduce(<s1, app("slice", [val(["ant", "bison", "camel", "duck", "elephant"]), val(1), val(5)])>) == <s1, val(["bison", "camel", "duck", "elephant"])> ;
@autoName test bool _fdd7efecc04e3cd5047de9c61d23beb8() = reduce(<s1, app("slice", [val(["ant", "bison", "camel", "duck", "elephant"]), val(-2)])>) == <s1, val(["duck", "elephant"])> ;
@autoName test bool _05ae3d963f847a86d23e3fb614c19670() = reduce(<s1, app("slice", [val(["ant", "bison", "camel", "duck", "elephant"]), val(2), val(-1)])>) == <s1, val(["camel", "duck"])> ;

/*
 * Reduction: Objects
 */

tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("object", args)>)
    = <s, val((() | it + v | val(OBJECT v) <- args))> when !any(arg <- args, val(OBJECT _) !:= arg) ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("entry", [val(STRING k1), val(v1)])>)
    = <s, val((k1: v1))> ;
tuple[DATA_STATE, DATA_EXPRESSION] reduce(<DATA_STATE s, DATA_EXPRESSION _: app("spread", [val(OBJECT m)])>)
    = <s, val(m)> ;

@autoName test bool _f8ff0a3a2a1eda5510d2031093eea3fd() = reduce(<s1, app("entry", [val("x"), val(NULL)])>) == <s1, val(("x": NULL))> ;
@autoName test bool _785194601d18494674ada47bbf867957() = reduce(<s1, app("spread", [val(("x": true, "y": 5, "z": "foo"))])>) == <s1, val(("x": true, "y": 5, "z": "foo"))> ;
@autoName test bool _19d92c7c76e0f1475befa2a8667ed55c() = reduce(<s1, app("object", [])>) == <s1, val(())> ;
@autoName test bool _9b95cbe60d6ff840c0cbc34303ffcca0() = reduce(<s1, app("object", [val(("x": NULL))])>) == <s1, val(("x": NULL))> ;
@autoName test bool _3c4ce56082ccc34ce9d29e4613738a9e() = reduce(<s1, app("object", [val(("x": true)), val(("y": 5)), val(("z": "foo"))])>) == <s1, val(("x": true, "y": 5, "z": "foo"))> ;
