--This script validates that all the JSON files in the Engine-Documentation directory follow the data structure defined in the specification.
--Specification Implemented: 2019-11-17-Specification.md

--Code author: Rami Sabbagh (RamiLego4Game)

--Extend the package path so it search for the modules in the special directory.
package.path = "./Lua_Scripts/Modules/?.lua;./Lua_Scripts/Modules/?/init.lua;"..package.path

local startClock = os.clock()

--Load ANSI module
if not pcall(require,"ANSI") then print("\27[0;1;31mCould not load the ANSI module, please make sure that the script is executed with the repository being the working directory!\27[0;1;37m") os.exit(1) return end
local ANSI = require("ANSI")

--== Shared functions ==--

local function fail(...)
	local reason = {...}
	for k,v in pairs(reason) do reason[k] = tostring(v) end
	reason = table.concat(reason, " ")
	ANSI.setGraphicsMode(0, 1, 31) --Red output
	print(reason)
	ANSI.setGraphicsMode(0, 1, 37) --White output
	os.exit(1)
end

--== Load external modules ==--

if not pcall(require,"lfs") then fail("Could not load luafilesystem, please make sure it's installed using luarocks first!") end
local lfs = require("lfs")
if not pcall(require, "JSON") then fail("Could not load JSON module, please make sure that the script is executed with the repository being the working directory!") end
local JSON = require("JSON")

--== Validate the files content ==--

ANSI.setGraphicsMode(0, 37) --Light grey output
print("")
print("Documentation files content validation script (ValidateContent.lua) by Rami Sabbagh (RamiLego4Game)")
print("Using specification 2019-11-17")
print("")

ANSI.setGraphicsMode(0, 1, 34) --Blue output
print("Validating the files content.")
print("")

--== Validate Engine_Documentation ==--

local simpleTypes = {"number", "string", "boolean", "nil", "table", "userdata", "function"}
for k,v in ipairs(simpleTypes) do simpleTypes[v] = k end

--Returns true if the type was valid, false otherwise, with reason followed
local function validateType(vtype)
	if type(vtype) == "string" then
		--Check if it's the any type
		if vtype == "any" then return true end

		--Check if it's a simple type
		if simpleTypes[vtype] then return true end

		--Otherwise it's an invalid type
		return false, "Invalid simple type: "..vtype.."!"

	elseif type(vtype) == "table" then
		local l1 = #vtype
		if l1 == 0 then return false, "The type as a table of types must not be empty!" end
		for k1, v1 in pairs(vtype) do
			if type(k1) ~= "number" or k1 > l1 or k1 < 1 or k1 ~= math.floor(k1) then return false, "The type as a table of types can be only an array of continuous values!" end

			if type(v1) == "string" then
				if v1 == "any" then return false, "The \"any\" type can't be used in a table of types!" end
				if not simpleTypes[v1] then return false, "Invalid simple type: "..vtype.."!" end

			elseif type(v1) == "table" then --Complex type
				--Make sure that it's a valid array
				local l2 = #v1
				if l2 == 0 then return false, "The complex type in the table of types at index #"..k1.." must not be an empty array!" end
				for k2, v2 in pairs(v1) do
					if type(k2) ~= "number" or k2 > l2 or k2 < 1 or k2 ~= math.floor(k2) then return false, "The complex type in the table of types at index #"..k1..": can be only an array of continuous values!" end
					if type(v2) ~= "string" then return false, "The complex type in the table of types at index #"..k1..": has a non-string value!" end
				end

				--Make sure that it's a valid path
				local complexPath = table.concat(v1, "/") .. "/" .. v1[l2] .. ".json"
				if l2 < 2 or v1[l1-1] ~= "objects" or not isFile(complexPath) then return false, "Invalid object path for the complex type in the table of types at index #"..k1.."!" end
			else
				return false, "Invalid type of a type value in the types table at index #"..k1..": "..type(v1)..", it can be only a string or a table!"
			end
		end

		return true --Validated successfully
	else
		return false, "Invalid type of the type value: "..type(vtype)..", it can be only a string or a table!"
	end
end

