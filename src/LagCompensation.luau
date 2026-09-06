
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')

local LagCompensation = {}
local TrackedCharacters = setmetatable({}, { __mode = "k" })


LagCompensation.__index = LagCompensation
local MAX_TIME = .2


function LagCompensation.new(player : Player, Character : Instance, origin : Instance?)
    local self = setmetatable({}, LagCompensation)

    self.Logs = {}
    self.TrackedPart = origin or Character.HumanoidRootPart
    self.Conn = RunService.Heartbeat:Connect(function(deltaTime: number)
        local Time = os.clock()
       table.insert(self.Logs,{
        t = Time,
        c = self.TrackedPart.CFrame,
        p = self.TrackedPart.Position
       })

       while self.Logs[1] and self.Logs[1].t < Time - MAX_TIME do 
        table.remove(self.Logs,1)
       end
    end)
    self.CharacterDestroyed = Character.AncestryChanged:Connect(function()
        if Character.Parent == nil then 
            self:Destroy()
        end
    end)
    self.PlayerDisconnect = Players.PlayerRemoving:Connect(function(Player: Player)
        if Player.Character then 
            if TrackedCharacters[Player.Character] then 
                TrackedCharacters[Player.Character]:Destroy()
            end
        end
    end)
    TrackedCharacters[Character] = self
    return self
end


function LagCompensation:GetPositionAt(oldTime : number)
    local Count = #self.Logs
    if Count == 0 then 
        return self.TrackedPart.CFrame
    end
    if oldTime <= self.Logs[1].t then 
        return self.Logs[1].c
    end
    if oldTime >= self.Logs[1].t then 
        return self.TrackedPart.c
    end
    for i = 1, Count -1 do 
        local olderTime,newerTime = self.Logs[i], self.Logs[i + 1]
        if oldTime >= olderTime.t and oldTime <= newerTime.t then 
            local alpha = oldTime - olderTime.t / (newerTime.t - olderTime.t)
            return olderTime.c:Lerp(alpha)
        end
    end
    return self.TrackedPart.CFrame
end


function LagCompensation:Destroy()
    if self.Conn then 
        self.Conn:Disconnect()
    end
    if self.PlayerDisconnect then 
        self.PlayerDisconnect:Disconnect()
    end
    if self.CharacterDestroyed then 
        self.CharacterDestroyed:Disconnect()
    end
    TrackedCharacters[self.Character] = nil
    table.clear(self)
    setmetatable(self, nil)

end

return LagCompensation