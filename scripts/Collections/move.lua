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
  local offset = 0.5
  local posies = {
    {pos.x+offset, pos.y, pos.z+offset},
    {pos.x+offset, pos.y, pos.z-offset},
    {pos.x-offset, pos.y, pos.z-offset},
    {pos.x-offset, pos.y, pos.z+offset},
  }
  local posID = 1
  playersay('开始移动')
  -- SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, posies[posID][1], posies[posID][3])
  SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x+x, pos.z+z)


end

return move