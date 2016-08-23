--CONSTANTS
local MS = 1/1000000
local KS = 1/1000

local TRACKED_DAMAGE = {
  SWING_DAMAGE = true,
  RANGE_DAMAGE = true,
  SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
  SPELL_BUILDING_DAMAGE = true,
  DAMAGE_SHIELD = true,
  DAMAGE_SPLIT = true,
  DAMAGE_SPLIT = true,
}

local TRACKED_HEAL = {
  SWING_HEAL = true,
  RANGE_HEAL = true,
  SPELL_HEAL = true,
  SPELL_PERIODIC_HEAL = true,
  SPELL_BUILDING_HEAL = true,
}

local TRACKED_DISPEL = {
  SPELL_DISPEL = true,
}


local TRACKED_INTERRUPT = {
  SPELL_INTERRUPT = true,
}

local TRACKED_SUMMONS = {
  SPELL_SUMMON = true,
  SPELL_CREATE = true,
}



local CLASS_COLORS = {
  DEATHKNIGHT = {r=0.77, g=0.12, b=0.23}, 
  DEMONHUNTER = {r=0.64, g=0.19, b=0.79}, 
  DRUID = {r=1.00, g=0.49, b=0.04}, 
  HUNTER = {r=0.67, g=0.83, b=0.45}, 
  MAGE = {r=0.41, g=0.80, b=0.94}, 
  MONK = {r=0.00, g=1.00, b=0.59}, 
  PALADIN = {r=0.96, g=0.55, b=0.73}, 
  PRIEST = {r=1.00, g=1.00, b=1.00}, 
  ROGUE = {r=1.00, g=0.96, b=0.41}, 
  SHAMAN = {r=0.00, g=0.44, b=0.87}, 
  WARLOCK = {r=0.58, g=0.51, b=0.79}, 
  WARRIOR = {r=0.78, g=0.61, b=0.43}, 
}

local DEFAULT_COLORS = {
  {r=0.2, g=0.2, b=0.2}, 
  {r=0.4, g=0.4, b=0.4}, 
}
local DAMAGE = "Damage"
local TARGETS = "Targets"
local SPELLS = "Spells"
local FRIEND = "Friend Fire"
local SOURCE = "Source"
local HEAL = "Healing"
local DISPEL = "Dispel"
local INTERRUPT = "Interrupt"


local REFRESH_FREQ = 1.0

local MAIN_PREV = "KurecountPrevButton"
local MAIN_NEXT = "KurecountNextButton"
local MAIN_CLOSE = "KurecountClose"
local MAIN_ROW = "KurecountScrollFrameChildItem"
local MAIN_MENU_TEXT = "KurecountHeaderFrameMenuText"
local MAIN_TARGET_TEXT = "KurecountHeaderFrameTargetText"

local DETAILS_PREV = "KurecountDetailsPrevButton"
local DETAILS_NEXT = "KurecountDetailsNextButton"
local DETAILS_CLOSE = "KurecountDetailsClose"
local DETAILS_ROW = "KurecountDetailsScrollFrameChildItem"
local DETAILS_MENU_TEXT = "KurecountDetailsHeaderFrameMenuText"
local DETAILS_TARGET_TEXT = "KurecountDetailsHeaderFrameTargetText"


--DATA TABLES
local MAIN_FRAME_OPTIONS = {DAMAGE, TARGETS, FRIEND, HEAL, DISPEL, INTERRUPT}
local DETAILS_FRAME_OPTIONS = {
[DAMAGE] = {SPELLS, TARGETS}, 
[TARGETS] = {SOURCE},
[FRIEND] = {TARGETS, SPELLS},
[HEAL] = {TARGETS, SPELLS},
[DISPEL] = {TARGETS},
[INTERRUPT] = {TARGETS},
}

