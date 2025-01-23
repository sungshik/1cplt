module icplt::core::\prog::IDE

import IO;
import Map;
import Message;
import ParseTree;
import Set;
import util::IDEServices;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;

import icplt::core::\chor::IDE;
import icplt::core::\chor::\semantics::Dynamic;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\prog::\semantics::JavaScript;
import icplt::core::\prog::\semantics::JSON;
import icplt::core::\chor::\semantics::Static;
import icplt::core::\prog::\semantics::Dynamic;
import icplt::core::\prog::\semantics::Static;
import icplt::core::\prog::\syntax::Abstract;
import icplt::core::\prog::\syntax::Concrete;
import icplt::core::\util::\semantics::JavaScript;
import icplt::core::\util::\semantics::JSON;

void register(Language lang = language()) {
    registerLanguage(lang);
}

void unregister(Language lang = language()) {
    unregisterLanguage(lang);
}

Language language() = language(
    pathConfig(srcs = [|std:///|, |project://1cplt-rascal/src/main/rascal|]),
    "1CPLT (Program Expressions)",
    {"1cp-prog"},
    "icplt::core::prog::IDE",
    "languageContributor"
);

set[LanguageService] languageContributor() = {
    parsing(parsingService, usesSpecialCaseHighlighting = false),
    analysis(analysisService, providesDocumentation = true, providesDefinitions = false, providesReferences = false, providesImplementations = false),
    codeLens(codeLensService),
    execution(executionService),
    inlayHint(inlayHintService)
};

Tree parsingService(str input, loc l) {
    return parse(#start[Prog], input, l);
}

Summary analysisService(loc l, start[Prog] input) {
    return analysisService(l, toAbstract(input.top.args[0]));
}

Summary analysisService(loc l, PROG_EXPRESSION e, PROG_CONTEXT c = toProgContext(e)) {
    CHOR_CONTEXT cChor = CHOR_CONTEXT::context(c.gammas, c.deltas);

    Summary analysis = summary(l);
    analysis.messages += {<m.at, m> | m <- analyze(c, e)};
    analysis.documentation += {*analysisService(l, eChor, c = cChor, p = just("<p>")).documentation | /glob(p, _, proceds) := e, /proced(_, eChor) := proceds};
    return analysis;
}

lrel[loc, Command] codeLensService(start[Prog] input) {
    PROG_EXPRESSION e = toAbstract(input.top.args[0]);
    set[PROG_EXPRESSION] globs = {ei | /ei: glob(_, _, _) := e};
    set[PROG_EXPRESSION] procs = {ei | /ei: proc(_, _, _) := e};
    set[PID] pids = {rk | proc(rk, _, _) <- procs};

    lrel[loc, Command] lenses = [];
    lenses += [<glob.src, generateCode(e, input.src, title = "Generate code")> | PROG_EXPRESSION glob <- globs];
    lenses += [<proc.src, generateCode(e, input.src, title = "Generate code")> | PROG_EXPRESSION proc <- procs];
    lenses += [<proc.src, simulate(e, pids, title = "Simulate all")> | PROG_EXPRESSION proc <- procs];
    lenses += [<proc.src, simulate(e, {rk}, title = "Simulate <toStr(val(rk))>")> | PROG_EXPRESSION proc: proc(rk, _, _) <- procs];
    return lenses;
}

data Command
    = simulate(PROG_EXPRESSION e, set[PID] pids)
    | generateCode(PROG_EXPRESSION e, loc file)
    ;

void executionService(simulate(PROG_EXPRESSION e, set[PID] pids)) {
    PROG_CONTEXT c = toProgContext(e);
    if ([] != analyze(c, e)) {
        Content content = plainText("Simulation aborted. Fix static errors (type checking failures), warnings (type inference failures), and infos (uninstantiated names) first.");
        showInteractiveContent(content, title = "Simulation");
        return;
    }

    PROG_STATE s = toProgState(e);
    if (state({map[PID, tuple[CHOR_STATE, CHOR_EXPRESSION]] alt}) := s) {
        alt = (rk: rk in pids ? alt[rk] : <alt[rk]<0>, skip()> | rk <- alt);
        s = state({alt});
    }

    int n = 0;
    tuple[PROG_STATE, PROG_EXPRESSION] initial = <s, e>;
    tuple[PROG_STATE, PROG_EXPRESSION] final   = initial;
    tuple[PROG_STATE, PROG_EXPRESSION] source  = <state({getOneFrom(initial<0>.alts)}), e>;
    for (int i <- [1..1000]) {
        tuple[PROG_STATE, PROG_EXPRESSION] target = reduce(source);
        if (source == target) {
            n = i;
            final = target;
            break;
        } else {
            source = <state({getOneFrom(target<0>.alts)}), e>;
            continue;
        }
    }

    str toPlainText(<PROG_STATE s, PROG_EXPRESSION e>) {
        str ret = "";

        if ({} := s.alts) {
            return "No alternatives";
        } else {
            int i = 1;
            for (alt <- s.alts) {
                ret += {_, _, *_} := s.alts ? "Alternative <i>:\n" : "";
                ret += {_, _, *_} := s.alts ? "\n" : "";
                for (/proc(rk: <r, _>, _, _) := e, /glob(r, formals, _) := e, rk in pids) {
                    ret += "  - <toStr(val(rk))>\n";
                    ret += "\n";
                    for (/formal(xData, _) := formals) {
                        ret += "      - <xData> = <toStr(alt[rk]<0>.phi[xData])>\n";
                    }
                    ret += "\n";
                }
                i += 1;
            }
        }

        return ret[..-2];
    }

    str text =
        "# Simulation
        '
        '## Initial state
        '
        '<toPlainText(initial)>
        '
        '## Final state (after <n> reductions)
        '
        '<toPlainText(final)>
        '
        '";

    Content content = plainText(text);
    showInteractiveContent(content, title = "Simulation");
}

void executionService(generateCode(PROG_EXPRESSION e, loc file)) {

    void generateFile(loc target, str s) {
        loc source = file;
        copy(source, target);
        writeFile(target, s);
    }

    loc parent = file.parent + "<file.file>.package";

    str json = icplt::core::\util::\semantics::JSON::format(toJSON(e));
    generateFile(parent + "<file.file>.json", json);

    str js = "";
    js += "jsonPath = \'<file.file>.json\';\n";
    js += "jsPath = \'<file.file>.js\';\n";
    js += "\n";
    js += "<icplt::core::\util::\semantics::JavaScript::format(toJavaScript(e))>\n";
    js += "\n";
    js += readFile(|project://1cplt-rascal/src/main/resources/main.js|);
    generateFile(parent + "<file.file>.js", js);

    str sh = "";
    sh += "npm install ajv 1\> /dev/null\n";
    sh += "node <file.file>.js\n";
    generateFile(parent + "<file.file>.sh", sh);
}

list[InlayHint] inlayHintService(start[Prog] input) {
    return inlayHintService(toAbstract(input.top.args[0]));
}

list[InlayHint] inlayHintService(PROG_EXPRESSION e) {
    return [*inlayHintService(eChor) | /proced(_, eChor) := e];
}
