const luau = require "@std/luau"
const path = require "@std/path"
const query = require "@std/syntax/query"
const richterm = require "@rose/batteries/richterm"
const syntax = require "@std/syntax"
const utils = require "@std/syntax/utils"

export type Globals = { [string]: { value: unknown? } }

export type TransformerContext = {
	tree: syntax.ParseResult,
	filepath: string,
	source: string,
	globals: Globals,
	sourcemapIndices: { [string]: string },
}

local function resolveRequires(context: TransformerContext)
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
				-- "ambiguous configuration file" happens when rose is cloned inside the workspace; skip silently
				if not (resolvedOrError :: string):find("ambiguous configuration file") then
					print(richterm.yellow(`! Failed to resolve require {pathArgument.node.token.text}:`))
					print(richterm.yellow(`  {resolvedOrError}`))
					print(richterm.yellow(`  in {path.format(context.filepath)}`))
				end
				return nil
			end

			const requirePath = context.sourcemapIndices[path.format(resolvedOrError)]
			return if requirePath then `require {string.format("%q", requirePath)}` else nil
		end)
end

return resolveRequires
