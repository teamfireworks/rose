-- Adapted from https://github.com/checkraisefold/warmluau/blob/8299341613adfef565a19b8ee7da25c1c66ccb10/src/ingredients/resolve_require/init.luau

const deserializeSourcemap = require "@rose/sourcemap/deserializeSourcemap"
const types = require "@rose/sourcemap/types"

local function indexSourcemap(source: string): types.Indices
	const sourcemap = deserializeSourcemap(source)
	const indices: types.Indices = {}

	const topLevelNodes = sourcemap.children
	if not topLevelNodes then return indices end

	local nodeCount = #topLevelNodes
	for index = 1, nodeCount do
		local serviceNode = topLevelNodes[index]
		serviceNode.name = `@game/{serviceNode.name}`
	end

	local cursor = 0
	while cursor < nodeCount do
		cursor += 1
		const node: types.Node = topLevelNodes[cursor]
		const nodeName = node.name

		const filePaths = node.filePaths
		if filePaths then
			for _, filePath in filePaths do
				indices[string.gsub(filePath, "\\", "/")] = nodeName
			end
		end

		const children = node.children
		if children then
			const childrenCount = #children
			for childIndex = 1, childrenCount do
				local child = children[childIndex]
				child.name = `{nodeName}/{child.name}`
			end
			table.move(children, 1, childrenCount, nodeCount + 1, topLevelNodes)
			nodeCount += childrenCount
		end
	end

	return indices
end

return indexSourcemap