--Returns true if the version was valid, false otherwise, with reason followed
local function validateVersion(version)
	if type(version) ~= "table" then return false, "The version must be a table, provided: "..type(version).."!" end
	if #version ~= 2 then return false, "The version must be an array (table) with exactly 2 tables in it only!" end

	for k,v in pairs(version) do
		if type(k) ~= "number" or k > 2 or k < 1 or k ~= math.floor(k) or type(v) ~= "table" then return false, "The version must be an array (table) with exactly 2 tables in it only!" end
	end

	if #version[1] ~= 3 then return false, "The category version must be an array of 3 natural numbers!" end
	for k,v in pairs(version[1]) do
		if type(k) ~= "number" or k > 3 or k < 1 or k ~= math.floor(k) or type(v) ~= "number" or v < 0 or v ~= math.floor(v) then
			return false, "The category version must be an array of 3 natural numbers!"
		end
	end

	if #version[2] ~= 3 then return false, "The LIKO-12 version must be an array of 3 natural numbers!" end
	for k,v in pairs(version[2]) do
		if type(k) ~= "number" or k > 3 or k < 1 or k ~= math.floor(k) or type(v) ~= "number" or v < 0 or v ~= math.floor(v) then
			return false, "The LIKO-12 version must be an array of 3 natural numbers!"
		end
	end

	--Validated successfully
	return true
end

--Returns true if the date was valid, false otherwise, with reason followed
local function validateDate(date)
	if type(date) ~= "string" then return false, "The date can be only a string, provided: "..type(date).."" end
	if not date:match("%d%d%d%d%-%d%d%-%d%d") then return false, "Invalid date: "..date.."!" end

	--For the sake of simplicity I'm not going to validate if the month has 31 or 30 days, especially that some years are longer then others by 1 day (in an integer system)...

	local month = tonumber(date:sub(6,7))
	local day = tonumber(date:sub(9,10))

	if month < 1 or month > 12 then return false, "Invalid month ("..month..") in date: "..date.."!" end
	if day < 1 or day > 31 then return false, "Invalid day ("..day..") in date: "..date.."!" end

	return true
end

--Returns true if the value was a simple text string with no control charactes, false otherwise, with reason followed
local function validateSimpleText(text)
	if type(text) ~= "string" then return false, "It must be a string, not a "..type(text).."!" end

	for i=1, #text do
		local c = string.byte(text, i)
		if c < 32 or c == 127 then return false, "Control characters (including new line) are not allowed, found one at "..i.."!" end
	end

	return true
end

--Returns true if the notes was valid, false otherwise, with reason followed
local function validateNotes(notes)
	if type(notes) ~= "table" then return false, "It must be a table, not a "..type(notes).."!" end
	
	local length = #notes
	for k,v in pairs(notes) do
		if type(k) ~= "number" or k < 1 or k > length or k ~= math.floor(k) or type(v) ~= "string" then
			return false, "Notes must be an array of strings with continuous values!"
		end
	end

	return true
end

--Returns true if the field was valid, false otherwise, with reason followed
local function validateField(field)
	--Every field that's been validated is set to nil => This function destroys the data it has been passed
	--Why doing so? Inorder to find any unwanted extra values in the data

	local ok1, reason1 = validateVersion(field.availableSince)
	if not ok1 then return false, "Failed to validate 'availableSince': "..reason1 end
	field.availableSince = nil

	local ok2, reason2 = validateVersion(field.lastUpdatedIn)
	if not ok2 then return false, "Failed to validate 'lastUpdatedIn': "..reason2 end
	field.lastUpdatedIn = nil

	if type(field.shortDescription) ~= "nil" then
		local ok3, reason3 = validateSimpleText(field.shortDescription)
		if not ok3 then return false, "Failed to validate 'shortDescription': "..reason3 end
		field.shortDescription = nil
	end

	if type(field.longDescription) ~= "nil" and type(field.longDescription) ~= "string" then
		return false, "Failed to validate 'longDescription': It must be a string!"
	end
	field.longDescription = nil

	if type(field.notes) ~= "nil" then
		local ok4, reason4 = validateNotes(field.notes)
		if not ok4 then return false, "Failed to validate 'notes': "..reason4 end
		field.notes = nil
	end

	if type(field.extra) ~= "nil" and type(field.extra) ~= "string" then
		return false, "Failed to validate 'extra': It must be a string!"
	end
	field.extra = nil

	local ok5, reason5 = validateType(field.type)
	if not ok5 then return false, "Failed to validate 'type': "..reason5 end
	field.type = nil

	if type(field.protected) ~= "nil" and type(field.protected) ~= "boolean" then
		return false, "Failed to validate 'protected': It must be a boolean!"
	end
	field.protected = nil

	--Reject any extra data in the field
	for k,v in pairs(field) do
		if type(v) ~= "nil" then
			return false, "Invalid data field with the key: "..k.."!"
		end
	end

	--Validated successfully
	return true
