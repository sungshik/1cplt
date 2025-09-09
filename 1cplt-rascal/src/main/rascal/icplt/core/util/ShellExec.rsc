module icplt::core::util::ShellExec

import IO;
import List;
import util::ShellExec;
import util::UUID;

// TODO: Make it work on Windows
int execAsync(str processCommand, loc workingDir = |cwd:///|, list[str] args = [], map[str, str] env = (), void() callback = void () {;}) {
    
    // Define a few locations
    loc directory = |tmp:///| + uuid().authority;
    loc begin = directory + "begin.sh";
    loc end = directory + "end.txt";
    
    // Create a script in `directory` that: (1) begins the execution of
    // `processCommand` on `args`; (2) creates a file to signal when/that the
    // execution has ended.
    writeFile(begin,
        "<processCommand> <intercalate(" ", args)>
        'touch <resolveLocation(end).path>");

    // Watch `directory` until `end` is created. Asynchronously run `callback`
    // when this happens.
    void(FileSystemChange) watcher = void(FileSystemChange e) {
        if (e.file == end) {
            unwatch(directory, false, watcher);
            callback();
        }
    };
    watch(directory, false, watcher);

    // Run the script
    return createProcess("sh", workingDir = workingDir, args = ["<resolveLocation(begin).path>"], envVars = env);
}

void main() {
    execAsync("sleep", args = ["3"], callback = void() {
        print("\nDone\nrascal\>");
    });
}
