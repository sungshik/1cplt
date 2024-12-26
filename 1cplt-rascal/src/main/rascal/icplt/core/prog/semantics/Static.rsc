module icplt::core::\prog::\semantics::Static

import List;
import Message;
import util::Maybe;

import icplt::core::\chor::\semantics::Static;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\data::\semantics::Static;
import icplt::core::\data::\syntax::Abstract;
import icplt::core::\prog::\syntax::Abstract;

/*
 * Contexts
 */

data PROG_CONTEXT = context(
    map[ROLE, map[DATA_VARIABLE, DATA_TYPE]] gammas,
    map[ROLE, map[CHOR_VARIABLE, CHOR_TYPE]] deltas) ;

PROG_CONTEXT toProgContext(PROG_EXPRESSION e) {
    map[ROLE, map[DATA_VARIABLE, DATA_TYPE]] gammas
        = (r: (xData: tData | formal(xData, tData) <- formals) + ("self": pid(r)) | /glob(r, formals, _) := e) ;
    map[ROLE, map[CHOR_VARIABLE, CHOR_TYPE]] deltas
        = (r: (xChor: chor(r) | proced(xChor, _) <- proceds) | /glob(r, _, proceds) := e) ;

    /* -----------------------------------------------------------------------*/
    /*                               `foreach`                                */
    /* ---------------------------------------------------------------------- */

    map[DATA_VARIABLE, DATA_TYPE] gammaForeach = ();
    for (/glob(_, _, proceds) := e, /proced(_, eChor) := proceds) {
        gammaForeach += toGammaForeach(eChor);
    }
    gammas = (r: gammas[r] + gammaForeach | r <- gammas);

    return context(gammas, deltas);
}

/*
 * Analysis
 */

list[Message] analyze(PROG_EXPRESSION e)
    = analyze(toProgContext(e), e) ;

list[Message] analyze(PROG_CONTEXT c, PROG_EXPRESSION e) {
    list[Message] messages = [];

    // Check closedness
    messages += [info("Uninstantiated name", eData.src) | /eData: val(rk: <_, k>) := e, /proc(rk, _, _) !:= e, 0 <= k];

    // Check well-formedness
    set[PARAMETER] duplicateFormals = {formal1 | /glob(_, formals, _) := e, /formal1: formal(xData, _) := formals, /formal2: formal(xData, _) := formals, formal1 != formal2};
    set[PROCEDURE] duplicateProceds = {proced1 | /glob(_, _, proceds) := e, /proced1: proced(xChor, _) := proceds, /proced2: proced(xChor, _) := proceds, proced1 != proced2};
    set[PROG_EXPRESSION] duplicateGlobs = {glob1 | /glob1: glob(r,  _, _) := e, /glob2: glob(r,  _, _) := e, glob1 != glob2};
    set[PROG_EXPRESSION] duplicateProcs = {proc1 | /proc1: proc(rk, _, _) := e, /proc2: proc(rk, _, _) := e, proc1 != proc2};

    messages += [warning("Duplicate name", formal.xDataSrc) | formal <- duplicateFormals];
    messages += [warning("Duplicate name", proced.xChorSrc) | proced <- duplicateProceds];
    messages += [warning("Duplicate name", glob.rSrc)  | glob <- duplicateGlobs];
    messages += [warning("Duplicate name", proc.rkSrc) | proc <- duplicateProcs];

    // Check well-typedness of globals
    c = toProgContext(e);
    CHOR_CONTEXT cChor = CHOR_CONTEXT::context(c.gammas, c.deltas);
    messages += [*check(chor(r), cChor, eChor)| /glob(r, _, [*_, proced(_, eChor), *_]) := e];

    // Check well-typedness of processes
    for (/proc: proc(<r, _>, actuals, eChor) := e) {;
        messages += [error("Unexpected name", proc.rkSrc) | /glob(r, _, _) !:= e];
        messages += [error("Expected number of actual parameters: <size(formals)>. Actual: <size(actuals)>.", proc.rkSrc) | /glob(r, formals, _) := e, size(formals) != size(actuals)];
        messages += [*check(tData, context(("self": pid(r))), eData) | /glob(r, formals, _) := e, size(formals) == size(actuals), <formal(_, tData), actual(eData)> <- zip2(formals, actuals)];
        messages += [*check(chor(r), cChor, eChor) | /glob(r, _, _) := e];
    }

    return messages;
}

