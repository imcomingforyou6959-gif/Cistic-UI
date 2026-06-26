local Library = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration (Midnight Theme)
local Config = {
	Theme = {
		Text = Color3.fromRGB(200, 190, 195),        -- hsl(348, 30%, 75%)
		TextDark = Color3.fromRGB(140, 130, 135),     -- hsl(348, 15%, 40%)
		TextLight = Color3.fromRGB(230, 220, 225),    -- hsl(348, 45%, 85%)
		Accent = Color3.fromRGB(200, 100, 130),       -- hsl(348, 65%, 60%)
		AccentDark = Color3.fromRGB(180, 80, 110),    -- hsl(348, 55%, 50%)
		AccentLight = Color3.fromRGB(220, 140, 160),  -- hsl(348, 70%, 65%)
		Background = Color3.fromRGB(25, 18, 20),      -- hsla(348, 25%, 7%, 0.5)
		BackgroundLight = Color3.fromRGB(40, 30, 35), -- hsla(348, 25%, 10%, 0.5)
		BackgroundDark = Color3.fromRGB(15, 10, 12),  -- hsla(348, 25%, 7%, 0.5)
		Border = Color3.fromRGB(60, 50, 55),          -- rgba(255, 255, 255, 0.08)
		BorderLight = Color3.fromRGB(80, 70, 75),     -- rgba(255, 255, 255, 0.15)
		Shadow = Color3.fromRGB(0, 0, 0),
		Online = Color3.fromRGB(64, 162, 88),         -- #40a258
		Idle = Color3.fromRGB(204, 149, 76),          -- #cc954c
		DND = Color3.fromRGB(216, 58, 65),            -- #d83a41
		Offline = Color3.fromRGB(130, 130, 140),      -- hsl(348, 15%, 35%)
	},
	Font = Enum.Font.Gotham,
	FontBold = Enum.Font.GothamBold,
	CornerRadius = UDim.new(0, 20),
	SmallRadius = UDim.new(0, 10),
	Padding = UDim.new(0, 12),
	Gap = UDim.new(0, 8)
}

-- Variables
local Window = nil
local Instances = {}
local Dragging = { false, nil, nil }

-- Helper Functions
local function Create(className, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		instance[property] = value
	end
	return instance
end

local function AddCorner(instance, radius)
	local corner = Create("UICorner", {
		CornerRadius = radius or Config.CornerRadius,
		Parent = instance
	})
	return corner
end

local function AddStroke(instance, color, thickness)
	local stroke = Create("UIStroke", {
		Color = color or Config.Theme.Border,
		Thickness = thickness or 1,
		Parent = instance
	})
	return stroke
end

local function AddShadow(instance)
	local shadow = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Config.Theme.Shadow,
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 49, 49),
		ZIndex = -1,
		Parent = instance
	})
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	return shadow
end

-- Blur Effect
local function CreateBlurEffect(parent)
	local blur = Create("Frame", {
		BackgroundTransparency = 0.3,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = parent
	})
	
	local blurEffect = Create("BlurEffect", {
		Size = 18,
		Parent = blur
	})
	
	return blur
end