function Kurecount_OnLoad(self)
  
  self:RegisterForDrag("LeftButton");
  self:RegisterEvent("RAID_ROSTER_UPDATE")
  self:RegisterEvent("GROUP_ROSTER_UPDATE")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("ENCOUNTER_START")
  self:RegisterEvent("ENCOUNTER_END")
  self:RegisterEvent("ADDON_LOADED")
  
  --Kurecount_HideRows()
  getglobal(MAIN_PREV):SetScript("OnClick", Kurecount_prevMainFrame)
  getglobal(MAIN_PREV):SetScale(0.7)
  getglobal(MAIN_NEXT):SetScript("OnClick", Kurecount_nextMainFrame)
  getglobal(MAIN_NEXT):SetScale(0.7)
  getglobal(MAIN_CLOSE):SetScale(0.8)
  --getglobal(MAIN_MENU_TEXT):SetText(MAIN_FRAME_OPTIONS[kure_main_option+1])
 
  for i = 1, 40 do
	local row = getglobal(MAIN_ROW..i)
	row:SetScript("OnMouseUp", Kurecount_OpenDetails)
  end
  
end


function KurecountDetails_OnLoad(self)
	self:RegisterForDrag("LeftButton");
	getglobal(DETAILS_PREV):SetScript("OnClick", Kurecount_prevDetailsFrame)
	getglobal(DETAILS_PREV):SetScale(0.7)
    getglobal(DETAILS_NEXT):SetScript("OnClick", Kurecount_nextDetailsFrame)
	getglobal(DETAILS_NEXT):SetScale(0.7)
    getglobal(DETAILS_CLOSE):SetScale(0.8)
    --getglobal(DETAILS_MENU_TEXT):SetText(DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_main_option+1][kure_details_option+1]])
	self:Hide()
end


--self = selected row
function Kurecount_OpenDetails(self)
	kure_selected_guid = self.id
	if kure_selected_main_option ~= kure_main_option then
		kure_selected_main_option = kure_main_option
		kure_details_option = 0
		local text = getglobal(DETAILS_MENU_TEXT)
		text:SetText(DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][1])	
	end
	Kurecount_UpdateDetails()
	getglobal("KurecountDetails"):Show()
end


function Kurecount_SessionAssignments()
	Kurecount_TablesAssignments()
	Kurecount_UpdatePlayersInfo()
	kure_main_option = 0
	kure_details_option = 0
	kure_selected_main_option = 0
	kure_refresh_counter = 0
	kure_session = true
end 

function Kurecount_TablesAssignments()
	kure_party_damage = kure_party_damage or {}
    kure_party_spells = kure_party_spells or {}
    kure_party_targets = kure_party_targets or {}
    kure_target_damage = kure_target_damage or {}
    kure_target_source = kure_target_source or {}
    kure_friend_damage = kure_friend_damage or {}
    kure_friend_targets = kure_friend_targets or {}
    kure_friend_spells = kure_friend_spells or {}
    kure_heal = kure_heal or {}
    kure_heal_spells = kure_heal_spells or {}
    kure_heal_targets = kure_heal_targets or {}
	kure_dispel = kure_dispel or {}
    kure_dispel_targets = kure_dispel_targets or {}
	kure_interrupt = kure_interrupt or {}
    kure_interrupt_targets = kure_interrupt_targets or {}
	
	


	MAIN_DATA_TABLES = {[DAMAGE] = kure_party_damage, [TARGETS] = kure_target_damage, [FRIEND] = kure_friend_damage, [HEAL] = kure_heal, [DISPEL] = kure_dispel, [INTERRUPT] = kure_interrupt}
	DETAILS_DATA_TABLES = {
		[DAMAGE] = {[SPELLS] = kure_party_spells, 
					[TARGETS] = kure_party_targets}, 
					
		[TARGETS] = {[SOURCE] = kure_target_source}, 
		
		[FRIEND] = {[TARGETS] = kure_friend_targets, 
					[SPELLS] = kure_friend_spells}, 
					
		[HEAL] = {[TARGETS] = kure_heal_targets, 
					[SPELLS] = kure_heal_spells}, 
					
		[DISPEL] = {[TARGETS] = kure_dispel_targets, 
					},
					
		[INTERRUPT] = {[TARGETS] = kure_interrupt_targets, 
					},
	}
end

