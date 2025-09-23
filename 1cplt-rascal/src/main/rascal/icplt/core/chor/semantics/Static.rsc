module icplt::core::\chor::\semantics::Static

import List;
import Message;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\data::\semantics::Static;
import util::Maybe;

/*
 * Contexts
 */

data CHOR_CONTEXT = context(
    map[ROLE, map[DATA_VARIABLE, DATA_TYPE]] gammas,
    map[ROLE, map[CHOR_VARIABLE, CHOR_TYPE]] deltas) ;

CHOR_CONTEXT c1 = context((), ()) ;
CHOR_CONTEXT c2 = context(("@alice": ("i": number()), "@bob": ("i": number(), "b": boolean())), ("@alice": ("f": chor("@alice"), "g": chor("@bob")), "@bob": ())) ;
CHOR_CONTEXT c3 = context(("@alice": (), "@bob": ("x": union([number(), undefined()]), "y": number(), "z": undefined())), ("@alice": ("f": chor("@alice"), "g": chor("@bob")), "@bob": ())) ;
CHOR_CONTEXT c4 = context(("@alice": ("i": union([number(), undefined()]), "j": number()), "@bob": ("i": union([number(), undefined()]))), ("@alice": (), "@bob": ())) ;

CHOR_CONTEXT toChorContext(CHOR_EXPRESSION e) {
    set[PID]  pids  = {rk | /PID rk := e};
    set[ROLE] roles = {r | <r, _> <- pids};

    map[DATA_VARIABLE, DATA_TYPE] gamma = ();
    map[CHOR_VARIABLE, CHOR_TYPE] delta = ();

    gamma = (gamma | it + toDataContext(eData).gamma | /DATA_EXPRESSION eData := e);
    gamma = (gamma | it + toDataContext(xData).gamma | /asgn(xData, _) := e);
    gamma = (gamma | it + toDataContext(xData).gamma | /comm(_, _, xData, _) := e);
    return context((r: gamma | r <- roles), (r: delta | r <- roles));
}

/*
 * Analysis
 */

