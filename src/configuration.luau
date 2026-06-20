export type RojoMappingNode = {
	name: string,
	className: string?,
	ignoreUnknownInstances: boolean?,
}

export type RojoPath = string | { optional: string }

export type RojoNode = {
	["$className"]: string?,
	["$ignoreUnknownInstances"]: boolean?,
	["$path"]: RojoPath?,
	["$properties"]: { [string]: unknown }?,
	[string]: RojoNode,
}

export type WorkspaceConfiguration = {
	name: string,
	members: { string }?,

	rojo: {
		placeMappings: { [string]: { RojoMappingNode } },
		placeBase: RojoNode,
	},
}

const function castIntoRoot() end
