const types = require "@rose/transpilation/types"

const BUILD_TRANSFORMERS: { types.Transformer } = {
	require "@rose/transpilation/build/resolveGlobals",
	require "@rose/transpilation/build/resolveRequires",
}

const SOURCE_TRANSFORMERS: { types.Transformer } = {}

return table.freeze {
	BUILD_TRANSFORMERS = BUILD_TRANSFORMERS,
	SOURCE_TRANSFORMERS = SOURCE_TRANSFORMERS,
}
