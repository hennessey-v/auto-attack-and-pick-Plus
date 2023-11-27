local function playersay(str)
  if ThePlayer.components.talker then
      local success, result = pcall(function()
          ThePlayer.components.talker:Say(str)
      end)
      
      if not success then
          print("发生错误:", result)
      end
  end
end

local move = function( x,z )
  local pos = ThePlayer:GetPosition()
  playersay("开始移动，移动至 x:"..pos.x+x.. " z: "..pos.z+z)
  SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x+x, pos.z+z)
end

return move