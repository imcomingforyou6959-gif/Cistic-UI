
local SaveManager = {}

local HttpService = game:GetService("HttpService")

SaveManager.Config = {
	Folder = "RawrUI",
	Ignore = {},
	AutoSave = true,
	AutoSaveInterval = 60,
	UseSUNC = True,
}

local function checkFilesystem()
	local functions = {
		"writefile", "readfile", "appendfile", 
		"listfiles", "delfile", "delfolder",
		"isfile", "isfolder", "makefolder", 
		"loadfile", "getcustomasset"
	}
	
	for _, funcName in ipairs(functions) do
		if getfenv()[funcName] == nil then
			warn("[SaveManager] Missing filesystem function: " .. funcName)
			return false
		end
	end
	
	return true
end

local function checkSUNC()
	local success, sunc = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("SUNC", 3))
	end)
	
	return success and sunc
end

local function getFilesystem()
	if SaveManager.Config.UseSUNC then
		local sunc = checkSUNC()
		if sunc then
			return {
				Write = sunc.Set,
				Read = sunc.Get,
				Exists = sunc.Exists,
				MakeDir = sunc.MakeDirectory,
				DeleteDir = sunc.DeleteDirectory,
				List = sunc.ListDirectory,
				Delete = sunc.DeleteFile,
				IsFile = function(path) return sunc.Exists(path) and not sunc.IsDirectory(path) end,
				IsDir = function(path) return sunc.IsDirectory(path) end,
			}
		end
	end
	
	if checkFilesystem() then
		return {
			Write = writefile,
			Read = readfile,
			Exists = isfile,
			MakeDir = makefolder,
			DeleteDir = delfolder,
			List = listfiles,
			Delete = delfile,
			IsFile = isfile,
			IsDir = isfolder,
		}
	end
	
	return nil
end

local Elements = {
	Toggles = {},
	Sliders = {},
	Dropdowns = {},
	ColorPickers = {},
	KeyPickers = {},
	Inputs = {},
	Labels = {},
	Buttons = {},
}

SaveManager.Parsers = {
	Toggle = {
		Save = function(element)
			return {
				Type = "Toggle",
				ID = element.ID,
				Value = element.Value,
			}
		end,
		Load = function(data)
			if Elements.Toggles[data.ID] then
				Elements.Toggles[data.ID]:SetValue(data.Value)
			end
		end,
	},
	
	Slider = {
		Save = function(element)
			return {
				Type = "Slider",
				ID = element.ID,
				Value = element.Value,
			}
		end,
		Load = function(data)
			if Elements.Sliders[data.ID] then
				Elements.Sliders[data.ID]:SetValue(data.Value)
			end
		end,
	},
	
	Dropdown = {
		Save = function(element)
			return {
				Type = "Dropdown",
				ID = element.ID,
				Value = element.Value,
				Multi = element.Multi or false,
			}
		end,
		Load = function(data)
			if Elements.Dropdowns[data.ID] then
				Elements.Dropdowns[data.ID]:SetValue(data.Value)
			end
		end,
	},
	
	ColorPicker = {
		Save = function(element)
			return {
				Type = "ColorPicker",
				ID = element.ID,
				Value = element.Value:ToHex(),
			}
		end,
		Load = function(data)
			if Elements.ColorPickers[data.ID] then
				Elements.ColorPickers[data.ID]:SetValueRGB(Color3.fromHex(data.Value))
			end
		end,
	},
	
	KeyPicker = {
		Save = function(element)
			return {
				Type = "KeyPicker",
				ID = element.ID,
				Key = element.Value,
				Mode = element.Mode,
			}
		end,
		Load = function(data)
			if Elements.KeyPickers[data.ID] then
				Elements.KeyPickers[data.ID]:SetValue({data.Key, data.Mode})
			end
		end,
	},
	
	Input = {
		Save = function(element)
			return {
				Type = "Input",
				ID = element.ID,
				Text = element.Value,
			}
		end,
		Load = function(data)
			if Elements.Inputs[data.ID] then
				Elements.Inputs[data.ID]:SetValue(data.Text)
			end
		end,
	},
	
	Label = {
		Save = function(element)
			return {
				Type = "Label",
				ID = element.ID,
				Text = element.Text,
			}
		end,
		Load = function(data)
			if Elements.Labels[data.ID] then
				Elements.Labels[data.ID]:SetText(data.Text)
			end
		end,
	},
	
	Button = {
		Save = function(element)
			return {
				Type = "Button",
				ID = element.ID,
				Text = element.Text,
			}
		end,
		Load = function(data)
			if Elements.Buttons[data.ID] then
				Elements.Buttons[data.ID]:SetText(data.Text)
			end
		end,
	},
}