end

--Returns true if the object meta was valid, false otherwise, with reason followed
local function validateObjectMeta(meta)
	--Every field that's been validated is set to nil => This function destroys the data it has been passed
	--Why doing so? Inorder to find any unwanted extra values in the data

	local ok1, reason1 = validateVersion(meta.availableSince)
	if not ok1 then return false, "Failed to validate 'availableSince': "..reason1 end
	meta.availableSince = nil

	local ok2, reason2 = validateVersion(meta.lastUpdatedIn)
	if not ok2 then return false, "Failed to validate 'lastUpdatedIn': "..reason2 end
	meta.lastUpdatedIn = nil

	if type(meta.shortDescription) ~= "nil" then
		local ok3, reason3 = validateSimpleText(meta.shortDescription)
		if not ok3 then return false, "Failed to validate 'shortDescription': "..reason3 end
		meta.shortDescription = nil
	end

	if type(meta.fullDescription) ~= "nil" and type(meta.fullDescription) ~= "string" then
		return false, "Failed to validate 'fullDescription': It must be a string!"
	end
	meta.fullDescription = nil

	if type(meta.notes) ~= "nil" then
		local ok4, reason4 = validateNotes(meta.notes)
		if not ok4 then return false, "Failed to validate 'notes': "..reason4 end
		meta.notes = nil
	end

	if type(meta.extra) ~= "nil" and type(meta.extra) ~= "string" then
		return false, "Failed to validate 'extra': It must be a string!"
	end
	meta.extra = nil

	--Reject any extra data in the object meta
	for k,v in pairs(meta) do
		if type(v) ~= "nil" then
			return false, "Invalid data field with the key: "..k.."!"
		end
	end

	--Validated successfully
	return true
end

--Returns true if the documentation meta was valid, false otherwise, with reason followed
local function validateDocumentationMeta(meta)
	--Every field that's been validated is set to nil => This function destroys the data it has been passed
	--Why doing so? Inorder to find any unwanted extra values in the data

	if type(meta.engineVersion) ~= "table" then return false, "Failed to validate 'engineVersion': It must be a table!" end
	local ok1, reason1 = validateVersion({{0,0,0}, meta.engineVersion})
	if not ok1 then return false, "Failed to validate 'engineVersion': "..reason1 end
	meta.engineVersion = nil

	local ok2, reason2 = validateDate(meta.revisionDate)
	if not ok2 then return false, "Failed to validate 'revisionDate': "..reason2 end
	meta.revisionDate = nil

	if type(meta.revisionNumber) ~= "number" or meta.revisionNumber < 0 or meta.revisionNumber ~= math.floor(meta.revisionNumber) then
		return false, "Failed to validate 'revisionNumber': It must be a natural number!"
	end
	meta.revisionNumber = nil

	local ok3, reason3 = validateDate(meta.specificationDate)
	if not ok3 then return false, "Failed to validate 'specificationDate': "..reason3 end
	meta.specificationDate = nil

	local ok4, reason4 = validateSimpleText(meta.specificationLink)
	if not ok4 then return false, "Failed to validate 'specificationLink': "..reason4 end
	meta.specificationLink = nil

	--Reject any extra data in the documentation meta
	for k,v in pairs(meta) do
		if type(v) ~= "nil" then
			return false, "Invalid data field with the key: "..k.."!"
		end
	end

	--Validated successfully
	return true
end

--== The end of the script ==--

local endClock = os.clock()
local executionTime = endClock - startClock

ANSI.setGraphicsMode(0, 1, 32) --Green output
print("")
print("The documentation files content has been validated successfully in "..executionTime.."s.")
print("")

ANSI.setGraphicsMode(0, 1, 37) --White output