-- Window Creation
function Library:CreateWindow(options)
	options = options or {}
	
	if Window then
		Window:Destroy()
		Window = nil
	end
	
	local Title = options.Title or "rawr.xyz"
	local Center = options.Center or true
	local AutoShow = options.AutoShow or true
	
	-- Main GUI
	local ScreenGui = Create("ScreenGui", {
		Name = "RawrUI",
		IgnoreGuiInset = true,
		Parent = CoreGui
	})
	
	-- Background Blur
	local BlurContainer = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = ScreenGui
	})
	CreateBlurEffect(BlurContainer)
	
	-- Main Window
	local Main = Create("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 520, 0, 600),
		Position = Center and UDim2.new(0.5, -260, 0.5, -300) or UDim2.new(0, 50, 0, 50),
		BackgroundColor3 = Config.Theme.Background,
		BorderSizePixel = 0,
		Parent = ScreenGui
	})
	
	AddCorner(Main)
	AddStroke(Main, Config.Theme.Border, 1)
	AddShadow(Main)
	
	-- Dragging
	Main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging[1] = true
			Dragging[2] = input.Position
			Dragging[3] = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging[1] = false
				end
			end)
		end
	end)
	
	Main.InputChanged:Connect(function(input)
		if Dragging[1] and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - Dragging[2]
			local newPosition = UDim2.new(
				Dragging[3].X.Scale,
				Dragging[3].X.Offset + delta.X,
				Dragging[3].Y.Scale,
				Dragging[3].Y.Offset + delta.Y
			)
			Main.Position = newPosition
		end
	end)
	
	-- Top Bar
	local TopBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = Main
	})
	
	-- Brand
	local Brand = Create("TextLabel", {
		Name = "Brand",
		Size = UDim2.new(0, 200, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Text = "✦ " .. Title,
		TextColor3 = Config.Theme.Accent,
		TextSize = 18,
		Font = Config.FontBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar
	})
	
	-- Window Controls
	local Controls = Create("Frame", {
		Name = "Controls",
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = TopBar
	})
	
	-- Close Button (Red Dot)
	local CloseBtn = Create("TextButton", {
		Name = "CloseBtn",
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		Parent = Controls
	})
	
	local CloseDot = Create("Frame", {
		Name = "Dot",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Config.Theme.DND,
		Parent = CloseBtn
	})
	AddCorner(CloseDot, UDim.new(1, 0))
	
	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseDot, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 70, 80)}):Play()
	end)
	
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseDot, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.DND}):Play()
	end)
	
	CloseBtn.MouseButton1Click:Connect(function()
		Library:Close()
	end)
	
	-- Minimize Button (Yellow Dot)
	local MinBtn = Create("TextButton", {
		Name = "MinBtn",
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(1, -42, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Text = "",
		Parent = Controls
	})
	
	local MinDot = Create("Frame", {
		Name = "Dot",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Config.Theme.Idle,
		Parent = MinBtn
	})
	AddCorner(MinDot, UDim.new(1, 0))
	
	MinBtn.MouseButton1Click:Connect(function()
		Main.Visible = not Main.Visible
	end)
	
	-- Tabs Container
	local TabsContainer = Create("Frame", {
		Name = "TabsContainer",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = Main
	})
	
	-- Content Container
	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Size = UDim2.new(1, -40, 1, -110),
		Position = UDim2.new(0, 20, 0, 100),
		BackgroundColor3 = Config.Theme.BackgroundLight,
		BorderSizePixel = 0,
		Parent = Main
	})
	AddCorner(ContentContainer, Config.SmallRadius)
	
	-- Scroll Frame
	local ScrollFrame = Create("ScrollingFrame", {
		Name = "ScrollFrame",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Config.Theme.BackgroundDark,
		Parent = ContentContainer
	})
	
	-- UIListLayout for Tabs
	local TabLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		FillDirection = Enum.FillDirection.Horizontal,
		Parent = TabsContainer
	})
	
	-- Store references
	Window = {
		Main = Main,
		ScreenGui = ScreenGui,
		TabsContainer = TabsContainer,
		ContentContainer = ContentContainer,
		ScrollFrame = ScrollFrame,
		TopBar = TopBar,
		Tabs = {},
		TabButtons = {},
		CurrentTab = nil
	}
	
	-- ============================================================
	-- FIX: Define AddTab BEFORE creating the Home tab
	-- ============================================================
	
	-- Tab Creation (defined on Window object)
	function Window:AddTab(name)
		local tab = {}
		
		local TabButton = Create("TextButton", {
			Name = name .. "Tab",
			Size = UDim2.new(0, 100, 1, 0),
			BackgroundTransparency = 1,
			Text = "  " .. name,
			TextColor3 = Config.Theme.TextDark,
			TextSize = 14,
			Font = Config.FontBold,
			Parent = self.TabsContainer
		})
		
		local TabContent = Create("Frame", {
			Name = name .. "Content",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = self.ScrollFrame
		})
		
		local TabLayout = Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
			Parent = TabContent
		})
		
		-- Tab groups
		tab._Groups = {}
		
		-- Select tab
		TabButton.MouseButton1Click:Connect(function()
			self:SelectTab(name)
		end)
		
		tab.Button = TabButton
		tab.Content = TabContent
		tab.Name = name
		
		table.insert(self.Tabs, tab)
		self.TabButtons[name] = TabButton
		
		-- If first tab, select it
		if #self.Tabs == 1 then
			self:SelectTab(name)
		end
		
		-- Groupbox creation functions
		function tab:AddLeftGroupbox(title)
			local group = {}
			local container = Create("Frame", {
				Size = UDim2.new(0.5, -6, 0, 0),
				BackgroundColor3 = Config.Theme.BackgroundDark,
				BorderSizePixel = 0,
				Parent = TabContent
			})
			AddCorner(container, Config.SmallRadius)
			AddStroke(container, Config.Theme.Border, 1)
			
			local titleLabel = Create("TextLabel", {
				Size = UDim2.new(1, -20, 0, 30),
				Position = UDim2.new(0, 10, 0, 10),
				BackgroundTransparency = 1,
				Text = title,
				TextColor3 = Config.Theme.TextLight,
				TextSize = 14,
				Font = Config.FontBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = container
			})
			
			local content = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 0),
				Position = UDim2.new(0, 10, 0, 40),
				BackgroundTransparency = 1,
				Parent = container
			})
			
			local layout = Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = content
			})
			
			group.Container = container
			group.Content = content
			group.Layout = layout
			group.Title = titleLabel
			
			-- Add elements
			function group:AddToggle(id, options)
				local toggle = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local label = Create("TextLabel", {
					Size = UDim2.new(1, -50, 1, 0),
					BackgroundTransparency = 1,
					Text = options.Text or "Toggle",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame
				})
				
				local switch = Create("Frame", {
					Size = UDim2.new(0, 40, 0, 20),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = options.Default and Config.Theme.Accent or Config.Theme.BackgroundDark,
					Parent = frame
				})
				AddCorner(switch, UDim.new(1, 0))
				
				local knob = Create("Frame", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = options.Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
					BackgroundColor3 = Config.Theme.TextLight,
					Parent = switch
				})
				AddCorner(knob, UDim.new(1, 0))
				
				local value = options.Default or false
				
				local function updateState(newValue)
					value = newValue
					TweenService:Create(switch, TweenInfo.new(0.2), {
						BackgroundColor3 = value and Config.Theme.Accent or Config.Theme.BackgroundDark
					}):Play()
					TweenService:Create(knob, TweenInfo.new(0.2), {
						Position = value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
					}):Play()
					if options.Callback then
						options.Callback(value)
					end
				end
				
				local button = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = frame
				})
				
				button.MouseButton1Click:Connect(function()
					updateState(not value)
				end)
				
				toggle.Set = updateState
				toggle.Get = function() return value end
				
				return toggle
			end
			
			function group:AddSlider(id, options)
				local slider = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local label = Create("TextLabel", {
					Size = UDim2.new(1, -60, 0, 20),
					BackgroundTransparency = 1,
					Text = options.Text or "Slider",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame
				})
				
				local valueLabel = Create("TextLabel", {
					Size = UDim2.new(0, 40, 0, 20),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
					Text = tostring(options.Default or 50),
					TextColor3 = Config.Theme.TextDark,
					TextSize = 13,
					Font = Config.FontBold,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = frame
				})
				
				local bar = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 0, 25),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Parent = frame
				})
				AddCorner(bar, UDim.new(1, 0))
				
				local fill = Create("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundColor3 = Config.Theme.Accent,
					Parent = bar
				})
				AddCorner(fill, UDim.new(1, 0))
				
				local min = options.Min or 0
				local max = options.Max or 100
				local current = options.Default or 50
				
				local function updateValue(val)
					current = math.clamp(val, min, max)
					local percentage = (current - min) / (max - min)
					fill.Size = UDim2.new(percentage, 0, 1, 0)
					valueLabel.Text = tostring(math.floor(current * 100) / 100)
					if options.Callback then
						options.Callback(current)
					end
				end
				
				-- Drag functionality
				local dragging = false
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local pos = input.Position.X - bar.AbsolutePosition.X
						local percent = math.clamp(pos / bar.AbsoluteSize.X, 0, 1)
						updateValue(min + (max - min) * percent)
					end
				end)
				
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)
				
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local pos = input.Position.X - bar.AbsolutePosition.X
						local percent = math.clamp(pos / bar.AbsoluteSize.X, 0, 1)
						updateValue(min + (max - min) * percent)
					end
				end)
				
				slider.Set = updateValue
				slider.Get = function() return current end
				
				return slider
			end
			
			function group:AddDropdown(id, options)
				local dropdown = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local button = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Text = options.Text or "Dropdown",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					Parent = frame
				})
				AddCorner(button, Config.SmallRadius)
				AddStroke(button, Config.Theme.Border, 1)
				
				local currentValue = options.Values[options.Default or 1] or options.Values[1]
				
				local dropDown = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 1, 4),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Visible = false,
					ClipsDescendants = true,
					Parent = frame
				})
				AddCorner(dropDown, Config.SmallRadius)
				AddStroke(dropDown, Config.Theme.Border, 1)
				
				local listLayout = Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
					Parent = dropDown
				})
				
				local function updateDropdown()
					dropDown.Size = UDim2.new(1, 0, 0, #options.Values * 30 + 10)
					dropDown.Visible = not dropDown.Visible
				end
				
				for _, value in ipairs(options.Values) do
					local item = Create("TextButton", {
						Size = UDim2.new(1, -10, 0, 26),
						Position = UDim2.new(0, 5, 0, 0),
						BackgroundTransparency = 1,
						Text = value,
						TextColor3 = Config.Theme.Text,
						TextSize = 13,
						Font = Config.Font,
						Parent = dropDown
					})
					
					item.MouseEnter:Connect(function()
						TweenService:Create(item, TweenInfo.new(0.2), {TextColor3 = Config.Theme.Accent}):Play()
					end)
					
					item.MouseLeave:Connect(function()
						TweenService:Create(item, TweenInfo.new(0.2), {TextColor3 = Config.Theme.Text}):Play()
					end)
					
					item.MouseButton1Click:Connect(function()
						currentValue = value
						button.Text = options.Text .. ": " .. value
						dropDown.Visible = false
						if options.Callback then
							options.Callback(value)
						end
					end)
				end
				
				button.MouseButton1Click:Connect(updateDropdown)
				
				dropdown.Set = function(val)
					currentValue = val
					button.Text = options.Text .. ": " .. val
					if options.Callback then
						options.Callback(val)
					end
				end
				
				dropdown.Get = function() return currentValue end
				
				return dropdown
			end
			
			function group:AddLabel(text)
				local label = Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content
				})
				return label
			end
			
			-- Update container height
			local function updateHeight()
				local height = 40 + content.AbsoluteSize.Y + 10
				container.Size = UDim2.new(0.5, -6, 0, height)
			end
			
			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
			task.wait(0.1)
			updateHeight()
			
			table.insert(tab._Groups, group)
			
			return group
		end
		
		function tab:AddRightGroupbox(title)
			local group = {}
			local container = Create("Frame", {
				Size = UDim2.new(0.5, -6, 0, 0),
				Position = UDim2.new(0.5, 6, 0, 0),
				BackgroundColor3 = Config.Theme.BackgroundDark,
				BorderSizePixel = 0,
				Parent = TabContent
			})
			AddCorner(container, Config.SmallRadius)
			AddStroke(container, Config.Theme.Border, 1)
			
			local titleLabel = Create("TextLabel", {
				Size = UDim2.new(1, -20, 0, 30),
				Position = UDim2.new(0, 10, 0, 10),
				BackgroundTransparency = 1,
				Text = title,
				TextColor3 = Config.Theme.TextLight,
				TextSize = 14,
				Font = Config.FontBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = container
			})
			
			local content = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 0),
				Position = UDim2.new(0, 10, 0, 40),
				BackgroundTransparency = 1,
				Parent = container
			})
			
			local layout = Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = content
			})
			
			group.Container = container
			group.Content = content
			group.Layout = layout
			
			-- Copy all the same functions from left groupbox
			function group:AddToggle(id, options)
				local toggle = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local label = Create("TextLabel", {
					Size = UDim2.new(1, -50, 1, 0),
					BackgroundTransparency = 1,
					Text = options.Text or "Toggle",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame
				})
				
				local switch = Create("Frame", {
					Size = UDim2.new(0, 40, 0, 20),
					Position = UDim2.new(1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = options.Default and Config.Theme.Accent or Config.Theme.BackgroundDark,
					Parent = frame
				})
				AddCorner(switch, UDim.new(1, 0))
				
				local knob = Create("Frame", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = options.Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
					BackgroundColor3 = Config.Theme.TextLight,
					Parent = switch
				})
				AddCorner(knob, UDim.new(1, 0))
				
				local value = options.Default or false
				
				local function updateState(newValue)
					value = newValue
					TweenService:Create(switch, TweenInfo.new(0.2), {
						BackgroundColor3 = value and Config.Theme.Accent or Config.Theme.BackgroundDark
					}):Play()
					TweenService:Create(knob, TweenInfo.new(0.2), {
						Position = value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
					}):Play()
					if options.Callback then
						options.Callback(value)
					end
				end
				
				local button = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = frame
				})
				
				button.MouseButton1Click:Connect(function()
					updateState(not value)
				end)
				
				toggle.Set = updateState
				toggle.Get = function() return value end
				
				return toggle
			end
			
			function group:AddSlider(id, options)
				local slider = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local label = Create("TextLabel", {
					Size = UDim2.new(1, -60, 0, 20),
					BackgroundTransparency = 1,
					Text = options.Text or "Slider",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame
				})
				
				local valueLabel = Create("TextLabel", {
					Size = UDim2.new(0, 40, 0, 20),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
					Text = tostring(options.Default or 50),
					TextColor3 = Config.Theme.TextDark,
					TextSize = 13,
					Font = Config.FontBold,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = frame
				})
				
				local bar = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 0, 25),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Parent = frame
				})
				AddCorner(bar, UDim.new(1, 0))
				
				local fill = Create("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundColor3 = Config.Theme.Accent,
					Parent = bar
				})
				AddCorner(fill, UDim.new(1, 0))
				
				local min = options.Min or 0
				local max = options.Max or 100
				local current = options.Default or 50
				
				local function updateValue(val)
					current = math.clamp(val, min, max)
					local percentage = (current - min) / (max - min)
					fill.Size = UDim2.new(percentage, 0, 1, 0)
					valueLabel.Text = tostring(math.floor(current * 100) / 100)
					if options.Callback then
						options.Callback(current)
					end
				end
				
				local dragging = false
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local pos = input.Position.X - bar.AbsolutePosition.X
						local percent = math.clamp(pos / bar.AbsoluteSize.X, 0, 1)
						updateValue(min + (max - min) * percent)
					end
				end)
				
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)
				
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local pos = input.Position.X - bar.AbsolutePosition.X
						local percent = math.clamp(pos / bar.AbsoluteSize.X, 0, 1)
						updateValue(min + (max - min) * percent)
					end
				end)
				
				slider.Set = updateValue
				slider.Get = function() return current end
				
				return slider
			end
			
			function group:AddDropdown(id, options)
				local dropdown = {}
				local frame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = content
				})
				
				local button = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Text = options.Text or "Dropdown",
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					Parent = frame
				})
				AddCorner(button, Config.SmallRadius)
				AddStroke(button, Config.Theme.Border, 1)
				
				local currentValue = options.Values[options.Default or 1] or options.Values[1]
				
				local dropDown = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 1, 4),
					BackgroundColor3 = Config.Theme.BackgroundDark,
					Visible = false,
					ClipsDescendants = true,
					Parent = frame
				})
				AddCorner(dropDown, Config.SmallRadius)
				AddStroke(dropDown, Config.Theme.Border, 1)
				
				local listLayout = Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
					Parent = dropDown
				})
				
				local function updateDropdown()
					dropDown.Size = UDim2.new(1, 0, 0, #options.Values * 30 + 10)
					dropDown.Visible = not dropDown.Visible
				end
				
				for _, value in ipairs(options.Values) do
					local item = Create("TextButton", {
						Size = UDim2.new(1, -10, 0, 26),
						Position = UDim2.new(0, 5, 0, 0),
						BackgroundTransparency = 1,
						Text = value,
						TextColor3 = Config.Theme.Text,
						TextSize = 13,
						Font = Config.Font,
						Parent = dropDown
					})
					
					item.MouseEnter:Connect(function()
						TweenService:Create(item, TweenInfo.new(0.2), {TextColor3 = Config.Theme.Accent}):Play()
					end)
					
					item.MouseLeave:Connect(function()
						TweenService:Create(item, TweenInfo.new(0.2), {TextColor3 = Config.Theme.Text}):Play()
					end)
					
					item.MouseButton1Click:Connect(function()
						currentValue = value
						button.Text = options.Text .. ": " .. value
						dropDown.Visible = false
						if options.Callback then
							options.Callback(value)
						end
					end)
				end
				
				button.MouseButton1Click:Connect(updateDropdown)
				
				dropdown.Set = function(val)
					currentValue = val
					button.Text = options.Text .. ": " .. val
					if options.Callback then
						options.Callback(val)
					end
				end
				
				dropdown.Get = function() return currentValue end
				
				return dropdown
			end
			
			function group:AddLabel(text)
				local label = Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Config.Theme.Text,
					TextSize = 13,
					Font = Config.Font,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = content
				})
				return label
			end
			
			-- Update height
			local function updateHeight()
				local height = 40 + content.AbsoluteSize.Y + 10
				container.Size = UDim2.new(0.5, -6, 0, height)
			end
			
			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
			task.wait(0.1)
			updateHeight()
			
			table.insert(tab._Groups, group)
			
			return group
		end
		
		return tab
	end
	
	-- Select Tab (defined on Window object)
	function Window:SelectTab(name)
		if self.CurrentTab then
			local oldTab = self.Tabs[self.CurrentTab]
			if oldTab then
				oldTab.Content.Visible = false
				TweenService:Create(oldTab.Button, TweenInfo.new(0.2), {
					TextColor3 = Config.Theme.TextDark
				}):Play()
			end
		end
		
		for i, tab in ipairs(self.Tabs) do
			if tab.Name == name then
				tab.Content.Visible = true
				TweenService:Create(tab.Button, TweenInfo.new(0.2), {
					TextColor3 = Config.Theme.Accent
				}):Play()
				self.CurrentTab = i
				break
			end
		end
	end
	
	-- ============================================================
	-- NOW create the Home tab (AFTER AddTab is defined)
	-- ============================================================
	
	local HomeTab = Window:AddTab("Home")
	local HomeContent = HomeTab:AddLeftGroupbox("Welcome")
	
	HomeContent:AddLabel("Welcome to rawr.xyz UI")
	HomeContent:AddLabel("Based on the midnight theme")
	HomeContent:AddLabel("✦ Use the tabs above to navigate")
	
	Instances.ScreenGui = ScreenGui
	Instances.Window = Window
	
	return Window
end

-- Close Window
function Library:Close()
	if Window then
		Window.Main.Visible = false
	end
end

-- Show Window
function Library:Show()
	if Window then
		Window.Main.Visible = true
	end
end

-- Toggle Window
function Library:Toggle()
	if Window then
		Window.Main.Visible = not Window.Main.Visible
	end
end

-- Theme Manager (simplified)
local ThemeManager = {}

function ThemeManager:SetLibrary(library)
	-- Store reference
end

function ThemeManager:SetFolder(folder)
	-- Store folder name
end

function ThemeManager:ApplyToTab(tab)
	-- Apply theme settings to tab
end

-- Save Manager (simplified)
local SaveManager = {}

function SaveManager:SetLibrary(library)
	-- Store reference
end

function SaveManager:SetFolder(folder)
	-- Store folder name
end

function SaveManager:IgnoreThemeSettings()
	-- Ignore theme settings in saves
end

function SaveManager:BuildConfigSection(tab)
	-- Build config section in tab
end

-- Return library
return Library, ThemeManager, SaveManager