list[Message] analyze(CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = just(t) := infer(c, e)
    ? check(t, c, e)
    : [warning("Failed to infer type", e.src)] ;

/*
 * Inference
 */

Maybe[CHOR_TYPE] infer(CHOR_CONTEXT _, CHOR_EXPRESSION _: at(eData, _))
    = just(chor(r)) when just(pid(r)) := infer(DATA_CONTEXT::context(()), eData) ;

default Maybe[CHOR_TYPE] infer(CHOR_CONTEXT _, CHOR_EXPRESSION _)
    = nothing() ;

@autoName test bool _4e552d91e7b7c59d6e0de4979c82b864() = infer(c1, CHOR_EXPRESSION::err()) == nothing() ;
@autoName test bool _bbdd58ef98e2b31b996269825e3cb4d2() = infer(c1, skip()) == nothing() ;
@autoName test bool _452501888665afae4e987055017c3d53() = infer(c1, CHOR_EXPRESSION::var("f")) == nothing() ;
@autoName test bool _8844bbf723c911e9f6b3fda251e8e078() = infer(c1, asgn("b", app("!=", [var("i"), val(5)]))) == nothing() ;
@autoName test bool _3ed7c910658a753e8f122fa2424cc83f() = infer(c1, comm(app("==", [var("i"), val(5)]), val(<"@alice", 5>), "j", asgn("b", val(false)))) == nothing() ;
@autoName test bool _ac0512a9228777f607d139cc3b571d53() = infer(c1, choice(app("==", [var("i"), val(5)]), skip(), asgn("b", val(false)))) == nothing() ;
@autoName test bool _1b3146bce6563a876bad126daf44e265() = infer(c1, loop(app("==", [var("j"), val(6)]), asgn("b", val(false)))) == nothing() ;
@autoName test bool _5d9ddbe71a3a3a182519a1fbaa2acd02() = infer(c1, at(val(<"@alice", 5>), asgn("b", val(false)))) == just(chor("@alice")) ;
@autoName test bool _7934b6d97ed481782633beeebe48b23d() = infer(c1, seq(asgn("b", val(false)), asgn("b", val(true)))) == nothing() ;

/*
 * Checking
 */

list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = [error("Unexpected name `<p>`", e.src)] when !inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION _: CHOR_EXPRESSION::err())
    = [] when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION _: skip())
    = [] when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: esc(f, args))
    = [error("Expected number of arguments: 0. Actual: <size(args)>", e.fSrc) | [] !:= args]
    when inContext(p, c), f in {"\\load", "\\save"};
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: esc("\\echo", args))
    = [error("Expected number of arguments: 1. Actual: <size(args)>", e.fSrc) | [_] !:= args]
    + [*analyze(context(c.gammas[p]), eData) | [eData] := args]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: esc("\\ping", args))
    = [error("Expected number of arguments: 1. Actual: <size(args)>", e.fSrc) | [_] !:= args]
    + [*check(number(), context(c.gammas[p]), eData) | [eData] := args] 
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: CHOR_EXPRESSION::var(x))
    = [error("Unexpected choreography variable", e.src) | x notin c.deltas[p]]
    + [error("Expected choreography type: `<toStr(t)>`. Actual: `<toStr(c.deltas[p][x])>`.", e.src) | x in c.deltas[p], t != c.deltas[p][x]]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: asgn(xData, eData))
    = [error("Unexpected data variable", e.xDataSrc) | xData notin c.gammas[p]]
    + [error("Expected data type: not `undefined`. Actual: <actual(maybe)>.", eData.src) | maybe := infer(context(c.gammas[p]), eData), just(/undefined()) := maybe]
    + [*check(c.gammas[p][xData], context(c.gammas[p]), eData) | just(/undefined()) !:= infer(context(c.gammas[p]), eData), xData in c.gammas[p]]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: comm(eData1, eData2, xData, e1))
    = [error("Expected data type: any name. Actual: <actual(maybe)>.", eData2.src) | maybe := infer(context(c.gammas[p]), eData2), just(pid(_)) !:= maybe]
    + [error("Unexpected name", eData2.src) | just(pid(q)) := infer(context(c.gammas[p]), eData2), !inContext(q, c)]
    + [error("Unexpected data variable: `<xData>`", e.xDataSrc) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c), xData notin c.gammas[q]]
    + [error("Expected data type: not `undefined`. Actual: <actual(maybe)>.", eData1.src) | maybe := infer(context(c.gammas[p]), eData1), just(/undefined()) := maybe]
    + [*check(c.gammas[q][xData], context(c.gammas[p]), eData1) | just(/undefined()) !:= infer(context(c.gammas[p]), eData1), just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c), xData in c.gammas[q]]
    + [*check(pid(q), context(c.gammas[p]), eData2) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c)]
    + [*check(chor(q), removeUndefinedFrom(c, q, {xData}), e1) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c)]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: choice(eData, e1, e2))
    = check(boolean(), context(c.gammas[p]), eData) + check(t, removeUndefinedFrom(c, p, getDefined(eData)), e1) + check(t, c, e2) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: loop(eData, e1))
    = check(boolean(), context(c.gammas[p]), eData) + check(t, c, e1) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: at(eData, e1))
    = [error("Expected data type: <p>. Actual: <actual(maybe)>.", eData.src) | maybe := infer(context(()), eData), just(pid(p)) !:= maybe]
    + [*check(t, c, e1) | just(pid(p)) := infer(context(()), eData)] ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: seq(e1, e2))
    = check(t, c, e1) + check(t, removeUndefinedFrom(c, p, {xData}), e2) when asgn(xData ,_) := e1 ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: seq(e1, e2))
    = check(t, c, e1) + check(t, c, e2) when asgn(_ ,_) !:= e1 ;

