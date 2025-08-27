module icplt::core::\chor::\semantics::Static

import Message;
import util::Maybe;

import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\data::\semantics::Static;

/*
 * Contexts
 */

data CHOR_CONTEXT = context(
    map[ROLE, map[DATA_VARIABLE, DATA_TYPE]] gammas,
    map[ROLE, map[CHOR_VARIABLE, CHOR_TYPE]] deltas) ;

CHOR_CONTEXT c1 = context((), ()) ;
CHOR_CONTEXT c2 = context(("@alice": ("i": number()), "@bob": ("i": number(), "b": boolean())), ("@alice": ("f": chor("@alice"), "g": chor("@bob")), "@bob": ())) ;

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
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: CHOR_EXPRESSION::var(x))
    = [error("Unexpected choreography variable", e.src) | x notin c.deltas[p]]
    + [error("Expected choreography type: `<toStr(t)>`. Actual: `<toStr(c.deltas[p][x])>`.", e.src) | x in c.deltas[p], t != c.deltas[p][x]]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: asgn(xData, eData))
    = [error("Unexpected data variable", e.xDataSrc) | xData notin c.gammas[p]]
    + [*check(c.gammas[p][xData], context(c.gammas[p]), eData) | xData in c.gammas[p]]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE _: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: comm(eData1, eData2, xData, e1))
    = [error("Expected data type: any name. Actual: <actual(maybe)>.", eData2.src) | maybe := infer(context(c.gammas[p]), eData2), just(pid(_)) !:= maybe]
    + [error("Unexpected name", eData2.src) | just(pid(q)) := infer(context(c.gammas[p]), eData2), !inContext(q, c)]
    + [error("Unexpected data variable: `<xData>`", e.xDataSrc) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c), xData notin c.gammas[q]]
    + [*check(tAny, context(c.gammas[p]), eData1) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c), xData in c.gammas[q], tAny := c.gammas[q][xData]]
    + [*check(pid(q), context(c.gammas[p]), eData2) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c)]
    + [*check(chor(q), c, e1) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c)]
    when inContext(p, c) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: choice(eData, e1, e2))
    = check(boolean(), context(c.gammas[p]), eData) + check(t, c, e1) + check(t, c, e2) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: loop(eData, e1))
    = check(boolean(), context(c.gammas[p]), eData) + check(t, c, e1) ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: at(eData, e1))
    = [error("Expected data type: <p>. Actual: <actual(maybe)>.", eData.src) | maybe := infer(context(()), eData), just(pid(p)) !:= maybe]
    + [*check(t, c, e1) | just(pid(p)) := infer(context(()), eData)] ;
list[Message] check(CHOR_TYPE t: chor(p), CHOR_CONTEXT c, CHOR_EXPRESSION e: seq(e1, e2))
    = check(t, c, e1) + check(t, c, e2) ;

