module icplt::core::\data::\semantics::Static

import Message;
import util::Maybe;

import icplt::core::\data::\syntax::Abstract;

/*
 * Contexts
 */

data DATA_CONTEXT = context(map[DATA_VARIABLE, DATA_TYPE] gamma) ;

DATA_CONTEXT c1 = context(()) ;
DATA_CONTEXT c2 = context(("x": number(), "y": string())) ;

DATA_CONTEXT toDataContext(DATA_EXPRESSION e)
    = context((() | it + toDataContext(x).gamma | /var(x) := e)) ;

DATA_CONTEXT toDataContext(DATA_VARIABLE x) {
    DATA_TYPE toDataType(/^b[0-9]*$/) = boolean();
    DATA_TYPE toDataType(/^n[0-9]*$/) = number();
    DATA_TYPE toDataType(/^s[0-9]*$/) = string();
    return context((x: toDataType(x) | /^[bns][0-9]*$/ := x));
}

/*
 * Analysis
 */

list[Message] analyze(DATA_CONTEXT c, DATA_EXPRESSION e)
    = just(t) := infer(c, e)
    ? check(t, c, e)
    : [warning("Failed to infer data type", e.src)] ;

/*
 * Inference
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: err())
    = nothing() ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: var(x))
    = just(c.gamma[x]) when x in c.gamma ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: asc(_, t))
    = just(t) ;

default Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _)
    = nothing() ;

@autoName test bool _51c99049575d7f1416a94d8b2cb3a2a8() = infer(c2, err()) == nothing() ;
@autoName test bool _ce48ff87fb7abec78a3db3a0b4561714() = infer(c2, var("x")) == just(number()) ;
@autoName test bool _64d5f4af17c44fcc0dd4d72ddfd7e931() = infer(c2, var("y")) == just(string()) ;
@autoName test bool _b790297532a97488100999b4819ab614() = infer(c2, var("z")) == nothing() ;
@autoName test bool _3302a6f1b6d87769cc6fa7649739765e() = infer(c2, asc(var("x"), number())) == just(number()) ;

/*
 * Inference: Any
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("??", [e1, _]))
    = just(t) when just(t) := infer(c, e1), null() != t ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("??", [e1, e2]))
    = infer(c, e2) when just(null()) := infer(c, e1) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("?:", [_, e2, e3]))
    = just(t) when just(t) := infer(c, e2), just(t) := infer(c, e3) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app(",", args))
    = just(t) when just(t) := infer(c, args[-1]) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("access", [e1, val(k)]))
    = just(entries[k]) when just(object(entries)) := infer(c, e1), k in entries ;

@autoName test bool _0fa6283096175ed7ec660bc8ec8c9177() = infer(c1, app("??", [val(true), val(6)])) == just(boolean()) ;
@autoName test bool _af9406768698f27536722616478727c0() = infer(c1, app("??", [val(NULL), val(6)])) == just(number()) ;
@autoName test bool _beed366e77058d09b7d1ec0288d1faf7() = infer(c1, app("?:", [val(true), val(5), val(6)])) == just(number()) ;
@autoName test bool _087622313782d95462a0a2886cd56db0() = infer(c1, app("?:", [val(true), val(5), val(false)])) == nothing() ;
@autoName test bool _1a01b51fc3d410290b5113c61bdb7ae2() = infer(c1, app(",", [val(5), val(6), val(7)])) == just(number()) ;
@autoName test bool _dee0f8c5d525a564f4bf49991019c35c() = infer(c1, app(",", [val(5), val(6), val(false)])) == just(boolean()) ;
@autoName test bool _88618b735db0e3416dad3aa6ed9342f9() = infer(c1, app("access", [app("object", []), val("x")])) == nothing() ;
@autoName test bool _4dd10af27891279a8d12d09bd42d5fe0() = infer(c1, app("access", [app("object", [app("entry", [val("x"), val(NULL)])]), val("x")])) == just(null()) ;

/*
 * Inference: Pids
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: val(PID _: <r, _>))
    = just(pid(r)) ;

@autoName test bool _070f69047be4b36d059aa1f6f6cb8f0f() = infer(c1, val(<"Alice", 5>)) == just(pid("Alice")) ;

/*
 * Inference: Null
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: val(NULL _))
    = just(null()) ;

@autoName test bool _6eefc9aa71dc4806c6a26696a6f025d3() = infer(c1, val(NULL)) == just(null()) ;

/*
 * Inference: Booleans
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: val(BOOLEAN _))
    = just(boolean()) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: app(f, [_]))
    = just(boolean()) when f in {"!"} ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: app(f, [_, _]))
    = just(boolean()) when f in {"\<", "\<=", "\>", "\>=", "==", "!=", "&&", "||"} ;

@autoName test bool _227164a2a0b1a915608c5db6bed058cf() = infer(c1, val(true)) == just(boolean()) ;
@autoName test bool _6fe08ca190b42974768ed830a61c89e3() = infer(c1, val(false)) == just(boolean()) ;
@autoName test bool _20e0770a72e3889054a5fc56adfa9a3e() = infer(c1, app("!", [val(true)])) == just(boolean()) ;
@autoName test bool _e683b31b327c9ac99f9dcf7e0a99472e() = infer(c1, app("\<", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _4782966760e724e31f6d234b519a735e() = infer(c1, app("\<=", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _33f81ffbdee098d0781d3b6dc04a6511() = infer(c1, app("\>", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _e0d6dc29f205b79e882bf35d87d60b22() = infer(c1, app("\>=", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _8c45c85dd13feef7375f6374d96899ca() = infer(c1, app("==", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _f76301c8b061bfc56e97fc4ee527793f() = infer(c1, app("!=", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _72e24360b6360e1b47d834c29d4341da() = infer(c1, app("&&", [val(true), val(false)])) == just(boolean()) ;
@autoName test bool _f615e21ed891178d36e35b9f394c23f6() = infer(c1, app("||", [val(true), val(false)])) == just(boolean()) ;

/*
 * Inference: Numbers
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: val(NUMBER _))
    = just(number()) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: app(f, [_]))
    = just(number()) when f in {"length", "-", "+"} ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: app(f, [_, _]))
    = just(number()) when f in {"-", "*", "/", "%", "**"} ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("+", [e1, e2]))
    = just(number()) when just(number()) := infer(c, e1), just(number()) := infer(c, e2) ;

@autoName test bool _cfdd88fc5c4bcc9e5f9968375f628555() = infer(c1, val(5)) == just(number()) ;
@autoName test bool _43f4874d8f6e0060a69f3bad84111112() = infer(c1, app("length", [val([])])) == just(number()) ;
@autoName test bool _c981e70759dccd0c78e10716a03fd827() = infer(c1, app("+", [val(5)])) == just(number()) ;
@autoName test bool _79a5a515dce41ae39151fedc440b6940() = infer(c1, app("-", [val(5)])) == just(number()) ;
@autoName test bool _8bcd5b1b942a4da19a0475ca9d701af6() = infer(c1, app("-", [val(5), val(6)])) == just(number()) ;
@autoName test bool _b09c00c5841500128409f0c4e8272ee5() = infer(c1, app("*", [val(5), val(6)])) == just(number()) ;
@autoName test bool _65282e6d0b202519a34c746f8cd24935() = infer(c1, app("/", [val(5), val(6)])) == just(number()) ;
@autoName test bool _3bcd9cf22fc11ef185f53e16b8fed55b() = infer(c1, app("%", [val(5), val(6)])) == just(number()) ;
@autoName test bool _1e500e32406983263ed7136e083396bf() = infer(c1, app("**", [val(5), val(6)])) == just(number()) ;
@autoName test bool _a2ddcfea8710e7060285b369fe64fd9b() = infer(c1, app("+", [val(5), val(6)])) == just(number()) ;
@autoName test bool _8f01122a3f5f5e70857ee20b8c071ae5() = infer(c1, app("+", [val(5), val(false)])) == nothing() ;
@autoName test bool _a5fbde165b154e2d388119f5cc74e04c() = infer(c1, app("+", [val(true), val(6)])) == nothing() ;

/*
 * Inference: Strings
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT _, DATA_EXPRESSION _: val(STRING _))
    = just(string()) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("+", [e1, e2]))
    = just(string()) when just(string()) := infer(c, e1), just(string()) := infer(c, e2) ;

@autoName test bool _82821fec7444ca966b08b496b71e8122() = infer(c1, val("foo")) == just(string()) ;
@autoName test bool _5f001d8ea134c7eb39420d332aee3ab2() = infer(c1, app("+", [val("foo"), val("bar")])) == just(string()) ;
@autoName test bool _4d7e957e8314705caf956f12edf8ca82() = infer(c1, app("+", [val("foo"), val(false)])) == nothing() ;
@autoName test bool _72e75dcb9712fad722bafc4659fe4666() = infer(c1, app("+", [val(true), val("bar")])) == nothing() ;

/*
 * Inference: Arrays
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: val(ARRAY _: [e1, *rest]))
    = just(array(t1)) when just(t1) := infer(c, val(e1)), !any(vi <- rest, just(t1) != infer(c, val(vi))) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("array", [e1, *rest]))
    = just(array(t1)) when just(t1) := infer(c, e1), !any(ei <- rest, just(t1) != infer(c, ei)) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("concat", [e1, e2]))
    = just(array(t1)) when just(array(t1)) := infer(c, e1) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("concat", [val([]), e2]))
    = just(array(t2)) when just(array(t2)) := infer(c, e2) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("concat", [app("array", []), e2]))
    = just(array(t2)) when just(array(t2)) := infer(c, e2) ;

@autoName test bool _b47a9920b452f7fe8be0d24437d0b8c6() = infer(c1, val([])) == nothing() ;
@autoName test bool _c15371cc30ad1eb9d721989ca73c8ecd() = infer(c1, val([NULL])) == just(array(null())) ;
@autoName test bool _95b83c57b7c728f451746d00bad4d22e() = infer(c1, val([true, false])) == just(array(boolean())) ;
@autoName test bool _ce43170f855b17d6795603a37cc22e20() = infer(c1, val([NULL, true, false])) == nothing() ;
@autoName test bool _1ca0b52f336b6c4326b5f7727fb8c1a5() = infer(c1, app("concat", [val([true]), val([false])])) == just(array(boolean())) ;
@autoName test bool _81c9eeb260aab5e3f39a059e9d44ad72() = infer(c1, app("concat", [val([true]), val([])])) == just(array(boolean())) ;
@autoName test bool _783546a2c4d79bbd7a862155c1738d52() = infer(c1, app("concat", [val([]), val([false])])) == just(array(boolean())) ;
@autoName test bool _943ea08ce336646d09f73d942e59454f() = infer(c1, app("concat", [val([]), val([])])) == nothing() ;
@autoName test bool _63ba680c261e94e4e50d40d1cc28cb4e() = infer(c1, app("array", [])) == nothing() ;
@autoName test bool _37dc3661b2e0fc38a01f1ecae3b830a7() = infer(c1, app("array", [val(NULL)])) == just(array(null())) ;
@autoName test bool _0ad2ebc2ef27799d9b7b275bc7f6211e() = infer(c1, app("array", [val(true), val(false)])) == just(array(boolean())) ;
@autoName test bool _9f2792f1357638afdc2db3939e10c4ea() = infer(c1, app("array", [val(NULL), val(true), val(false)])) == nothing() ;
@autoName test bool _83f9eadadab4801a08606ba562153989() = infer(c1, app("concat", [app("array", [val(true)]), app("array", [val(false)])])) == just(array(boolean())) ;
@autoName test bool _181ba604db748a1b138e2025f8f19196() = infer(c1, app("concat", [app("array", [val(true)]), app("array", [])])) == just(array(boolean())) ;
@autoName test bool _866c09d937a950a74c6f457ee5523778() = infer(c1, app("concat", [app("array", []), app("array", [val(false)])])) == just(array(boolean())) ;
@autoName test bool _0136c2dfd8573ad4821bace61086d263() = infer(c1, app("concat", [app("array", []), app("array", [])])) == nothing() ;

/*
 * Inference: Objects
 */

Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("object", args))
    = just(object((() | it + entries | arg <- args, just(object(entries)) := infer(c, arg))))
    when !any(arg <- args, just(object(_)) !:= infer(c, arg)) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("entry", [val(STRING k1), DATA_EXPRESSION e1]))
    = just(object((k1: t1))) when just(DATA_TYPE t1) := infer(c, e1) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("spread", [DATA_EXPRESSION e1]))
    = just(t) when just(t: object(_)) := infer(c, e1) ;

