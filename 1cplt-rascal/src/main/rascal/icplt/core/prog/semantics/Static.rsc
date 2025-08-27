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

@autoName test bool _b8e7d763da5a5bb7d3a7024aa1118762() = ret := analyze(glob("@alice", [], [])) && [] := ret ;
@autoName test bool _2a455820499065584e433e1de26eb7f4() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [] := ret ;
@autoName test bool _b5f7389f1579263a78901dc5bb4f878e() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("skip", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _] := ret ;
@autoName test bool _e03a6cd7b1deed9efae098409b9d6c7f() = ret := analyze(glob("@alice", [formal("b", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _] := ret ;
@autoName test bool _90222c8f2a4e69a10a51e3fc4440dc66() = ret := analyze(glob("@alice", [formal("b", number()), formal("b", boolean())], [proced("skip", CHOR_EXPRESSION::var("skip")), proced("skip", skip())])) && [_, _, _, _] := ret ;
@autoName test bool _86e647a1bc534451dbddd50fdb351e66() = ret := analyze(seq(glob("@alice", [], []), glob("@bob", [], []))) && [] := ret ;
@autoName test bool _63f82b66733898b6632cf48dd4603653() = ret := analyze(seq(glob("@alice", [], [], src = |unknown://foo|), glob("@alice", [], [], src = |unknown://bar|))) && [_, _] := ret ;
@autoName test bool _7c60c39669a759236a5f3aee371465d6() = ret := analyze(seq(seq(glob("@alice", [], []), glob("@bob", [], [])), seq(proc(<"@alice", 5>, [], skip()), proc(<"@bob", 0>, [], skip())))) && [] := ret ;
@autoName test bool _0d6314da1a610febea22bfd349b49f9b() = ret := analyze(seq(seq(glob("@alice", [], []), glob("@bob", [], [])), seq(proc(<"@alice", 5>, [], skip(), src = |unknown://foo|), proc(<"@alice", 5>, [], skip(), src = |unknown://bar|)))) && [_, _] := ret ;
@autoName test bool _88e0c6da3edfc2f90c7928c17ea3d2d1() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("i", val(5)))])) && [] := ret ;
@autoName test bool _ca1881991c2c706bddcd390fac84453b() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("i", val(true)))])) && [_] := ret ;
@autoName test bool _84c54a34bffd939156c8187925fcfabf() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("assign", asgn("i", val(5)))])) && [_] := ret ;
@autoName test bool _91189e6e1729bb3ea24b63f3bb1acf3d() = ret := analyze(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("main", CHOR_EXPRESSION::var("skip")), proced("assign", asgn("i", val(true)))])) && [_, _] := ret ;
@autoName test bool _2f346a85424e2f5ee92bbca8131b9e52() = ret := analyze(seq(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"@alice", 5>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("assign")))) && [] := ret ;
@autoName test bool _49c3d76d7cf524c7d9115c14ddbdbdb1() = ret := analyze(seq(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"@alice", 5>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("main")))) && [_] := ret ;
@autoName test bool _b9f4a496ef484b55f81145e4182e831f() = ret := analyze(seq(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"@alice", 5>, [actual(val(6)), actual(val(7))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _98fbecd9695dc8b5b5fd3c6146081573() = ret := analyze(seq(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"@alice", 5>, [actual(val(6))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _e36d1423c26b576d40055ef4f640b5c3() = ret := analyze(seq(glob("@alice", [formal("i", number()), formal("b", boolean())], [proced("assign", asgn("i", val(5)))]), proc(<"@bob", 0>, [actual(val(6)), actual(val(false))], CHOR_EXPRESSION::var("assign")))) && [_] := ret ;
@autoName test bool _548a81faf50c54f4a35d77cfb0917664() = ret := analyze(seq(glob("@alice", [formal("self", pid("@alice"))], [proced("main", asgn("self", val(<"@alice", 5>)))]), proc(<"@alice", 5>, [actual(val(<"@alice", 5>))], skip()))) && [] := ret ;
@autoName test bool _f75cc5f564c055e359ecbf3ba324da0c() = ret := analyze(seq(glob("@alice", [formal("self", pid("@alice"))], [proced("main", asgn("self", val(<"@alice", 5>)))]), proc(<"@alice", 5>, [actual(val(<"@alice", 6>))], skip()))) && [_] := ret ;
@autoName test bool _21ec2e56aa1370f0dea92cc38bf7bb00() = ret := analyze(seq(glob("@alice", [formal("self", pid("@alice"))], [proced("main", asgn("self", val(<"@alice", 5>)))]), proc(<"@alice", 6>, [actual(val(<"@alice", 5>))], skip()))) && [_, _] := ret ;
@autoName test bool _b40e2ce968fee750ffb6c3c064d9daa4() = ret := analyze(seq(glob("@alice", [formal("self", pid("@alice"))], [proced("main", asgn("self", val(<"@alice", 6>)))]), proc(<"@alice", 5>, [actual(val(<"@alice", 5>))], skip()))) && [_] := ret ;
