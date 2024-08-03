local httpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SaveManager = {} do
    SaveManager.Folder = "HalalHub"
    SaveManager.Ignore = {}
    SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = "Toggle", idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = "Slider", idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Colorpicker = {
			Save = function(idx, object)
				return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		Keybind = {
			Save = function(idx, object)
				return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.key, data.mode)
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = "Input", idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] and type(data.text) == "string" then
					SaveManager.Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

    function SaveManager:GetPlayerName()
        local player = Players.LocalPlayer
        return player and player.Name or "UnknownPlayer"
    end

    function SaveManager:CreateAndLoadConfig()
        local playerName = self:GetPlayerName()
        local configName = "HalalHub" .. playerName

        -- Создание конфигурационного файла, если его еще нет
        local configPath = self.Folder .. "/settings/" .. configName .. ".json"
        if not isfile(configPath) then
            self:Save(configName)
        end

        -- Загрузка конфигурации
        local success, err = self:Load(configName)
        if not success then
            return self.Library:Notify({
                Title = "Interface",
                Content = "Config loader",
                SubContent = "Failed to load config: " .. err,
                Duration = 7
            })
        end

        self.Library:Notify({
            Title = "Interface",
            Content = "Config loader",
            SubContent = string.format("Loaded config %q", configName),
            Duration = 7
        })
    end

    function SaveManager:Save(name)
        if (not name) then
            return false, "no config file is selected"
        end

        local fullPath = self.Folder .. "/settings/" .. name .. ".json"

        local data = {
            objects = {}
        }

        for idx, option in next, SaveManager.Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end	

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, "failed to encode data"
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        if (not name) then
            return false, "no config file is selected"
        end
        
        local file = self.Folder .. "/settings/" .. name .. ".json"
        if not isfile(file) then return false, "invalid file" end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, "decode error" end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                task.spawn(function() self.Parser[option.type].Load(option.idx, option) end) -- task.spawn() so the config loading wont get stuck.
            end
        end

        return true
    end

    -- Обновленная функция для постоянного сохранения
    function SaveManager:AutoSaveConfig()
        local playerName = self:GetPlayerName()
        local configName = "HalalHub" .. playerName

        -- Периодическое сохранение (например, каждые 5 минут)
        while true do
            wait(300) -- Ждать 5 минут
            local success, err = self:Save(configName)
            if not success then
                self.Library:Notify({
                    Title = "Interface",
                    Content = "Config saver",
                    SubContent = "Failed to auto save config: " .. err,
                    Duration = 7
                })
            end
        end
    end

    function SaveManager:SetLibrary(library)
        self.Library = library
        self.Options = library.Options

        -- Запуск автоматического сохранения в отдельном потоке
        task.spawn(function() self:AutoSaveConfig() end)
    end

    -- Вызов функции для создания и загрузки конфигурации при запуске скрипта
    SaveManager:BuildFolderTree()
    SaveManager:CreateAndLoadConfig()
end

return SaveManager