@autoName test bool _6919d71f830fa0240623c36d88e2fa90() = infer(c1, app("object", [])) == just(object(())) ;
@autoName test bool _5cddcbfd53d72e838c124c2d1d007442() = infer(c1, app("object", [app("entry", [val("x"), val(NULL)])])) == just(object(("x": null()))) ;
@autoName test bool _fcfb0e4d242a91ea870d80c339cb0281() = infer(c1, app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])) == just(object(("x": boolean(), "y": number(), "z": string()))) ;
@autoName test bool _e64541260e0e580f9f3009b4385020f4() = infer(c1, app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])])) == just(object(("outer": object(("inner": object(())))))) ;
@autoName test bool _69fd485a48ca45253bff613cf0ca4aca() = infer(c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])) == just(object(("x": boolean(), "y": number(), "z": string()))) ;
@autoName test bool _26b16e38e221d62eed97941008ae329d() = infer(c1, app("object", [app("entry", [val("x"), val(false)]), app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])])])) == just(object(("x": boolean(), "y": number(), "z": string()))) ;
@autoName test bool _f248be8a07db0fbc2dca1cb2307e2957() = infer(c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])]), app("entry", [val("x"), val(false)])])) == just(object(("x": boolean(), "y": number(), "z": string()))) ;

/*
 * Checking
 */

