const Log = require "@rose/Log"
const syntax = require "@std/syntax"
const types = require "@std/syntax/types"

export type TransformerContext = {
	tree: syntax.ParseResult,
	filepath: string,
	source: string,

	log: Log.Log,
	globals: { [string]: { value: unknown? } },
	sourcemapIndices: { [string]: string },
}

export type Transformer = (context: TransformerContext) -> types.Replacements

return nil
