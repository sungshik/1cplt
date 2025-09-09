module icplt::core::\prog::\semantics::JavaScript

import List;
import icplt::core::\chor::\semantics::JavaScript;
import icplt::core::\prog::\syntax::Abstract;

str toJavaScript(PROG_EXPRESSION e) {
    return 
        "export class Library { 
        '  static {
        '    this.procedures = {};
        '    <for (/glob(r, _, proceds) := e) {>
        '    this.procedures[\'<r>\'] = {};
        '    <intercalate("\n", ["this.procedures[\'<r>\'][\'<xChor>\'] = runtime =\> { <toJavaScript(eChor)> };" | proced(xChor, eChor) <- proceds])>
        '    <intercalate("\n", ["this.procedures[\'<r>\'][\'<labelOf(eChor)>\'] = runtime =\> { <toJavaScript(eChor)> };" | /comm(_, _, _, eChor) := e])>
        '    <}>
        '  }
        '}
        '";
}