list[Message] check(DATA_TYPE _, DATA_CONTEXT _, DATA_EXPRESSION _: err())
    = [] ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION e: var(x))
    = [error("Unexpected data variable", e.src) | x notin c.gamma]
    + [error("Expected data type: `<toStr(t)>`. Actual: `<toStr(c.gamma[x])>`.", e.src) | x in c.gamma, t !:= c.gamma[x]] ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: asc(e1, t))
    = check(t, c, e1) ;

default list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION e)
    = [error("Expected data type: `<toStr(t)>`. Actual: <actual(infer(c, e))>.", e.src)] ;

@autoName test bool _c361f9cc4f4191a7b307cd645337d828() = check(number(), c2, err()) == [] ;
@autoName test bool _b63d9d1a4bd13fa61a84b768430a0361() = check(number(), c2, var("x")) == [] ;
@autoName test bool _6c744d1265f5b796f53aaa43aba2909b() = check(number(), c2, var("y")) != [] ;
@autoName test bool _89b9aa032872d287b0e886daec647606() = check(number(), c2, var("z")) != [] ;
@autoName test bool _75016c16a6a27487275705914c094a18() = check(number(), c2, asc(var("x"), number())) == [] ;
@autoName test bool _3a2d7b5147a262b51bb7f0a73a99f36d() = check(number(), c2, asc(var("y"), number())) != [] ;
@autoName test bool _4ea05890087f2246147b77a055a32f9d() = check(number(), c2, asc(var("y"), string())) != [] ;

str actual(Maybe[DATA_TYPE] _: just(t))   = "`<toStr(t)>`" ;
str actual(Maybe[DATA_TYPE] _: nothing()) = "Failed to infer" ;

/*
 * Checking: Any
 */

list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: app("??", [e1, e2]))
    = check(t, c, e1) when [_, *_] := check(null(), c, e1) ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: app("??", [e1, e2]))
    = check(t, c, e2) when [] == check(null(), c, e1) ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: app("?:", [e1, e2, e3]))
    = check(boolean(), c, e1) + check(t, c, e2) + check(t, c, e3) ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: app(",", args))
    = [*analyze(c, ei) | ei <- args] ;
list[Message] check(DATA_TYPE t, DATA_CONTEXT c, DATA_EXPRESSION _: app("access", [e1, e2: val(k)]))
    = [error("Expected data type: `{...; <k>: <toStr(t)>; ...}`. Actual: Failed to infer.", e1.src) | nothing() := infer(c, e1)]
    + analyze(c, e1)
    + [error("Unexpected property", e2.src) | just(object(entries)) := infer(c, e1), k notin entries]
    + [error("Expected data type: `<toStr(t)>`. Actual: `<toStr(entries[k])>`.", e2.src) | just(object(entries)) := infer(c, e1), k in entries, t !:= entries[k]] ;

