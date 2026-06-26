-- too lazy to fix rn
--!nonstrict

const configuration = require "@rose/configuration"
const path = require "@std/path"

const function insertMapping(
	tree: configuration.RojoInstance,
	segments: { configuration.MappingSegment },
	sourceName: string?,
	sourcePath: path.Pathlike?
)
	local current = tree
	for _, segment in segments do
		if not current[segment.name] then current[segment.name] = {} end

		current = current[segment.name]

		if segment.className then current["$className"] = segment.className end
	end

	if sourceName and sourcePath then
		if not current[sourceName] then current[sourceName] = {} end

		current = current[sourceName]

		current["$path"] = {
			optional = path.format(sourcePath),
		}
	end
end

return insertMapping
