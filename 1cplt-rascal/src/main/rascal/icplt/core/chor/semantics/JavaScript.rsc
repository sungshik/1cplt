module icplt::core::\chor::\semantics::JavaScript

import IO;

import icplt::core::\data::semantics::JavaScript;
import icplt::core::\chor::\syntax::Abstract;

data Mode
    = procedure()
    | continuations()
    ;

str toJavaScript(procedure(), CHOR_EXPRESSION _: CHOR_EXPRESSION::err())
    = "throw new Error();" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: skip())
    = "" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: CHOR_EXPRESSION::var(x))
    = "API.call(\'<x>\');" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: asgn(xData, eData))
    = "state[\'<xData>\'] = <toJavaScript(eData)>;" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: comm(eData1, eData2, _, e1))
    = "API.send(<toJavaScript(eData2)>, <toJavaScript(eData1)>, \'<labelOf(e1)>\');" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: choice(eData, e1, e2))
    = "if (<toJavaScript(eData)>) { <toJavaScript(procedure(), e1)> } else { <toJavaScript(procedure(), e2)> }" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: loop(eData, e1))
    = "while (<toJavaScript(eData)>) { <toJavaScript(procedure(), e1)> }" ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: at(_, e1))
    = toJavaScript(procedure(), e1) ;
str toJavaScript(procedure(), CHOR_EXPRESSION _: seq(e1, e2))
    = "<toJavaScript(procedure(), e1)> <toJavaScript(procedure(), e2)>" ;

str toJavaScript(continuations(), CHOR_EXPRESSION e) {
    str s = "";
    visit (e) {
        case comm(_, _, xData, e1): {
            s += "continuations[\'<labelOf(e1)>\'] = (message) =\> { state[\'<xData>\'] = message; <toJavaScript(procedure(), e1)> }; ";
        }
    }
    return s;
}

private str labelOf(CHOR_EXPRESSION e) = md5Hash(e) ;
