const gt = require "@rose/vendor/gt"

const RojoPath = gt.build(gt.union(gt.string(), gt.table { optional = gt.string() }))

const RojoInstanceTable = {
	["$className"] = gt.optional(gt.string()),
	["$ignoreUnknownInstances"] = gt.optional(gt.boolean()),
	["$path"] = gt.optional(RojoPath:type()),
	["$properties"] = gt.optional(gt.anyTable()),
}

const RojoInstance = gt.build(gt.table(RojoInstanceTable))
RojoInstance[gt.string()] = Instance

-- Note: name and tree is required, it's optional here so it can be used for
-- workspace configuration
const RojoProject = gt.build(gt.table {
	name = gt.optional(gt.string()),
	tree = gt.optional(RojoInstance:type()),
	servePort = gt.optional(gt.number()),
	servePlaceIds = gt.optional(gt.array(gt.number())),
	placeId = gt.optional(gt.number()),
	gameId = gt.optional(gt.number()),
	serveAddress = gt.optional(gt.string()),
	globIgnorePaths = gt.optional(gt.array(gt.string())),
	emitLegacyScripts = gt.optional(gt.boolean()),
})

const MappingSegment = gt.build(gt.table { name = gt.string(), className = gt.optional(gt.string()) })
const Mapping = gt.build(gt.array(MappingSegment:type()))

const Globals = gt.build(gt.dictionary(gt.string(), gt.table { value = gt.unknown() }))
const Profile = gt.build(gt.table { globals = gt.optional(Globals:type()) })
const Casing = gt.build(
	gt.union(gt.literal "camel", gt.literal "snake", gt.literal "pascal", gt.literal "kebab") :: "camel" | "snake" | "pascal" | "kebab"
)

const Workspace = gt.build(gt.table {
	name = gt.string(),
	members = gt.array(gt.string()),
	paths = gt.optional(gt.table {
		buildDir = gt.optional(gt.string()),
		buildProject = gt.optional(gt.string()),
		sourcemapProject = gt.optional(gt.string()),
		sourcemap = gt.optional(gt.string()),
	}),
	build = gt.table {
		globals = gt.optional(Globals:type()),
		place = gt.table {
			folderCasing = gt.optional(Casing),
			baseProject = gt.optional(RojoProject:type()),
			dirMappings = gt.dictionary(gt.string(), Mapping:type()),
		},
	},
	profiles = gt.optional(gt.dictionary(gt.string(), Profile:type())),
})

const Place = gt.build(gt.table {
	title = gt.optional(gt.string()),
	folderName = gt.optional(gt.string()),
	placeId = gt.optional(gt.string()),
	globals = gt.optional(Globals:type()),
	dependencies = gt.optional(gt.dictionary(gt.string(), gt.literal(true) :: true)),
})

const PlaceMixin = gt.build(gt.table {
	transpile = gt.optional(gt.boolean()),
	folderName = gt.optional(gt.string()),
	mapping = Mapping,
})

const LuauConfig = gt.build(gt.table {
	rose = gt.optional(gt.table {
		workspace = gt.optional(Workspace:type()),
		place = gt.optional(Place:type()),
		placeMixin = gt.optional(PlaceMixin:type()),
	}),
})

export type RojoPath = typeof(RojoPath:type())
export type RojoInstance = typeof(RojoInstance:type())
export type RojoProject = typeof(RojoProject:type())
export type MappingSegment = typeof(MappingSegment:type())
export type Mapping = typeof(Mapping:type())
export type Globals = typeof(Globals:type())
export type Profile = typeof(Profile:type())
export type Casing = typeof(Casing:type())
export type Workspace = typeof(Workspace:type())
export type Place = typeof(Place:type())
export type PlaceMixin = typeof(PlaceMixin:type())
export type LuauConfig = typeof(LuauConfig:type())

return table.freeze {
	RojoPath = RojoPath,
	RojoInstance = RojoInstance,
	RojoProject = RojoProject,
	MappingSegment = MappingSegment,
	Mapping = Mapping,
	Globals = Globals,
	Profile = Profile,
	Casing = Casing,
	Workspace = Workspace,
	Place = Place,
	PlaceMixin = PlaceMixin,
	LuauConfig = LuauConfig,
}
