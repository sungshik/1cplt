module icplt::core::\prog::\syntax::Abstract
extend icplt::core::\chor::\syntax::Abstract;
extend icplt::core::\data::\syntax::Abstract;
extend icplt::core::\util::\syntax::Abstract;

import ParseTree;

import icplt::core::\prog::\syntax::Concrete;

/*
 * Expressions
 */

data PROG_EXPRESSION(loc src = |unknown:///|)
    = empty()
    | glob(ROLE r, list[PARAMETER] formals, list[PROCEDURE] proceds, loc rSrc = |unknown:///|)
    | proc(PID rk, list[PARAMETER] actuals, CHOR_EXPRESSION eChor, loc rkSrc = |unknown:///|)
    | seq(PROG_EXPRESSION e1, PROG_EXPRESSION e2)
    ;

PROG_EXPRESSION toAbstract(e: (ProgExpression) `<Global _>`)
    = toAbstract(e.args[0]) ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<Process _>`)
    = toAbstract(e.args[0]) ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<ProgExpression e1> <ProgExpression e2>`)
    = seq(toAbstract(e1), toAbstract(e2)) [src = e.src] ;

@autoName test bool _e5df19b9a8ef06e5a14f8c62b349a21e() = compare(toAbstract(parse(#ProgExpression, "global @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _26025a27fd6df3a230c1cd61e9cc3800() = compare(toAbstract(parse(#ProgExpression, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _af20a478ad168d6730d9583fde96e576() = compare(toAbstract(parse(#ProgExpression, "global @alice() global @bob() global @carol()")), seq(seq(glob("@alice", [], [proced("main", skip())]), glob("@bob", [], [proced("main", skip())])), glob("@carol", [], [proced("main", skip())]))) ;

/*
 * Expressions: Globals
 */

PROG_EXPRESSION toAbstract(e: (Global) `global <Role r>(<{FormalParameter ","}* formals>)`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([])) [src = e.src] [rSrc = r.src] ;
PROG_EXPRESSION toAbstract(e: (Global) `global <Role r>(<{FormalParameter ","}* formals>) { <Procedure* proceds> }`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([toAbstract(proced) | proced <- proceds])) [src = e.src] [rSrc = r.src] ;

@autoName test bool _405a086da7e84e7640471ee04ac5cbc0() = compare(toAbstract(parse(#Global, "global @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _177f520b67f8cc8f8b49200dc8857fec() = compare(toAbstract(parse(#Global, "global @alice(x: number, y: boolean)")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", skip())])) ;
@autoName test bool _9b17befb2929497bab28a08c00a3be3a() = compare(toAbstract(parse(#Global, "global @alice() { main: assign assign: x := 5 }")), glob("@alice", [], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;
@autoName test bool _fcf06dd688192cfd7e95bdfefbec3a45() = compare(toAbstract(parse(#Global, "global @alice(x: number, y: boolean) { main: assign assign: x := 5 }")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;

private list[PROCEDURE] addMain(list[PROCEDURE] proceds)
    = proceds + ((/proced("main", _) := proceds) ? [] : [proced("main", skip())]) ;

/*
 * Expressions: Processes
 */

PROG_EXPRESSION toAbstract(e: (Process) `process <Pid rk>(<{ActualParameter ","}* actuals>)`)
    = proc(toAbstract(rk), [toAbstract(actual) | actual <- actuals], CHOR_EXPRESSION::var("main")) [src = e.src] [rkSrc = rk.src] ;
PROG_EXPRESSION toAbstract(e: (Process) `process <Pid rk>(<{ActualParameter ","}* actuals>) |\> <ChorExpression eChor>`)
    = proc(toAbstract(rk), [toAbstract(actual) | actual <- actuals], toAbstract(eChor)) [src = e.src] [rkSrc = rk.src] ;

@autoName test bool _b0afc7b971277fd5521d555a292513ef() = compare(toAbstract(parse(#Process, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _02bf104e8a391d355faf8c3e7031e6f9() = compare(toAbstract(parse(#Process, "process @alice[5](5, 6)")), proc(<"@alice", 5>, [actual(val(5)), actual(val(6))], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _7759626afa3f2ce5ba0f2685b5f93b09() = compare(toAbstract(parse(#Process, "process @bob(5, 6)")), proc(<"@bob", 0>, [actual(val(5)), actual(val(6))], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _ddddd996bb74644b1c2c5ca689a90aef() = compare(toAbstract(parse(#Process, "process @alice[5]() |\> n := 5")), proc(<"@alice", 5>, [], asgn("n", val(5)))) ;
@autoName test bool _2fa9e77b4fa65948677285b69057c4f4() = compare(toAbstract(parse(#Process, "process @alice[5](5, 6) |\> n := 5")), proc(<"@alice", 5>, [actual(val(5)), actual(val(6))], asgn("n", val(5)))) ;
@autoName test bool _82c9ab2c0f73d191da1272716f625339() = compare(toAbstract(parse(#Process, "process @bob(5, 6) |\> n := 5")), proc(<"@bob", 0>, [actual(val(5)), actual(val(6))], asgn("n", val(5)))) ;

/*
 * Procedures
 */

data PROCEDURE(loc src = |unknown:///|)
    = proced(CHOR_VARIABLE xChor, CHOR_EXPRESSION eChor, loc xChorSrc = |unknown:///|) ;

PROCEDURE toAbstract(e: (Procedure) `<ChorVariable xChor>: <ChorExpression eChor>`)
    = proced(toAbstract(xChor), toAbstract(eChor)) [src = e.src] [xChorSrc = xChor.src] ;

@autoName test bool _04634e0b0bbc96875a5494def8d510c9() = compare(toAbstract(parse(#Procedure, "main: assign")), proced("main", CHOR_EXPRESSION::var("assign"))) ;
@autoName test bool _98822f7200815c84b308853a0f72bb0f() = compare(toAbstract(parse(#Procedure, "assign: x := 5")), proced("assign", asgn("x", val(5)))) ;

/*
 * Parameters
 */

data PARAMETER(loc src = |unknown:///|)
    = formal(DATA_VARIABLE xData, DATA_TYPE tData, loc xDataSrc = |unknown:///|)
    | actual(DATA_EXPRESSION eData)
    ;

list[PARAMETER] toAbstract(e: (FormalParameter) `<{DataVariable ","}+ xDatas>: <DataType tData>`)
    = [formal(toAbstract(xData), toAbstract(tData)) [src = e.src] [xDataSrc = xData.src] | xData <- xDatas];

@autoName test bool _b1de474881069e6d3bce185c5a6da340() = compare(toAbstract(parse(#FormalParameter, "x: number")), [formal("x", number())]) ;
@autoName test bool _d5dab34732b3ad044f569ee05d3431fd() = compare(toAbstract(parse(#FormalParameter, "x, y: number")), [formal("x", number()), formal("y", number())]) ;

PARAMETER toAbstract(e: (ActualParameter) `<DataExpression eData>`)
    = actual(toAbstract(eData)) [src = e.src];

@autoName test bool _7b66dd025de28bfbf574b8877929321f() = compare(toAbstract(parse(#ActualParameter, "5")), actual(DATA_EXPRESSION::val(5))) ;
