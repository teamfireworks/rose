const pp = require "@rose/batteries/pp"
const types = require "@rose/transpilation/types"
const query = require "@std/syntax/query"
const syntax = require "@std/syntax"
const utils = require "@std/syntax/utils"

const resolveGlobals: types.Transformer = function(context: types.TransformerContext)
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
