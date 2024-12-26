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
CHOR_CONTEXT c2 = context(("Alice": ("i": number()), "Bob": ("i": number(), "b": boolean())), ("Alice": ("f": chor("Alice"), "g": chor("Bob")), "Bob": ())) ;

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
@autoName test bool _5cf8f1c32dfbfbfbebe6019b2fcd4e39() = infer(c1, comm(app("==", [var("i"), val(5)]), val(<"Alice", 5>), "j", asgn("b", val(false)))) == nothing() ;
@autoName test bool _ac0512a9228777f607d139cc3b571d53() = infer(c1, choice(app("==", [var("i"), val(5)]), skip(), asgn("b", val(false)))) == nothing() ;
@autoName test bool _1b3146bce6563a876bad126daf44e265() = infer(c1, loop(app("==", [var("j"), val(6)]), asgn("b", val(false)))) == nothing() ;
@autoName test bool _433b70f0cf4424b1d5abdacdbaee7c98() = infer(c1, at(val(<"Alice", 5>), asgn("b", val(false)))) == just(chor("Alice")) ;
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
    + [error("Unexpected data variable: <xData>", e.xDataSrc) | just(pid(q)) := infer(context(c.gammas[p]), eData2), inContext(q, c), xData notin c.gammas[q]]
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

@autoName test bool _2ae7405b76446862a1ee892dfe12ed51() = check(chor("Carol"), c2, skip()) != [] ;
@autoName test bool _836cd9367b8d0f1a4b2ea6d860e8c016() = check(chor("Alice"), c2, CHOR_EXPRESSION::err()) == [] ;
@autoName test bool _381541a9ed4cc6c8e675baeff4961f09() = check(chor("Alice"), c2, skip()) == [] ;
@autoName test bool _32596d8b1082e4e59563d59ff190aa3c() = check(chor("Alice"), c2, CHOR_EXPRESSION::var("f")) == [] ;
@autoName test bool _abe771815fee480c6ffd4d945d3d7c53() = check(chor("Alice"), c2, CHOR_EXPRESSION::var("g")) != [] ;
@autoName test bool _2615d3ce15753d272df59abcb0e7d01d() = check(chor("Alice"), c2, CHOR_EXPRESSION::var("h")) != [] ;
@autoName test bool _cbbce78d5995573c0990bdd71afa4145() = check(chor("Alice"), c2, asgn("i", val(5))) == [] ;
@autoName test bool _87f3916bc915cb842e65f7fde7161da3() = check(chor("Alice"), c2, asgn("i", val(false))) != [] ;
@autoName test bool _0fbfa150700e9bc5980456ba63e6017c() = check(chor("Alice"), c2, asgn("j", val(5))) != [] ;
@autoName test bool _47bc74b3d138fa99ec2208e8bf0af34e() = check(chor("Alice"), c2, comm(val(5), val(<"Bob", 0>), "i", skip())) == [] ;
@autoName test bool _7df335f7c9b7717dfb70b5996e90a5fe() = check(chor("Alice"), c2, comm(val(5), val(<"Bob", 0>), "i", asgn("j", val(5)))) != [] ;
@autoName test bool _33151caf461bdc7b99c659fc2a89daa3() = check(chor("Alice"), c2, comm(val(5), val(<"Bob", 0>), "j", skip())) != [] ;
@autoName test bool _ecd10e0dab0aaf9bbc5d8357df5173f9() = check(chor("Alice"), c2, comm(val(5), val(<"Bob", 0>), "b", skip())) != [] ;
@autoName test bool _8d7477139ab8ac5b475079c2c691b7a8() = check(chor("Alice"), c2, comm(val(5), val(<"Carol", 0>), "i", skip())) != [] ;
@autoName test bool _28e764a5fab3b6060deac576980bf0a8() = check(chor("Alice"), c2, comm(val(5), asc(val(<"Bob", 0>), pid("Alice")), "i", skip())) != [] ;
@autoName test bool _9f2352aca76aed8a2c1dad9063996ace() = check(chor("Alice"), c2, comm(val(false), val(<"Bob", 0>), "i", skip())) != [] ;
@autoName test bool _215075c750b840bf9aaf2a7d0079107a() = check(chor("Alice"), c2, choice(val(false), skip(), skip())) == [] ;
@autoName test bool _9a55ed675226be0fc9fedf7a85ca0005() = check(chor("Alice"), c2, choice(val(false), skip(), asgn("j", val(5)))) != [] ;
@autoName test bool _5101d966322a8ba6d1a0d353e4fc4a8b() = check(chor("Alice"), c2, choice(val(false), asgn("j", val(5)), skip())) != [] ;
@autoName test bool _863c85e4a6c0b73f16edd9999e96ce90() = check(chor("Alice"), c2, choice(val(5), skip(), skip())) != [] ;
@autoName test bool _39614328beecbd5ed248d976d6b5ff8b() = check(chor("Alice"), c2, loop(val(false), skip())) == [] ;
@autoName test bool _49e35f3e49acb7eeda4e63fc22932385() = check(chor("Alice"), c2, loop(val(false), at(val(<"Bob", 0>), skip()))) != [] ;
@autoName test bool _0d97b1c644c640a835525c3c5eb55d57() = check(chor("Alice"), c2, at(val(<"Alice", 5>), skip())) == [] ;
@autoName test bool _115ba364fd1f1b864499e2b30c44722c() = check(chor("Alice"), c2, at(val(<"Alice", 5>), asgn("j", val(5)))) != [] ;
@autoName test bool _ed0af1a8b12955800b28033e77a86caa() = check(chor("Alice"), c2, at(val(<"Bob", 0>), skip())) != [] ;
@autoName test bool _af39ba72b93cf0ed13b8a81567b0b3ec() = check(chor("Alice"), c2, seq(asgn("i", val(5)), asgn("i", val(6)))) == [] ;
@autoName test bool _7e40732f8e52f897dec842fc06cf842d() = check(chor("Alice"), c2, seq(asgn("i", val(5)), asgn("j", val(6)))) != [] ;
@autoName test bool _e778077b43365e447d914d727a6ae6f1() = check(chor("Alice"), c2, seq(asgn("j", val(5)), asgn("i", val(6)))) != [] ;

private bool inContext(ROLE r, CHOR_CONTEXT _: context(gammas, deltas))
    = r in gammas && r in deltas ;

private str actual(CHOR_CONTEXT c, CHOR_EXPRESSION e)
    = just(t) := infer(c, e) ? "`<toStr(t)>`" : "Failed to infer" ;