function Kurecount_ResetValues()
  kure_party_damage = {}
  kure_party_spells = {}
  kure_party_targets = {}
  kure_target_damage = {}
  kure_target_source = {}
  kure_friend_damage = {}
  kure_friend_targets = {}
  kure_friend_spells = {}
  kure_heal = {}
  kure_heal_spells = {}
  kure_heal_targets = {}
  kure_player_info = {}
  kure_pet_info = {}
  kure_dispel = {}
  kure_dispel_targets = {}
  kure_interrupt = {}
  kure_interrupt_targets = {}
  Kurecount_TablesAssignments()
  
  kure_target = nil
  kure_combat_start = nil
  kure_combat_end = nil
  kure_combat_time = 0
  kure_refresh_counter = 0
  
  Kurecount_UpdatePlayersInfo()
  Kurecount_UpdatePets()
end

function Kurecount_Init()
    kure_main_option = 0
	kure_details_option = 0
	kure_selected_main_option = 0
	Kurecount_ResetValues()	
	kure_initialized = true
end



function Kurecount_OnUpdate(self, elapsed)
	if not kure_initialized then 
		Kurecount_Init()
	end 
  
	if kure_is_on_combat then
	  kure_refresh_counter = kure_refresh_counter + elapsed
	  if kure_refresh_counter >= REFRESH_FREQ then
		kure_refresh_counter = 0
		Kurecount_UpdateFrames()
	  end
	end
end

function Kurecount_OnEvent(self, event, ...)
  	
  if event == "ADDON_LOADED" then
	if not kure_initialized then 
		Kurecount_Init()
	end 
	Kurecount_SessionAssignments()
	Kurecount_UpdateFrames()
	
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local srcFlags = select(6, ...)
    if bit.band(srcFlags, bit.bor(COMBATLOG_OBJECT_AFFILIATION_RAID, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_MINE)) > 0 then
      Kurecount_TrackCombatLog(...)
    end
	

  elseif event == "RAID_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
    Kurecount_UpdatePlayersInfo()
    Kurecount_UpdatePets()

	
  elseif event == "ENCOUNTER_START" or event == "PLAYER_REGEN_DISABLED" then
	Kurecount_ResetValues()
	kure_is_on_combat = true
	kure_combat_start = GetServerTime()
	kure_target = select(2, ...)
	Kurecount_UpdateFrames()

  elseif event == "ENCOUNTER_END" or event == "PLAYER_REGEN_ENABLED" then
    kure_is_on_combat = false
	kure_combat_end = GetServerTime()
	kure_combat_time = kure_combat_end - kure_combat_start
	Kurecount_UpdateFrames()
  end
	
  
end

function Kurecount_UpdatePlayersInfo()
  Kurecount_UpdatePlayerInfoUnit("player")
  for i = 1, 40 do
    Kurecount_UpdatePlayerInfoUnit("raid"..i)
  end
  for i = 1, 4 do
    Kurecount_UpdatePlayerInfoUnit("party"..i)
  end
  
end

function Kurecount_UpdatePlayerInfoUnit(unit)
  if unit and UnitExists(unit) then
    local guid = UnitGUID(unit)
    Kurecount_UpdatePlayerInfoGuid(guid)
  end
end

function Kurecount_UpdatePlayerInfoGuid(guid)
	local class, classFilename, race, raceFilename, sex, name, realm = GetPlayerInfoByGUID(guid)
	kure_player_info[guid] = {class = class, classFilename = classFilename, race = race, raceFilename = raceFilename, sex = sex, name = name, realm = realm}
end 


function compareByValueDesc(a,b)
  return a.value > b.value
end


function getPetOwner(srcGUID)
	if kure_pet_info[srcGUID] == nil then
	  Kurecount_UpdatePets()
	  Kurecount_UpdatePlayersInfo()
	  if kure_pet_info[srcGUID] == nil then
		return nil
	  end
    end
    return kure_pet_info[srcGUID].ownerGuid
end 


