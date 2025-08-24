-- Simulate enum for immutability
function enum(tbl)
  return setmetatable({}, {
    __index = tbl,
    __newindex = function(_, k, v)
      error("Cannot modify enum: " .. tostring(k) .. "=" .. tostring(v))
    end
  })
end

local addonName = ...
local Slurp = CreateFrame("Frame", "SlurpFrame")

-- Only register relevant events
Slurp:RegisterEvent("CHAT_MSG_LOOT")

-- Data storage
Slurp.tally = {}

-- Configuration
local suppressOwnServerName = true -- If true, the player's server name will be hidden in the ledger.
local applyCauldronItemFiltering = true -- If true, will only record cauldron items.
local recordAnyFleetingItems = false -- If true, will record all fleeting items even if cauldron filtering is active.

-- Sorting configuration
-- Enum for sort behavior for the ledger
Slurp.SortMode = enum {
    COUNT_ASCENDING = "count_ascending",
    COUNT_DESCENDING = "count_descending",
    NAME_ASCENDING = "name_ascending",
    NAME_DESCENDING = "name_descending"
}
Slurp.sortMode = Slurp.SortMode.COUNT_DESCENDING

-- Localization Headaches
local FLEETING_ITEM_KEYWORD = "Fleeting" -- The string to identify fleeting items
local PLAYER_NAME_YOU = "You" -- The string used in loot messages to refer to the player running the addon

-- Cauldron item IDs
Slurp.ItemType = enum {
    FLASK = "flask",
    POTION = "potion",
    NONCAULDRON = "non-cauldron",
    ANYFLEETING = "any-fleeting"
}

function CauldronPotion(name)
    return { name = name, itemType = Slurp.ItemType.POTION }
end

function CauldronFlask(name)
    return { name = name,itemType = Slurp.ItemType.FLASK }
end

Slurp.cauldronItems = {
    -- Flasks
    [212725] = CauldronFlask("Fleeting Flask of Tempered Aggression"),
    [212727] = CauldronFlask("Fleeting Flask of Tempered Aggression"),
    [212728] = CauldronFlask("Fleeting Flask of Tempered Aggression"),
    [212729] = CauldronFlask("Fleeting Flask of Tempered Swiftness"),
    [212730] = CauldronFlask("Fleeting Flask of Tempered Swiftness"),
    [212731] = CauldronFlask("Fleeting Flask of Tempered Swiftness"),
    [212732] = CauldronFlask("Fleeting Flask of Tempered Versatility"),
    [212733] = CauldronFlask("Fleeting Flask of Tempered Versatility"),
    [212734] = CauldronFlask("Fleeting Flask of Tempered Versatility"),
    [212735] = CauldronFlask("Fleeting Flask of Tempered Mastery"),
    [212736] = CauldronFlask("Fleeting Flask of Tempered Mastery"),
    [212738] = CauldronFlask("Fleeting Flask of Tempered Mastery"),
    [212739] = CauldronFlask("Fleeting Flask of Alchemical Chaos"),
    [212740] = CauldronFlask("Fleeting Flask of Alchemical Chaos"),
    [212741] = CauldronFlask("Fleeting Flask of Alchemical Chaos"),
    [212745] = CauldronFlask("Fleeting Flask of Saving Graces"),
    [212746] = CauldronFlask("Fleeting Flask of Saving Graces"),
    [212747] = CauldronFlask("Fleeting Flask of Saving Graces"),

    -- Potions
    [212941] = CauldronPotion("Fleeting Algari Healing Potion"),
    [212942] = CauldronPotion("Fleeting Algari Healing Potion"),
    [212943] = CauldronPotion("Fleeting Algari Healing Potion"),
    [212944] = CauldronPotion("Fleeting Algari Healing Potion"),
    [212945] = CauldronPotion("Fleeting Algari Mana Potion"),
    [212946] = CauldronPotion("Fleeting Algari Mana Potion"),
    [212947] = CauldronPotion("Fleeting Algari Mana Potion"),
    [212948] = CauldronPotion("Fleeting Cavedweller's Delight"),
    [212949] = CauldronPotion("Fleeting Cavedweller's Delight"),
    [212950] = CauldronPotion("Fleeting Cavedweller's Delight"),
    [212951] = CauldronPotion("Fleeting Slumbering Soul Serum"),
    [212952] = CauldronPotion("Fleeting Slumbering Soul Serum"),
    [212953] = CauldronPotion("Fleeting Slumbering Soul Serum"),
    [212954] = CauldronPotion("Fleeting Draught of Silent Footfalls"),
    [212955] = CauldronPotion("Fleeting Draught of Silent Footfalls"),
    [212956] = CauldronPotion("Fleeting Draught of Silent Footfalls"),
    [212957] = CauldronPotion("Fleeting Draught of Shocking Revelations"),
    [212958] = CauldronPotion("Fleeting Draught of Shocking Revelations"),
    [212959] = CauldronPotion("Fleeting Draught of Shocking Revelations"),
    [212960] = CauldronPotion("Fleeting Grotesque Vial"),
    [212961] = CauldronPotion("Fleeting Grotesque Vial"),
    [212962] = CauldronPotion("Fleeting Grotesque Vial"),
    [212963] = CauldronPotion("Fleeting Potion of Unwavering Focus"),
    [212964] = CauldronPotion("Fleeting Potion of Unwavering Focus"),
    [212965] = CauldronPotion("Fleeting Potion of Unwavering Focus"),
    [212966] = CauldronPotion("Fleeting Frontline Potion"),
    [212967] = CauldronPotion("Fleeting Frontline Potion"),
    [212968] = CauldronPotion("Fleeting Frontline Potion"),
    [212969] = CauldronPotion("Fleeting Tempered Potion"),
    [212970] = CauldronPotion("Fleeting Tempered Potion"),
    [212971] = CauldronPotion("Fleeting Tempered Potion"),
    [212972] = CauldronPotion("Fleeting Potion of the Reborn Cheetah"),
    [212973] = CauldronPotion("Fleeting Potion of the Reborn Cheetah"),
    [212974] = CauldronPotion("Fleeting Potion of the Reborn Cheetah"),
    [244849] = CauldronPotion("Fleeting Invigorating Healing Potion"),
}

