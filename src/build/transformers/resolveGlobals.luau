const pp = require "@rose/batteries/pp"
const query = require "@std/syntax/query"
const syntax = require "@std/syntax"
const utils = require "@std/syntax/utils"

export type Globals = { [string]: { value: unknown? } }

export type TransformerContext = {
	tree: syntax.ParseResult?,
	filepath: string,
	source: string,
	globals: Globals,
	sourcemapIndices: { [string]: string },
}

local function resolveGlobals(context: TransformerContext)
	return query
		.findAllFromRoot(context.tree, utils.isExprIndexName)
		:filter(function(expression: syntax.AstExprIndexName): boolean
			return expression.expression.tag == "global" and expression.expression.name.text == "_G"
		end)
		:replace(function(expression: syntax.AstExprIndexName)
			const globalKey = expression.index.text
			const globalEntry = context.globals[globalKey]
			return if globalEntry == nil then nil else pp(globalEntry.value)
		end)
end

return resolveGlobals