function Kurecount_UpdateDetailsTable(tableVar, id, petId, subId, amount)
	local updated = false
	if tableVar[id] then
		tableVar[id].value = tableVar[id].value + amount
		
		for i, elem in ipairs(tableVar[id].data) do
			if elem.id == petId then 
				elem.value = elem.value + amount
				for j, subelem in ipairs(elem.data) do
					if subelem.id == subId then 
						subelem.value = subelem.value + amount
						subelem.maxval = max(subelem.maxval, amount)
						subelem.minval = min(subelem.minval, amount)
						subelem.media = (amount + subelem.media*subelem.count)/(subelem.count + 1)
						subelem.count = subelem.count + 1
						updated = true
						table.sort(elem.data, compareByValueDesc)
						break
					end
				end
				if not updated then
					table.insert(elem.data, {id = subId, value = amount, count = 1, maxval = amount, minval = amount, media = amount})
					table.sort(elem.data, compareByValueDesc)
					updated = true
				end
			end
		end
		if not updated then
			table.insert(tableVar[id].data,{id = petId, value = amount, data={{id = subId, value = amount, count = 1, maxval = amount, minval = amount, media = amount}}})
		end
	else
		tableVar[id] = {value = amount, data = {{id = petId, value = amount, data={{id = subId, value = amount, count = 1, maxval = amount, minval = amount, media = amount}}}}}
	end
	table.sort(tableVar[id].data, compareByValueDesc)
end

function Kurecount_UpdateMainTable(tableVar, id, amount)
	
	local updated = false
	
	for i,elem in ipairs(tableVar) do
		if elem.id == id then
			elem.value = elem.value + amount
			updated = true
			break
		end
	end
	if not updated then
		table.insert(tableVar, {id = id, value = amount})
	end
	table.sort(tableVar, compareByValueDesc)
end


function Kurecount_GetTotalValue(tableVar)
	local result = 0
	for i,elem in ipairs(tableVar) do
		result = result + elem.value
	end
	return result
end


function Kurecount_UpdateDamageAmount(srcGUID, srcName, srcFlags, amount, destGUID, destName, destFlags, spellName)

  local ownerGUID = srcGUID
  
  -- if source is guardian, object or pet: change guid to owner's
  if bit.band(srcFlags, bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_PET)) >0 then
    if not getPetOwner(srcGUID)then 
		return
	end
	ownerGUID = getPetOwner(srcGUID)
	-- if spellName then
		-- spellName = spellName.." <"..srcName..">"
	-- end
  end
  
  local name = kure_player_info[ownerGUID].name
  
  if kure_player_info[destGUID] then
	-- friend fire
	Kurecount_UpdateMainTable(kure_friend_damage, ownerGUID, amount)
	Kurecount_UpdateDetailsTable(kure_friend_targets, ownerGUID, destName, srcName, amount)
	Kurecount_UpdateDetailsTable(kure_friend_spells, ownerGUID, srcName, spellName, amount)
  else
	-- damage
	Kurecount_UpdateMainTable(kure_party_damage, ownerGUID, amount)
	Kurecount_UpdateDetailsTable(kure_party_targets, ownerGUID, destName, srcName, amount)
	Kurecount_UpdateDetailsTable(kure_party_spells, ownerGUID, srcName, spellName, amount)
	
	Kurecount_UpdateMainTable(kure_target_damage, destName, amount)
	Kurecount_UpdateDetailsTable(kure_target_source, destName, destName, ownerGUID, amount)
  end
end

function Kurecount_UpdateHealAmount(srcGUID, srcName, srcFlags, amount, overhealing, absorbed, destGUID, destName, destFlags, spellName)

  local ownerGUID = srcGUID
  
  -- if source is guardian, object or pet: change guid to owner's
  if bit.band(srcFlags, bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_PET)) >0 then
    if not getPetOwner(srcGUID)then 
		return
	end
	ownerGUID = getPetOwner(srcGUID)
  end
  
  local name = kure_player_info[ownerGUID].name
  
  if kure_player_info[destGUID] and amount ~= overhealing then
	-- healing
	Kurecount_UpdateMainTable(kure_heal, ownerGUID, amount-overhealing)
	Kurecount_UpdateDetailsTable(kure_heal_targets, ownerGUID, srcName, destGUID, amount-overhealing)
	Kurecount_UpdateDetailsTable(kure_heal_spells, ownerGUID, srcName, spellName, amount-overhealing)
  end
end

function Kurecount_UpdateInterrupt(srcGUID, srcName, srcFlags, destName, destFlags, spellName, extraSpellName)
	Kurecount_UpdateMainTable(kure_interrupt, srcGUID, 1)
	Kurecount_UpdateDetailsTable(kure_interrupt_targets, srcGUID, destName, extraSpellName, 1)