@autoName test bool _d20643ad73e72af30385ae9ea20c8adb() = check(number(), c1, app("??", [val(5), val(6)])) == [] ;
@autoName test bool _a1ca13c1a726c598b55a8a234b110915() = check(number(), c1, app("??", [val(true), val(6)])) != [] ;
@autoName test bool _efedc9fea899ab5dd5397cbb643632d8() = check(number(), c1, app("??", [val(NULL), val(6)])) == [] ;
@autoName test bool _ec30108c4034355bb8866980cc463b81() = check(number(), c1, app("??", [val(NULL), val(false)])) != [] ;
@autoName test bool _04fbcfbf100273cf3e31489f389e55f2() = ret := check(number(), c1, app("?:", [val(true), val(5), val(6)])) && [] == ret ;
@autoName test bool _b9ded782be9e877017162c08232490b3() = ret := check(number(), c1, app("?:", [val(true), val(5), val(false)])) && [_] := ret ;
@autoName test bool _89284e05c04f554be668c88b7f31f05e() = ret := check(number(), c1, app("?:", [val(true), val(true), val(6)])) && [_] := ret ;
@autoName test bool _0a4d8c97b1bec39dac323e5bd5f19f12() = ret := check(number(), c1, app("?:", [val(true), val(true), val(false)])) && [_, _] := ret ;
@autoName test bool _ea6e934ddc632079268efcc0a6d18ab9() = ret := check(number(), c1, app("?:", [val(NULL), val(5), val(6)])) && [_] := ret ;
@autoName test bool _343da6f211979382ce3d37524e411d9f() = ret := check(number(), c1, app("?:", [val(NULL), val(5), val(false)])) && [_, _] := ret ;
@autoName test bool _6427c6c99625cce933e1c5d1123e747f() = ret := check(number(), c1, app("?:", [val(NULL), val(true), val(6)])) && [_, _] := ret ;
@autoName test bool _b7ace307348152eb25d93b39e9ba1831() = ret := check(number(), c1, app("?:", [val(NULL), val(true), val(false)])) && [_, _, _] := ret ;
@autoName test bool _60641a96ae8f55e7f665e7df93f45808() = ret := check(number(), c1, app(",", [val(5), val(6), val(7)])) && [] == ret ;
@autoName test bool _a6f23016e0184374024316bdf098144d() = ret := check(number(), c1, app(",", [val(5), val(6), var("x")])) && [_] := ret ;
@autoName test bool _0c6b17aa603c1d64ed0e016f516dc34a() = ret := check(number(), c1, app(",", [val(5), var("x"), val(7)])) && [_] := ret ;
@autoName test bool _97ff22783300bcded16ecf13e984a95a() = ret := check(number(), c1, app(",", [var("x"), val(6), val(7)])) && [_] := ret ;
@autoName test bool _59093a3fc5154bfb70e213651c8f3f7c() = ret := check(number(), c1, app(",", [var("x"), var("x"), var("x")])) && [_, _, _] := ret ;
@autoName test bool _4555b72521b249d129759374d2a02544() = ret := check(null(), c1, app("access", [app("object", [app("entry", [val("x"), val(NULL)])]), val("x")])) && [] == ret ;
@autoName test bool _ee0092fadd3e29e5bcd13d535d5f2f3c() = ret := check(boolean(), c1, app("access", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])]), val("x")])) && [] == ret ;
@autoName test bool _0fac89470430b85fbabbd595781c444f() = ret := check(number(), c1, app("access", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])]), val("y")])) && [] == ret ;
@autoName test bool _de762fbcfb8a149db0d1d0e21e88f689() = ret := check(string(), c1, app("access", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])]), val("z")])) && [] == ret ;
@autoName test bool _9950f66e860b8d9450f910df33322dc7() = ret := check(object(("inner": object(()))), c1, app("access", [app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])]), val("outer")])) && [] == ret ;
@autoName test bool _bb51bf0f66878e601abff8b30bb2061a() = ret := check(object(()), c1, app("access", [app("access", [app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])]), val("outer")]), val("inner")])) && [] == ret ;
@autoName test bool _5f1af219135a75d0e2d22f30a623fe23() = ret := check(number(), c1, app("access", [app("object", []), val("x")])) && [_] := ret ;
@autoName test bool _c2f97fb16f89e47ca3a1c02072404932() = ret := check(number(), c1, app("access", [app("object", [app("entry", [val("x"), val(NULL)])]), val("x")])) && [_] := ret ;

/*
 * Checking: Pids
 */

list[Message] check(DATA_TYPE _: pid(r), DATA_CONTEXT _, DATA_EXPRESSION _: val(PID _: <r, _>))
    = [] ;

@autoName test bool _c7000bd51e50018191553bb09a993a56() = check(pid("Alice"), c1, val(<"Alice", 5>)) == [] ;
@autoName test bool _57de2a703110c19f7895e12f61f038c0() = check(pid("Alice"), c1, val(<"Bob", 5>)) != [] ;

/*
 * Checking: Null
 */

list[Message] check(DATA_TYPE _: null(), DATA_CONTEXT _, DATA_EXPRESSION _: val(NULL _))
    = [] ;

@autoName test bool _83a97367bc6149d9dec907b0ff2e1c69() = check(null(), c1, val(NULL)) == [] ;

