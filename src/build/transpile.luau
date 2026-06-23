const richterm = require "@rose/batteries/richterm"
const resolveGlobals = require "@rose/build/transformers/resolveGlobals"
const resolveRequires = require "@rose/build/transformers/resolveRequires"
const path = require "@std/path"
const printer = require "@std/syntax/printer"
const syntax = require "@std/syntax"

export type TransformerContext = resolveGlobals.TransformerContext

const transformers = { resolveGlobals, resolveRequires }

local function transpile(context: TransformerContext): string
	local source = context.source

	for _, transformer in transformers do
		const parseSuccess, treeOrError = pcall(syntax.parse, source)
		if not parseSuccess then
			print(richterm.yellow(`! Failed to parse {path.format(context.filepath)}:`))
			print(richterm.yellow(`  {treeOrError}`))
			return source
		end

		context = table.clone(context)
		context.tree = treeOrError
		context.source = source

		source = printer.printFile(treeOrError, transformer(context))
	end

	return source
end

return transpile
