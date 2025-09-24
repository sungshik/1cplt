module icplt::core::\prog::\syntax::Abstract
extend icplt::core::\chor::\syntax::Abstract;
extend icplt::core::\data::\syntax::Abstract;
extend icplt::core::\util::\syntax::Abstract;

import icplt::core::\prog::\syntax::Concrete;
import util::Maybe;

default PROG_EXPRESSION toAbstract(e: (ProgExpression) _)
    = empty() [src = e.src] ;

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
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<ProcessDefinition _>`)
    = toAbstract(e.args[0]) ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<Directive _>`)
    = empty() [src = e.src] ;
PROG_EXPRESSION toAbstract(e: (ProgExpression) `<ProgExpression e1> <ProgExpression e2>`)
    = seq(toAbstract(e1), toAbstract(e2)) [src = e.src] ;

@autoName test bool _188f7be011594b42859e2b2e53354518() = compare(toAbstract(parse(#ProgExpression, "role @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _26025a27fd6df3a230c1cd61e9cc3800() = compare(toAbstract(parse(#ProgExpression, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _0d58009016b73b8d3b74369c80d1e905() = compare(toAbstract(parse(#ProgExpression, "role @alice() role @bob() role @carol()")), seq(seq(glob("@alice", [], [proced("main", skip())]), glob("@bob", [], [proced("main", skip())])), glob("@carol", [], [proced("main", skip())]))) ;

/*
 * Expressions: Role definitions
 */

PROG_EXPRESSION toAbstract(e: (RoleDefinition) `role <Role r>(<{FormalParameter ","}* formals>)`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([])) [src = e.src] [rSrc = r.src] ;
PROG_EXPRESSION toAbstract(e: (RoleDefinition) `role <Role r>(<{FormalParameter ","}* formals>) { <Procedure* proceds> }`)
    = glob(toAbstract(r), [*toAbstract(formal) | formal <- formals], addMain([toAbstract(proced) | proced <- proceds])) [src = e.src] [rSrc = r.src] ;

@autoName test bool _a0d8241b9ec7d41f1cb9372786241862() = compare(toAbstract(parse(#RoleDefinition, "role @alice()")), glob("@alice", [], [proced("main", skip())])) ;
@autoName test bool _b99600d1081c4f7a1b22b67e13bc74b6() = compare(toAbstract(parse(#RoleDefinition, "role @alice(x: number, y: boolean)")), glob("@alice", [formal("x", number(), nothing()), formal("y", boolean(), nothing())], [proced("main", skip())])) ;
@autoName test bool _66dc133fceb5edbca164a2fda680c25c() = compare(toAbstract(parse(#RoleDefinition, "role @alice() { main: assign assign: x := 5 }")), glob("@alice", [], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;
@autoName test bool _19db31d78d64c11d0809086d1f97dd29() = compare(toAbstract(parse(#RoleDefinition, "role @alice(x: number, y: boolean) { main: assign assign: x := 5 }")), glob("@alice", [formal("x", number(), nothing()), formal("y", boolean(), nothing())], [proced("main", CHOR_EXPRESSION::var("assign")), proced("assign", asgn("x", val(5)))])) ;

private list[PROCEDURE] addMain(list[PROCEDURE] proceds)
    = proceds + ((/proced("main", _) := proceds) ? [] : [proced("main", skip())]) ;

/*
 * Expressions: Process definitions
 */

PROG_EXPRESSION toAbstract(e: (ProcessDefinition) `process <Pid rk>(<{ActualParameter ","}* actuals>)`)
    = proc(toAbstract(rk), [toAbstract(actual) | actual <- actuals], CHOR_EXPRESSION::var("main")) [src = e.src] [rkSrc = rk.src] ;

@autoName test bool _035a4e7a981e5daf4a3cf169a1989d01() = compare(toAbstract(parse(#ProcessDefinition, "process @alice[5]()")), proc(<"@alice", 5>, [], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _56ba384707ba19180a6288a21ab96ccf() = compare(toAbstract(parse(#ProcessDefinition, "process @alice[5](x = 5, y = 6)")), proc(<"@alice", 5>, [actual("x", just(val(5))), actual("y", just(val(6)))], CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _7af0ca1ba05dea3b8bee062811d564ff() = compare(toAbstract(parse(#ProcessDefinition, "process @bob(x = 5, y = 6)")), proc(<"@bob", 0>, [actual("x", just(val(5))), actual("y", just(val(6)))], CHOR_EXPRESSION::var("main"))) ;

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

data PARAMETER(loc src = |unknown:///|, loc xDataSrc = |unknown:///|)
    = formal(DATA_VARIABLE xData, DATA_TYPE tData, Maybe[DATA_EXPRESSION] eData)
    | actual(DATA_VARIABLE xData, Maybe[DATA_EXPRESSION] eData)
    ;

list[PARAMETER] toAbstract(e: (FormalParameter) `<DataVariable xData>: <DataType tData>`)
    = [formal(toAbstract(xData), toAbstract(tData), nothing()) [src = e.src] [xDataSrc = xData.src]] ;
list[PARAMETER] toAbstract(e: (FormalParameter) `<DataVariable xData>: <DataType tData> = <DataExpression eData>`)
    = [formal(toAbstract(xData), toAbstract(tData), just(toAbstract(eData))) [src = e.src] [xDataSrc = xData.src]] ;
list[PARAMETER] toAbstract(e: (FormalParameter) `<DataVariable xData>?: <DataType tData>`)
    = [formal(toAbstract(xData), union([toAbstract(tData), undefined()]) [src = tData.src], just(val(UNDEFINED))) [src = e.src] [xDataSrc = xData.src]] ;
list[PARAMETER] toAbstract(e: (FormalParameter) `<DataVariable xData>?: <DataType tData> = <DataExpression eData>`)
    = [formal(toAbstract(xData), union([toAbstract(tData), undefined()]) [src = tData.src], just(toAbstract(eData))) [src = e.src] [xDataSrc = xData.src]] ;

@autoName test bool _fb12e555db5485983dfd55656bd82c4e() = compare(toAbstract(parse(#FormalParameter, "x: number")), [formal("x", number(), nothing())]) ;
@autoName test bool _7c60a9916e6ce67f04e815204b09bed0() = compare(toAbstract(parse(#FormalParameter, "x: number = 5")), [formal("x", number(), just(val(5)))]) ;
@autoName test bool _f5370bf81653a13fd7dd696c50303179() = compare(toAbstract(parse(#FormalParameter, "x?: number")), [formal("x", union([number(), undefined()]), just(val(UNDEFINED)))]) ;
@autoName test bool _6bddbe692aed8c5c6b4f6fc2f6f587f2() = compare(toAbstract(parse(#FormalParameter, "x?: number = 5")), [formal("x", union([number(), undefined()]), just(val(5)))]) ;

PARAMETER toAbstract(e: (ActualParameter) `<DataVariable xData> = <DataExpression eData>`)
    = actual(toAbstract(xData), just(toAbstract(eData))) [src = e.src] [xDataSrc = xData.src] ;

@autoName test bool _c91c81da5e9b8b0931c8944b1bea2076() = compare(toAbstract(parse(#ActualParameter, "x = 5")), actual("x", just(DATA_EXPRESSION::val(5)))) ;