function SaveManager:SetLibrary(library)
	self.Library = library
end

function SaveManager:SetFolder(folder)
	self.Config.Folder = folder
	self:BuildFolderTree()
end

function SaveManager:SetSavePath(path)
	self.SavePath = path
end

function SaveManager:IgnoreThemeSettings()
	self:IgnoreIndex({ 
		"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
		"ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName"
	})
end

function SaveManager:IgnoreIndex(indexes)
	if type(indexes) == "table" then
		for _, idx in ipairs(indexes) do
			self.Config.Ignore[idx] = true
		end
	elseif type(indexes) == "string" then
		self.Config.Ignore[indexes] = true
	end
end

function SaveManager:RegisterElement(id, element)
	local elementType = element.Type or "Toggle"
	local storage = Elements[elementType .. "s"]
	if storage then
		storage[id] = element
	end
end

function SaveManager:BuildFolderTree()
	local fs = getFilesystem()
	if not fs then
		warn("[SaveManager] No filesystem available")
		return false
	end
	
	local paths = {
		self.Config.Folder,
		self.Config.Folder .. '/themes',
		self.Config.Folder .. '/settings'
	}
	
	for _, path in ipairs(paths) do
		if not fs.IsDir(path) then
			local success = pcall(function()
				fs.MakeDir(path)
			end)
			if not success then
				warn("[SaveManager] Failed to create folder: " .. path)
			end
		end
	end
	
	return true
end

function SaveManager:Save(name)
	local fs = getFilesystem()
	if not fs then
		warn("[SaveManager] No filesystem available")
		return false, 'no filesystem'
	end
	
	local fullPath = self.Config.Folder .. '/settings/' .. name .. '.json'
	
	local data = {
		objects = {},
		metadata = {
			name = name,
			date = os.date("%Y-%m-%d %H:%M:%S"),
			version = "2.0.0"
		}
	}
	
	for _, elementType in ipairs({"Toggle", "Slider", "Dropdown", "ColorPicker", "KeyPicker", "Input", "Label", "Button"}) do
		local storage = Elements[elementType .. "s"]
		if storage then
			for id, element in pairs(storage) do
				if not self.Config.Ignore[id] then
					local parser = self.Parsers[elementType]
					if parser then
						table.insert(data.objects, parser.Save(element))
					end
				end
			end
		end
	end
	
	local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not success then
		return false, 'failed to encode data'
	end
	
	local writeSuccess = pcall(function()
		fs.Write(fullPath, encoded)
	end)
	
	if not writeSuccess then
		return false, 'failed to write file'
	end
	
	return true
end

function SaveManager:Load(name)
	local fs = getFilesystem()
	if not fs then
		return false, 'no filesystem'
	end
	
	local fullPath = self.Config.Folder .. '/settings/' .. name .. '.json'
	
	if not fs.Exists(fullPath) then
		return false, 'file not found'
	end
	
	local success, content = pcall(function()
		return fs.Read(fullPath)
	end)
	
	if not success or not content then
		return false, 'failed to read file'
	end
	
	local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
	if not success then
		return false, 'decode error'
	end
	
	for _, obj in ipairs(decoded.objects) do
		local parser = self.Parsers[obj.Type]
		if parser then
			parser.Load(obj)
		end
	end
	
	return true
end

function SaveManager:DeleteConfig(name)
	local fs = getFilesystem()
	if not fs then
		return false, 'no filesystem'
	end
	
	local fullPath = self.Config.Folder .. '/settings/' .. name .. '.json'
	
	if not fs.Exists(fullPath) then
		return false, 'file not found'
	end
	
	local success = pcall(function()
		fs.Delete(fullPath)
	end)
	
	return success
end

function SaveManager:ListConfigs()
	local fs = getFilesystem()
	if not fs then
		return {}
	end
	
	local fullPath = self.Config.Folder .. '/settings/'
	
	if not fs.Exists(fullPath) then
		return {}
	end
	
	local files = fs.List(fullPath)
	local configs = {}
	
	for _, file in ipairs(files) do
		if file:match("%.json$") then
			local name = file:gsub("%.json$", "")
			table.insert(configs, name)
		end
	end
	
	return configs
end

function SaveManager:SetAutoload(name)
	local fs = getFilesystem()
	if not fs then
		return false
	end
	
	local path = self.Config.Folder .. '/settings/autoload.txt'
	
	local success = pcall(function()
		fs.Write(path, name)
	end)
	
	return success
end

