const types = require "@rose/transpilation/types"
const path = require "@std/path"
const printer = require "@std/syntax/printer"
const syntax = require "@std/syntax"

const function transpile(transformers: { types.Transformer }, context: types.TransformerContext): string
	local source = context.source

	for _, transformer in transformers do
		const parseSuccess, treeOrError = pcall(syntax.parse, source)

		if not parseSuccess then
			context.log:atWarn(`Failed to parse {path.format(context.filepath)}:`, tostring(treeOrError))
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
