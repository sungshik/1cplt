module icplt::core::Main

import util::LanguageServer;

import icplt::core::\prog::IDE;

void main() {
    Language lang = language()[name = "1CPLT"][extensions = {"1cp"}];
    icplt::core::\prog::IDE::register(lang = lang);
}
