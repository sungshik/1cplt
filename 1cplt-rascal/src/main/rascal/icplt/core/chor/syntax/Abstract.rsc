module icplt::core::\chor::\syntax::Abstract
extend icplt::core::\data::\syntax::Abstract;
extend icplt::core::\util::\syntax::Abstract;

import ParseTree;

import icplt::core::\chor::\syntax::Concrete;

/*
 * Types
 */

data CHOR_TYPE(loc src = |unknown:///|)
    = chor(ROLE r) ;

CHOR_TYPE toAbstract(t: (ChorType) `chor[<Role r>]`)
    = chor(toAbstract(r)) [src = t.src] ;

@autoName test bool _956a4c119d4888fea9c5d7e720428c13() = compare(toAbstract(parse(#ChorType, "chor[Alice]")), chor("Alice")) ;

str toStr(CHOR_TYPE _: chor(r))
    = "chor[<r>]" ;

/*
 * Expressions
 */

data CHOR_EXPRESSION(loc src = |unknown:///|)
    = err()
    | skip()
    | var(CHOR_VARIABLE x)
    | asgn(DATA_VARIABLE xData, DATA_EXPRESSION eData, loc xDataSrc = |unknown:///|)
    | comm(DATA_EXPRESSION eData1, DATA_EXPRESSION eData2, DATA_VARIABLE xData, CHOR_EXPRESSION e1, loc xDataSrc = |unknown:///|)
    | choice(DATA_EXPRESSION eData, CHOR_EXPRESSION e1, CHOR_EXPRESSION e2)
    | loop(DATA_EXPRESSION eData, CHOR_EXPRESSION e1)
    | at(DATA_EXPRESSION eData, CHOR_EXPRESSION e1)
    | seq(CHOR_EXPRESSION e1, CHOR_EXPRESSION e2)
    ;

CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<ChorVariable x>`)
    = CHOR_EXPRESSION::var(toAbstract(x)) [src = e.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<DataVariable xData> := <DataExpression eData>`)
    = asgn(toAbstract(xData), toAbstract(eData)) [src = e.src] [xDataSrc = xData.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<DataExpression eData1> -\> <DataExpression eData2>.<DataVariable xData>`)
    = comm(toAbstract(eData1), toAbstract(eData2), toAbstract(xData), skip()) [src = e.src] [xDataSrc = xData.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `{ <ChorExpression e1> }`)
    = toAbstract(e1) ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<DataExpression eData1> -\> <DataExpression eData2>.<DataVariable xData> |\> <ChorExpression e1>`)
    = comm(toAbstract(eData1), toAbstract(eData2), toAbstract(xData), toAbstract(e1)) [src = e.src] [xDataSrc = xData.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `if <DataExpression eData> then <ChorExpression e1>`)
    = choice(toAbstract(eData), toAbstract(e1), skip()) [src = e.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `if <DataExpression eData> then <ChorExpression e1> else <ChorExpression e2>`)
    = choice(toAbstract(eData), toAbstract(e1), toAbstract(e2)) [src = e.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `while <DataExpression eData> do <ChorExpression e1>`)
    = loop(toAbstract(eData), toAbstract(e1)) [src = e.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<DataExpression eData>.<ChorExpression e1>`)
    = at(toAbstract(eData), toAbstract(e1)) [src = e.src] ;
CHOR_EXPRESSION toAbstract(e: (ChorExpression) `<ChorExpression e1> ; <ChorExpression e2>`)
    = seq(toAbstract(e1), toAbstract(e2)) [src = e.src] ;

@autoName test bool _85e62f21d42a95037af721f8390a397c() = compare(toAbstract(parse(#ChorExpression, "main")), CHOR_EXPRESSION::var("main")) ;
@autoName test bool _1328850d06a0378af47fff5936681b1a() = compare(toAbstract(parse(#ChorExpression, "i := 5")), asgn("i", val(5))) ;
@autoName test bool _66f6185e3d96371a1c7fd9c6df62b165() = compare(toAbstract(parse(#ChorExpression, "5 -\> Alice[5].i")), comm(val(5), val(<"Alice", 5>), "i", skip())) ;
@autoName test bool _463cbe92deb6136e7009654766725813() = compare(toAbstract(parse(#ChorExpression, "{ 5 -\> Alice[5].i }")), comm(val(5), val(<"Alice", 5>), "i", skip())) ;
@autoName test bool _cefa39758c7592871c130010e023690f() = compare(toAbstract(parse(#ChorExpression, "5 -\> Alice[5].i |\> main")), comm(val(5), val(<"Alice", 5>), "i", CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _4e0d3edbb044868d875c7b535d873e98() = compare(toAbstract(parse(#ChorExpression, "if true then main")), choice(val(true), CHOR_EXPRESSION::var("main"), skip())) ;
@autoName test bool _8840c5b90650b448682e7016edbb56eb() = compare(toAbstract(parse(#ChorExpression, "if true then main else main")), choice(val(true), CHOR_EXPRESSION::var("main"), CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _a269925b6bfaf8b43f069b770135c3b5() = compare(toAbstract(parse(#ChorExpression, "while (true) do main")), loop(val(true), CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _e6331f2c9d81a2635ef7678e4cefd60f() = compare(toAbstract(parse(#ChorExpression, "Alice[5].main")), at(val(<"Alice", 5>), CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _264bf3d7d21c07e752b8607c1ec18895() = compare(toAbstract(parse(#ChorExpression, "Alice[5].if true then main")), at(val(<"Alice", 5>), choice(val(true), CHOR_EXPRESSION::var("main"), skip()))) ;
@autoName test bool _c680d5819eb7d17fd8e9e517be62c115() = compare(toAbstract(parse(#ChorExpression, "Alice[5].main; main")), seq(at(val(<"Alice", 5>), CHOR_EXPRESSION::var("main")), CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _da529655dc56a30531a2d787577af216() = compare(toAbstract(parse(#ChorExpression, "main; main")), seq(CHOR_EXPRESSION::var("main"), CHOR_EXPRESSION::var("main"))) ;
@autoName test bool _9613f73106037251bb6d970586fde8df() = compare(toAbstract(parse(#ChorExpression, "main; main; main")), seq(seq(CHOR_EXPRESSION::var("main"), CHOR_EXPRESSION::var("main")), CHOR_EXPRESSION::var("main"))) ;

/*
 * Variables
 */

alias CHOR_VARIABLE = str ;

CHOR_VARIABLE toAbstract(x: (ChorVariable) _)
    = "<x>";

@autoName test bool _27633c47e7c92a7f3d3620c69c3b7b0e() = toAbstract(parse(#ChorVariable, "x")) == "x" ;

/* -------------------------------------------------------------------------- */
/*                                 `foreach`                                  */
/* -------------------------------------------------------------------------- */

CHOR_EXPRESSION toAbstract(e: (ChorExpression) `foreach\<<DataType tData>\> <DataVariable xData> in <DataExpression eData> do <ChorExpression e1>`)
    = seq(
        asgn(xDataColl, toAbstract(eData)),
        loop(
            app("!", [app("isNil", [var(xDataColl)])]),
            seq(
                asgn("<xDataElem>", app("headOrDefault", [var(xDataColl), defaultOf(toAbstract(tData))])),
                seq(
                    substVar("<xData>", xDataElem, toAbstract(e1)),
                    asgn(xDataColl, app("tailOrDefault", [var(xDataColl), val([])]))
                )
            )
        )
    ) when
        xDataColl := "(foreach\<<tData>\> <xData>, <e.src.offset>).coll" ,
        xDataElem := "(foreach\<<tData>\> <xData>, <e.src.offset>).elem" ;

map[DATA_VARIABLE, DATA_TYPE] toGammaForeach(CHOR_EXPRESSION e) {
    map[DATA_VARIABLE, DATA_TYPE] gamma = ();

    for (/asgn(/^\(foreach\<<s1:[0-9A-Za-z]+>\> <s2:[0-9A-Za-z]+>, <offset:[0-9]*>\).coll$/, _) := e) {
        DATA_TYPE tData = toAbstract(parse(#DataType, s1));
        DATA_VARIABLE xData = s2;

        gamma += (
            "(foreach\<<toStr(tData)>\> <xData>, <offset>).coll": array(tData),
            "(foreach\<<toStr(tData)>\> <xData>, <offset>).elem": tData
        );
    }

    return gamma;
}

CHOR_EXPRESSION substVar(str old, str new, CHOR_EXPRESSION e)
    = visit (e) { case eData: DATA_EXPRESSION::var(old) => eData [x = new] } ;

DATA_EXPRESSION defaultOf(DATA_TYPE _: pid(r))
    = val(<r, -1>) ;
DATA_EXPRESSION defaultOf(DATA_TYPE _: null())
    = val(NULL) ;
DATA_EXPRESSION defaultOf(DATA_TYPE _: boolean())
    = val(false) ;
DATA_EXPRESSION defaultOf(DATA_TYPE _: number())
    = val(0) ;
DATA_EXPRESSION defaultOf(DATA_TYPE _: string())
    = val("") ;
DATA_EXPRESSION defaultOf(DATA_TYPE _: array(t1))
    = val([]) ;
