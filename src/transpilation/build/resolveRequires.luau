const luau = require "@std/luau"
const path = require "@std/path"
const query = require "@std/syntax/query"
const syntax = require "@std/syntax"
const utils = require "@std/syntax/utils"
const types = require "@rose/transpilation/types"

const resolveRequires: types.Transformer = function(context: types.TransformerContext)
	return query
		.findAllFromRoot(context.tree, utils.isExprCall)
		:filter(function(call: syntax.AstExprCall): boolean
			return call.func.tag == "global" and call.func.name.text == "require"
		end)
		:replace(function(call: syntax.AstExprCall)
			const pathArgument = call.arguments[1]
			if not pathArgument or pathArgument.node.tag ~= "string" then return nil end

			const resolveSuccess, resolvedOrError =
				pcall(luau.resolveModule, pathArgument.node.token.text, context.filepath)

			if not resolveSuccess then
				context.log:atWarn(
					`Failed to resolve require path {pathArgument.node.token.text}`,
					`In {path.format(context.filepath)}:{call.location.beginLine}:`,
					tostring(resolvedOrError)
				)

				return nil
			end

			const requireRealpath = "/" .. table.concat(path.resolve(resolvedOrError).parts, "/")
			const requirePath = context.sourcemapIndices[requireRealpath]
			return if requirePath then `require {string.format("%q", requirePath)}` else nil
		end)
end

return resolveRequires
