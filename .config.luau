return {
	luau = {
		languagemode = "strict",
		lint = { ["*"] = true },
		aliases = {
			-- Lute
			std = "~/.lute/typedefs/1.0.0/std",
			lute = "~/.lute/typedefs/1.0.0/lute",
			lint = "~/.lute/typedefs/1.0.0/lint",
			-- Rose
			rose = "src",
			-- WTH workspace aliases — mirrors the root .config.luau so that
			-- luau.resolveModule doesn't error with "ambiguous configuration file"
			-- when called on workspace source files from inside the rose directory.
			chapter = "../workspace/chapter",
			chapter1 = "../workspace/chapter1",
			chapter2 = "../workspace/chapter2",
			chapter3 = "../workspace/chapter3",
			chapter4 = "../workspace/chapter4",
			chapter5 = "../workspace/chapter5",
			chapter6 = "../workspace/chapter6",
			chapter7 = "../workspace/chapter7",
			core = "../workspace/core",
			kit = "../workspace/kit",
			libs = "../workspace/libs",
			title = "../workspace/title",
			universe = "../workspace/universe",
			pkgs = "../roblox_packages",
			serverpkgs = "../roblox_server_packages",
		},
	},
}
