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

@autoName test bool _ebeb82900a28c876646747d776133055() = compare(toAbstract(parse(#ProgExpression, "global @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _ed6699be93ab74b06db4fb8d79526be6() = compare(toAbstract(parse(#ProgExpression, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _f684eaffa84eda8f75a9e5091e296e91() = compare(toAbstract(parse(#ProgExpression, "global @alice() global @bob() global @carol()")), seq(seq(glob("@alice", [], [proced("main", skip())]), glob("@bob", [], [proced("main", skip())])), glob("@carol", [], [proced("main", skip())]))) ;

/*
 * Expressions: Globals
 */

PROG_EXPRESSION toAbstract(e: (Global) `global <Role r>(<{FormalParameter ","}* formals>)`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([])) [src = e.src] [rSrc = r.src] ;
PROG_EXPRESSION toAbstract(e: (Global) `global <Role r>(<{FormalParameter ","}* formals>) { <Procedure* proceds> }`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([toAbstract(proced) | proced <- proceds])) [src = e.src] [rSrc = r.src] ;

@autoName test bool _0fef4616a15340b26df4768fab3e856a() = compare(toAbstract(parse(#Global, "global @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _dbc360f3eae7e73e95679945bf4e59a7() = compare(toAbstract(parse(#Global, "global @alice(x: number, y: boolean)")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", skip())])) ;
@autoName test bool _68dbedd557c89e2bb894569f49a9448a() = compare(toAbstract(parse(#Global, "global @alice() { main: assign assign: x := 5 }")), glob("@alice", [], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;
@autoName test bool _ccb8e2f4f1e90e71de7cb68002f3f4aa() = compare(toAbstract(parse(#Global, "global @alice(x: number, y: boolean) { main: assign assign: x := 5 }")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;

private list[PROCEDURE] addMain(list[PROCEDURE] proceds)
    = proceds + ((/proced("main", _) := proceds) ? [] : [proced("main", skip())]) ;

/*
 * Expressions: Processes
 */

PROG_EXPRESSION toAbstract(e: (Process) `process <Pid rk>(<{ActualParameter ","}* actuals>)`)
    = proc(toAbstract(rk), [toAbstract(actual) | actual <- actuals], CHOR_EXPRESSION::var("main")) [src = e.src] [rkSrc = rk.src] ;
PROG_EXPRESSION toAbstract(e: (Process) `process <Pid rk>(<{ActualParameter ","}* actuals>) |\> <ChorExpression eChor>`)
    = proc(toAbstract(rk), [toAbstract(actual) | actual <- actuals], toAbstract(eChor)) [src = e.src] [rkSrc = rk.src] ;

@autoName test bool _6f2124f318cc44db0b3345bb9fbdf5fe() = compare(toAbstract(parse(#Process, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _2120b0e692f4fa7a17c1c238cc225bfe() = compare(toAbstract(parse(#Process, "process @alice[5](5, 6)")), proc(<"@alice", 5>, [actual(val(5)), actual(val(6))], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _7337bb44f794f84c599ea619e91943f7() = compare(toAbstract(parse(#Process, "process @bob(5, 6)")), proc(<"@bob", 0>, [actual(val(5)), actual(val(6))], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _af95ce68a7fb346348ce04062b37d11d() = compare(toAbstract(parse(#Process, "process @alice[5]() |\> n := 5")), proc(<"@alice", 5>, [], asgn("n", val(5)))) ;
@autoName test bool _7720d08b4ef1d97e0864586b127fa786() = compare(toAbstract(parse(#Process, "process @alice[5](5, 6) |\> n := 5")), proc(<"@alice", 5>, [actual(val(5)), actual(val(6))], asgn("n", val(5)))) ;
@autoName test bool _5ce0d715ad2f3744b8f86559b28af3da() = compare(toAbstract(parse(#Process, "process @bob(5, 6) |\> n := 5")), proc(<"@bob", 0>, [actual(val(5)), actual(val(6))], asgn("n", val(5)))) ;

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
