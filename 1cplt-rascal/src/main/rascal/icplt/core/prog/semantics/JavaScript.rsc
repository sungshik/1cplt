module icplt::core::\prog::\semantics::JavaScript

import List;

import icplt::core::\chor::\semantics::JavaScript;
import icplt::core::\prog::\syntax::Abstract;

str toJavaScript(PROG_EXPRESSION e) {
    str s = "";
    s += "procedures = {}; ";
    for (/glob(r, _, proceds) := e) {
        s += "procedures[\'<r>\'] = {}; ";
        s += intercalate(" ", ["procedures[\'<r>\'][\'<xChor>\'] = () =\> { <toJavaScript(procedure(), eChor)> };" | proced(xChor, eChor) <- proceds]);
    }
    s += "\n";
    s += "continuations = {}; ";
    for (/glob(_, _, proceds) := e) {
        s += intercalate(" ", [toJavaScript(continuations(), eChor) | proced(_, eChor) <- proceds]);
    }
    return s;
}
