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

@autoName test bool _8382366aad44216fea219c27d937041c() = normalize(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _59d82c0e8ed7dc4b4e3d479537693f5d() = normalize(<state({(<"@alice", 5>: <state((), (), {}), comm(val(false), val(<"@bob", 0>), "b", skip())>, <"@bob", 0>: <state(("b": val(true)), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;

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

@autoName test bool _ee30191d62e15edbd4f91d6b6f749853() = reduce(<state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state((), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state((), (), {}), skip()>)}), empty()> ;
@autoName test bool _811b828858728b8ae848f253e0bd2450() = reduce(<state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _4cb190301bfe6a82187ec7a3797d20b0() = reduce(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>), (<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()> ;
@autoName test bool _59b19a12c1c675f29e47026343183d50() = reduce(<state({(<"@alice", 5>: <state(("b": val(true)), (), {}), asgn("b", val(false))>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>), (<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), asgn("b", val(false))>)}), empty()>) == <state({(<"@alice", 5>: <state(("b": val(false)), (), {}), skip()>, <"@bob", 0>: <state(("b": val(false)), (), {}), skip()>)}), empty()> ;
@autoName test bool _9a4d5753c3ba2b48d9b29a04dbc12020() = reduce(<state({(<"@alice", 5>: <state((), (), {}), comm(val(false), val(<"@bob", 0>), "b", skip())>, <"@bob", 0>: <state(("b": val(true)), (), {}), skip()>)}), empty()>) == <state({(<"@alice", 5>: <state((), (), {}), skip()>, <"@bob", 0>: <state(("b": val(true)), (), {}), seq(skip(), seq(asgn("b", val(false)), skip()))>)}), empty()> ;

private rel[PID, CHOR_EXPRESSION] getChi(<CHOR_STATE sChor, CHOR_EXPRESSION _>)
    = sChor.chi ;
private tuple[CHOR_STATE, CHOR_EXPRESSION] setChi(<CHOR_STATE sChor, CHOR_EXPRESSION eChor>, rel[PID, CHOR_EXPRESSION] chi)
    = <sChor[chi = chi], eChor> ;