/*
 * Checking: Booleans
 */

list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT _, DATA_EXPRESSION _: val(BOOLEAN _))
    = [] ;
list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1]))
    = check(boolean(), c, e1) when f in {"!"};
list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(number(), c, e1) + check(number(), c, e2) when f in {"\<", "\<=", "\<", "\>="} ;
list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(boolean(), c, e1) + check(boolean(), c, e2) when f in {"&&", "||"} ;
list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = analyze(c, e1) + analyze(c, e2) when f in {"==", "!="} ;

@autoName test bool _1f0dd382aff0c2408b5d043837c3d5ed() = check(boolean(), c1, val(true)) == [] ;
@autoName test bool _c4ad0abfb3e651508d45258ee8535eb7() = check(boolean(), c1, val(false)) == [] ;
@autoName test bool _88a0f6b8560e4703ab40ca87e8d4be5c() = check(boolean(), c1, app("!", [val(true)])) == [] ;
@autoName test bool _1ebcc785afdb6098187fbaf79107cc58() = check(boolean(), c1, app("!", [val(5)])) != [] ;
@autoName test bool _e905d11b30e5aa6af4c2306fac5c841c() = ret := check(boolean(), c1, app("\<", [val(5), val(6)])) && [] == ret ;
@autoName test bool _f592a1432e33676fd64199f50cc518c7() = ret := check(boolean(), c1, app("\<", [val(5), val(false)])) && [_] := ret ;
@autoName test bool _dfa98b5846d064229841c82bc47cf3b7() = ret := check(boolean(), c1, app("\<", [val(true), val(6)])) && [_] := ret ;
@autoName test bool _d22c5b212510f5efaac2fe8768d9053f() = ret := check(boolean(), c1, app("\<", [val(true), val(false)])) && [_, _] := ret ;
@autoName test bool _04968c682b70abc86dda231b9ab78df3() = ret := check(boolean(), c1, app("&&", [val(true), val(false)])) && [] == ret ;
@autoName test bool _b26a9f7eeb2881c73ab4420b7697035f() = ret := check(boolean(), c1, app("&&", [val(true), val(6)])) && [_] := ret ;
@autoName test bool _6c8af9b2c91683956bdcae95228c1ca2() = ret := check(boolean(), c1, app("&&", [val(5), val(false)])) && [_] := ret ;
@autoName test bool _81c80976a44770f4e447a85de27e8ea3() = ret := check(boolean(), c1, app("&&", [val(5), val(6)])) && [_, _] := ret ;

/*
 * Checking: Numbers
 */

list[Message] check(DATA_TYPE _: number(), DATA_CONTEXT _, DATA_EXPRESSION _: val(NUMBER _))
    = [] ;
list[Message] check(DATA_TYPE _: number(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1]))
    = [error("Expected data type: any array. Actual: <actual(maybe)>.", e1.src) | maybe := infer(c, e1), just(array(_)) !:= maybe]
    + [*check(array(t), c, e1) | just(array(t)) := infer(c, e1)]
    when f in {"length"} ;
list[Message] check(DATA_TYPE _: number(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1]))
    = check(number(), c, e1) when f in {"-", "+"} ;
