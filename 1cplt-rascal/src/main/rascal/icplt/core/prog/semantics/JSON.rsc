module icplt::core::\prog::\semantics::JSON

import List;
import String;
import icplt::core::\data::\semantics::Dynamic;
import icplt::core::\data::\semantics::JSON;
import icplt::core::\prog::\syntax::Abstract;

str toJSON(PROG_EXPRESSION e) {
    list[PROG_EXPRESSION] globs = [ei | /ei: glob(_, _, _) := e];
    list[PROG_EXPRESSION] procs = [ei | /ei: proc(_, _, _) := e];
    
    str s =
        "{
        '  \"schemas\": {
        '    <for (glob(r, formals, _) <- globs) {>
        '    \"<r>\": {
        '      \"type\": \"object\",
        '      \"properties\": {
        '        <intercalate(", ", ["\"<xData>\": <toJSON(tData)>" | formal(xData, tData) <- formals])>
        '      },
        '      \"required\": [
        '        <intercalate(", ", ["\"<xData>\"" | formal(xData, _) <- formals])>
        '      ]
        '    },
        '    <}>
        '  },
        '  \"conn\": {
        '    <for (proc(pi: <p, i>, _, _) <- procs) {>
        '    \"<i == 0 ? "<p>" : "<p>[<i>]">\": [
        '      <intercalate(", ", sort(["\"<j == 0 ? "<q>" : "<q>[<j>]">\"" | <q, j> <- neighborsOf(pi, e)]))>
        '    ],
        '    <}>
        '  },
        '  \"init\": {
        '    <for (proc(<r, k>, actuals, _) <- procs, /glob(r, formals, _) := globs) {>
        '    \"<k == 0 ? "<r>" : "<r>[<k>]">\": {
        '      <intercalate(", ", ["\"<xData>\": <toJSON(normalize(<state(()), eData>)<1>)>" | <formal(xData, _), actual(eData)> <- zip2(formals, actuals)])>
        '    },
        '    <}>
        '  }
        '}
        '";
    
    s = visit (s) { case /,<rest:\s*}>/ => rest };
    return s;
}

private set[PID] neighborsOf(PID pi, PROG_EXPRESSION e) {
    set[PID] neighbors = {};
    neighbors += {qj | /proc(pi, actuals, _) := e, /val(PID qj) := actuals};
    neighbors += {qj | /glob(_, _, proceds) := e, /val(PID qj) := proceds};
    return {qj | PID qj: <_, j> <- neighbors, j >= 0};
}