default list[Message] check(CHOR_TYPE t, CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = [error("Expected choreograpy type: `<toStr(t)>`. Actual: <actual(c, e)>.", e.src)] ;

@autoName test bool _d8f3d2ca09ff1d772a7da01ddc8b2eb3() = check(chor("@carol"), c2, skip()) != [] ;
@autoName test bool _99b29139a064808f492eea2834015a52() = check(chor("@alice"), c2, CHOR_EXPRESSION::err()) == [] ;
@autoName test bool _962e53d57a4937b425486ac7220b6f21() = check(chor("@alice"), c2, skip()) == [] ;
@autoName test bool _0203f092fc2795454a0dcb7df167754f() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("f")) == [] ;
@autoName test bool _e35809cf4ede85aac05fe7f13fc77103() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("g")) != [] ;
@autoName test bool _409437fdc8091251a897af424d17d55e() = check(chor("@alice"), c2, CHOR_EXPRESSION::var("h")) != [] ;
@autoName test bool _9343f174bd7c55a94764fcd6b7a13259() = check(chor("@alice"), c2, asgn("i", val(5))) == [] ;
@autoName test bool _c7dd4ed2288ebc124800ce7c07f79baa() = check(chor("@alice"), c2, asgn("i", val(false))) != [] ;
@autoName test bool _fe835e7af17776bb33eb95f65df75619() = check(chor("@alice"), c2, asgn("j", val(5))) != [] ;
@autoName test bool _791c62822996212bd8e4e2bdbd561e9e() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "i", skip())) == [] ;
@autoName test bool _2e6086313023f12c0dfb3a9196b8cb6d() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "i", asgn("j", val(5)))) != [] ;
@autoName test bool _ad3719f7181316972c1ab95d956e2e0e() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "j", skip())) != [] ;
@autoName test bool _5238ddd92720a1c7e41165231eb1e029() = check(chor("@alice"), c2, comm(val(5), val(<"@bob", 0>), "b", skip())) != [] ;
@autoName test bool _46f3b25d7982d271723ea9aefb26d194() = check(chor("@alice"), c2, comm(val(5), val(<"@carol", 0>), "i", skip())) != [] ;
@autoName test bool _e4a7af07618bb66bbf146c1bb378a9d6() = check(chor("@alice"), c2, comm(val(5), asc(val(<"@bob", 0>), pid("@alice")), "i", skip())) != [] ;
@autoName test bool _34597625cdd5605c3659c5d7e5c885eb() = check(chor("@alice"), c2, comm(val(false), val(<"@bob", 0>), "i", skip())) != [] ;
@autoName test bool _7af7c7e404cb2443f663b5dab138cdcb() = check(chor("@alice"), c2, choice(val(false), skip(), skip())) == [] ;
@autoName test bool _ba4b8282de9656efcf3de58af2de0c5a() = check(chor("@alice"), c2, choice(val(false), skip(), asgn("j", val(5)))) != [] ;
@autoName test bool _20f46c6e3892eb2fa95eee9cf777a32c() = check(chor("@alice"), c2, choice(val(false), asgn("j", val(5)), skip())) != [] ;
@autoName test bool _b8e2bc8c5c9bbda35cc7e77154672a2a() = check(chor("@alice"), c2, choice(val(5), skip(), skip())) != [] ;
@autoName test bool _3999a054ea75c189d01ca28aedafcbf8() = check(chor("@alice"), c2, loop(val(false), skip())) == [] ;
@autoName test bool _4c1aee248c7e212fe3499b18d77146dc() = check(chor("@alice"), c2, loop(val(false), at(val(<"@bob", 0>), skip()))) != [] ;
@autoName test bool _ec0956e5919676a7d608d79a2128e8dc() = check(chor("@alice"), c2, at(val(<"@alice", 5>), skip())) == [] ;
@autoName test bool _4867297179ed60c5b2481d405b38f1c2() = check(chor("@alice"), c2, at(val(<"@alice", 5>), asgn("j", val(5)))) != [] ;
@autoName test bool _4d08b58dc1afc7e30520225a24b316ec() = check(chor("@alice"), c2, at(val(<"@bob", 0>), skip())) != [] ;
@autoName test bool _43719ac33090385401cd615eb1748589() = check(chor("@alice"), c2, seq(asgn("i", val(5)), asgn("i", val(6)))) == [] ;
@autoName test bool _af9220d3189eb79e132e3386eedce5ff() = check(chor("@alice"), c2, seq(asgn("i", val(5)), asgn("j", val(6)))) != [] ;
@autoName test bool _0bc53afec1b6ad0e61a751ec78899528() = check(chor("@alice"), c2, seq(asgn("j", val(5)), asgn("i", val(6)))) != [] ;

private bool inContext(ROLE r, CHOR_CONTEXT _: context(gammas, deltas))
    = r in gammas && r in deltas ;

private str actual(CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = just(t) := infer(c, e) ? "`<toStr(t)>`" : "Failed to infer" ;