list[Message] check(DATA_TYPE _: number(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(number(), c, e1) + check(number(), c, e2) when f in {"+", "-", "*", "/", "%", "**"} ;

@autoName test bool _aa853b56bfc9d7c7342723a0f79392a4() = check(number(), c1, val(5)) == [] ;
@autoName test bool _bde4f4a0bf77456da7dde96d901ee2ec() = check(number(), c1, app("length", [val([5])])) == [] ;
@autoName test bool _389d9fb332c88dd8adaae1b80bf509c7() = check(number(), c1, app("length", [val(false)])) != [] ;
@autoName test bool _8adbbe758b3165543bd3587dbc2df548() = check(number(), c1, app("+", [val(5)])) == [] ;
@autoName test bool _bbab6700f7dbd87ae88c25e5fef8910b() = check(number(), c1, app("+", [val(true)])) != [] ;
@autoName test bool _924e872858d361bb39fb677ebda5594a() = ret := check(number(), c1, app("+", [val(5), val(6)])) && [] == ret ;
@autoName test bool _444f65b872e33efa8f8d83785ef6c9ec() = ret := check(number(), c1, app("+", [val(5), val(false)])) && [_] := ret ;
@autoName test bool _2583c31a03df994c0c5c2a1e1a926bda() = ret := check(number(), c1, app("+", [val(true), val(6)])) && [_] := ret ;
@autoName test bool _40038569aa9b7bbbd5f45472314d4bc3() = ret := check(number(), c1, app("+", [val(true), val(false)])) && [_, _] := ret ;

/*
 * Checking: Strings
 */

list[Message] check(DATA_TYPE _: string(), DATA_CONTEXT _, DATA_EXPRESSION _: val(STRING _))
    = [] ;
list[Message] check(DATA_TYPE _: string(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(string(), c, e1) + check(string(), c, e2) when f in {"+"} ;

@autoName test bool _90003fa25b3328b6844e35bdc9360d5f() = check(string(), c1, val("foo")) == [] ;
@autoName test bool _3f3d927ee19c7ce561b396d8201d09c7() = ret := check(string(), c1, app("+", [val("foo"), val("bar")])) && [] == ret ;
@autoName test bool _c6d4488214cd3a1b69474e36c3fdfc75() = ret := check(string(), c1, app("+", [val("foo"), val(false)])) && [_] := ret ;
@autoName test bool _bcc5e8c5c8362a4df20ace8fd3e5ff1f() = ret := check(string(), c1, app("+", [val(true), val("bar")])) && [_] := ret ;
@autoName test bool _79dd6ffbeacab3dc04633440b3e9c126() = ret := check(string(), c1, app("+", [val(true), val(false)])) && [_, _] := ret ;

/*
 * Checking: Arrays
 */

list[Message] check(DATA_TYPE _: array(t1), DATA_CONTEXT c, DATA_EXPRESSION e: val(ARRAY a))
    = [*check(t1, c, val(vi)[src = e.src]) | vi <- a] ;
list[Message] check(DATA_TYPE _: array(t1), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, args))
    = [*check(t1, c, arg) | arg <- args] when f in {"array"} ;
list[Message] check(DATA_TYPE _: array(t1), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(array(t1), c, e1) + check(array(t1), c, e2) when f in {"concat"} ;

@autoName test bool _a5e95bbf20dfd6e7a23b9b3ff3505a69() = check(array(number()), c1, val([])) == [] ;
@autoName test bool _23f47ebe702d204b6e5345b9f3ea254b() = ret := check(array(number()), c1, val([5, 6])) && [] == ret ;
@autoName test bool _db0c13da39b4fd0f7736e04ee2b6dbea() = ret := check(array(number()), c1, val([5, 6, true])) && [_] := ret ;
@autoName test bool _15e21f40822a64a8a907cb56ab0bc0fe() = ret := check(array(number()), c1, val([5, 6, true, false])) && [_, _] := ret ;
@autoName test bool _72651e0cc114ebc2f035717e1b954d70() = ret := check(array(number()), c1, app("concat", [val([5]), val([6])])) && [] == ret ;
@autoName test bool _2d844eeca8238b6564d782f13ea5048e() = ret := check(array(number()), c1, app("concat", [val([5]), val([false])])) && [_] := ret ;
@autoName test bool _f1abf293e87976396deb6a82b985971b() = ret := check(array(number()), c1, app("concat", [val([true]), val([6])])) && [_] := ret ;
@autoName test bool _6d6dbd97bcfbc916819572545542db1d() = ret := check(array(number()), c1, app("concat", [val([true]), val([false])])) && [_, _] := ret ;
@autoName test bool _4b38147791e6116385c5a6d80372559b() = check(array(number()), c1, app("array", [])) == [] ;
@autoName test bool _cda346d856c6b68ac527848d31587d35() = ret := check(array(number()), c1, app("array", [val(5), val(6)])) && [] == ret ;
@autoName test bool _95c9d8d89587985a72992d4d55126e8b() = ret := check(array(number()), c1, app("array", [val(5), val(6), val(true)])) && [_] := ret ;
@autoName test bool _a74777c5d1687fde2398f9355051e236() = ret := check(array(number()), c1, app("array", [val(5), val(6), val(true), val(false)])) && [_, _] := ret ;
@autoName test bool _f13c4e0c8ecf1a8456b9d0c2bd1c6ad7() = ret := check(array(number()), c1, app("concat", [app("array", [val(5)]), app("array", [val(6)])])) && [] == ret ;
@autoName test bool _1c582cd379c778fd83b4bf8534d444f8() = ret := check(array(number()), c1, app("concat", [app("array", [val(5)]), app("array", [val(false)])])) && [_] := ret ;
@autoName test bool _7a7918c46bbacdbaa77f7f1a7438c861() = ret := check(array(number()), c1, app("concat", [app("array", [val(true)]), app("array", [val(6)])])) && [_] := ret ;
@autoName test bool _4b27ab68a00d14ca3efb749b2c47cb52() = ret := check(array(number()), c1, app("concat", [app("array", [val(true)]), app("array", [val(false)])])) && [_, _] := ret ;

/*
 * Checking: Objects
 */

list[Message] check(DATA_TYPE t: object(_), DATA_CONTEXT c, DATA_EXPRESSION e: app(f, args))
    = [error("Expected data type: any object. Actual: <actual(maybe)>", e.src) | maybe := infer(c, e), just(object(_)) !:= maybe]
    + [error("Expected property: `<k>`", e.src) | just(object(entries)) := infer(c, e), k <- t.entries, k notin entries]
    + [*check(t, c, arg) | arg <- args]
    when f in {"object"} ;
list[Message] check(DATA_TYPE _: object(entries), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1: val(STRING k1), DATA_EXPRESSION e2]))
    = [error("Unexpected property", e1.src) | k1 notin entries]
    + [*check(entries[k1], c, e2) | k1 in entries]
    when f in {"entry"} ;
list[Message] check(DATA_TYPE t: object(entries), DATA_CONTEXT c, _: DATA_EXPRESSION e: app(f, [DATA_EXPRESSION e1]))
    = [error("Expected data type: any object. Actual: <actual(maybe)>.", e1.src) | maybe := infer(c, e1), just(object(_)) !:= maybe]
    + [*check(object((k: entries[k] | k <- entries1, k in entries)), c, e1) | just(object(entries1)) := infer(c, e1)]
    when f in {"spread"};

@autoName test bool _5964ee1ce46983e2f2753970468f5c07() = ret := check(object(("x": null())), c1, app("entry", [val("x"), val(NULL)])) && [] == ret ;
@autoName test bool _d54982a4dfec7b4951123ade0307cc9b() = ret := check(object(("x": null())), c1, app("entry", [val("y"), val(NULL)])) && [_] := ret ;
@autoName test bool _2b11ef3450474268609f7021b2054cd0() = ret := check(object(("x": null())), c1, app("entry", [val("x"), val(5)])) && [_] := ret ;
@autoName test bool _995b0901040a7409011638060967c566() = ret := check(object(("x": boolean(), "y": number())), c1, app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)])])])) && [] == ret ;
@autoName test bool _338bd4cd599f0b13d7e0c659476c092d() = ret := check(object(("x": boolean(), "y": number())), c1, app("spread", [app("object", [app("entry", [val("x"), val(true)])])])) && [] == ret ;
@autoName test bool _1841170688a1de9a2b3eb431a665607d() = ret := check(object(("x": boolean(), "y": number())), c1, app("spread", [val(5)])) && [_] := ret ;
@autoName test bool _9490f9f4c4efd546cdf93d5e8fdd8700() = ret := check(object(("x": boolean(), "y": number())), c1, app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val("foo")])])])) && [_] := ret ;
@autoName test bool _fe170de48623f56f88dd7990fb50f1e0() = ret := check(object(("x": boolean(), "y": number())), c1, app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("z"), val("foo")])])])) && [_] := ret ;
@autoName test bool _a16f65d4548c1fd802ac54ff06fb9bf5() = ret := check(object(()), c1, app("object", [])) && [] == ret ;
@autoName test bool _53bef20c9c6e64caa4e00ce63e0dca3f() = ret := check(object(("x": null())), c1, app("object", [app("entry", [val("x"), val(NULL)])])) && [] == ret ;
@autoName test bool _aad7f3b96b7e377f56e4257a55067147() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val("foo")])])) && [] == ret ;
@autoName test bool _3d195474b8866fdc02d976f0220a6b87() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)])])]), app("entry", [val("z"), val("foo")])])) && [] == ret ;
@autoName test bool _bad49f0fa69955baf24fb1e193db9188() = ret := check(object(("outer": object(("inner": object(()))))), c1, app("object", [app("entry", [val("outer"), app("object", [app("entry", [val("inner"), app("object", [])])])])])) && [] == ret ;
@autoName test bool _2a1590520c47213c9b23a357ec5479b6() = ret := check(object(("x": null())), c1, val(5)) && [_] := ret ;
@autoName test bool _6ea5483264febd27e5a12b7d30186592() = ret := check(object(("x": null())), c1, app("object", [])) && [_] := ret ;
@autoName test bool _7f10ea6a613a87d1ab2b7c948051ea58() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)]), app("entry", [val("z"), val(NULL)])])) && [_] := ret ;
@autoName test bool _9d4637ae272f57c9733e30717a739fc5() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(NULL)]), app("entry", [val("z"), val(NULL)])])) && [_, _] := ret ;
@autoName test bool _a0b8fe4ad9497ce11bc9f122cf21f315() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("entry", [val("x"), val(NULL)]), app("entry", [val("y"), val(NULL)]), app("entry", [val("z"), val(NULL)])])) && [_, _, _] := ret ;
@autoName test bool _168561c1567b842d46711d3afaa19162() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)])])])])) && [_] := ret ;
@autoName test bool _a63629509a2a84f0f44a5baf67400547() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)])])]), app("entry", [val("z"), val("foo")])])) && [_] := ret ;
@autoName test bool _995d60369f01bf3fd688dc942243bd22() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)])])]), app("entry", [val("zz"), val(NULL)])])) && [_, _] := ret ;
@autoName test bool _15ae61b696bd601b842ce76bdc580002() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(5)])])]), app("entry", [val("z"), val(NULL)])])) && [_] := ret ;
@autoName test bool _06acbe1d718ffb46ba14ce18f4db6dda() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(true)]), app("entry", [val("y"), val(NULL)])])]), app("entry", [val("z"), val(NULL)])])) && [_, _] := ret ;
@autoName test bool _0abc8c6bb327b86fbaea10bd4af71b2c() = ret := check(object(("x": boolean(), "y": number(), "z": string())), c1, app("object", [app("spread", [app("object", [app("entry", [val("x"), val(NULL)]), app("entry", [val("y"), val(NULL)])])]), app("entry", [val("z"), val(NULL)])])) && [_, _, _] := ret ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("isNil", [e1]))
    = just(boolean()) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("cons", [e1, _]))
    = just(array(t1)) when just(t1) := infer(c, e1) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("headOrDefault", [_, e2]))
    = just(t2) when just(t2) := infer(c, e2) ;