function NonCauldronItem(name, itemID)
    return { name = name, itemType = Slurp.ItemType.NONCAULDRON }
end
Slurp.nonCauldronItems = {

}

function AnyFleetingItem(name, itemID)
    return { name = name, itemType = Slurp.ItemType.FLEETING }
end
Slurp.anyFleetingItems = {

}

local emitDebugMessages = true
function Slurp.DebugPrint(msg)
    if not emitDebugMessages or not msg then return end
    print("SlurpDebug: " .. msg)
end

-- UI stub
function Slurp:CreateWindow()
    if self.window then return end
    local f = CreateFrame("Frame", "SlurpWindow", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(600, 400)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
    f.title:SetText("Slurp Cauldron Usage")

    -- Sorting Dropdown
    local sortingOptions = {
        { text = "Name Ascending", value = Slurp.SortMode.NAME_ASCENDING },
        { text = "Name Descending", value = Slurp.SortMode.NAME_DESCENDING },
        { text = "Count Ascending", value = Slurp.SortMode.COUNT_ASCENDING },
        { text = "Count Descending", value = Slurp.SortMode.COUNT_DESCENDING },
    }
    f.sortDropdown = CreateFrame("Frame", "SlurpSortDropdown", f, "UIDropDownMenuTemplate")
    f.sortDropdown:SetPoint("TOPRIGHT", -10, -10)
    UIDropDownMenu_SetWidth(f.sortDropdown, 150)
    UIDropDownMenu_Initialize(f.sortDropdown, function(self, level)
        for _, opt in ipairs(sortingOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function()
                Slurp.sortMode = opt.value
                UIDropDownMenu_SetSelectedValue(f.sortDropdown, opt.value)
                Slurp:UpdateWindow()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(f.sortDropdown, Slurp.sortMode)

    -- Reset Button
    f.resetBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.resetBtn:SetPoint("BOTTOMLEFT", 10, 10)
    f.resetBtn:SetSize(80, 25)
    f.resetBtn:SetText("Reset")
    f.resetBtn:SetScript("OnClick", function()
        Slurp.tally = {}
        Slurp:UpdateWindow()
    end)

    -- Close Button
    f.closeBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    f.closeBtn:SetSize(80, 25)
    f.closeBtn:SetText("Close")
    f.closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Usage List
    f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.scrollFrame:SetPoint("TOPLEFT", 10, -40)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    f.content = CreateFrame("Frame", nil, f.scrollFrame)
    f.content:SetSize(1, 1)
    f.scrollFrame:SetScrollChild(f.content)

    -- Group by ItemType Checkbox
    f.groupByTypeCheckbox = CreateFrame("CheckButton", nil, f, "ChatConfigCheckButtonTemplate")
    f.groupByTypeCheckbox:SetPoint("TOPLEFT", 10, -10)
    f.groupByTypeCheckbox.Text:SetText("Group by Item Type")
    f.groupByTypeCheckbox:SetChecked(self.groupByType or false)
    f.groupByTypeCheckbox:SetScript("OnClick", function(self)
        Slurp.groupByType = self:GetChecked()
        Slurp:UpdateWindow()
    end)

    self.window = f
    self:UpdateWindow()
end

function Slurp:UpdateWindow()
    if not self.window or not self.window.content then return end
    local content = self.window.content

    Slurp.fontStrings = Slurp.fontStrings or {}
    for _, fs in ipairs(Slurp.fontStrings) do fs:Hide() end

    local entries = {}

    if self.groupByType then
        -- Aggregate by ItemType
        local typeTally = {}
        for user, items in pairs(self.tally) do
            typeTally[user] = typeTally[user] or {}
            for itemID, count in pairs(items) do
                local itemType =
                    (self.cauldronItems[itemID] and self.cauldronItems[itemID].itemType)
                    or (self.nonCauldronItems[itemID] and self.nonCauldronItems[itemID].itemType)
                    or (self.anyFleetingItems[itemID] and self.anyFleetingItems[itemID].itemType)
                    or "Unknown"
                typeTally[user][itemType] = (typeTally[user][itemType] or 0) + count
            end
        end
        for user, types in pairs(typeTally) do
            for itemType, count in pairs(types) do
                table.insert(entries, { user = user, name = itemType, count = count })
            end
        end
    else
        -- Aggregate by item
        for user, items in pairs(self.tally) do
            for itemID, count in pairs(items) do
                local itemName = (self.cauldronItems[itemID] and self.cauldronItems[itemID].name)
                    or (self.nonCauldronItems[itemID] and self.nonCauldronItems[itemID].name)
                    or (self.anyFleetingItems[itemID] and self.anyFleetingItems[itemID].name)
                    or ("Unknown Item with ID: " .. itemID)
                table.insert(entries, { user = user, itemID = itemID, name = itemName, count = count })
            end
        end
    end

    -- Sorting logic (by name or count)
    table.sort(entries, function(a, b)
        if Slurp.sortMode == Slurp.SortMode.NAME_ASCENDING then
            return a.name < b.name
        elseif Slurp.sortMode == Slurp.SortMode.NAME_DESCENDING then
            return a.name > b.name
        elseif Slurp.sortMode == Slurp.SortMode.COUNT_ASCENDING then
            return a.count < b.count
        elseif Slurp.sortMode == Slurp.SortMode.COUNT_DESCENDING then
            return a.count > b.count
        else
            return a.name < b.name
        end
    end)

    local y = -5
    local idx = 1
    for _, entry in ipairs(entries) do
        local fs = Slurp.fontStrings[idx]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            Slurp.fontStrings[idx] = fs
        end
        fs:SetText(entry.user .. " took " .. entry.count .. " x " .. entry.name)
        fs:SetPoint("TOPLEFT", 10, y)
        fs:Show()
        y = y - 20
        idx = idx + 1
    end
end

function Slurp:ShowWindow()
    self:CreateWindow()
    self.window:Show()
    self:UpdateWindow()
end

-- Slash command
SLASH_SLURP1 = "/slurp"
SlashCmdList["SLURP"] = function(msg)
    if msg:lower() == "show" or msg:lower() == "open" then
        Slurp:ShowWindow()
    elseif msg:lower() == "reset" then
        Slurp.tally = {}
        Slurp:UpdateWindow()
    elseif msg:lower() == "hide" then
        Slurp:HideWindow()
    elseif msg:lower() == "debug" then
        emitDebugMessages = not emitDebugMessages
        print("SlurpDebug is now " .. (emitDebugMessages and "enabled" or "disabled"))
    elseif msg:lower() == "all" then
        applyCauldronItemFiltering = not applyCauldronItemFiltering
        print("Slurp will now record " .. (applyCauldronItemFiltering and "only cauldron items." or "all items."))
    else
        print("Slurp commands:")
        print("/slurp show - Show the Slurp window")
        print("/slurp hide - Hide the Slurp window")
        print("/slurp reset - Reset all recorded data")
        print("/slurp debug - Toggle debug messages")
        print("/slurp all - Toggle recording all items vs only cauldron items")
    end
end

-- Event handler stub
Slurp:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local msg, user = ...
        Slurp:ParseMessage(msg, user)
    end
end)

-- Message parsing stub
function Slurp:ParseMessage(msg, user)
    -- Example loot message: "Sparklebeard-Stormrage creates: [Fleeting Flask of Tempered Aggression]."
    local player, itemLink = msg:match("^(%a[%a%-]*) creates*: (.-)%.$")
    if not player or not itemLink then end

    if player == PLAYER_NAME_YOU then
        if suppressOwnServerName then
            -- remove the "-ServerName" from the name
            local nameOnly = user:match("^[^%-]+")
            if not nameOnly then 
                nameOnly = user
            end
            player = nameOnly
        else
            player = user
        end
    end

    -- Get the item ID
    local itemID = self:GetItemIDFromLink(itemLink)
    self.DebugPrint(itemID)
    if not itemID then return end

    -- Get the item name
    local itemName = self:GetItemNameFromLink(itemLink)

    -- Apply filtering for cauldron items. Restrict to items in the cauldronItems dictionary, or "Fleeting" items if enabled.
    local isCauldronItem = self.cauldronItems[itemID] ~= nil
    local isFleetingItem = self.anyFleetingItems[itemID] ~= nil
    local isNonCauldronItem = self.nonCauldronItems[itemID] ~= nil

    if not isCauldronItem then
        -- If we're recording any fleeting items, check if this is one we know about
        if recordAnyFleetingItems and not isFleetingItem then
            -- We don't know about this itemID, so check if the name contains "Fleeting"
            isFleetingItem = itemLink:find(FLEETING_ITEM_KEYWORD) ~= nil
            if isFleetingItem then
                -- Add this item to our known list of fleeting items
                self.anyFleetingItems[itemID] = AnyFleetingItem(itemName)
            end
        end
        -- If we still don't know about this itemID, and we're not filtering cauldron items, then it must be a non-cauldron item
        if not applyCauldronItemFiltering and not isFleetingItem and not isNonCauldronItem then
            isNonCauldronItem = true
            self.nonCauldronItems[itemID] = NonCauldronItem(itemName)
        end
    end

    if applyCauldronItemFiltering then
        -- If we're not recording any fleeting items and this isn't a cauldron item, then we can stop processing
        if not recordAnyFleetingItems and not isCauldronItem then return end
        -- If we are recording any fleeting items, but this isn't fleeting, then we can stop.
        if recordAnyFleetingItems and not isFleetingItem then return end
    end

    self:IncrementItemIDCountForPlayer(itemID, player)
end

-- Increment the count for an itemID for a given player
function Slurp:IncrementItemIDCountForPlayer(itemID, player)
    if not itemID or not player then return end
    self.tally[player] = self.tally[player] or {}
    self.tally[player][itemID] = (self.tally[player][itemID] or 0) + 1
    self:UpdateWindow()
end

-- Extract item ID from an item link
function Slurp:GetItemIDFromLink(link)
    if type(link) ~= "string" then return nil end
    local itemID = link:match("item:(%d+)")
    return tonumber(itemID)
end

-- Extract item name from an item link
function Slurp:GetItemNameFromLink(link)
    if type(link) ~= "string" then return nil end
    local name = link:match("|h%[(.-)%]|h")
    return name
end

-- Check if a string is an item link
function Slurp:IsItemLink(str)
    return type(str) == "string" and str:find("|Hitem:") ~= nil
end
