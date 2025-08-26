module icplt::core::\chor::\semantics::Dynamic

import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\data::\semantics::Dynamic;

/*
 * States
 */

data CHOR_STATE = state(
    map[DATA_VARIABLE, DATA_EXPRESSION] phi,
    map[CHOR_VARIABLE, CHOR_EXPRESSION] psi,
    rel[PID, CHOR_EXPRESSION] chi) ;

CHOR_STATE s1 = state((), (), {}) ;
CHOR_STATE s2 = state(("b": val(true), "i": val(5), "j": val(6)), ("f": asgn("b", val(false))), {}) ;
CHOR_STATE s3 = state(("b": val(true)), (), {<<"@alice", 5>, asgn("b", val(false))>}) ;

/*
 * Normalization
 */

tuple[CHOR_STATE, CHOR_EXPRESSION] normalize(tuple[CHOR_STATE, CHOR_EXPRESSION] se) {
    return solve (se) {
        se = reduce(se);
    }
}

@autoName test bool _0f4fd983107f73830cf64c9c649cdf27() = normalize(<s2, CHOR_EXPRESSION::var("f")>) == <s2[phi = s2.phi + ("b": val(false))], skip()> ;
@autoName test bool _cceb010d0ffc841b3e8cc7a31e0c325d() = normalize(<s2, choice(app("!=", [var("i"), val(5)]), skip(), asgn("b", val(false)))>) == <s2[phi = s2.phi + ("b": val(false))], skip()> ;
@autoName test bool _4babbf8a7a25fb684c11c79379b3c664() = normalize(<s2, loop(app("\>", [var("j"), val(0)]), seq(asgn("j", app("-", [var("j"), val(1)])), asgn("i", app("+", [var("i"), val(1)]))))>) == <s2[phi = s2.phi + ("i": val(11), "j": val(0))], skip()> ;
@autoName test bool _70c246f17eb2cc7ce0d1f5e1fa371b19() = normalize(<s2, seq(asgn("b", val(false)), asgn("b", val(true)))>) == <s2, skip()> ;
@autoName test bool _9be68f7aacd9f397a3194036bb393359() = normalize(<s3, skip()>) == <s3[phi = s3.phi + ("b": val(false))][chi = {}], skip()> ;

/*
 * Reduction
 */

tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION e: CHOR_EXPRESSION::err()>)
    = <s, e> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION e: skip()>)
    = <s, e> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: CHOR_EXPRESSION::var(x)>)
    = <s, s.psi[x]> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: asgn(xData, eData)>)
    = <s[phi = s.phi + (xData: eval(s, eData))], skip()> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: comm(eData1, eData2, xData, e1)>)
    = <s[chi = {<qj, seq(asgn(xData, eval(s, eData1)), e1)>}], skip()> when val(PID qj) := eval(s, eData2) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: choice(eData, e1, e2)>)
    = <s, e1> when val(true) := eval(s, eData) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: choice(eData, e1, e2)>)
    = <s, e2> when val(false) := eval(s, eData) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: loop(eData, e1)>)
    = <s, seq(e1, loop(eData, e1))> when val(true) := eval(s, eData) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: loop(eData, e1)>)
    = <s, skip()> when val(false) := eval(s, eData) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: at(_, e1)>)
    = reduce(<s, e1>) ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: seq(e1, e2)>)
    = <sPrime, seq(e1Prime, e2)> when
        <sPrime, e1Prime> := reduce(<s, e1>) ,
        <sPrime, e1Prime> != <s, e1> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {}), CHOR_EXPRESSION _: seq(e1, e2)>)
    = reduce(<s, e2>) when
        <sPrime, e1Prime> := reduce(<s, e1>) ,
        <sPrime, e1Prime> == <s, e1> ;
tuple[CHOR_STATE, CHOR_EXPRESSION] reduce(<CHOR_STATE s: state(_, _, {<_, e1>}), CHOR_EXPRESSION e>)
    = <s[chi = {}], seq(e, e1)> ;

@autoName test bool _24b15bb3b686f3f01a90c07281119a42() = reduce(<s2, CHOR_EXPRESSION::err()>) == <s2, CHOR_EXPRESSION::err()> ;
@autoName test bool _7c8547314d294a8c1661adc173aecb96() = reduce(<s2, skip()>) == <s2, skip()> ;
@autoName test bool _d79866851bffed4a826acb6cc5a020dc() = reduce(<s2, CHOR_EXPRESSION::var("f")>) == <s2, asgn("b", val(false))> ;
@autoName test bool _47944926e01ca5a5cff95a3e94c4aeab() = reduce(<s2, asgn("b", app("!=", [var("i"), val(5)]))>) == <s2[phi = s2.phi + ("b": val(false))], skip()> ;
@autoName test bool _d4839a04ff4a301cbed45c0ecb524284() = reduce(<s2, comm(app("==", [var("i"), val(5)]), val(<"@alice", 5>), "j", asgn("b", val(false)))>) == <s2[chi = {<<"@alice", 5>, seq(asgn("j", val(true)), asgn("b", val(false)))>}], skip()> ;
@autoName test bool _f58041d5494419cfa0ec7311c7495461() = reduce(<s2, choice(app("==", [var("i"), val(5)]), skip(), asgn("b", val(false)))>) == <s2, skip()> ;
@autoName test bool _a1b602b11ae54c0cdd045a096f06d1e4() = reduce(<s2, choice(app("!=", [var("i"), val(5)]), skip(), asgn("b", val(false)))>) == <s2, asgn("b", val(false))> ;
@autoName test bool _d624a9f75ffd5f8d9deff085d827bcb2() = reduce(<s2, loop(app("==", [var("j"), val(6)]), asgn("b", val(false)))>) == <s2, seq(asgn("b", val(false)), loop(app("==", [var("j"), val(6)]), asgn("b", val(false))))> ;
@autoName test bool _ebda346e14e53a23c8e2b82c4528e54d() = reduce(<s2, loop(app("!=", [var("j"), val(6)]), asgn("b", val(false)))>) == <s2, skip()> ;
@autoName test bool _fad99b37a666f3c465bba8363b23c460() = reduce(<s2, at(val(<"@alice", 5>), asgn("b", val(false)))>) == <s2[phi = s2.phi + ("b": val(false))], skip()> ;
@autoName test bool _19f152efadb3a5250f63748ed277b907() = reduce(<s2, seq(asgn("b", val(false)), asgn("b", val(true)))>) == <s2[phi = s2.phi + ("b": val(false))], seq(skip(), asgn("b", val(true)))> ;
@autoName test bool _ecdce3fa6adbf7a56b7bc596da1da79e() = reduce(<s2[phi = s2.phi + ("b": val(false))], seq(skip(), asgn("b", val(true)))>) == <s2, skip()> ;
@autoName test bool _06502795f44ac913abadd1c8df3ea308() = reduce(<s3, skip()>) == <s3[chi = {}], seq(skip(), asgn("b", val(false)))> ;

private DATA_EXPRESSION eval(CHOR_STATE s, DATA_EXPRESSION e)
    = normalize(<state(s.phi), e>)<1> ;
