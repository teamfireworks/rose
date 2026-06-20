# Rose

Next-generation Roblox monorepository toolchain.

## About Rose

Rose is an open source monorepository toolchain optimized for developing 
sprawling Roblox multiplace games with a mixture of code, assets, and
requirements.

Rose begun as an attempt to unify our monorepositories under 
[Welcome To Hell by Team Fireworks](https://welcomestohell.com).

## Overview

First, install Rose. Rokit works well:

```sh
rokit add teamfireworks/rose
```

Rose is configured through `.config.luau` files. Let's say you have this
repository:

```
roblox_packages      (Yes, you can bring your own package manager)
workspace/core       (Core game logic)
workspace/spawn      (Spawn place with a title screen)
workspace/chapter    (Shared logic for your games chapters, or areas, or whatev)
workspace/chapter1   (and etc)
.config.luau
rokit.toml
pesde.toml
```


Create a `.config.luau` for the root of your repository:

```luau
-- .config.luau

-- This region will be replaced with Rose's require aliases.
-- #region rose-aliases
const aliases = {}
-- #endregion

return {
	luau = {
		languagemode = "strict",
		lint = { ["*"] = true },

		-- You can write your own require aliases, or include Rose's generated
		-- require aliases here:
		aliases = aliases,
	},
	rose = {
		workspace = {
			-- Globs to search for `.config.luau`s
			members = { "./workspace/*" },

			-- Base output directory
			output = ".output",
			
			-- Rojo configuration
			rojo = {
				-- Paths to output Rojo project files.
				-- The following are defaults:
				outputProject = "default.project.json",
				sourcemapProject = "sourcemap.project.json",
				sourcemap = "sourcemap.json",
				
				-- Mappings of directories in a workspace place to it's
				-- Rojo parent. 
				-- 
				-- Path components can specify the key (name), alongside it's
				-- className and whether to ignoreUnknownInstances. These will
				-- be used to build out Rojo projects.
				-- 
				-- This is an excerpt from our Welcome To Hell:
				placeMappings = {
					client = {
						{ name = "ReplicatedStorage" },
						{ name = "Internal", className = "Folder" },
						{ name = "Client", className = "Folder" },
					},
					server = {
						{ name = "ServerScriptService" },
						{ name = "Internal", className = "Folder" },
						{ name = "Server", className = "Folder" },
					},
					shared = {
						{ name = "ReplicatedStorage" },
						{ name = "Internal", className = "Folder" },
						{ name = "Shared", className = "Folder" },
					},
					ui = {
						{ name = "ReplicatedStorage" },
						{ name = "Internal", className = "Folder" },
						{ name = "UI", className = "Folder" },
					},
				},

				-- Base tree for all workspace places to inherit.
				-- This is where you can set shared properties like R6 or
				-- server authority.
				placeTree = {
					["$className"] = "DataModel",
					Workspace = {
						["$properties"] = {}
					}
				}
			},

			-- Build configuration
			build = {
				-- Globals to be injected under _G.
				-- A few additional globals are injected by Rose:
				-- 
				-- * __DEV__: Whether the place is being built with `rose dev`
				-- * ROSE_DIR_NAME: Directory name of the current place
				-- * ROSE_PLACE_FOLDER: Rojo folder name of the current place
				-- * ROSE_PLACE_TITLE: Rojo place name of the current place
				-- * ROSE_PLACE_SUBTITLE: Subtitle of the current place or nil
				-- 
				-- You can specify additional globals to be shared here, or in
				-- developer profiles.
				globals = {
					DEV = {}
				}
			}

			-- Developer profiles. Your team members should each have a profile
			-- for themselves and set it using `rose profile [profilename]`
			profiles = {
				godmothersfire = {
					-- 
				}
			}
		}
	}
}
```

### "What about XYZ package manager?"

Write a `.config.luau` for your packages directory. Seriously.

```luau
-- roblox_packages/.config.luau
return {
	rose = {
		placeMixin = {
			folderName = "Packages",
			rojo = {
				{ name = "ReplicatedStorage" },
			},
		}
	}
}
```

You may need to configure your `.gitignore` to track the `.config.luau`:

```gitignore
roblox_packages/*
!roblox_packages/.config.luau
```

It looks ridiculous but it works in practice.
