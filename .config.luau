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
			src = "src",
			batteries = "src/batteries",
		},
	},
}