Maybe[DATA_TYPE] infer(DATA_CONTEXT c, DATA_EXPRESSION _: app("tailOrDefault", [_, e2]))
    = just(array(t2)) when just(array(t2)) := infer(c, e2) ;

@autoName test bool _09f3d682db0387cd1ac0063897a31542() = infer(c1, app("isNil", [val([5, 6, 7])])) == just(boolean()) ;
@autoName test bool _af0a516f80ce7296b3d814134e7a1c39() = infer(c1, app("isNil", [app("array", [val(5), val(6), val(7)])])) == just(boolean()) ;
@autoName test bool _a8a0f21229df7e184cf8c91eddbdba6e() = infer(c1, app("cons", [val(5), val([6, 7])])) == just(array(number())) ;
@autoName test bool _559f8523af4661a2d5fb87c1594b6e0c() = infer(c1, app("cons", [val(5), app("array", [val(6), val(7)])])) == just(array(number())) ;
@autoName test bool _5967f45337d308af8d5d3a5ef7bd7001() = infer(c1, app("headOrDefault", [val([5, 6]), val(7)])) == just(number()) ;
@autoName test bool _233fd248e738814fef791b99b5d157ef() = infer(c1, app("headOrDefault", [app("array", [val(5), val(6)]), val(7)])) == just(number()) ;
@autoName test bool _ee51d9294d75edecc16ba35bb9fbe7c8() = infer(c1, app("tailOrDefault", [val([5, 6]), val([7])])) == just(array(number())) ;
@autoName test bool _0307af036d542333cc095e646436b128() = infer(c1, app("tailOrDefault", [app("array", [val(5), val(6)]), app("array", [val(7)])])) == just(array(number())) ;