function SaveManager:GetAutoload()
	local fs = getFilesystem()
	if not fs then
		return nil
	end
	
	local path = self.Config.Folder .. '/settings/autoload.txt'
	
	if not fs.Exists(path) then
		return nil
	end
	
	local success, content = pcall(function()
		return fs.Read(path)
	end)
	
	if success and content then
		return content:gsub("%s+", "")
	end
	
	return nil
end

function SaveManager:LoadAutoloadConfig()
	local name = self:GetAutoload()
	if name and name ~= "" then
		local success, err = self:Load(name)
		if success and self.Library then
			self.Library:Notify("Auto-loaded config: " .. name)
		end
		return success
	end
	return false
end

function SaveManager:EnableAutoSave(enabled)
	self.Config.AutoSave = enabled
end

function SaveManager:SetAutoSaveInterval(seconds)
	self.Config.AutoSaveInterval = seconds
end

local function autoSaveLoop()
	while true do
		task.wait(SaveManager.Config.AutoSaveInterval or 60)
		
		if SaveManager.Config.AutoSave and SaveManager.Config.AutoSaveInterval then
			local configs = SaveManager:ListConfigs()
			if #configs > 0 then
				local lastConfig = configs[#configs]
				SaveManager:Save(lastConfig)
				if SaveManager.Library then
					SaveManager.Library:Notify("Auto-saved config: " .. lastConfig)
				end
			end
		end
	end
end

function SaveManager:BuildConfigSection(tab)
	assert(self.Library, 'Must set SaveManager.Library first')
	
	local section = tab:AddRightGroupbox('Configuration')
	
	local configList = section:AddDropdown('SaveManager_ConfigList', {
		Text = 'Config list',
		Values = self:ListConfigs(),
		AllowNull = true,
	})
	
	local configName = section:AddInput('SaveManager_ConfigName', {
		Text = 'Config name',
	})
	
	section:AddDivider()
	
	local createBtn = section:AddButton('Create config', function()
		local name = configName.Value
		
		if name:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid config name (empty)', 2)
		end
		
		local success, err = self:Save(name)
		if not success then
			return self.Library:Notify('Failed to save config: ' .. err)
		end
		
		self.Library:Notify('Created config: ' .. name)
		configList.Values = self:ListConfigs()
		configList:SetValue(nil)
	end)
	
	createBtn:AddButton('Load config', function()
		local name = configList.Value
		
		if not name then
			return self.Library:Notify('Please select a config to load', 2)
		end
		
		local success, err = self:Load(name)
		if not success then
			return self.Library:Notify('Failed to load config: ' .. err)
		end
		
		self.Library:Notify('Loaded config: ' .. name)
	end)
	
	createBtn:AddButton('Overwrite config', function()
		local name = configList.Value
		
		if not name then
			return self.Library:Notify('Please select a config to overwrite', 2)
		end
		
		local success, err = self:Save(name)
		if not success then
			return self.Library:Notify('Failed to overwrite config: ' .. err)
		end
		
		self.Library:Notify('Overwrote config: ' .. name)
	end)
	
	section:AddButton('Autoload config', function()
		local name = configList.Value
		
		if not name then
			return self.Library:Notify('Please select a config to autoload', 2)
		end
		
		local success = self:SetAutoload(name)
		if success then
			self.Library:Notify('Set autoload config: ' .. name)
		else
			self.Library:Notify('Failed to set autoload config', 2)
		end
	end)
	
	section:AddButton('Refresh config list', function()
		configList.Values = self:ListConfigs()
		configList:SetValue(nil)
		self.Library:Notify('Config list refreshed')
	end)
	
	section:AddButton('Delete config', function()
		local name = configList.Value
		
		if not name then
			return self.Library:Notify('Please select a config to delete', 2)
		end
		
		local success = self:DeleteConfig(name)
		if success then
			self.Library:Notify('Deleted config: ' .. name)
			configList.Values = self:ListConfigs()
			configList:SetValue(nil)
		else
			self.Library:Notify('Failed to delete config', 2)
		end
	end)
	
	local autoloadLabel = section:AddLabel('Current autoload config: none')
	
	local autoload = self:GetAutoload()
	if autoload then
		autoloadLabel:SetText('Current autoload config: ' .. autoload)
	end
	
	self:IgnoreIndex({ 
		'SaveManager_ConfigList', 
		'SaveManager_ConfigName'
	})
end

local fs = getFilesystem()
if fs then
	SaveManager:BuildFolderTree()
	print('[SaveManager] Filesystem initialized successfully')
else
	warn('[SaveManager] No filesystem available - sUNC test may fail')
end

return SaveManager
