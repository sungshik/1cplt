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
        = (r: (xData: tData | formal(xData, tData, _) <- formals) + ("self": pid(r)) | /glob(r, formals, _) := e) ;
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
    messages += [info("Unexpected pid", eData.src) | /eData: val(rk: <_, k>) := e, /proc(rk, _, _) !:= e, 0 <= k];

    // Check well-formedness
    set[PROG_EXPRESSION] duplicateGlobs = {dup | /seq(/dup: glob(r, _, _), /glob(r, _, _)) := e};
    set[PROG_EXPRESSION] duplicateProcs = {dup | /seq(/dup: proc(rk, _, _), /proc(rk, _, _)) := e};
    set[PROCEDURE] duplicateProceds = {dup | /glob(_, _, [*_, dup: proced(xChor, _), *_, proced(xChor, _), *_]) := e};
    set[PARAMETER] duplicateFormals = {dup | /glob(_, [*_, dup: formal(xData, _, _), *_, formal(xData, _, _), *_], _) := e};
    set[PARAMETER] duplicateActuals = {dup | /proc(_, [*_, dup: actual(xData, _), *_, actual(xData, _), *_], _) := e};

    messages += [warning("Unexpected role", glob.rSrc)  | glob <- duplicateGlobs];
    messages += [warning("Unexpected process", proc.rkSrc) | proc <- duplicateProcs];
    messages += [warning("Unexpected procedure", proced.xChorSrc) | proced <- duplicateProceds];
    messages += [warning("Unexpected parameter", formal.xDataSrc) | formal <- duplicateFormals];
    messages += [warning("Unexpected parameter", actual.xDataSrc) | actual <- duplicateActuals];

    set[PROG_EXPRESSION] excessiveProcs = {exc | /g: glob(r, _, _) := e, g.cardinality == "1", /seq(/exc: proc(<r, _>, _, _), /proc(<r, _>, _, _)) := e};
    messages += [warning("Unexpected process (single instance role)", proc.rkSrc) | proc <- excessiveProcs - duplicateProcs];

    // Check well-typedness of roles
    c = toProgContext(e);
    CHOR_CONTEXT cChor = CHOR_CONTEXT::context(c.gammas, c.deltas);
    messages += [*check(tData, context(("self": pid(r))), eData) | /glob(r, [*_, formal(_, tData, just(eData)), *_], _) := e];
    messages += [*check(chor(r), cChor, eChor)| /glob(r, _, [*_, proced(_, eChor), *_]) := e];

    // Check well-typedness of processes
    for (/proc: proc(<r, _>, actuals, eChor) := e) {
        if (/glob(r, formals, _) := e) {;
            messages += [error("Unexpected parameter", a.xDataSrc) | /a: actual(xData, _) := actuals, /formal(xData, _, _) !:= formals];
            messages += [error("Expected parameter: `<xData>`", proc.rkSrc) | /formal(xData, _, nothing()) := formals, /actual(xData, _) !:= actuals];
            messages += [*check(tData, context(("self": pid(r))), eData) | /formal(xData, tData, _) := formals, /actual(xData, just(eData)) := actuals];
            messages += [*check(chor(r), cChor, eChor)];
        } else {
            messages += [error("Unexpected role", proc.rkSrc)];
        }
    }

    return messages;
}

@autoName test bool _b8e7d763da5a5bb7d3a7024aa1118762() = ret := analyze(glob("@alice", [], [])) && [] := ret ;
@autoName test bool _6abbd534b41e09f07bc0e3e0197a957f() = ret := analyze(glob("@alice", [formal("i", number(), just(val(5)))], [proced("main", comm(val(6), val(<"@alice", 0>), "i", skip()))])) && [_] := ret ;
@autoName test bool _5efe0ba0aa9e0fe8f3fa38ed38d35c2d() = ret := analyze(seq(glob("@alice", [], []), proc(<"@alice", 5>, [], skip()))) && [] := ret ;
@autoName test bool _7c56d024d977dc0c681ffcacafbd0108() = ret := analyze(seq(glob("@alice", [], []), glob("@alice", [], []))) && [_] := ret ;
@autoName test bool _5a04ac6def6d4f081e22545e49795b17() = ret := analyze(seq(glob("@alice", [], []), seq(proc(<"@alice", 5>, [], skip()), proc(<"@alice", 5>, [], skip())))) && [_] := ret ;
@autoName test bool _5d771dd9d14d752c9147400ed98d8796() = ret := analyze(glob("@alice", [], [proced("skip", skip())])) && [] := ret ;
@autoName test bool _8e612125be79ac69fee312d0f915fa94() = ret := analyze(glob("@alice", [], [proced("skip", skip()), proced("skip", skip())])) && [_] := ret ;
@autoName test bool _da4dfe5754a49ca089632ace92f416c4() = ret := analyze(glob("@alice", [formal("i", number(), nothing())], [])) && [] := ret ;
@autoName test bool _a548c231366652aaf99407c4ea98c702() = ret := analyze(glob("@alice", [formal("i", number(), nothing()), formal("i", boolean(), nothing())], [])) && [_] := ret ;
@autoName test bool _c5e341b399c56590dd7de1823158b9d4() = ret := analyze(seq(glob("@alice", [formal("i", number(), nothing())], []), proc(<"@alice", 5>, [actual("i", just(val(5)))], skip()))) && [] := ret ;
@autoName test bool _d82ec25b7d1b8bb835a5f8f7a6cc9adf() = ret := analyze(seq(glob("@alice", [formal("i", number(), nothing())], []), proc(<"@alice", 5>, [actual("i", just(val(5))), actual("i", just(val(6)))], skip()))) && [_] := ret ;
@autoName test bool _444d4a5e40d1a252d5577f469d99b8a0() = ret := analyze(seq(glob("@alice", [], []), proc(<"@alice", 5>, [actual("i", just(val(5)))], skip()))) && [_] := ret ;
@autoName test bool _c8bb5880106e3f933fa0daee168d4660() = ret := analyze(seq(glob("@alice", [formal("i", number(), just(val(5)))], []), proc(<"@alice", 5>, [], skip()))) && [] := ret ;
@autoName test bool _3068e68b8715dcbd136cb1796e43676b() = ret := analyze(seq(glob("@alice", [formal("i", number(), nothing())], []), proc(<"@alice", 5>, [], skip()))) && [_] := ret ;
@autoName test bool _c90632146b421f953ff22a660df74c07() = ret := analyze(seq(glob("@alice", [formal("i", number(), nothing())], []), proc(<"@alice", 5>, [actual("i", just(val(true)))], skip()))) && [_] := ret ;
@autoName test bool _ce1f2375b783aecd1c00b53175f90c23() = ret := analyze(seq(glob("@alice", [formal("i", number(), just(val(5)))], []), proc(<"@alice", 5>, [], asgn("i", val(true))))) && [_] := ret ;
@autoName test bool _c1370a139a258f0c719542317ed288b1() = ret := analyze(seq(glob("@alice", [], []), proc(<"@bob", 5>, [], skip()))) && [_] := ret ;