end

function Kurecount_UpdateDispel(srcGUID, srcName, srcFlags, destName, destFlags, spellName, extraSpellName)
	Kurecount_UpdateMainTable(kure_dispel, srcGUID, 1)
	Kurecount_UpdateDetailsTable(kure_dispel_targets, srcGUID, destName, extraSpellName, 1)
end


function Kurecount_UpdatePets()
  Kurecount_UpdatePetUnit("pet", "player")
  for i = 1, 40 do
    Kurecount_UpdatePetUnit("raidpet"..i, "raid"..i)
  end
  for i = 1, 4 do
    Kurecount_UpdatePetUnit("partypet"..i, "party"..i)
  end
end

function Kurecount_UpdatePetUnit(petUnit, ownerUnit)
  if petUnit and UnitExists(petUnit) then
    local guid = UnitGUID(ownerUnit)
    local petGUID = UnitGUID(petUnit)
    local petName = GetUnitName(petUnit, false)
    kure_pet_info[petGUID] = {name = petName, ownerGuid = guid}
  end
end

function Kurecount_TrackCombatLog(timestamp, combatEvent, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
  
  if TRACKED_SUMMONS[combatEvent] then
    kure_pet_info[destGUID] = {name = destName, ownerGuid = srcGUID}
	
  elseif TRACKED_DAMAGE[combatEvent] then
    if srcGUID == "" then
		return
	end
	-- if the kure_target is a pet ignore it (for mages)
	if kure_pet_info[destGUID] then
		return
	end
	
	local offset = 4
	local spellName
    if (combatEvent == "SWING_DAMAGE") then
      offset = 1
	  spellName = "Melee"
    else
      spellName = select(2, ...)
    end

	local amount, overkill, school, resisted, blocked, absorbed = select(offset, ...)
    Kurecount_UpdateDamageAmount(srcGUID, srcName, srcFlags, amount, destGUID, destName, destFlags, spellName)
    
	kure_target = kure_target or destName
    
  
  
  elseif TRACKED_HEAL[combatEvent] and kure_is_on_combat then
    if srcGUID == "" then
		return
	end
	local spellName = select(2, ...)
    local amount, overhealing, absorbed = select(4, ...)
    Kurecount_UpdateHealAmount(srcGUID, srcName, srcFlags, amount, overhealing, absorbed, destGUID, destName, destFlags, spellName)
    
  elseif TRACKED_DISPEL[combatEvent] and kure_is_on_combat then
    if srcGUID == "" then
		return
	end
	local spellName = select(2, ...)
    local extraSpellId, extraSpellName = select(4, ...)
    Kurecount_UpdateDispel(srcGUID, srcName, srcFlags, destName, destFlags, spellName, extraSpellName)
 	
  
  elseif TRACKED_INTERRUPT[combatEvent] and kure_is_on_combat then
    if srcGUID == "" then
		return
	end
	local spellName = select(2, ...)
    local extraSpellId, extraSpellName = select(4, ...)
	Kurecount_UpdateInterrupt(srcGUID, srcName, srcFlags, destName, destFlags, spellName, extraSpellName)
 	
  end
  
end


function Kurecount_prevMainFrame()
	kure_main_option = (kure_main_option - 1) % #MAIN_FRAME_OPTIONS
	local text = getglobal(MAIN_MENU_TEXT)
	text:SetText(MAIN_FRAME_OPTIONS[kure_main_option + 1])	
	Kurecount_UpdateFrames()
end

function Kurecount_nextMainFrame()
	kure_main_option = (kure_main_option + 1) % #MAIN_FRAME_OPTIONS
	local text = getglobal(MAIN_MENU_TEXT)
	text:SetText(MAIN_FRAME_OPTIONS[kure_main_option + 1])
	Kurecount_UpdateFrames()	
end

function Kurecount_prevDetailsFrame()
	kure_details_option = (kure_details_option - 1) % #DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]]
	local text = getglobal(DETAILS_MENU_TEXT)
	text:SetText(DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][kure_details_option + 1])	
	Kurecount_UpdateFrames()
end