@autoName test bool _79639dd88e86771e156f47b20f22b907() = ret := analyze(glob("Alice", [], [])) && [] := ret ;
@autoName test bool _674d30e28982819886fb10af338b5791() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [] := ret ;
@autoName test bool _8c22d53f61358426377f0891b4643bfd() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("skip", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _] := ret ;
@autoName test bool _ad64f9910f6fe7840ec9a0da19489094() = ret := analyze(glob("Alice", [formal("b", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _] := ret ;
@autoName test bool _5132e9a6c35218923884dc7c2ee1e079() = ret := analyze(glob("Alice", [formal("b", number()), formal("b", boolean())], [proced("skip", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _, _, _] := ret ;
@autoName test bool _e9c02023fde3ed53d63beee34fd88e25() = ret := analyze(seq(glob("Alice", [], []), glob("Bob", [], []))) && [] := ret ;
@autoName test bool _877d047b8e2cdd4b7891756a7bb9d229() = ret := analyze(seq(glob("Alice", [], [], src = |unknown://foo|), glob("Alice", [], [], src = |unknown://bar|))) && [_, _] := ret ;
@autoName test bool _a99a2b85ba66c8055f7557d740980ac7() = ret := analyze(seq(seq(glob("Alice", [], []), glob("Bob", [], [])), seq(proc(<"Alice", 5>, [], skip()), proc(<"Bob", 0>, [], skip())))) && [] := ret ;
@autoName test bool _4bb530d594fba8d0d0bb4f40a95348c5() = ret := analyze(seq(seq(glob("Alice", [], []), glob("Bob", [], [])), seq(proc(<"Alice", 5>, [], skip(), src = |unknown://foo|), proc(<"Alice", 5>, [], skip(), src = |unknown://bar|)))) && [_, _] := ret ;
@autoName test bool _94b373a5c180038b6ef625bcc3d09218() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("i", val(5)))])) && [] := ret ;
@autoName test bool _176ef47a564389cc2c1e903f64153053() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("i", val(true)))])) && [_] := ret ;
@autoName test bool _8672c8b728cf604b94cf8ef8d057240b() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("assign", asgn("i", val(5)))])) && [_] := ret ;
@autoName test bool _2e10c3247e5da905322d50a9ec44b704() = ret := analyze(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("assign", asgn("i", val(true)))])) && [_, _] := ret ;
@autoName test bool _222c43774e9baa0abf5b5ecae8b34d7e() = ret := analyze(seq(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"Alice", 5>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("assign")))) && [] := ret ;
@autoName test bool _c6312bbfbbbcde465db3ab3ec76584da() = ret := analyze(seq(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"Alice", 5>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("main")))) && [_] := ret ;
@autoName test bool _4824cd7bcd374947495bc686c62d9846() = ret := analyze(seq(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"Alice", 5>, [actual(val(6)), actual(val(7))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _a5a81141171f4a7da2e72e9edb3a2011() = ret := analyze(seq(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"Alice", 5>, [actual(val(6))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _1eaa03805a020d0a99b6631d22959a13() = ret := analyze(seq(glob("Alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"Bob", 0>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _25bee6939d2bc64165859fb08c728aae() = ret := analyze(seq(glob("Alice", [formal("self", pid("Alice"))], [proced("main", asgn("self", val(<"Alice", 5>)))]), proc(<"Alice", 5>, [actual(val(<"Alice", 5>))], skip()))) && [] := ret ;
@autoName test bool _276bfb3d1a6d711edb28395253385ad7() = ret := analyze(seq(glob("Alice", [formal("self", pid("Alice"))], [proced("main", asgn("self", val(<"Alice", 5>)))]), proc(<"Alice", 5>, [actual(val(<"Alice", 6>))], skip()))) && [_] := ret ;
@autoName test bool _121964678ab40ba6b64cc0233ebb2d3d() = ret := analyze(seq(glob("Alice", [formal("self", pid("Alice"))], [proced("main", asgn("self", val(<"Alice", 5>)))]), proc(<"Alice", 6>, [actual(val(<"Alice", 5>))], skip()))) && [_, _] := ret ;
@autoName test bool _0dcc6637fe40fc28c52d2ec12cb7c63c() = ret := analyze(seq(glob("Alice", [formal("self", pid("Alice"))], [proced("main", asgn("self", val(<"Alice", 6>)))]), proc(<"Alice", 5>, [actual(val(<"Alice", 5>))], skip()))) && [_] := ret ;
