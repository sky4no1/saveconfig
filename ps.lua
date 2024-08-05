local function skibidi()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local chooseTypeFrame = playerGui:WaitForChild("chooseType").Frame
    local remoteEvent = chooseTypeFrame:WaitForChild("RemoteEvent")

    while true do
        remoteEvent:FireServer(true)
        wait(0.1)
    end
end

skibidi()
