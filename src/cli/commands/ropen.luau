const Command = require "@rose/cli/Command"
const openStudio = require "@rose/openStudio"
const assertWorkspace = require "@rose/workspace/assertWorkspace"
const assertWorkspacePlace = require "@rose/workspace/assertWorkspacePlace"

const ropen = Command.new { help = "Opens the given workspace member or place ID in Roblox Studio" }
ropen.args:add("place", "positional", { help = "Place name or ID to open", required = true })

function ropen.onRun()
	const place = ropen.args:get "place" :: string

	const placeId = tonumber(place)
	if placeId then return openStudio(placeId) end

	const workspace = assertWorkspace()
	const memberPlace = assertWorkspacePlace(workspace, place)
	const memberPlaceId = memberPlace.placeId or error(`workspace member {place} is missing it's rose.place.placeId`)

	openStudio(memberPlaceId)
end

return ropen
