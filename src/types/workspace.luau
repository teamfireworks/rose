const rojo = require "@src/types/rojo"
const gt = require "@src/vendor/gt"

const MappingSegment = gt.build(gt.table { name = gt.string(), className = gt.optional(gt.string()) })
const Mapping = gt.build(gt.array(MappingSegment:type()))

const Globals = gt.build(gt.dictionary(gt.string(), gt.table { value = gt.unknown() }))
const Profile = gt.build(gt.table { globals = Globals:type() })
const Casing = gt.build(
	gt.union(gt.literal "camel", gt.literal "snake", gt.literal "pascal", gt.literal "kebab") :: "camel" | "snake" | "pascal" | "kebab"
)

const Workspace = gt.build(gt.table {
	name = gt.string(),
	members = gt.string(),
	paths = gt.table {
		buildDir = gt.optional(gt.string()),
		buildProject = gt.optional(gt.string()),
		sourcemapProject = gt.optional(gt.string()),
		sourcemap = gt.optional(gt.string()),
	},
	build = gt.table {
		globals = Globals:type(),
		place = gt.table {
			folderCasing = gt.optional(Casing),
			baseProject = gt.optional(rojo.Project:type()),
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

const LuauConfiguration = gt.build(gt.table {
	rose = gt.table {
		workspace = Workspace:type(),
		place = Place:type(),
		placeMixin = PlaceMixin:type(),
	},
})

export type MappingSegment = typeof(MappingSegment:type())
export type Mapping = typeof(Mapping:type())
export type Globals = typeof(Globals:type())
export type Profile = typeof(Profile:type())
export type Casing = typeof(Casing:type())
export type Workspace = typeof(Workspace:type())
export type Place = typeof(Place:type())
export type PlaceMixin = typeof(PlaceMixin:type())
export type LuauConfiguration = typeof(LuauConfiguration:type())

return table.freeze {
	MappingSegment = MappingSegment,
	Mapping = Mapping,
	Globals = Globals,
	Profile = Profile,
	Casing = Casing,
	Workspace = Workspace,
	Place = Place,
	PlaceMixin = PlaceMixin,
	LuauConfiguration = LuauConfiguration,
}