default list[Message] check(CHOR_TYPE t, CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = [error("Expected choreograpy type: `<toStr(t)>`. Actual: <actual(c, e)>.", e.src)] ;

@autoName test bool _99b29139a064808f492eea2834015a52() = check(chor("@alice"), c2, CHOR_EXPRESSION::err()) == [] ;
@autoName test bool _962e53d57a4937b425486ac7220b6f21() = check(chor("@alice"), c2, skip()) == [] ;
@autoName test bool _d8f3d2ca09ff1d772a7da01ddc8b2eb3() = check(chor("@carol"), c2, skip()) != [] ;
@autoName test bool _5e8b75c3c68a7039b83afac5824ab05f() = check(chor("@alice"), c2, esc("\\load", [])) == [] ;
@autoName test bool _a7c1fdc815c631096e237894c3619dfe() = check(chor("@alice"), c2, esc("\\load", [val(5)])) != [] ;
@autoName test bool _67066b09dc1bd21a1f3bd6b144790fec() = check(chor("@alice"), c2, esc("\\save", [])) == [] ;
@autoName test bool _cab174da194388c397bf508c5a9e4d0f() = check(chor("@alice"), c2, esc("\\save", [val(5)])) != [] ;
@autoName test bool _0a19c055995cf36ad5bde9e7547908a1() = check(chor("@alice"), c2, esc("\\echo", [val(5)])) == [] ;
@autoName test bool _44234ec8e442e7dac41801387b78060a() = check(chor("@alice"), c2, esc("\\echo", [val(5), val(6)])) != [] ;
@autoName test bool _2a7f7dd68699e172eee8d85fba06c8ac() = check(chor("@alice"), c2, esc("\\echo", [app("-", [val(5), val(true)])])) != [] ;
@autoName test bool _9f2bd5c63a9b0ee07a096eae0ecbb510() = check(chor("@alice"), c2, esc("\\ping", [val(5)])) == [] ;
@autoName test bool _1710bdcc1f14f0aab10f2d0fd5f04a24() = check(chor("@alice"), c2, esc("\\ping", [val("foo")])) != [] ;
@autoName test bool _5722ef7335e56f62eca85c1e40ccb39e() = check(chor("@alice"), c2, esc("\\ping", [val(5), val(6)])) != [] ;
@autoName test bool _4ed1913a8252f77f81959c6546b96100() = check(chor("@alice"), c2, esc("\\ping", [app("-", [val(5), val(true)])])) != [] ;
@autoName test bool _0203f092fc2795454a0dcb7df167754f() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("f")) == [] ;
@autoName test bool _e35809cf4ede85aac05fe7f13fc77103() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("g")) != [] ;
@autoName test bool _409437fdc8091251a897af424d17d55e() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("h")) != [] ;
@autoName test bool _9343f174bd7c55a94764fcd6b7a13259() = check(chor("@alice"), c2, asgn("i", val(5))) == [] ;
@autoName test bool _c7dd4ed2288ebc124800ce7c07f79baa() = check(chor("@alice"), c2, asgn("i", val(false))) != [] ;
@autoName test bool _fe835e7af17776bb33eb95f65df75619() = check(chor("@alice"), c2, asgn("j", val(5))) != [] ;
@autoName test bool _7f82370534f5e44a9092f1c45afe2bc9() = check(chor("@alice"), c4, asgn("i", val(5))) == [] ;
@autoName test bool _4ce992e42b563e6fdfb3ad71dff674ce() = check(chor("@alice"), c4, asgn("i", val(UNDEFINED))) != [] ;
@autoName test bool _48a8ad926896f7592673b8e533f615cd() = check(chor("@alice"), c4, asgn("i", var("i"))) != [] ;
@autoName test bool _791c62822996212bd8e4e2bdbd561e9e() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "i", skip())) == [] ;
@autoName test bool _ad3719f7181316972c1ab95d956e2e0e() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "j", skip())) != [] ;
@autoName test bool _5238ddd92720a1c7e41165231eb1e029() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "b", skip())) != [] ;
@autoName test bool _46f3b25d7982d271723ea9aefb26d194() = check(chor("@alice"), c2, comm(val(5), val(<"@carol", 0>), "i", skip())) != [] ;
@autoName test bool _e4a7af07618bb66bbf146c1bb378a9d6() = check(chor("@alice"), c2, comm(val(5), asc(val(<"@bob", 0>), pid("@alice")), "i", skip())) != [] ;
@autoName test bool _34597625cdd5605c3659c5d7e5c885eb() = check(chor("@alice"), c2, comm(val(false), val(<"@bob", 0>), "i", skip())) != [] ;
@autoName test bool _2e6086313023f12c0dfb3a9196b8cb6d() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "i", asgn("j", val(5)))) != [] ;
@autoName test bool _ac73ee9b991596489b8b5cc1a8203574() = check(chor("@alice"), c3, comm(val(5), val(<"@bob", 0>), "x", asgn("y", var("x")))) == [] ;
@autoName test bool _4ada56af8701b3bf74d77746f9f016d9() = check(chor("@alice"), c3, comm(val(5), val(<"@bob", 0>), "x", asgn("z", var("x")))) != [] ;
@autoName test bool _ad48f289dc1171c50f22ac16a1570247() = check(chor("@alice"), c3, comm(val(5), val(<"@bob", 0>), "x", asgn("x", val(UNDEFINED)))) != [] ;
@autoName test bool _a13475aa6f1b0d22a01e67deec2d8d2d() = check(chor("@alice"), c3, comm(val(UNDEFINED), val(<"@bob", 0>), "x", asgn("y", var("x")))) != [] ;
@autoName test bool _cfa6390e1a435d1a400da54dd5a6b873() = check(chor("@alice"), c3, comm(val(UNDEFINED), val(<"@bob", 0>), "x", asgn("x", val(5)))) != [] ;
@autoName test bool _ef1136c954830402ce38e4a25299f0a8() = check(chor("@alice"), c4, comm(val(5), val(<"@bob", 0>), "i", skip())) == [] ;
@autoName test bool _bfbd24f933eb362a3dffcd55f7d8bdf7() = check(chor("@alice"), c4, comm(val(UNDEFINED), val(<"@bob", 0>), "i", skip())) != [] ;
@autoName test bool _f3687eb04bf855841cb3f91ffbaea8ea() = check(chor("@alice"), c4, comm(var("i"), val(<"@bob", 0>), "i", skip())) != [] ;
@autoName test bool _7af7c7e404cb2443f663b5dab138cdcb() = check(chor("@alice"), c2, choice(val(false), skip(), skip())) == [] ;
@autoName test bool _ba4b8282de9656efcf3de58af2de0c5a() = check(chor("@alice"), c2, choice(val(false), skip(), asgn("j", val(5)))) != [] ;
@autoName test bool _20f46c6e3892eb2fa95eee9cf777a32c() = check(chor("@alice"), c2, choice(val(false), asgn("j", val(5)), skip())) != [] ;
@autoName test bool _b8e2bc8c5c9bbda35cc7e77154672a2a() = check(chor("@alice"), c2, choice(val(5), skip(), skip())) != [] ;
@autoName test bool _dc413bfe8a3720a846ef05d0e86e3bb7() = check(chor("@alice"), c4, choice(app("!=", [var("i"), val(UNDEFINED)]), asgn("i", app("-", [var("i"), val(1)])), skip())) == [] ;
@autoName test bool _f08e57fa6daeb87a7c57c9b07f838bc0() = check(chor("@alice"), c4, asgn("i", app("-", [var("i"), val(1)]))) != [] ;
@autoName test bool _3999a054ea75c189d01ca28aedafcbf8() = check(chor("@alice"), c2, loop(val(false), skip())) == [] ;
@autoName test bool _4c1aee248c7e212fe3499b18d77146dc() = check(chor("@alice"), c2, loop(val(false), at(val(<"@bob", 0>), skip()))) != [] ;
@autoName test bool _ec0956e5919676a7d608d79a2128e8dc() = check(chor("@alice"), c2, at(val(<"@alice", 5>), skip())) == [] ;
@autoName test bool _4867297179ed60c5b2481d405b38f1c2() = check(chor("@alice"), c2, at(val(<"@alice", 5>), asgn("j", val(5)))) != [] ;
@autoName test bool _4d08b58dc1afc7e30520225a24b316ec() = check(chor("@alice"), c2, at(val(<"@bob", 0>), skip())) != [] ;
@autoName test bool _43719ac33090385401cd615eb1748589() = check(chor("@alice"), c2, seq(asgn("i", val(5)), asgn("i", val(6)))) == [] ;
@autoName test bool _af9220d3189eb79e132e3386eedce5ff() = check(chor("@alice"), c2, seq(asgn("i", val(5)), asgn("j", val(6)))) != [] ;
@autoName test bool _0bc53afec1b6ad0e61a751ec78899528() = check(chor("@alice"), c2, seq(asgn("j", val(5)), asgn("i", val(6)))) != [] ;
@autoName test bool _242a2c5928e6c81942e683251b7936a8() = check(chor("@alice"), c4, seq(asgn("i", val(5)), asgn("j", var("i")))) == [] ;
@autoName test bool _1ba2a3c4a2062a251085cce15ff7d311() = check(chor("@alice"), c4, seq(skip(), asgn("j", var("i")))) != [] ;

private bool inContext(ROLE r, CHOR_CONTEXT _: context(gammas, deltas))
    = r in gammas && r in deltas ;

private str actual(CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = just(t) := infer(c, e) ? "`<toStr(t)>`" : "Failed to infer" ;

private CHOR_CONTEXT removeUndefinedFrom(CHOR_CONTEXT c, ROLE r, set[DATA_VARIABLE] xDatas)
    = c [gammas = c.gammas + (r: c.gammas[r] + (xData: tData | xData <- xDatas, xData in c.gammas[r], union([tData, undefined()]) := c.gammas[r][xData]))] ;