function Kurecount_nextDetailsFrame()
	kure_details_option = (kure_details_option + 1) % #DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]]
	local text = getglobal(DETAILS_MENU_TEXT)
	text:SetText(DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][kure_details_option + 1])	
	Kurecount_UpdateFrames()
end

function Kurecount_UpdateFrames()
  if not kure_session then 
		return
  end 

  if not kure_initialized then 
		return
  end 
  
  if #kure_party_damage == 0 then 
    return
  end
  
  Kurecount_UpdateMain()
  Kurecount_UpdateDetails()
end

function Kurecount_UpdateMain()
	if kure_is_on_combat then 
		getglobal(MAIN_TARGET_TEXT):SetText(kure_target.." ("..date("!%X",kure_combat_start)..")")
	elseif kure_target then
		getglobal(MAIN_TARGET_TEXT):SetText(kure_target.." ("..date("!%X",kure_combat_start).." - "..date("!%X",kure_combat_end)..")")
	else
		getglobal(MAIN_TARGET_TEXT):SetText("KURECOUNT")
	end
	getglobal(MAIN_MENU_TEXT):SetText(MAIN_FRAME_OPTIONS[kure_main_option+1])
	tableVar = MAIN_DATA_TABLES[MAIN_FRAME_OPTIONS[kure_main_option + 1]]
	for i, v in ipairs(tableVar) do
		Kurecount_UpdateMainFrame(tableVar, i)
	end
	Kurecount_HideRowsMainFrame(#tableVar + 1, 40)		
end





function Kurecount_HideRowsMainFrame(init_idx, end_idx)
	for i = init_idx, end_idx do
		local row = getglobal(MAIN_ROW..i)
		row:Hide()
	end
end

function Kurecount_HideRowsDetailsFrame(init_idx, end_idx)
	for i = init_idx, end_idx do
		local row = getglobal(DETAILS_ROW..i)
		row:Hide()
	end
end

function Kurecount_UpdateDetails()
	getglobal(DETAILS_MENU_TEXT):SetText(DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][kure_details_option + 1])	
	if not kure_selected_guid then return end
	tableDetails = DETAILS_DATA_TABLES[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][DETAILS_FRAME_OPTIONS[MAIN_FRAME_OPTIONS[kure_selected_main_option + 1]][kure_details_option+1]]
	if 	kure_player_info[kure_selected_guid] then 
		getglobal(DETAILS_TARGET_TEXT):SetFormattedText("Details: %s", kure_player_info[kure_selected_guid].name)
	else
		getglobal(DETAILS_TARGET_TEXT):SetFormattedText("Details: %s", kure_selected_guid)
	end
	Kurecount_UpdateDetailsDamage(tableDetails)
	
end

function Kurecount_ShowDetailsFrameButtons()
	getglobal(DETAILS_MENU_TEXT):Show()
	getglobal(DETAILS_PREV):Show()
	getglobal(DETAILS_NEXT):Show()
end

function Kurecount_HideDetailsFrameButtons()
	getglobal(DETAILS_MENU_TEXT):Hide()
	getglobal(DETAILS_PREV):Hide()
	getglobal(DETAILS_NEXT):Hide()		
end


