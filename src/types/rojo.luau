const gt = require "@src/vendor/gt"

const Path = gt.build(gt.union(gt.string(), gt.table { optional = gt.string() }))

const InstanceTable = {
	["$className"] = gt.optional(gt.string()),
	["$ignoreUnknownInstances"] = gt.optional(gt.boolean()),
	["$path"] = gt.optional(Path:type()),
	["$properties"] = gt.optional(gt.anyTable()),
}

const Instance = gt.build(gt.table(InstanceTable))
InstanceTable[gt.string()] = Instance

-- Note: name and tree is required, it's optional here so it can be used for
-- workspace configuration
const Project = gt.build(gt.table {
	name = gt.optional(gt.string()),
	tree = gt.optional(Instance:type()),
	servePort = gt.optional(gt.number()),
	servePlaceIds = gt.optional(gt.array(gt.number())),
	placeId = gt.optional(gt.number()),
	gameId = gt.optional(gt.number()),
	serveAddress = gt.optional(gt.string()),
	globIgnorePaths = gt.optional(gt.array(gt.string())),
	emitLegacyScripts = gt.optional(gt.boolean()),
})

export type Path = typeof(Path:type())
export type Instance = typeof(Instance:type())
export type Project = typeof(Project:type())

return table.freeze {
	Path = Path,
	Instance = Instance,
	Project = Project,
}
