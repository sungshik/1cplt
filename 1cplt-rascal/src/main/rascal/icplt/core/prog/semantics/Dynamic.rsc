module icplt::core::\prog::\semantics::Dynamic

import List;
import Message;
import util::Maybe;

import icplt::core::\chor::\semantics::Dynamic;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\data::\semantics::Dynamic;
import icplt::core::\data::\syntax::Abstract;
import icplt::core::\prog::\syntax::Abstract;

/*
 * Contexts
 */

data PROG_STATE = state(set[map[PID, tuple[CHOR_STATE, CHOR_EXPRESSION]]] alts) ;

PROG_STATE toProgState(PROG_EXPRESSION e) {
    map[PID, map[DATA_VARIABLE, DATA_EXPRESSION]] phis
        = (rk: (xData: normalize(<state(()), eData>)<1> | <formal(xData, _), actual(eData)> <- zip2(formals, actuals)) + ("self": val(rk)) | /proc(PID rk: <r, _>, actuals, _) := e, /glob(r, formals, _) := e) ;
    map[PID, map[CHOR_VARIABLE, CHOR_EXPRESSION]] psis
        = (rk: (xChor: eChor | proced(xChor, eChor) <- proceds) | /proc(PID rk: <r, _>, _, _) := e, /glob(r, _, proceds) := e) ;

    map[PID, tuple[CHOR_STATE, CHOR_EXPRESSION]] alt
        = (rk: <state(phis[rk], psis[rk], {}), eChor> | rk <- phis, rk in psis, /proc(rk, _, eChor) := e);

    return state({alt});
}

/*
 * Normalization
 */

tuple[PROG_STATE, PROG_EXPRESSION] normalize(tuple[PROG_STATE, PROG_EXPRESSION] se) {
    return solve (se) {
        se = reduce(se);
    }
}

@autoName test bool _b9971b6db6d8fb2642eb7408bef44c0e() = normalize(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _a198d17ec54ce199e291418b165ad8ec() = normalize(<state({(<"@alice", 5>: <state((), (), {}), comm(val(false), val(<"@bob", 0>), "b", skip())>, <"@bob", 0>: <state(("b": val(true)), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;

/*
 * Reduction
 */

tuple[PROG_STATE, PROG_EXPRESSION] reduce(<PROG_STATE s, PROG_EXPRESSION e>) {
    set[map[PID, tuple[CHOR_STATE, CHOR_EXPRESSION]]] alts = {};

    alts += {alt + (rk: rkTarget) | alt <- s.alts, rk <- alt,
                                    rkSource := alt[rk],
                                    rkTarget := reduce(rkSource),
                                    rkSource != rkTarget,
                                    {} := getChi(rkTarget)};

    alts += {alt + (pi: setChi(piTarget, {}), qj: qjTarget) | alt <- s.alts, pi <- alt,
                                                              piSource := alt[pi],
                                                              piTarget := reduce(piSource),
                                                              {<qj, _>} := getChi(piTarget),
                                                              pi != qj,
                                                              qjSource := alt[qj],
                                                              qjTarget := reduce(setChi(qjSource, getChi(piTarget))),
                                                              {} := getChi(qjTarget)};

    alts += {alt + (pi: piTarget2) | alt <- s.alts, pi <- alt,
                                     piSource1 := alt[pi],
                                     piTarget1 := reduce(piSource1),
                                     {<pi, _>} := getChi(piTarget1),
                                     piSource2 := piTarget1,
                                     piTarget2 := reduce(setChi(piSource2, getChi(piTarget1))),
                                     {} := getChi(piTarget2)};

    return <{} == alts ? s : state(alts), e>;
}

@autoName test bool _f340c51abce25420d9d39923df77e7fc() = reduce(<state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state((), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state((), (), {}), skip()>)}), empty()> ;
@autoName test bool _5b5dede4fb25806e73b36e33412c94ee() = reduce(<state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _008846099754815b753891ba4284d30c() = reduce(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>), (<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()> ;
@autoName test bool _a5df7f45b7c4c865503dcc7f48077c2e() = reduce(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>), (<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _539e73477e803e657abc6c74b0177f90() = reduce(<state({(<"@alice", 5>: <state((), (), {}), comm(val(false), val(<"@bob", 0>), "b", skip())>, <"@bob", 0>: <state(("b": val(true)), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), seq(skip(), seq(asgn("b", val(false)), skip()))>)}), empty()> ;

private rel[PID, CHOR_EXPRESSION] getChi(<CHOR_STATE sChor, CHOR_EXPRESSION _>)
    = sChor.chi ;
private tuple[CHOR_STATE, CHOR_EXPRESSION] setChi(<CHOR_STATE sChor, CHOR_EXPRESSION eChor>, rel[PID, CHOR_EXPRESSION] chi)
    = <sChor[chi = chi], eChor> ;
