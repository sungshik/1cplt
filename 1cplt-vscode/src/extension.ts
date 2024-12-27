import * as vscode from 'vscode';
import { ParameterizedLanguageServer, VSCodeUriResolverServer, LanguageParameter } from '@usethesource/rascal-vscode-dsl-lsp-server';
import { join } from 'path';

export function activate(context: vscode.ExtensionContext) {
	const jar = `|jar+file://${context.extensionUri.path}/assets/jars/1cplt-rascal.jar!|`;

	const language = <LanguageParameter>{
		pathConfig: `pathConfig(srcs=[${jar}])`,
		name: "1CPLT",
		extensions: ["1cp"],
		mainModule: "icplt::core::prog::IDE",
		mainFunction: "languageContributor"
	};

	const server = new ParameterizedLanguageServer(
		context,
		new VSCodeUriResolverServer(false),
		context.asAbsolutePath(join('.', 'dist', 'rascal-lsp')),
		true,
		"1cplt",
		"1CPLT",
		language);

	context.subscriptions.push(server);
}

export function deactivate() {}