list[Message] check(DATA_TYPE _: boolean(), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1]))
    = [error("Expected data type: any array. Actual: <actual(maybe)>.", e1.src) | maybe := infer(c, e1), just(array(_)) !:= maybe]
    + [*check(array(t), c, e1) | just(array(t)) := infer(c, e1)]
    when f in {"isNil"} ;
list[Message] check(DATA_TYPE _: array(t1), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(t1, c, e1) + check(array(t1), c, e2) when f in {"cons"} ;
list[Message] check(DATA_TYPE _: t2, DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(array(t2), c, e1) + check(t2, c, e2) when f in {"headOrDefault"} ;
list[Message] check(DATA_TYPE _: array(t2), DATA_CONTEXT c, DATA_EXPRESSION _: app(f, [e1, e2]))
    = check(array(t2), c, e1) + check(array(t2), c, e2) when f in {"tailOrDefault"} ;

@autoName test bool _084f4fd9901f5a3f968ffd1a8333c1e0() = check(boolean(), c1, app("isNil", [val([5, 6, 7])])) == [] ;
@autoName test bool _1679704e0582d7c9bea8b39d4746702c() = check(boolean(), c1, app("isNil", [val([5, 6, false])])) != [] ;
@autoName test bool _b91bb394c45f2e87b516e6e9993d675d() = check(boolean(), c1, app("isNil", [app("array", [val(5), val(6), val(7)])])) == [] ;
@autoName test bool _233249f316583b209d199037700fca88() = check(boolean(), c1, app("isNil", [app("array", [val(5), val(6), val(false)])])) != [] ;
@autoName test bool _43e108ce484fd1d2057a9c14020cd4bc() = check(boolean(), c1, app("isNil", [val(false)])) != [] ;
@autoName test bool _5cecb60cf612cd19019efccf1f2860fe() = check(array(number()), c1, app("cons", [val(5), val([6, 7])])) == [] ;
@autoName test bool _547b71178bf538046ea7de98a2b6b7de() = check(array(number()), c1, app("cons", [val(5), val([6, false])])) != [] ;
@autoName test bool _effb6ed6f7ec44cf5a51c90fd91c2cd3() = check(array(number()), c1, app("cons", [val(false), val([6, 7])])) != [] ;
@autoName test bool _e6b9ab65e4ae06897a423629f5bcf510() = check(array(number()), c1, app("cons", [val(5), app("array", [val(6), val(7)])])) == [] ;
@autoName test bool _39a4b415ef24fab7a0a87e7f03c26b7e() = check(array(number()), c1, app("cons", [val(5), app("array", [val(6), val(false)])])) != [] ;
@autoName test bool _d46bb7eb53e9d4efb2e461931acc45cb() = check(array(number()), c1, app("cons", [val(false), app("array", [val(6), val(7)])])) != [] ;
@autoName test bool _ef096966bec88c8e1bade323f25ca436() = check(number(), c1, app("headOrDefault", [val([5, 6]), val(7)])) == [] ;
@autoName test bool _270eecb94868360a5b4c955c9e1bf52c() = check(number(), c1, app("headOrDefault", [val([5, 6]), val(false)])) != [] ;
@autoName test bool _d73cedec342cc75e533503ab8757d073() = check(number(), c1, app("headOrDefault", [val([5, false]), val(7)])) != [] ;
@autoName test bool _a5f99329dbe010bc99bf404e0628a462() = check(number(), c1, app("headOrDefault", [app("array", [val(5), val(6)]), val(7)])) == [] ;
@autoName test bool _67f52ddc2936f9df93ab757f89ce3059() = check(number(), c1, app("headOrDefault", [app("array", [val(5), val(6)]), val(false)])) != [] ;
@autoName test bool _14f0ef0cd93fedede084d9297be92348() = check(number(), c1, app("headOrDefault", [app("array", [val(5), val(false)]), val(7)])) != [] ;
@autoName test bool _f4d0489c982c5f8887c74d25f6fdd6d7() = check(array(number()), c1, app("tailOrDefault", [val([5, 6]), val([7])])) == [] ;
@autoName test bool _829ad6f3de0b94069a9f91b9d1f9278d() = check(array(number()), c1, app("tailOrDefault", [val([5, 6]), val([false])])) != [] ;
@autoName test bool _87b252e5ea0f7ebeaba5c4a8098d8cbb() = check(array(number()), c1, app("tailOrDefault", [val([5, false]), val([7])])) != [] ;
@autoName test bool _2ce45d5000a3aaf5357fad9c4e102217() = check(array(number()), c1, app("tailOrDefault", [app("array", [val(5), val(6)]), app("array", [val(7)])])) == [] ;
@autoName test bool _8e369a18e072100792962e5b8b2661b5() = check(array(number()), c1, app("tailOrDefault", [app("array", [val(5), val(6)]), app("array", [val(false)])])) != [] ;
@autoName test bool _b2753231cff58ad3938bd1d98fa5cced() = check(array(number()), c1, app("tailOrDefault", [app("array", [val(5), val(false)]), app("array", [val(7)])])) != [] ;
