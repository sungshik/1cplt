module icplt::core::\prog::IDE

import Map;
import Message;
import ParseTree;
import Set;
import util::IDEServices;
import util::LanguageServer;
import util::Maybe;
import util::Reflective;

import icplt::core::\chor::IDE;
import icplt::core::\chor::\syntax::Abstract;
import icplt::core::\chor::\semantics::Static;
import icplt::core::\chor::\semantics::Dynamic;
import icplt::core::\prog::\syntax::Abstract;
import icplt::core::\prog::\syntax::Concrete;
import icplt::core::\prog::\semantics::Static;
import icplt::core::\prog::\semantics::Dynamic;

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
    set[PROG_EXPRESSION] procs = {toAbstract(process) | /process: (Process) _ := input};
    set[PID] pids = {rk | proc(rk, _, _) <- procs};

    lrel[loc, Command] lenses = [];
    lenses += [<proc.src, simulate(toAbstract(input.top.args[0]), pids, title = "Simulate all")> | PROG_EXPRESSION proc <- procs];
    lenses += [<proc.src, simulate(toAbstract(input.top.args[0]), {rk}, title = "Simulate <toStr(val(rk))>")> | PROG_EXPRESSION proc: proc(rk, _, _) <- procs];
    return lenses;
}

data Command
    = simulate(PROG_EXPRESSION e, set[PID] pids)
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

list[InlayHint] inlayHintService(start[Prog] input) {
    return inlayHintService(toAbstract(input.top.args[0]));
}

list[InlayHint] inlayHintService(PROG_EXPRESSION e) {
    return [*inlayHintService(eChor) | /proced(_, eChor) := e];
}
