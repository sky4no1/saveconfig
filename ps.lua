local function skibidi()
  while true do
  game:GetService("Players").LocalPlayer.PlayerGui.chooseType.Frame.RemoteEvent:FireServer(true)
  wait(0.1)
  end
end

skibidi()

