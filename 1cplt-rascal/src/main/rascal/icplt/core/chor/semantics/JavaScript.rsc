module icplt::core::\chor::\semantics::JavaScript

import IO;
import icplt::core::\data::semantics::JavaScript;
import icplt::core::\chor::\syntax::Abstract;

str toJavaScript(CHOR_EXPRESSION _: CHOR_EXPRESSION::err())
    = "throw new Error();" ;
str toJavaScript(CHOR_EXPRESSION _: skip())
    = "" ;
str toJavaScript(CHOR_EXPRESSION _: CHOR_EXPRESSION::var(x))
    = "runtime.call(\'<x>\');" ;
str toJavaScript(CHOR_EXPRESSION _: asgn(xData, eData))
    = "runtime.state[\'<xData>\'] = <toJavaScript(eData)>;" ;
str toJavaScript(CHOR_EXPRESSION _: comm(eData1, eData2, xData, e1))
    = "runtime.send(<toJavaScript(eData2)>, <toJavaScript(eData1)>, \'<xData>\', \'<labelOf(e1)>\');" ;
str toJavaScript(CHOR_EXPRESSION _: choice(eData, e1, e2))
    = "if (<toJavaScript(eData)>) { <toJavaScript(e1)> } else { <toJavaScript(e2)> }" ;
str toJavaScript(CHOR_EXPRESSION _: loop(eData, e1))
    = "while (<toJavaScript(eData)>) { <toJavaScript(e1)> }" ;
str toJavaScript(CHOR_EXPRESSION _: at(_, e1))
    = toJavaScript(e1) ;
str toJavaScript(CHOR_EXPRESSION _: seq(e1, e2))
    = "<toJavaScript(e1)> <toJavaScript(e2)>" ;

str labelOf(CHOR_EXPRESSION e) = md5Hash(e) ;