function Kurecount_UpdateDetailsDamage(damageTable)
	if not damageTable[kure_selected_guid] then return end
	local maxDamage1 = 0
	local rowIdx = 1
	local total = damageTable[kure_selected_guid].value
	for j, w in ipairs(damageTable[kure_selected_guid].data) do
		
		if j==1 then maxDamage1 = w.value end
		
		local percentRowLength = w.value / maxDamage1
		--local percentRowLength = 1
		local percenttext = PercentageNum(w.value / total)
		local name = w.id
		local color = {r=0, g=0, b=1}
		local textName = string.format("%d. %s", j, name)
		local textDamage = string.format("%s (%s)", ShortNum(w.value), percenttext)
		Kurecount_FillRowFrame(DETAILS_ROW..rowIdx, w.id, textName, textDamage, color, percentRowLength)
		
		rowIdx = rowIdx+1
		if rowIdx > 40 then 
			return
		end
		
		if #w.data > 0 then 
			local maxDamage2 = 0
	
			for i, v in ipairs(w.data) do
				if i==1 then maxDamage2 = v.value end
		
				local percentRowLength = v.value / maxDamage2
				--local percenttext = PercentageNum(v.value / total)
				local percenttext = PercentageNum(v.value / w.value)
				local name = v.id
				--local color = DEFAULT_COLORS[1 + j%(#DEFAULT_COLORS)]
				local color = DEFAULT_COLORS[1]
				if kure_player_info[v.id] then
					name = kure_player_info[v.id].name
					color = CLASS_COLORS[kure_player_info[v.id].classFilename]
				end
				
				local textName = string.format("%d. %s (%d)", i, name, v.count)
				local textDamage = string.format("%s (%s)", ShortNum(v.value), percenttext)
				Kurecount_FillRowFrame(DETAILS_ROW..rowIdx, v.id, textName, textDamage, color, percentRowLength)
				rowIdx = rowIdx+1
				if rowIdx > 40 then 
					return
				end
			end
		end
	end
	Kurecount_HideRowsDetailsFrame(rowIdx, 40)
end




function Kurecount_UpdateMainFrame(tableVar, i)
	local id, textName, textDamage, color, colorPercent = Kurecount_GetRowParamsFromTable(tableVar, i)
	Kurecount_FillRowFrame(MAIN_ROW..i, id, textName, textDamage, color, colorPercent)
end


function Kurecount_GetRowParamsFromTable(tableVar, i)
	local total = Kurecount_GetTotalValue(tableVar)
	local color, name
	local id = tableVar[i].id
	if kure_player_info[id] then
		Kurecount_UpdatePlayerInfoGuid(id)
		color = CLASS_COLORS[kure_player_info[id].classFilename] or {r=0, g=0, b=0}
		name = kure_player_info[id].name
	else
		color = DEFAULT_COLORS[1 + i%(#DEFAULT_COLORS)] or {r=0, g=0, b=0}
		name = id
	end
	
	local maxDamage = tableVar[1].value
	local damagetext = ShortNum(tableVar[i].value)
	local percenttext = PercentageNum(tableVar[i].value/total)
	
	local totalTime
	if kure_is_on_combat then
		totalTime = GetServerTime() - kure_combat_start
	else
		totalTime = kure_combat_time
	end
	local dpstext = ShortNum(0)
	if totalTime > 0 then 
		dpstext = ShortNum(tableVar[i].value/totalTime)
	end
	local percentRowLength = tableVar[i].value / maxDamage
	local textName = ""
	if not name then
		textName = string.format("%d. %s", i, "Unknown")
	else 
		textName = string.format("%d. %s", i, name)
	end
	local textDamage = string.format("%s (%s, %s)", damagetext, dpstext, percenttext)
	
	return id, textName, textDamage, color, percentRowLength
end 

function Kurecount_FillRowFrame(frameName, id, textLeft, textRight, color, colorPercent)
	local row = getglobal(frameName)
	row.id = id
	local texture = getglobal(frameName.."Bar")
	texture:SetColorTexture(color.r, color.g, color.b, 1)
	texture:SetWidth(row:GetWidth() * colorPercent)
	local textLeftFrame = getglobal(frameName.."TextLeft")
	textLeftFrame:SetFormattedText("%s", textLeft)
	local textRightFrame = getglobal(frameName.."TextRight")
	textRightFrame:SetFormattedText("%s", textRight)
	row:Show()
end



function Kurecount_HideRows()
	local scrollFrame = getglobal("KurecountScrollFrameChild")
	for i=1,40 do
		local row = getglobal(MAIN_ROW..i)
		row:SetWidth(scrollFrame:GetWidth())
		row:Hide()
	end
end


function ShortNum(num)
  if num > 1000000 then
    return string.format("%.2f%s", num * MS, "M")
  elseif num > 1000 then
    return string.format("%.2f%s", num * KS, "k")
  else
    return string.format("%.2f", num)
  end
end

function PercentageNum(num)
  if num > 0 then
    return string.format("%.2f%s", num * 100, "%")
  else
    return "0.0%"
  end
end

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end



------------------------------------------------------------------------------
------------------------------------------------------------------------------

SLASH_KURECOUNT1 = "/kurecount"
SlashCmdList["KURECOUNT"] = function()
	getglobal("Kurecount"):Show()
end








