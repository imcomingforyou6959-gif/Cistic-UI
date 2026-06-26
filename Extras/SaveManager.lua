--[[
	rawr.xyz SaveManager
	Based on Linoria-style save manager
	Version: 1.0.0
]]

local HttpService = game:GetService('HttpService')

local SaveManager = {} do
	-- Configuration
	SaveManager.Folder = 'RawrUI'
	SaveManager.Ignore = {}
	
	-- Parser definitions for each UI element type
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = 'Toggle', idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if Toggles[idx] then 
					Toggles[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue(data.value)
				end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex() }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValueRGB(Color3.fromHex(data.value))
				end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then 
					Options[idx]:SetValue({ data.key, data.mode })
				end
			end,
		},
		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then
					Options[idx]:SetValue(data.text)
				end
			end,
		},
		-- Custom rawr.xyz elements
		Label = {
			Save = function(idx, object)
				return { type = 'Label', idx = idx, text = object.Text }
			end,
			Load = function(idx, data)
				if Labels[idx] then 
					Labels[idx]:SetText(data.text)
				end
			end,
		},
		Button = {
			Save = function(idx, object)
				return { type = 'Button', idx = idx, text = object.Text }
			end,
			Load = function(idx, data)
				if Buttons[idx] then 
					Buttons[idx]:SetText(data.text)
				end
			end,
		},
	}

	-- Set indexes to ignore (won't be saved)
	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	-- Set folder path
	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	-- Save config to file
	function SaveManager:Save(name)
		local fullPath = self.Folder .. '/settings/' .. name .. '.json'

		local data = {
			objects = {}
		}

		-- Save toggles
		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		-- Save options (sliders, dropdowns, color pickers, etc.)
		for idx, option in next, Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		-- Save labels
		for idx, label in next, Labels do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser.Label.Save(idx, label))
		end

		-- Save buttons
		for idx, button in next, Buttons do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser.Button.Save(idx, button))
		end

		local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
		if not success then
			return false, 'failed to encode data'
		end

		writefile(fullPath, encoded)
		return true
	end

	-- Load config from file
	function SaveManager:Load(name)
		local file = self.Folder .. '/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(file))
		if not success then return false, 'decode error' end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				self.Parser[option.type].Load(option.idx, option)
			end
		end

		return true
	end

	-- Ignore theme settings
	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", -- themes
			"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', -- themes
			"RawrTheme_Accent", "RawrTheme_Background", "RawrTheme_Text" -- rawr.xyz theme options
		})
	end

	-- Build folder structure
	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	-- Refresh config list
	function SaveManager:RefreshConfigList()
		local list = listfiles(self.Folder .. '/settings')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local start = pos

				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end
		
		return out
	end

	-- Set library reference
	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	-- Load autoload config
	function SaveManager:LoadAutoloadConfig()
		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load autoload config: ' .. err)
			end

			self.Library:Notify(string.format('Auto loaded config %q', name))
		end
	end

	-- Build config section in tab
	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, 'Must set SaveManager.Library')

		local section = tab:AddRightGroupbox('Configuration')

		-- Config list dropdown
		section:AddDropdown('SaveManager_ConfigList', { 
			Text = 'Config list', 
			Values = self:RefreshConfigList(), 
			AllowNull = true 
		})
		
		-- Config name input
		section:AddInput('SaveManager_ConfigName', { 
			Text = 'Config name' 
		})

		section:AddDivider()

		-- Create config button
		section:AddButton('Create config', function()
			local name = Options.SaveManager_ConfigName.Value

			if name:gsub(' ', '') == '' then 
				return self.Library:Notify('Invalid config name (empty)', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to save config: ' .. err)
			end

			self.Library:Notify(string.format('Created config %q', name))

			Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
			Options.SaveManager_ConfigList:SetValues()
			Options.SaveManager_ConfigList:SetValue(nil)
		end):AddButton('Load config', function()
			local name = Options.SaveManager_ConfigList.Value

			if not name then
				return self.Library:Notify('Please select a config to load', 2)
			end

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify('Failed to load config: ' .. err)
			end

			self.Library:Notify(string.format('Loaded config %q', name))
		end)

		-- Overwrite config button
		section:AddButton('Overwrite config', function()
			local name = Options.SaveManager_ConfigList.Value

			if not name then
				return self.Library:Notify('Please select a config to overwrite', 2)
			end

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify('Failed to overwrite config: ' .. err)
			end

			self.Library:Notify(string.format('Overwrote config %q', name))
		end)
		
		-- Autoload config button
		section:AddButton('Autoload config', function()
			local name = Options.SaveManager_ConfigList.Value

			if not name then
				return self.Library:Notify('Please select a config to autoload', 2)
			end

			writefile(self.Folder .. '/settings/autoload.txt', name)
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
			self.Library:Notify(string.format('Set %q to auto load', name))
		end)

		-- Refresh config list button
		section:AddButton('Refresh config list', function()
			Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
			Options.SaveManager_ConfigList:SetValues()
			Options.SaveManager_ConfigList:SetValue(nil)
		end)

		-- Delete config button
		section:AddButton('Delete config', function()
			local name = Options.SaveManager_ConfigList.Value

			if not name then
				return self.Library:Notify('Please select a config to delete', 2)
			end

			local file = self.Folder .. '/settings/' .. name .. '.json'
			if isfile(file) then
				delfile(file)
				self.Library:Notify(string.format('Deleted config %q', name))
				Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
				Options.SaveManager_ConfigList:SetValues()
				Options.SaveManager_ConfigList:SetValue(nil)
			else
				self.Library:Notify('Config file not found', 2)
			end
		end)

		-- Autoload label
		SaveManager.AutoloadLabel = section:AddLabel('Current autoload config: none', true)

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local name = readfile(self.Folder .. '/settings/autoload.txt')
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. name)
		end

		-- Ignore config UI elements from being saved
		SaveManager:SetIgnoreIndexes({ 
			'SaveManager_ConfigList', 
			'SaveManager_ConfigName',
			'ThemeManager_ThemeList',
			'ThemeManager_CustomThemeList',
			'ThemeManager_CustomThemeName'
		})
	end

	-- Build folder tree on init
	SaveManager:BuildFolderTree()
end

return SaveManager
