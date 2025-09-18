module icplt::core::\prog::\syntax::Abstract
extend icplt::core::\chor::\syntax::Abstract;
extend icplt::core::\data::\syntax::Abstract;
extend icplt::core::\util::\syntax::Abstract;

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

PROG_EXPRESSION toAbstract(e: (ProgExpression) `<RoleDefinition _>`)
    = toAbstract(e.args[0]) ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<Process _>`)
    = toAbstract(e.args[0]) ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<Directive _>`)
    = empty() [src = e.src] ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<ProgExpression e1> <ProgExpression e2>`)
    = seq(toAbstract(e1), toAbstract(e2)) [src = e.src] ;

@autoName test bool _188f7be011594b42859e2b2e53354518() = compare(toAbstract(parse(#ProgExpression, "role @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _26025a27fd6df3a230c1cd61e9cc3800() = compare(toAbstract(parse(#ProgExpression, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _0d58009016b73b8d3b74369c80d1e905() = compare(toAbstract(parse(#ProgExpression, "role @alice() role @bob() role @carol()")), seq(seq(glob("@alice", [], [proced("main", skip())]), glob("@bob", [], [proced("main", skip())])), glob("@carol", [], [proced("main", skip())]))) ;

/*
 * Expressions: Roles
 */

PROG_EXPRESSION toAbstract(e: (RoleDefinition) `role <Role r>(<{FormalParameter ","}* formals>)`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([])) [src = e.src] [rSrc = r.src] ;
PROG_EXPRESSION toAbstract(e: (RoleDefinition) `role <Role r>(<{FormalParameter ","}* formals>) { <Procedure* proceds> }`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([toAbstract(proced) | proced <- proceds])) [src = e.src] [rSrc = r.src] ;

@autoName test bool _a0d8241b9ec7d41f1cb9372786241862() = compare(toAbstract(parse(#RoleDefinition, "role @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _32baf377e4e5acf9cea004c1bca94205() = compare(toAbstract(parse(#RoleDefinition, "role @alice(x: number, y: boolean)")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", skip())])) ;
@autoName test bool _66dc133fceb5edbca164a2fda680c25c() = compare(toAbstract(parse(#RoleDefinition, "role @alice() { main: assign assign: x := 5 }")), glob("@alice", [], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;
@autoName test bool _1eda478459ef733f6f70f667e06632b6() = compare(toAbstract(parse(#RoleDefinition, "role @alice(x: number, y: boolean) { main: assign assign: x := 5 }")), glob("@alice", [formal("x", number()), formal("y", boolean())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;

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
