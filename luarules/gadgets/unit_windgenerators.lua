
if not gadgetHandler:IsSyncedCode() then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Wind generators",
		desc     = "adds extra wind energy income as defined in customparams.windgen",
		author   = "Floris",
		date     = "November, 2016",
		layer    = 0,
		enabled  = true -- loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- searching for units with customparam: windgen
local windDefs = {}
for udefID, ud in pairs(UnitDefs) do
	if ud.customParams ~= nil and ud.customParams.windgen ~= nil then
		windDefs[udefID] = ud.customParams.windgen
	end
end

local windmills = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetWind              = Spring.GetWind
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitIsStunned     = Spring.GetUnitIsStunned
local spAddUnitResource      = Spring.AddUnitResource
local spGetUnitPosition      = Spring.GetUnitPosition

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local heightBoost = false
local boostMaxFactor = 0.5
local boostMaxHeight = 500
if Spring.GetModOptions and Spring.GetModOptions().windheightbonus ~= nil and Spring.GetModOptions().windheightbonus then
	heightBoost = true
end


function gadget:GameFrame(n)
	if (n % 30 == 0) then
		if (next(windmills)) then
			local _, _, _, windStrength, _, _, _ = spGetWind()
			local windEnergy = 0
			for unitID, entry in pairs(windmills) do
				windEnergy = windStrength * entry[1]
				if windEnergy > entry[2] then windEnergy = entry[2] end
				local paralyzed = spGetUnitIsStunned(unitID)
				if (not paralyzed) then
					spAddUnitResource(unitID, 'energy', windEnergy)
				end
			end
		end
	end
end

function addWindUnit(unitID, unitDefID)
	local boost = 0
	if heightBoost then
		local _,y,_ = spGetUnitPosition(unitID)
		boost = (y / boostMaxHeight) * boostMaxFactor
		if boost > boostMaxFactor then
			boost = boostMaxFactor
		elseif boost < 0 then
			boost = 0
		end
	end
	windmills[unitID] = {windDefs[unitDefID]+boost, (UnitDefs[unitDefID].windGenerator * windDefs[unitDefID])}
end

function gadget:Initialize()
	-- in case a /luarules reload has been executed
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local unitDefID = spGetUnitDefID(unitID)
		if (unitDefID and windDefs[unitDefID]) then
		  addWindUnit(unitID, unitDefID)
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if (windDefs[unitDefID]) then
		addWindUnit(unitID, unitDefID)
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, unitTeam)
	if (windDefs[unitDefID]) then 
		if windmills[unitID] then
			addWindUnit(unitID, unitDefID)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (windDefs[unitDefID]) then 
		windmills[unitID] = nil
	end
end