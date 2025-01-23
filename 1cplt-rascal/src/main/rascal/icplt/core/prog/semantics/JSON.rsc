module icplt::core::\prog::\semantics::JSON

import List;
import String;

import icplt::core::\data::\semantics::Dynamic;
import icplt::core::\data::\semantics::JSON;
import icplt::core::\prog::\syntax::Abstract;

str toJSON(PROG_EXPRESSION e) {
    list[PROG_EXPRESSION] globs = [ei | /ei: glob(_, _, _) := e];
    list[PROG_EXPRESSION] procs = [ei | /ei: proc(_, _, _) := e];

    str s = "";
    s += "{ ";
    s += "\"schemas\": { ";
    for (glob(r, formals, _) <- globs) {
        s += "\"<r>\": { ";
        s += "\"type\": \"object\", ";
        s += "\"properties\": { <intercalate(", ", ["\"<xData>\": <toJSON(tData)>" | formal(xData, tData) <- formals])> }, ";
        s += "\"required\": [ <intercalate(", ", ["\"<xData>\"" | formal(xData, _) <- formals])> ] ";
        s += "}, ";
    }
    s = s[..-2];
    s += "}, ";
    s += "\"conn\": { ";
    for (proc(<r, k>, actuals, _) <- procs) {
        set[PID] neighbours = {};
        neighbours += {qj | /val(PID qj) := actuals};
        neighbours += {qj | glob(_, _, proceds) <- globs, /val(PID qj) := proceds};
        neighbours = {qj | qj: <_, j> <- neighbours, j >= 0};

        s += "\"<r>[<k>]\": [ ";
        s += "<intercalate(", ", sort(["\"<q>[<j>]\"" | <q, j> <- neighbours]))>";
        s += "], ";
    }
    s = s[..-2];
    s += "}, ";
    s += "\"init\": { ";
    for (proc(<r, k>, actuals, _) <- procs, /glob(r, formals, _) := globs) {
        s += "\"<r>[<k>]\": { ";
        s += intercalate(", ", ["\"<xData>\": <toJSON(normalize(<state(()), eData>)<1>)>" | <formal(xData, _), actual(eData)> <- zip2(formals, actuals)]);
        s += "}, ";
    }
    s = s[..-2];
    s += "} ";
    s += "}";
    return s;
}
