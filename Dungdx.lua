--[[ Dungdx PvP · -PvP- · AutoKen · FlyCam · CamLock · Simple Shader · 7yd7 Emote ]]
if not game:IsLoaded() then game.Loaded:Wait() end task.wait(.3)
if _G.DungdxPvP then pcall(function() _G.DungdxPvP:Destroy() end) task.wait(.15) end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TW = game:GetService("TweenService")
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local LT = game:GetService("Lighting")
local CP = game:GetService("ContentProvider")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local Cam = WS.CurrentCamera
-- Metatable hook: hard lock FieldOfView khi POV bật
local POV_Hook = {installed=false, active=false, target=70}
local function installPOVHook()
    if POV_Hook.installed then return true end
    local ok = pcall(function()
        if type(getrawmetatable) ~= "function"
           or type(newcclosure) ~= "function"
           or type(setreadonly) ~= "function" then
            error("executor thiếu hàm metatable")
        end
        local mt = getrawmetatable(game)
        local oldNI = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(function(self, key, value)
            if POV_Hook.active
               and key == "FieldOfView"
               and typeof(self) == "Instance"
               and self:IsA("Camera") then
                -- Nuốt write của mọi script khác (skill/game), ghi target của mình
                return oldNI(self, key, POV_Hook.target)
            end
            return oldNI(self, key, value)
        end)
        setreadonly(mt, true)
    end)
    POV_Hook.installed = ok
    return ok
end

-- Khởi tạo chắc chắn ở client trước khi tạo GUI.
local LP = Players.LocalPlayer
if not LP then
    repeat task.wait(0.1); LP = Players.LocalPlayer until LP
end

local GUI_PARENT = (function()
    -- Executor hỗ trợ gethui: ưu tiên parent riêng của executor.
    local ok, hui = pcall(function()
        if type(gethui) == "function" then return gethui() end
        return nil
    end)
    if ok and typeof(hui) == "Instance" then return hui end

    -- Nếu không có gethui, chờ PlayerGui sẵn sàng.
    local playerGui
    pcall(function()
        playerGui = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 15)
    end)
    if playerGui and playerGui:IsA("PlayerGui") then return playerGui end

    -- Dự phòng cho môi trường client không cung cấp PlayerGui đúng lúc.
    local coreGui
    pcall(function() coreGui = game:GetService("CoreGui") end)
    if coreGui and typeof(coreGui) == "Instance" then return coreGui end
    return nil
end)()
if not GUI_PARENT then
    warn("[DungdxPvP] Không tìm được nơi gắn giao diện. Hãy chạy script trong client Roblox sau khi vào game.")
    return
end

local AVATAR = "rbxassetid://84552655718654"
local LOGO_IMG = "rbxassetid://91434453184512"

local T = {
    Bg=Color3.fromRGB(10,15,30), Sidebar=Color3.fromRGB(13,20,40),
    Panel=Color3.fromRGB(19,27,50), Card=Color3.fromRGB(23,33,60),
    CardHi=Color3.fromRGB(30,42,76), Input=Color3.fromRGB(12,16,28),
    Accent=Color3.fromRGB(59,130,246), Accent2=Color3.fromRGB(37,99,235),
    On=Color3.fromRGB(59,130,246), Off=Color3.fromRGB(42,54,88),
    Text=Color3.fromRGB(230,240,255), Sub=Color3.fromRGB(120,140,180),
    Stroke=Color3.fromRGB(38,52,92), Danger=Color3.fromRGB(239,68,68),
    Green=Color3.fromRGB(80,240,180), Red=Color3.fromRGB(255,80,100),
}
local function cr(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function sk(p,c,t,tr) local s=Instance.new("UIStroke",p); s.Color=c or T.Stroke; s.Thickness=t or 1
    s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end
local function gr(p,a,b,r) local g=Instance.new("UIGradient",p); g.Color=ColorSequence.new(a,b); g.Rotation=r or 45; return g end
local function dg(f,h) h=h or f
    local on,st,sp=false,nil,nil
    local moveConn,endConn
    h.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            on=true; st=i.Position; sp=f.Position
            if moveConn then moveConn:Disconnect() end
            if endConn then endConn:Disconnect() end
            moveConn=UIS.InputChanged:Connect(function(changed)
                if on and (changed.UserInputType==Enum.UserInputType.MouseMovement or changed.UserInputType==Enum.UserInputType.Touch) then
                    local d=changed.Position-st
                    f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
                end
            end)
            endConn=UIS.InputEnded:Connect(function(ended)
                if ended.UserInputType==Enum.UserInputType.MouseButton1 or ended.UserInputType==Enum.UserInputType.Touch then
                    on=false
                    if moveConn then moveConn:Disconnect(); moveConn=nil end
                    if endConn then endConn:Disconnect(); endConn=nil end
                end
            end)
        end
    end)
end

local persistentConnections = {}
local function trackPersistent(conn)
    if conn then table.insert(persistentConnections, conn) end
    return conn
end

local GUI = Instance.new("ScreenGui")
GUI.Name="DungdxPvP"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.DisplayOrder=9999; GUI.Parent=GUI_PARENT

local DESIGN_W,DESIGN_H = 820,520
local Main = Instance.new("Frame",GUI)
Main.AnchorPoint=Vector2.new(.5,.5); Main.Position=UDim2.fromScale(.5,.5)
Main.Size=UDim2.fromOffset(DESIGN_W,DESIGN_H); Main.BackgroundColor3=T.Bg
Main.BorderSizePixel=0; Main.ClipsDescendants=true; cr(Main,20); sk(Main,T.Stroke,1.5)

-- Optional Roblox image background used by the "Ảnh nền" theme.
-- It is created before the rest of the UI so controls stay above it.
local ThemeImageBackground = Instance.new("ImageLabel")
ThemeImageBackground.Name = "__DungdxThemeImageBackground"
ThemeImageBackground.Size = UDim2.fromScale(1,1)
ThemeImageBackground.Position = UDim2.fromScale(0,0)
ThemeImageBackground.BackgroundTransparency = 1
ThemeImageBackground.BorderSizePixel = 0
ThemeImageBackground.Image = ""
ThemeImageBackground.ImageTransparency = 0.12
ThemeImageBackground.ScaleType = Enum.ScaleType.Crop
ThemeImageBackground.Visible = false
ThemeImageBackground.Active = false
ThemeImageBackground.ZIndex = 1
ThemeImageBackground.Parent = Main
cr(ThemeImageBackground,20)
local ImageThemeActive = false
local apAll -- forward declaration used by themeApply()

local R = {device="pc",auto=1,user=1,orientation="Ngang"}
local uiS = Instance.new("UIScale",Main); uiS.Scale=1
local function getViewport()
    local camera = WS.CurrentCamera or Cam
    if camera then return camera.ViewportSize end
    return Vector2.new(800, 600)
end
local function dev()
    local vp=getViewport()
    if (UIS.TouchEnabled and not UIS.KeyboardEnabled) or vp.X<720 then return "mobile"
    elseif vp.X<1100 then return "tablet" else return "pc" end
end
local function autoS()
    local vp=getViewport()
    local fit=math.min(math.max(vp.X-16,160)/DESIGN_W, math.max(vp.Y-24,160)/DESIGN_H)
    return math.clamp(fit, .32, 1.25)
end
local applyLayout = nil
local applyScale = function()
    R.device=dev(); R.auto=autoS()
    local vp=getViewport()
    local portraitMode=(R.orientation=="Doc") or (R.device=="mobile" and vp.Y>vp.X)
    if portraitMode then
        -- Use a tall canvas rather than shrinking the 820x520 landscape canvas.
        local scale=math.min(math.clamp(R.user,.6,1.5), math.max(.6,(vp.X-16)/320))
        local baseW=math.min(480, math.max(200, math.floor(math.max(200,vp.X-16)/scale)))
        local baseH=math.min(700, math.max(300, math.floor(math.max(300,vp.Y-24)/scale)))
        Main.Size=UDim2.fromOffset(baseW,baseH)
        uiS.Scale=scale
    else
        Main.Size=UDim2.fromOffset(DESIGN_W,DESIGN_H)
        local fit=math.min(math.max(vp.X-16,160)/DESIGN_W, math.max(vp.Y-24,160)/DESIGN_H)
        uiS.Scale=math.min(R.auto*R.user, math.max(.32,fit))
    end
    if _G.__tgl then
        local s=R.auto*R.user
        local b=math.floor(52*math.clamp(s,.85,1.2))
        _G.__tgl.Size=UDim2.fromOffset(b,b)
    end
    if applyLayout then applyLayout() end
end
local cameraViewportConn
local function bindCurrentCamera()
    Cam = WS.CurrentCamera
    if cameraViewportConn then pcall(function() cameraViewportConn:Disconnect() end) end
    if Cam then cameraViewportConn = Cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale) end
    applyScale()
end
trackPersistent(WS:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCurrentCamera))
if Cam then cameraViewportConn=Cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale) end
_G.__setUS = function(v) R.user=math.clamp((tonumber(v) or 100)/100,.6,1.5); applyScale() end

local H = Instance.new("Frame",Main)
H.Size=UDim2.new(1,0,0,60); H.BackgroundColor3=T.Sidebar; H.BorderSizePixel=0; cr(H,20)
local hc = Instance.new("Frame",H)
hc.Size=UDim2.new(1,0,0,16); hc.Position=UDim2.new(0,0,1,-16)
hc.BackgroundColor3=T.Sidebar; hc.BorderSizePixel=0; dg(Main,H)

local Lg = Instance.new("Frame",H)
Lg.Size=UDim2.fromOffset(40,40); Lg.Position=UDim2.fromOffset(14,10)
Lg.BackgroundColor3=Color3.fromRGB(245,245,248); Lg.BorderSizePixel=0; cr(Lg,10)
local LgImg = Instance.new("ImageLabel",Lg)
LgImg.Size=UDim2.fromScale(1,1); LgImg.BackgroundTransparency=1
LgImg.Image=LOGO_IMG; LgImg.ScaleType=Enum.ScaleType.Fit; LgImg.ZIndex=2; cr(LgImg,10)

local Tl = Instance.new("TextLabel",H)
Tl.Size=UDim2.fromOffset(220,22); Tl.Position=UDim2.fromOffset(64,10)
Tl.BackgroundTransparency=1; Tl.Text="Dungdx PvP"; Tl.Font=Enum.Font.GothamBold
Tl.TextSize=17; Tl.TextColor3=T.Text; Tl.TextXAlignment=Enum.TextXAlignment.Left
local Sb = Instance.new("TextLabel",H)
Sb.Size=UDim2.fromOffset(220,16); Sb.Position=UDim2.fromOffset(64,32)
Sb.BackgroundTransparency=1; Sb.Text="Blox Fruits Script"; Sb.Font=Enum.Font.Gotham
Sb.TextSize=12; Sb.TextColor3=T.Accent; Sb.TextXAlignment=Enum.TextXAlignment.Left
local Vr = Instance.new("TextLabel",H)
Vr.Size=UDim2.fromOffset(54,24); Vr.Position=UDim2.fromOffset(214,18)
Vr.BackgroundColor3=T.Accent2; Vr.Text="v1.2"; Vr.Font=Enum.Font.GothamBold
Vr.TextSize=11; Vr.TextColor3=Color3.fromRGB(220,235,255); Vr.BorderSizePixel=0; cr(Vr,12)

local function makeHeaderMetric(name, defaultText, x, width)
    local box=Instance.new("Frame",H)
    box.Name="HeaderMetric"..name
    box.Size=UDim2.fromOffset(width,26); box.Position=UDim2.fromOffset(x,17)
    box.BackgroundColor3=T.Card; box.BackgroundTransparency=.08; box.BorderSizePixel=0
    cr(box,8); sk(box,T.Stroke,1,.3)
    local label=Instance.new("TextLabel",box)
    label.Name="Value"; label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1; label.Text=defaultText
    label.Font=Enum.Font.GothamBold; label.TextSize=10; label.TextColor3=T.Text
    label.TextXAlignment=Enum.TextXAlignment.Center; label.TextTruncate=Enum.TextTruncate.AtEnd
    return box,label
end
local HfpsBox,Hfps=makeHeaderMetric("FPS","FPS --",390,68)
local HpingBox,Hping=makeHeaderMetric("Ping","PING --",466,82)

local Cl = Instance.new("TextButton",H)
Cl.Size=UDim2.fromOffset(30,30); Cl.AnchorPoint=Vector2.new(1,0)
Cl.Position=UDim2.new(1,-14,0,15); Cl.BackgroundColor3=T.Card; Cl.Text="X"
Cl.Font=Enum.Font.GothamBold; Cl.TextSize=14; Cl.TextColor3=T.Text
Cl.BorderSizePixel=0; Cl.AutoButtonColor=false; cr(Cl,8)
local Mn = Instance.new("TextButton",H)
Mn.Size=UDim2.fromOffset(30,30); Mn.AnchorPoint=Vector2.new(1,0)
Mn.Position=UDim2.new(1,-50,0,15); Mn.BackgroundColor3=T.Card; Mn.Text="-"
Mn.Font=Enum.Font.GothamBold; Mn.TextSize=16; Mn.TextColor3=T.Text
Mn.BorderSizePixel=0; Mn.AutoButtonColor=false; cr(Mn,8)

local Bd = Instance.new("Frame",Main)
Bd.Size=UDim2.new(1,0,1,-60); Bd.Position=UDim2.new(0,0,0,60); Bd.BackgroundTransparency=1

local SB = Instance.new("Frame",Bd)
SB.Size=UDim2.new(0,170,1,0); SB.BackgroundColor3=T.Sidebar; SB.BorderSizePixel=0; SB.ClipsDescendants=true; cr(SB,14)
local SBc = Instance.new("Frame",SB)
SBc.Size=UDim2.new(0,16,1,0); SBc.Position=UDim2.new(1,-16,0,0)
SBc.BackgroundColor3=T.Sidebar; SBc.BorderSizePixel=0

local NL = Instance.new("ScrollingFrame",SB)
NL.Size=UDim2.new(1,-16,1,-90); NL.Position=UDim2.fromOffset(8,8)
NL.BackgroundTransparency=1; NL.BorderSizePixel=0; NL.ScrollBarThickness=0
NL.CanvasSize=UDim2.new(); NL.AutomaticCanvasSize=Enum.AutomaticSize.Y
NL.ScrollingDirection=Enum.ScrollingDirection.Y; NL.ScrollingEnabled=true
local NLL = Instance.new("UIListLayout",NL)
NLL.Padding=UDim.new(0,4); NLL.SortOrder=Enum.SortOrder.LayoutOrder

local Ow = Instance.new("Frame",SB)
Ow.Size=UDim2.new(1,-16,0,72); Ow.AnchorPoint=Vector2.new(.5,1)
Ow.Position=UDim2.new(.5,0,1,-8); Ow.BackgroundColor3=T.Card
Ow.BorderSizePixel=0; cr(Ow,10); sk(Ow,T.Stroke,1)

local OI = Instance.new("Frame",Ow)
OI.Size=UDim2.fromOffset(40,40); OI.Position=UDim2.fromOffset(8,16)
OI.BackgroundColor3=T.Accent2; OI.BorderSizePixel=0; cr(OI,20); sk(OI,T.Accent,2,.3)
local OIImg = Instance.new("ImageLabel",OI)
OIImg.Size=UDim2.fromScale(1,1); OIImg.BackgroundTransparency=1
OIImg.Image=""; OIImg.ScaleType=Enum.ScaleType.Crop; OIImg.ZIndex=2; cr(OIImg,20)
task.spawn(function()
    local ok,thumb=pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and thumb and thumb~="" then OIImg.Image=thumb
    else OIImg.Image=LOGO_IMG; OIImg.ScaleType=Enum.ScaleType.Fit end
end)

local ON1 = Instance.new("TextLabel",Ow)
ON1.Size=UDim2.new(1,-60,0,16); ON1.Position=UDim2.fromOffset(56,6)
ON1.BackgroundTransparency=1; ON1.Text="Người chơi"; ON1.Font=Enum.Font.GothamBold
ON1.TextSize=12; ON1.TextColor3=T.Text; ON1.TextXAlignment=Enum.TextXAlignment.Left
ON1.TextTruncate=Enum.TextTruncate.AtEnd
local ON2 = Instance.new("TextLabel",Ow)
ON2.Size=UDim2.new(1,-60,0,14); ON2.Position=UDim2.fromOffset(56,22)
ON2.BackgroundTransparency=1; ON2.Text="@username"; ON2.Font=Enum.Font.Gotham
ON2.TextSize=10; ON2.TextColor3=T.Accent; ON2.TextXAlignment=Enum.TextXAlignment.Left
ON2.TextTruncate=Enum.TextTruncate.AtEnd
local ON3 = Instance.new("TextLabel",Ow)
ON3.Size=UDim2.new(1,-60,0,14); ON3.Position=UDim2.fromOffset(56,38)
ON3.BackgroundTransparency=1; ON3.Text="Lv.0 - Human"; ON3.Font=Enum.Font.GothamMedium
ON3.TextSize=10; ON3.TextColor3=T.Sub; ON3.TextXAlignment=Enum.TextXAlignment.Left
ON3.TextTruncate=Enum.TextTruncate.AtEnd

local function getBFStat()
    local lvl=0; local race="Human"
    local ok,v=pcall(function() return LP:GetAttribute("Level") end)
    if ok and type(v)=="number" then lvl=v end
    if lvl==0 then local ok2,WS=pcall(function() return LP.Data.Level.Value end)
        if ok2 and type(WS)=="number" then lvl=WS end end
    if lvl==0 then local ls=LP:FindFirstChild("leaderstats")
        if ls then local lv=ls:FindFirstChild("Level") or ls:FindFirstChild("Lv")
            if lv then lvl=tonumber(lv.Value) or 0 end end end
    local ok3,r=pcall(function() return LP:GetAttribute("Race") end)
    if ok3 and type(r)=="string" and r~="" then race=r end
    if race=="Human" then local ok4,r2=pcall(function() return LP.Data.Race.Value end)
        if ok4 and type(r2)=="string" and r2~="" then race=r2 end end
    return lvl,race
end
local function updateProfile()
    ON1.Text=LP.DisplayName or LP.Name
    ON2.Text="@"..LP.Name
    local lvl,race=getBFStat()
    ON3.Text="Lv."..tostring(lvl).." - "..tostring(race)
end
updateProfile()
task.spawn(function() while Ow.Parent do task.wait(2) updateProfile() end end)

local Ct = Instance.new("Frame",Bd)
Ct.Size=UDim2.new(1,-170,1,0); Ct.Position=UDim2.new(0,170,0,0); Ct.BackgroundTransparency=1

local UI = {Orientation="Ngang"}
local NavRefs = {}
local Pgs = {}; local NBs = {}

local function mkPage()
    local p=Instance.new("ScrollingFrame",Ct)
    p.Size=UDim2.new(1,-24,1,-16); p.Position=UDim2.fromOffset(12,8)
    p.BackgroundTransparency=1; p.BorderSizePixel=0; p.ScrollBarThickness=3
    p.ScrollBarImageColor3=T.Accent; p.ScrollBarImageTransparency=.4
    p.CanvasSize=UDim2.new(); p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.Visible=false
    local l=Instance.new("UIListLayout",p); l.Padding=UDim.new(0,10); l.SortOrder=Enum.SortOrder.LayoutOrder
    return p
end

local function addTab(id,ico,lbl,ord)
    local pg=mkPage(); Pgs[id]=pg
    local b=Instance.new("TextButton",NL)
    b.Size=UDim2.new(1,0,0,42); b.BackgroundColor3=T.Sidebar
    b.Text=""; b.AutoButtonColor=false; b.BorderSizePixel=0; b.LayoutOrder=ord; cr(b,10)
    local icBox=Instance.new("Frame",b)
    icBox.Size=UDim2.fromOffset(30,30); icBox.Position=UDim2.fromOffset(12,6)
    icBox.BackgroundColor3=T.Sub; icBox.BackgroundTransparency=.85; icBox.BorderSizePixel=0; cr(icBox,8)
    local ic=Instance.new("TextLabel",icBox)
    ic.Size=UDim2.fromScale(1,1); ic.BackgroundTransparency=1
    ic.Text=ico; ic.Font=Enum.Font.GothamBold; ic.TextSize=16; ic.TextColor3=T.Sub
    local lb=Instance.new("TextLabel",b)
    lb.Size=UDim2.new(1,-50,1,0); lb.Position=UDim2.fromOffset(50,0)
    lb.BackgroundTransparency=1; lb.Text=lbl; lb.Font=Enum.Font.GothamMedium
    lb.TextSize=13; lb.TextColor3=T.Sub; lb.TextXAlignment=Enum.TextXAlignment.Left
    local ac=Instance.new("Frame",b)
    ac.Size=UDim2.new(0,3,0,20); ac.Position=UDim2.new(0,0,.5,-10)
    ac.BackgroundColor3=T.Accent; ac.BorderSizePixel=0; ac.Visible=false; cr(ac,2)
    local function sA(a)
        ac.Visible=a; b.BackgroundColor3=a and T.Card or T.Sidebar
        ic.TextColor3=a and Color3.fromRGB(255,255,255) or T.Sub
        icBox.BackgroundColor3=a and T.Accent or T.Sub
        icBox.BackgroundTransparency=a and .3 or .85
        lb.TextColor3=a and T.Text or T.Sub
    end
    b.MouseButton1Click:Connect(function()
        for k,p in pairs(Pgs) do p.Visible=(k==id) end
        for k,fn in pairs(NBs) do fn(k==id) end
    end)
    NBs[id]=sA
    NavRefs[id]={btn=b,icBox=icBox,ic=ic,lb=lb,ac=ac}
    return pg
end

local pCombat  = addTab("Combat","⚔️","Combat",1)
local pMacro   = addTab("Macro","🎯","Macro",2)
local pMove    = addTab("Move","🏃","Move",3)
local pVisual  = addTab("Visual","👁️","Visual",4)
local pExt     = addTab("Extend","📂","Extend",5)
local pSet     = addTab("Settings","⚙️","Settings",6)
local pInfo    = addTab("Info","💠","Info",7)
for k,p in pairs(Pgs) do p.Visible=(k=="Combat") end
for k,fn in pairs(NBs) do fn(k=="Combat") end

applyLayout=function()
    local vp=getViewport()
    local portraitMode=(R.orientation=="Doc") or (R.device=="mobile" and vp.Y>vp.X)
    if portraitMode then
        -- Tall card: title and stats first, then a labeled, swipeable tab strip.
        H.Size=UDim2.new(1,0,0,82)
        hc.Position=UDim2.new(0,0,1,-16)
        Bd.Position=UDim2.new(0,0,0,82); Bd.Size=UDim2.new(1,0,1,-82)
        Lg.Size=UDim2.fromOffset(34,34); Lg.Position=UDim2.fromOffset(10,7)
        Tl.Position=UDim2.fromOffset(52,7); Tl.Size=UDim2.new(1,-207,0,22); Tl.TextSize=15
        Sb.Visible=false
        Vr.Size=UDim2.fromOffset(50,22); Vr.Position=UDim2.new(1,-145,0,8); Vr.TextSize=10
        Cl.Size=UDim2.fromOffset(28,28); Cl.Position=UDim2.new(1,-10,0,7)
        Mn.Size=UDim2.fromOffset(28,28); Mn.Position=UDim2.new(1,-44,0,7)
        local w=Main.Size.X.Offset
        local chipW=math.max(42,math.floor((w-22)/2))
        HfpsBox.Size=UDim2.fromOffset(chipW,24); HfpsBox.Position=UDim2.fromOffset(8,47)
        HpingBox.Size=UDim2.fromOffset(chipW,24); HpingBox.Position=UDim2.fromOffset(14+chipW,47)
        Hfps.TextSize=9; Hping.TextSize=9

        SB.Size=UDim2.new(1,0,0,52); SBc.Size=UDim2.new(1,0,0,5); SBc.Position=UDim2.new(0,0,1,-5)
        NL.Position=UDim2.fromOffset(8,3); NL.Size=UDim2.new(1,-16,0,44)
        NL.AutomaticCanvasSize=Enum.AutomaticSize.X; NL.ScrollingDirection=Enum.ScrollingDirection.X
        NL.CanvasPosition=Vector2.zero
        NLL.FillDirection=Enum.FillDirection.Horizontal; NLL.Padding=UDim.new(0,4)
        Ct.Position=UDim2.new(0,0,0,52); Ct.Size=UDim2.new(1,0,1,-52)
        Ow.Visible=false
        for _,ref in pairs(NavRefs) do
            ref.btn.Size=UDim2.fromOffset(82,42)
            ref.icBox.Size=UDim2.fromOffset(20,20)
            ref.icBox.Position=UDim2.fromOffset(5,11)
            ref.ic.TextSize=13; ref.lb.Visible=true
            ref.lb.Size=UDim2.new(1,-31,1,0); ref.lb.Position=UDim2.fromOffset(29,0)
            ref.lb.TextSize=9; ref.lb.TextXAlignment=Enum.TextXAlignment.Left
            ref.ac.AnchorPoint=Vector2.new(.5,1); ref.ac.Size=UDim2.new(1,-16,0,3)
            ref.ac.Position=UDim2.new(.5,0,1,-1)
        end
    else
        H.Size=UDim2.new(1,0,0,60)
        Bd.Position=UDim2.new(0,0,0,60); Bd.Size=UDim2.new(1,0,1,-60)
        Lg.Size=UDim2.fromOffset(40,40); Lg.Position=UDim2.fromOffset(14,10)
        Tl.Position=UDim2.fromOffset(64,8); Tl.Size=UDim2.fromOffset(140,22); Tl.TextSize=17
        Sb.Size=UDim2.fromOffset(142,16); Sb.Position=UDim2.fromOffset(64,32)
        Sb.Visible=(R.device~="mobile")
        Vr.Size=UDim2.fromOffset(54,24); Vr.Position=UDim2.fromOffset(214,18); Vr.TextSize=11
        Cl.Size=UDim2.fromOffset(30,30); Cl.Position=UDim2.new(1,-14,0,15)
        Mn.Size=UDim2.fromOffset(30,30); Mn.Position=UDim2.new(1,-50,0,15)
        HfpsBox.Size=UDim2.fromOffset(68,26); HfpsBox.Position=UDim2.fromOffset(390,17)
        HpingBox.Size=UDim2.fromOffset(82,26); HpingBox.Position=UDim2.fromOffset(466,17)
        Hfps.TextSize=10; Hping.TextSize=10
        Ow.Visible=true
        NLL.FillDirection=Enum.FillDirection.Vertical; NLL.Padding=UDim.new(0,4)
        NL.AutomaticCanvasSize=Enum.AutomaticSize.Y; NL.ScrollingDirection=Enum.ScrollingDirection.Y
        NL.CanvasPosition=Vector2.zero
        if R.device=="mobile" then
            SB.Size=UDim2.new(0,132,1,0); SBc.Size=UDim2.new(0,16,1,0); SBc.Position=UDim2.new(1,-16,0,0)
            Ct.Position=UDim2.new(0,132,0,0); Ct.Size=UDim2.new(1,-132,1,0)
            NL.Position=UDim2.fromOffset(6,6); NL.Size=UDim2.new(1,-12,1,-86)
            Ow.Size=UDim2.new(1,-12,0,68); Ow.Position=UDim2.new(.5,0,1,-6)
        elseif R.device=="tablet" then
            SB.Size=UDim2.new(0,155,1,0); SBc.Size=UDim2.new(0,16,1,0); SBc.Position=UDim2.new(1,-16,0,0)
            Ct.Position=UDim2.new(0,155,0,0); Ct.Size=UDim2.new(1,-155,1,0)
            NL.Position=UDim2.fromOffset(8,8); NL.Size=UDim2.new(1,-16,1,-84)
            Ow.Size=UDim2.new(1,-16,0,72); Ow.Position=UDim2.new(.5,0,1,-8)
        else
            SB.Size=UDim2.new(0,170,1,0); SBc.Size=UDim2.new(0,16,1,0); SBc.Position=UDim2.new(1,-16,0,0)
            Ct.Position=UDim2.new(0,170,0,0); Ct.Size=UDim2.new(1,-170,1,0)
            NL.Position=UDim2.fromOffset(8,8); NL.Size=UDim2.new(1,-16,1,-90)
            Ow.Size=UDim2.new(1,-16,0,72); Ow.Position=UDim2.new(.5,0,1,-8)
        end
        for _,ref in pairs(NavRefs) do
            ref.btn.Size=UDim2.new(1,0,0,42)
            ref.icBox.Size=UDim2.fromOffset(30,30)
            ref.icBox.Position=UDim2.fromOffset(12,6)
            ref.ic.TextSize=16; ref.lb.Visible=true
            ref.lb.Size=UDim2.new(1,-50,1,0); ref.lb.Position=UDim2.fromOffset(50,0)
            ref.lb.TextSize=13; ref.lb.TextXAlignment=Enum.TextXAlignment.Left
            ref.ac.AnchorPoint=Vector2.new(0,0.5); ref.ac.Size=UDim2.new(0,3,0,20)
            ref.ac.Position=UDim2.new(0,0,0.5,-10)
        end
    end
end

-- ═══════════════ UI BUILDERS ═══════════════
local function mSec(par,title,desc,ord)
    local c=Instance.new("Frame",par)
    c.Size=UDim2.new(1,0,0,0); c.AutomaticSize=Enum.AutomaticSize.Y
    c.BackgroundColor3=T.Panel; c.BorderSizePixel=0; c.LayoutOrder=ord
    cr(c,12); sk(c,T.Stroke,1)
    local t=Instance.new("Frame",c)
    t.Size=UDim2.new(1,0,0,48); t.BackgroundTransparency=1
    local tl=Instance.new("TextLabel",t)
    tl.Size=UDim2.new(1,-20,0,20); tl.Position=UDim2.fromOffset(14,6)
    tl.BackgroundTransparency=1; tl.Text=title; tl.Font=Enum.Font.GothamBold
    tl.TextSize=14; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",t)
    dl.Size=UDim2.new(1,-20,0,16); dl.Position=UDim2.fromOffset(14,26)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=11; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local r=Instance.new("Frame",c)
    r.Size=UDim2.new(1,-20,0,0); r.Position=UDim2.fromOffset(10,48)
    r.BackgroundTransparency=1; r.AutomaticSize=Enum.AutomaticSize.Y
    local rl=Instance.new("UIListLayout",r); rl.Padding=UDim.new(0,4); rl.SortOrder=Enum.SortOrder.LayoutOrder
    local pd=Instance.new("Frame",c)
    pd.Size=UDim2.new(1,0,0,10); pd.Position=UDim2.new(0,0,1,0)
    pd.AnchorPoint=Vector2.new(0,1); pd.BackgroundTransparency=1
    return r
end
local function mRow(par,ord)
    local r=Instance.new("Frame",par)
    r.Size=UDim2.new(1,0,0,44); r.BackgroundColor3=T.Card
    r.BorderSizePixel=0; r.LayoutOrder=ord; cr(r,8)
    r.MouseEnter:Connect(function() TW:Create(r,TweenInfo.new(.15),{BackgroundColor3=T.CardHi}):Play() end)
    r.MouseLeave:Connect(function() TW:Create(r,TweenInfo.new(.15),{BackgroundColor3=T.Card}):Play() end)
    return r
end
local function mTog(par,name,desc,def,ord,cb)
    local r=mRow(par,ord); local st=def==true
    local tl=Instance.new("TextLabel",r)
    tl.Size=UDim2.new(1,-80,0,18); tl.Position=UDim2.fromOffset(12,6)
    tl.BackgroundTransparency=1; tl.Text=name; tl.Font=Enum.Font.GothamMedium
    tl.TextSize=12; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",r)
    dl.Size=UDim2.new(1,-80,0,14); dl.Position=UDim2.fromOffset(12,24)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local sw=Instance.new("Frame",r)
    sw.Size=UDim2.fromOffset(42,22); sw.AnchorPoint=Vector2.new(1,.5)
    sw.Position=UDim2.new(1,-12,.5,0); sw.BackgroundColor3=st and T.On or T.Off
    sw.BorderSizePixel=0; cr(sw,11)
    local kn=Instance.new("Frame",sw)
    kn.Size=UDim2.fromOffset(18,18); kn.AnchorPoint=Vector2.new(0,.5)
    kn.Position=st and UDim2.new(1,-20,.5,0) or UDim2.new(0,2,.5,0)
    kn.BackgroundColor3=Color3.fromRGB(245,245,250); kn.BorderSizePixel=0; cr(kn,9)
    local b=Instance.new("TextButton",r)
    b.Size=UDim2.fromScale(1,1); b.BackgroundTransparency=1; b.Text=""
    local busy=false
    local function render(v)
        st=v==true
        TW:Create(sw,TweenInfo.new(.15),{BackgroundColor3=st and T.On or T.Off}):Play()
        TW:Create(kn,TweenInfo.new(.15),{Position=st and UDim2.new(1,-20,.5,0) or UDim2.new(0,2,.5,0)}):Play()
    end
    local function set(v, silent)
        v=v==true
        render(v)
        if silent or not cb or busy then return end
        busy=true
        local ok,err=pcall(function() cb(v) end)
        busy=false
        if not ok then
            warn("[DungdxPvP Toggle Error] "..tostring(name)..": "..tostring(err))
            pcall(function() cb(false) end)
            render(false)
        end
    end
    b.MouseButton1Click:Connect(function() set(not st,false) end)
    return {
        Get=function() return st end,
        Set=function(v) set(v,false) end,
        Sync=function(v) set(v,true) end,
        Render=function(v) render(v) end,
    }
end
local function mSld(par,name,desc,mn,mx,def,ord,cb)
    local r=mRow(par,ord); r.Size=UDim2.new(1,0,0,58)
    local tl=Instance.new("TextLabel",r)
    tl.Size=UDim2.new(1,-80,0,16); tl.Position=UDim2.fromOffset(12,6)
    tl.BackgroundTransparency=1; tl.Text=name; tl.Font=Enum.Font.GothamMedium
    tl.TextSize=12; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local vb=Instance.new("TextLabel",r)
    vb.Size=UDim2.fromOffset(56,20); vb.AnchorPoint=Vector2.new(1,0)
    vb.Position=UDim2.new(1,-12,0,6); vb.BackgroundColor3=T.Panel; vb.Text=tostring(def)
    vb.Font=Enum.Font.GothamMedium; vb.TextSize=11; vb.TextColor3=T.Text
    vb.BorderSizePixel=0; cr(vb,6)
    local dl=Instance.new("TextLabel",r)
    dl.Size=UDim2.new(1,-80,0,14); dl.Position=UDim2.fromOffset(12,22)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local tr=Instance.new("Frame",r)
    tr.Size=UDim2.new(1,-24,0,6); tr.AnchorPoint=Vector2.new(0,1)
    tr.Position=UDim2.new(0,12,1,-14); tr.BackgroundColor3=T.Off
    tr.BorderSizePixel=0; cr(tr,3)
    local fl=Instance.new("Frame",tr)
    fl.Size=UDim2.new((def-mn)/(mx-mn),0,1,0); fl.BackgroundColor3=T.Accent
    fl.BorderSizePixel=0; cr(fl,3)
    local kn=Instance.new("Frame",tr)
    kn.AnchorPoint=Vector2.new(.5,.5); kn.Position=UDim2.new((def-mn)/(mx-mn),0,.5,0)
    kn.Size=UDim2.fromOffset(14,14); kn.BackgroundColor3=Color3.fromRGB(255,255,255)
    kn.BorderSizePixel=0; cr(kn,7)
    local dragging=false
    local function up(i)
        local rl=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        local v=math.floor(mn+(mx-mn)*rl+.5)
        fl.Size=UDim2.new(rl,0,1,0); kn.Position=UDim2.new(rl,0,.5,0)
        vb.Text=tostring(v)
        if cb then
            local ok,err=pcall(cb,v)
            if not ok then warn("[DungdxPvP Slider Error] "..tostring(name)..": "..tostring(err)) end
        end
    end
    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; up(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then up(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    local function setValue(v, silent)
        v=math.clamp(math.floor((tonumber(v) or def)+.5),mn,mx)
        local rl=(v-mn)/(mx-mn)
        fl.Size=UDim2.new(rl,0,1,0); kn.Position=UDim2.new(rl,0,.5,0); vb.Text=tostring(v)
        if not silent and cb then pcall(cb,v) end
    end
    setValue(def,true)
    return {
        Get=function() return tonumber(vb.Text) or def end,
        Set=function(v) setValue(v,false) end,
        Sync=function(v) setValue(v,true) end,
        Frame=r,
    }
end
local function mBtn(par,name,desc,bTxt,ord,cb,dngr)
    local r=mRow(par,ord)
    local tl=Instance.new("TextLabel",r)
    tl.Size=UDim2.new(.55,0,0,18); tl.Position=UDim2.fromOffset(12,6)
    tl.BackgroundTransparency=1; tl.Text=name; tl.Font=Enum.Font.GothamMedium
    tl.TextSize=12; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",r)
    dl.Size=UDim2.new(.55,0,0,14); dl.Position=UDim2.fromOffset(12,24)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local b=Instance.new("TextButton",r)
    b.Size=UDim2.fromOffset(100,28); b.AnchorPoint=Vector2.new(1,.5)
    b.Position=UDim2.new(1,-12,.5,0); b.BackgroundColor3=dngr and T.Danger or T.Accent
    b.Text=bTxt; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.TextColor3=Color3.fromRGB(255,255,255)
    b.BorderSizePixel=0; b.AutoButtonColor=false; cr(b,8)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end
local function mDrop(par,name,desc,opts,def,ord,cb)
    local r=mRow(par,ord)
    local tl=Instance.new("TextLabel",r)
    tl.Size=UDim2.new(.55,0,0,18); tl.Position=UDim2.fromOffset(12,6)
    tl.BackgroundTransparency=1; tl.Text=name; tl.Font=Enum.Font.GothamMedium
    tl.TextSize=12; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",r)
    dl.Size=UDim2.new(.55,0,0,14); dl.Position=UDim2.fromOffset(12,24)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=10; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local b=Instance.new("TextButton",r)
    b.Size=UDim2.fromOffset(100,28); b.AnchorPoint=Vector2.new(1,.5)
    b.Position=UDim2.new(1,-12,.5,0); b.BackgroundColor3=T.Input
    b.Text=def.." ▾"; b.Font=Enum.Font.GothamBold; b.TextSize=11
    b.TextColor3=T.Text; b.BorderSizePixel=0; b.AutoButtonColor=false; cr(b,8); sk(b,T.Stroke,1)
    local cur=def
    local function setValue(v, silent)
        if #opts==0 then return end
        local ix=table.find(opts,v) or 1
        cur=opts[ix]
        b.Text=cur.." ▾"
        if not silent and cb then pcall(cb,cur) end
    end
    b.MouseButton1Click:Connect(function()
        local ix=table.find(opts,cur) or 1
        ix=ix%#opts+1
        setValue(opts[ix],false)
    end)
    return {Get=function() return cur end, Set=function(v) setValue(v,false) end, Sync=function(v) setValue(v,true) end}
end

-- ═══════════════ FEATURE CONFLICT CONTROL ═══════════════
local FeatureControl = {
    stopTargetTween = nil,
    stopManualTween = nil,
    ui = {},
}

local function syncFeatureUI(name, value)
    local ref=FeatureControl.ui[name]
    if ref then
        if ref.Sync then pcall(function() ref:Sync(value) end)
        elseif ref.Set then pcall(function() ref:Set(value) end) end
    end
end

local ExtShared = {
    tbl = nil,
    FlyCam = nil,
    flycamStop = nil,
    cleanup = nil,
    flycamReady = {start=nil,stop=nil},
    povReady = {start=nil,stop=nil,set=nil},
}

-- ═══════════════ MOVEMENT (Fly/Water/Noclip) ═══════════════
local Mv = {
    Fly={enabled=false,bv=nil,bg=nil,conn=nil,speed=80,origWS=16},
    Water={enabled=false,thread=nil,plane=nil,origSize=nil},
    Noclip={enabled=false,conns={},loopConn=nil},
}
local function flyStart()
    local F=Mv.Fly
    if F.enabled then return end
    pcall(function() if FeatureControl.stopTargetTween then FeatureControl.stopTargetTween() end end)
    pcall(function() if FeatureControl.stopManualTween then FeatureControl.stopManualTween() end end)
    pcall(function() if _G.DungdxPvP and _G.DungdxPvP.FlyCamStop then _G.DungdxPvP.FlyCamStop() end end)
    pcall(function() if FeatureControl.ui.FlyCam then FeatureControl.ui.FlyCam:Sync(false) end end)
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    F.enabled=true; F.origWS=hum.WalkSpeed; hum.PlatformStand=true
    F.bv=Instance.new("BodyVelocity")
    F.bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
    F.bv.P=125000; F.bv.Velocity=Vector3.zero; F.bv.Parent=hrp
    F.bg=Instance.new("BodyGyro")
    F.bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    F.bg.P=10000; F.bg.D=500; F.bg.CFrame=hrp.CFrame; F.bg.Parent=hrp
    F.conn=RS.RenderStepped:Connect(function()
        if not F.enabled or not F.bv or not F.bg then return end
        local character=LP.Character
        if not character or not character.Parent then return end
        local h=character:FindFirstChildOfClass("Humanoid")
        local root=character:FindFirstChild("HumanoidRootPart")
        local cam=WS.CurrentCamera
        if not h or not root or not cam then return end
        local camLook=cam.CFrame.LookVector
        local moveDir=h.MoveDirection
        local velocity=Vector3.zero
        if moveDir.Magnitude>0.01 then
            local horiz=Vector3.new(moveDir.X,0,moveDir.Z)
            if horiz.Magnitude>0.01 then horiz=horiz.Unit end
            local pitch=math.asin(math.clamp(camLook.Y,-1,1))
            local dir=horiz*math.cos(pitch)+Vector3.new(0,math.sin(pitch),0)
            velocity=dir*F.speed*moveDir.Magnitude
        end
        F.bv.Velocity=velocity
        F.bg.CFrame=cam.CFrame
    end)
end
local function flyStop()
    local F=Mv.Fly
    if not F.enabled then
        pcall(function() if FeatureControl.ui.Fly then FeatureControl.ui.Fly:Sync(false) end end)
        return
    end
    F.enabled=false
    if F.conn then pcall(function() F.conn:Disconnect() end); F.conn=nil end
    if F.bv then pcall(function() F.bv:Destroy() end); F.bv=nil end
    if F.bg then pcall(function() F.bg:Destroy() end); F.bg=nil end
    syncFeatureUI("Fly",false)
    local char=LP.Character
    if char then
        local h=char:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand=false
            pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    end
end
local function findWaterPlane()
    local map=WS:FindFirstChild("Map"); if not map then return nil end
    return map:FindFirstChild("WaterBase-Plane")
end
local function waterStart()
    local W=Mv.Water
    if W.enabled then return end
    W.enabled=true
    local ch=LP.Character
    if ch then local hum=ch:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Swimming,false) end) end end
    W.thread=task.spawn(function()
        local plane=findWaterPlane(); local tries=0
        while not plane and tries<30 and W.enabled do task.wait(0.5); plane=findWaterPlane(); tries=tries+1 end
        if not plane then W.enabled=false; return end
        W.plane=plane; W.origSize=plane.Size
        while W.enabled do
            if plane and plane.Parent then
                pcall(function() plane.Size=Vector3.new(plane.Size.X,113,plane.Size.Z) end)
            else
                plane=findWaterPlane()
                if plane then W.plane=plane; W.origSize=plane.Size end
            end
            task.wait(0.3)
        end
        if plane and plane.Parent and W.origSize then pcall(function() plane.Size=W.origSize end) end
    end)
end
local function waterStop()
    local W=Mv.Water
    if not W.enabled then syncFeatureUI("Water",false); return end
    W.enabled=false; task.wait(0.4)
    syncFeatureUI("Water",false)
    local ch=LP.Character
    if ch then local hum=ch:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Swimming,true) end) end end
end
local function noclipApply(ch)
    for _,p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then
            if p:GetAttribute("__nc_orig")==nil then p:SetAttribute("__nc_orig",p.CanCollide) end
            p.CanCollide=false
        end
    end
end
local function noclipRestore(ch)
    for _,p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then
            local o=p:GetAttribute("__nc_orig")
            if o~=nil then p.CanCollide=o; p:SetAttribute("__nc_orig",nil) end
        end
    end
end
local function noclipStart()
    local N=Mv.Noclip; if N.enabled then return end
    N.enabled=true; N.conns={}
    local function hook(ch)
        noclipApply(ch)
        table.insert(N.conns,ch.DescendantAdded:Connect(function(p)
            if N.enabled and p:IsA("BasePart") then
                if p:GetAttribute("__nc_orig")==nil then p:SetAttribute("__nc_orig",p.CanCollide) end
                p.CanCollide=false
            end
        end))
    end
    if LP.Character then hook(LP.Character) end
    table.insert(N.conns,LP.CharacterAdded:Connect(function(ch) task.wait(0.3); if N.enabled then hook(ch) end end))
    local acc=0
    N.loopConn=RS.Heartbeat:Connect(function(dt)
        if not N.enabled then return end
        acc=acc+dt; if acc<0.2 then return end; acc=0
        local ch=LP.Character; if not ch then return end
        for _,p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end)
end
local function noclipStop()
    local N=Mv.Noclip; if not N.enabled then syncFeatureUI("Noclip",false); return end
    N.enabled=false
    for _,c in ipairs(N.conns) do pcall(function() c:Disconnect() end) end
    N.conns={}
    if N.loopConn then pcall(function() N.loopConn:Disconnect() end); N.loopConn=nil end
    if LP.Character then noclipRestore(LP.Character) end
    syncFeatureUI("Noclip",false)
end
trackPersistent(LP.CharacterAdded:Connect(function()
    task.wait(0.4)
    if Mv.Fly.enabled then flyStop() else syncFeatureUI("Fly",false) end
    if Mv.Water.enabled then
        local ch=LP.Character
        if ch then local hum=ch:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Swimming,false) end) end end
    end
    if FlyCam and FlyCam.enabled then pcall(function() flycamStop() end) end
    if tbl and tbl.CamLock then pcall(function() OnCamLockToggle(false) end) end
    if tbl and tbl.SpectatePlayer then pcall(function() OnSpectateToggle(false) end) end
    pcall(function() tweenStop() end)
    if Mv.Noclip.enabled then pcall(function() noclipStop() end) end
    if POV and POV.enabled then pcall(function() povStop() end) end
end))

-- ═══════════════ VFX COLOR ═══════════════
local VFXColor = {
    enabled=false, color=Color3.fromRGB(255,0,170), backups={}, conns={},
    generation=0, previewFrame=nil, previewLabel=nil, picker=nil, tintOthers=false,
}
local VFX_CLASSES = {
    ParticleEmitter=true,Beam=true,Trail=true,Fire=true,Smoke=true,Sparkles=true,
    PointLight=true,SpotLight=true,SurfaceLight=true,Decal=true,Texture=true,
}
local BODY = {
    HumanoidRootPart=true,Head=true,Torso=true,["Left Arm"]=true,["Right Arm"]=true,
    ["Left Leg"]=true,["Right Leg"]=true,UpperTorso=true,LowerTorso=true,
    LeftUpperArm=true,RightUpperArm=true,LeftLowerArm=true,RightLowerArm=true,
    LeftUpperLeg=true,RightUpperLeg=true,LeftFoot=true,RightFoot=true,
    LeftHand=true,RightHand=true,
}
local function isBodyPart(obj)
    return obj:IsA("BasePart") and BODY[obj.Name]==true
        and obj.Parent and Players:GetPlayerFromCharacter(obj.Parent)~=nil
end
local function isVFXBasePart(obj)
    if not obj:IsA("BasePart") or obj==WS.Terrain or isBodyPart(obj) then return false end
    if obj.Material==Enum.Material.Neon or obj.Material==Enum.Material.ForceField
        or obj.Material==Enum.Material.Glass then return true end
    if obj.Transparency>0.05 and obj.Transparency<0.99 then return true end
    for _,c in ipairs(obj:GetChildren()) do
        if VFX_CLASSES[c.ClassName] then return true end
    end
    return false
end
local function getOwnerTag(obj)
    local anc=obj; local myChar=LP.Character
    while anc and anc~=WS do
        if myChar and anc==myChar then return "self" end
        local plr=Players:GetPlayerFromCharacter(anc)
        if plr then return plr==LP and "self" or "other" end
        if anc:FindFirstChildOfClass("Humanoid") and not plr then return "npc" end
        anc=anc.Parent
    end
    return "world"
end
local function nearLocalCharacter(obj, maxDistance)
    local ch=LP.Character
    local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pos=nil
    if obj:IsA("BasePart") then pos=obj.Position
    else
        local p=obj.Parent
        while p and p~=WS do
            if p:IsA("BasePart") then pos=p.Position; break end
            p=p.Parent
        end
    end
    return pos~=nil and (pos-hrp.Position).Magnitude<=(maxDistance or 110)
end
local function shouldTint(obj)
    if not VFXColor.enabled or not obj or not obj.Parent then return false end
    local tag=getOwnerTag(obj)
    if tag=="self" then return true end
    if VFXColor.tintOthers then
        return tag=="other" or tag=="npc" or nearLocalCharacter(obj,110)
    end
    return tag=="world" and nearLocalCharacter(obj,110)
end
local function remapColor(orig)
    local target=VFXColor.color
    if not orig then return target end
    local _,_,ov=Color3.toHSV(orig)
    local th,ts,tv=Color3.toHSV(target)
    local _,os,_=Color3.toHSV(orig)
    if ts<0.03 then return Color3.fromHSV(0,0,math.clamp(ov*tv,0,1)) end
    local value=math.clamp(ov*(0.55+tv*0.45),0,1)
    local sat=math.clamp(math.max(ts,0.85)*(0.65+os*0.35),0,1)
    return Color3.fromHSV(th,sat,value)
end
local function remapSeq(seq)
    if not seq then return seq end
    local kps={}
    for _,kp in ipairs(seq.Keypoints) do
        table.insert(kps,ColorSequenceKeypoint.new(kp.Time,remapColor(kp.Value)))
    end
    return ColorSequence.new(kps)
end
local function backup(obj,prop)
    local B=VFXColor.backups[obj]
    if not B then B={}; VFXColor.backups[obj]=B end
    if B[prop]==nil then
        local ok,v=pcall(function() return obj[prop] end)
        if ok then B[prop]=v end
    end
end
local function applyTint(obj)
    local B=VFXColor.backups[obj]
    if not B then return end
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            if B.Color then obj.Color=remapSeq(B.Color) end
        elseif obj:IsA("Beam") then
            if B.Color then obj.Color=remapSeq(B.Color) end
            if B.Color2 then obj.Color2=remapColor(B.Color2) end
        elseif obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            if B.Color then obj.Color=remapColor(B.Color) end
        elseif obj:IsA("Sparkles") then
            if B.SparkleColor then obj.SparkleColor=remapColor(B.SparkleColor) end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if B.Color3 then obj.Color3=remapColor(B.Color3) end
        elseif obj:IsA("BasePart") and isVFXBasePart(obj) then
            if B.Color then obj.Color=remapColor(B.Color) end
            for _,m in ipairs(obj:GetChildren()) do
                if m:IsA("SpecialMesh") then
                    local Bm=VFXColor.backups[m]
                    if Bm and Bm.VertexColor then m.VertexColor=remapColor(Bm.VertexColor) end
                end
            end
        end
    end)
end
local function tintObj(obj)
    if not shouldTint(obj) then return end
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then backup(obj,"Color")
        elseif obj:IsA("Beam") then backup(obj,"Color"); backup(obj,"Color2")
        elseif obj:IsA("Fire") or obj:IsA("Smoke")
            or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then backup(obj,"Color")
        elseif obj:IsA("Sparkles") then backup(obj,"SparkleColor")
        elseif obj:IsA("Decal") or obj:IsA("Texture") then backup(obj,"Color3")
        elseif obj:IsA("BasePart") and isVFXBasePart(obj) then
            backup(obj,"Color")
            for _,m in ipairs(obj:GetChildren()) do
                if m:IsA("SpecialMesh") then backup(m,"VertexColor") end
            end
        else return end
        applyTint(obj)
    end)
end
local function tintTree(root)
    if not root or not root.Parent then return end
    if VFX_CLASSES[root.ClassName] or (root:IsA("BasePart") and isVFXBasePart(root)) then tintObj(root) end
    for _,c in ipairs(root:GetDescendants()) do
        if VFX_CLASSES[c.ClassName] or (c:IsA("BasePart") and isVFXBasePart(c)) then tintObj(c) end
    end
end
local function onNewObj(obj)
    if not VFXColor.enabled or not obj or not obj.Parent then return end
    local gen=VFXColor.generation
    if VFX_CLASSES[obj.ClassName] or obj:IsA("BasePart") then
        task.defer(function()
            if VFXColor.enabled and VFXColor.generation==gen and obj.Parent then tintObj(obj) end
        end)
    end
end
local function restoreVFX()
    for obj,props in pairs(VFXColor.backups) do
        if obj and obj.Parent then
            for prop,val in pairs(props) do pcall(function() obj[prop]=val end) end
        end
    end
    VFXColor.backups={}
end
local function startVFX()
    if VFXColor.enabled then return end
    VFXColor.enabled=true
    VFXColor.generation=VFXColor.generation+1
    VFXColor.backups={}
    local gen=VFXColor.generation
    if LP.Character then tintTree(LP.Character) end
    table.insert(VFXColor.conns,LP.CharacterAdded:Connect(function(ch)
        task.wait(.25); if VFXColor.enabled then tintTree(ch) end
    end))
    table.insert(VFXColor.conns,WS.DescendantAdded:Connect(function(obj)
        if VFXColor.enabled and VFXColor.generation==gen then onNewObj(obj) end
    end))
end
local function stopVFX()
    if not VFXColor.enabled and next(VFXColor.backups)==nil then
        syncFeatureUI("VFX",false)
        return
    end
    VFXColor.enabled=false
    VFXColor.generation=VFXColor.generation+1
    for _,c in ipairs(VFXColor.conns) do pcall(function() c:Disconnect() end) end
    VFXColor.conns={}
    restoreVFX()
    syncFeatureUI("VFX",false)
end
local function reapplyVFX()
    if not VFXColor.enabled then return end
    for obj in pairs(VFXColor.backups) do
        if obj and obj.Parent and shouldTint(obj) then applyTint(obj) end
    end
end
local function updateVFXPreview()
    if VFXColor.previewFrame and VFXColor.previewFrame.Parent then
        VFXColor.previewFrame.BackgroundColor3=VFXColor.color
    end
    if VFXColor.previewLabel and VFXColor.previewLabel.Parent then
        local c=VFXColor.color
        VFXColor.previewLabel.Text=string.format("#%02X%02X%02X",
            math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))
    end
end

local function openVFXColorPicker()
    if VFXColor.picker and VFXColor.picker.Parent then return end
    local overlay=Instance.new("Frame",GUI)
    overlay.Name="VFXColorOverlay"
    overlay.Size=UDim2.fromScale(1,1); overlay.Position=UDim2.fromScale(0,0)
    overlay.BackgroundColor3=Color3.new(0,0,0); overlay.BackgroundTransparency=.5
    overlay.BorderSizePixel=0; overlay.ZIndex=9000
    overlay.Active=true
    overlay:SetAttribute("__NoPressScale",true)
    local modal=Instance.new("Frame",overlay)
    modal.Name="VFXColorPicker"
    modal.AnchorPoint=Vector2.new(.5,.5); modal.Position=UDim2.fromScale(.5,.5)
    modal.Size=UDim2.fromOffset(340,440)
    modal.BackgroundColor3=Color3.fromRGB(26,30,45)
    modal.BorderSizePixel=0; modal.ZIndex=9001
    modal.Active=true; modal:SetAttribute("__NoPressScale",true)
    modal.ClipsDescendants=false
    cr(modal,16); sk(modal,Color3.fromRGB(80,100,160),1.5)
    local modalScale=Instance.new("UIScale",modal); modalScale.Scale=0.75
    local titleBar=Instance.new("Frame",modal)
    titleBar.Size=UDim2.new(1,0,0,52); titleBar.Position=UDim2.fromOffset(0,0)
    titleBar.BackgroundColor3=Color3.fromRGB(32,38,58)
    titleBar.BorderSizePixel=0; titleBar.ZIndex=9002; titleBar.Active=false
    cr(titleBar,16)
    local titleMask=Instance.new("Frame",titleBar)
    titleMask.Size=UDim2.new(1,0,0,10); titleMask.Position=UDim2.new(0,0,1,-10)
    titleMask.BackgroundColor3=Color3.fromRGB(32,38,58)
    titleMask.BorderSizePixel=0; titleMask.ZIndex=9002; titleMask.Active=false
    local title=Instance.new("TextLabel",titleBar)
    title.Size=UDim2.new(1,-100,0,52); title.Position=UDim2.fromOffset(18,0)
    title.BackgroundTransparency=1; title.Text="Chọn một màu"
    title.TextColor3=Color3.fromRGB(240,245,255); title.Font=Enum.Font.GothamBold
    title.TextSize=17; title.TextXAlignment=Enum.TextXAlignment.Left; title.ZIndex=9003
    local closeBtn=Instance.new("TextButton",titleBar)
    closeBtn.Size=UDim2.fromOffset(32,32); closeBtn.AnchorPoint=Vector2.new(1,.5)
    closeBtn.Position=UDim2.new(1,-70,.5,0)
    closeBtn.BackgroundColor3=Color3.fromRGB(60,65,90)
    closeBtn.Text="X"; closeBtn.TextColor3=Color3.fromRGB(240,245,255)
    closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=14
    closeBtn.AutoButtonColor=false; closeBtn.BorderSizePixel=0
    closeBtn.ZIndex=9003; closeBtn.Active=true
    closeBtn:SetAttribute("__NoPressScale",true); cr(closeBtn,8)
    local choose=Instance.new("TextButton",titleBar)
    choose.Size=UDim2.fromOffset(62,32); choose.AnchorPoint=Vector2.new(1,.5)
    choose.Position=UDim2.new(1,-14,.5,0)
    choose.BackgroundColor3=Color3.fromRGB(59,130,246)
    choose.Text="Chọn"; choose.TextColor3=Color3.fromRGB(255,255,255)
    choose.Font=Enum.Font.GothamBold; choose.TextSize=13
    choose.AutoButtonColor=false; choose.BorderSizePixel=0
    choose.ZIndex=9003; choose.Active=true
    choose:SetAttribute("__NoPressScale",true); cr(choose,8)
    local hexLabel=Instance.new("TextLabel",modal)
    hexLabel.Size=UDim2.new(1,-36,0,18); hexLabel.Position=UDim2.fromOffset(18,64)
    hexLabel.BackgroundTransparency=1; hexLabel.Text="Mã màu HEX"
    hexLabel.TextColor3=Color3.fromRGB(140,155,190); hexLabel.Font=Enum.Font.GothamMedium
    hexLabel.TextSize=11; hexLabel.TextXAlignment=Enum.TextXAlignment.Left; hexLabel.ZIndex=9003
    local hex=Instance.new("TextBox",modal)
    hex.Size=UDim2.new(1,-36,0,42); hex.Position=UDim2.fromOffset(18,84)
    hex.BackgroundColor3=Color3.fromRGB(19,23,38)
    hex.TextColor3=Color3.fromRGB(240,245,255)
    hex.PlaceholderText="#RRGGBB"
    hex.PlaceholderColor3=Color3.fromRGB(120,130,160)
    hex.TextXAlignment=Enum.TextXAlignment.Left
    hex.Font=Enum.Font.GothamMedium; hex.TextSize=15
    hex.ClearTextOnFocus=false; hex.BorderSizePixel=0
    hex.ZIndex=9003; hex.Active=true
    hex:SetAttribute("__NoPressScale",true)
    cr(hex,10); sk(hex,Color3.fromRGB(60,75,120),1)
    local pickerLabel=Instance.new("TextLabel",modal)
    pickerLabel.Size=UDim2.new(1,-36,0,18); pickerLabel.Position=UDim2.fromOffset(18,136)
    pickerLabel.BackgroundTransparency=1; pickerLabel.Text="Độ bão hòa / Độ sáng"
    pickerLabel.TextColor3=Color3.fromRGB(140,155,190); pickerLabel.Font=Enum.Font.GothamMedium
    pickerLabel.TextSize=11; pickerLabel.TextXAlignment=Enum.TextXAlignment.Left; pickerLabel.ZIndex=9003
    local picker=Instance.new("Frame",modal)
    picker.Size=UDim2.new(1,-36,0,170); picker.Position=UDim2.fromOffset(18,156)
    picker.BackgroundColor3=VFXColor.color
    picker.BorderSizePixel=0; picker.ClipsDescendants=true
    picker.ZIndex=9002; picker.Active=true
    picker:SetAttribute("__NoPressScale",true)
    cr(picker,10); sk(picker,Color3.fromRGB(60,75,120),1)
    local white=Instance.new("Frame",picker)
    white.Size=UDim2.fromScale(1,1); white.BackgroundColor3=Color3.new(1,1,1)
    white.BorderSizePixel=0; white.ZIndex=9003; white.Active=false
    local wg=Instance.new("UIGradient",white)
    wg.Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1))
    wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
    local black=Instance.new("Frame",picker)
    black.Size=UDim2.fromScale(1,1); black.BackgroundColor3=Color3.new(0,0,0)
    black.BorderSizePixel=0; black.ZIndex=9004; black.Active=false
    local bg2=Instance.new("UIGradient",black)
    bg2.Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0))
    bg2.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
    bg2.Rotation=90
    local satKnob=Instance.new("Frame",picker)
    satKnob.Size=UDim2.fromOffset(20,20); satKnob.AnchorPoint=Vector2.new(.5,.5)
    satKnob.BackgroundColor3=Color3.new(1,1,1)
    satKnob.BorderSizePixel=0; satKnob.ZIndex=9006; satKnob.Active=false
    cr(satKnob,10); sk(satKnob,Color3.new(0,0,0),2)
    local hueLabel=Instance.new("TextLabel",modal)
    hueLabel.Size=UDim2.new(1,-36,0,18); hueLabel.Position=UDim2.fromOffset(18,336)
    hueLabel.BackgroundTransparency=1; hueLabel.Text="Màu sắc (Hue)"
    hueLabel.TextColor3=Color3.fromRGB(140,155,190); hueLabel.Font=Enum.Font.GothamMedium
    hueLabel.TextSize=11; hueLabel.TextXAlignment=Enum.TextXAlignment.Left; hueLabel.ZIndex=9003
    local hueBar=Instance.new("Frame",modal)
    hueBar.Size=UDim2.new(1,-36,0,24); hueBar.Position=UDim2.fromOffset(18,356)
    hueBar.BorderSizePixel=0; hueBar.ZIndex=9002; hueBar.Active=true
    hueBar:SetAttribute("__NoPressScale",true)
    cr(hueBar,10); sk(hueBar,Color3.fromRGB(60,75,120),1)
    local hg=Instance.new("UIGradient",hueBar)
    hg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(.166,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(.333,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(.666,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(.833,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })
    local hueKnob=Instance.new("Frame",hueBar)
    hueKnob.Size=UDim2.fromOffset(12,32); hueKnob.AnchorPoint=Vector2.new(.5,.5)
    hueKnob.BackgroundColor3=VFXColor.color
    hueKnob.BorderSizePixel=0; hueKnob.ZIndex=9003; hueKnob.Active=false
    cr(hueKnob,6); sk(hueKnob,Color3.new(1,1,1),2.5)
    local previewSwatch=Instance.new("Frame",modal)
    previewSwatch.Size=UDim2.fromOffset(60,32); previewSwatch.AnchorPoint=Vector2.new(1,0)
    previewSwatch.Position=UDim2.new(1,-18,0,400)
    previewSwatch.BackgroundColor3=VFXColor.color
    previewSwatch.BorderSizePixel=0; previewSwatch.ZIndex=9003; previewSwatch.Active=false
    cr(previewSwatch,8); sk(previewSwatch,Color3.fromRGB(80,100,160),1.5)
    local function hexOf(c) return string.format("#%02X%02X%02X",
        math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end
    local function parseHex(t)
        t=t:gsub("#",""):gsub("%s","")
        if #t~=6 then return nil end
        local n=tonumber(t,16); if not n then return nil end
        return Color3.fromRGB(math.floor(n/65536)%256,math.floor(n/256)%256,n%256)
    end
    local current=VFXColor.color
    local h,ss,v=Color3.toHSV(current)
    local closed=false
    local connections={}
    local function connect(sig,fn) local c=sig:Connect(fn); table.insert(connections,c); return c end
    local function setColor(c)
        if not c then return end
        current=c
        h,ss,v=Color3.toHSV(c)
        picker.BackgroundColor3=Color3.fromHSV(h,1,1)
        satKnob.Position=UDim2.fromScale(ss,1-v)
        hueKnob.Position=UDim2.fromScale(h,.5)
        hueKnob.BackgroundColor3=c
        previewSwatch.BackgroundColor3=c
        hex.Text=hexOf(c)
    end
    local draggingSV=false
    local function updateSV(x,y)
        if closed then return end
        local ps=picker.AbsoluteSize
        if ps.X<=0 or ps.Y<=0 then return end
        local a=math.clamp((x-picker.AbsolutePosition.X)/ps.X,0,1)
        local b=math.clamp((y-picker.AbsolutePosition.Y)/ps.Y,0,1)
        setColor(Color3.fromHSV(h,a,1-b))
    end
    connect(picker.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingSV=true; updateSV(i.Position.X,i.Position.Y)
        end
    end)
    connect(picker.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingSV=false end
    end)
    local draggingH=false
    local function updateH(x)
        if closed then return end
        local sz=hueBar.AbsoluteSize
        if sz.X<=0 then return end
        h=math.clamp((x-hueBar.AbsolutePosition.X)/sz.X,0,1)
        setColor(Color3.fromHSV(h,ss,v))
    end
    connect(hueBar.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingH=true; updateH(i.Position.X)
        end
    end)
    connect(hueBar.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingH=false end
    end)
    connect(UIS.InputChanged,function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            if draggingSV then updateSV(i.Position.X,i.Position.Y)
            elseif draggingH then updateH(i.Position.X) end
        end
    end)
    connect(hex.FocusLost,function()
        local c=parseHex(hex.Text)
        if c then setColor(c) else hex.Text=hexOf(current) end
    end)
    local function close(commit)
        if closed then return end
        closed=true
        draggingSV=false; draggingH=false
        if commit then
            VFXColor.color=current
            updateVFXPreview()
            reapplyVFX()
        end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        table.clear(connections)
        if overlay and overlay.Parent then
            overlay.Visible=false
            task.defer(function() if overlay and overlay.Parent then overlay:Destroy() end end)
        end
        if VFXColor.picker==overlay then VFXColor.picker=nil end
    end
    choose.MouseButton1Click:Connect(function() close(true) end)
    closeBtn.MouseButton1Click:Connect(function() close(false) end)
    setColor(current)
    VFXColor.picker=overlay
end

-- ═══════════════ THEME UI ═══════════════
local Theme = {
    color = T.Accent,
    mode = "Bình thường",
    intensity = 100,
    brightness = 100,
    rgbSpeed = 100,
    imageId = "",
    imageTransparency = 0.05,
    _rgbHue = 0,
    _rgbAcc = 0,
    previewFrame = nil,
    previewLabel = nil,
    applyToken = 0,
}
local ThemeColorOverlay = nil
local rgbBorder = Instance.new("UIStroke", Main)
rgbBorder.Name = "__rgbBorder"
rgbBorder.Color = T.Accent
rgbBorder.Thickness = 2
rgbBorder.Transparency = 0.05
rgbBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
local rgbGrad = Instance.new("UIGradient", rgbBorder)
rgbGrad.Name = "__rgbGradient"
rgbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255,0,0)),
    ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
    ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
    ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
    ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
    ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
})
rgbGrad.Rotation = 0

local ThemeTracked=setmetatable({}, {__mode="k"})
local function trackThemeObject(d)
    if d and (d:IsA("GuiObject") or d:IsA("UIStroke") or d:IsA("UIGradient")) then
        ThemeTracked[d]=true
    end
end
for _,d in ipairs(GUI:GetDescendants()) do trackThemeObject(d) end
local themeTrackAddedConn=GUI.DescendantAdded:Connect(trackThemeObject)
local themeTrackRemovingConn=trackPersistent(GUI.DescendantRemoving:Connect(function(d) ThemeTracked[d]=nil end))

local function themeSame(a,b)
    return typeof(a)=="Color3" and typeof(b)=="Color3"
        and math.abs(a.R-b.R)<0.0001
        and math.abs(a.G-b.G)<0.0001
        and math.abs(a.B-b.B)<0.0001
end

local function themeHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))
end

local function themeParseHex(t)
    t=tostring(t or ""):gsub("#",""):gsub("%s","")
    if #t~=6 then return nil end
    local n=tonumber(t,16)
    if not n then return nil end
    return Color3.fromRGB(
        math.floor(n/65536)%256,
        math.floor(n/256)%256,
        n%256
    )
end

local function themeNeon(c, intensity, bright)
    local h,s,v=Color3.toHSV(c)
    if s < 0.06 then
        local dh,ds,dv=Color3.toHSV(Color3.fromRGB(59,130,246))
        h=dh
        s=math.max(s,ds)
    end
    local i=math.clamp((tonumber(intensity) or 100)/100, .5, 1.5)
    local b=math.clamp((tonumber(bright) or 100)/100, .5, 1.5)
    s=math.clamp(math.max(s,.75)*i*1.15, .70, 1)
    v=math.clamp(math.max(v,.78)*b*1.18, .72, 1)
    return Color3.fromHSV(h,s,v)
end

local function themeRainbowSequence(h0)
    local k={}
    for i=0,6 do
        local p=i/6
        local c=Color3.fromHSV((h0+p)%1,1,1)
        k[#k+1]=ColorSequenceKeypoint.new(p,c)
    end
    k[#k]=ColorSequenceKeypoint.new(1,Color3.fromHSV(h0%1,1,1))
    return ColorSequence.new(k)
end

-- UIGradient on UIStroke is unreliable in some Roblox clients. Use four
-- real GuiObject strips so the rainbow is visible on every side of the frame.
local rgbEdgeItems={}
local function makeRgbEdge(name,position,size,rotation,phase)
    local edge=Instance.new("Frame")
    edge.Name=name
    edge.Position=position
    edge.Size=size
    edge.BackgroundColor3=Color3.new(1,1,1)
    edge.BorderSizePixel=0
    edge.Visible=false
    edge.Active=false
    edge.ZIndex=20
    edge.Parent=Main
    local gradient=Instance.new("UIGradient")
    gradient.Rotation=rotation
    gradient.Color=themeRainbowSequence(phase)
    gradient.Offset=Vector2.new(0,0)
    gradient.Parent=edge
    table.insert(rgbEdgeItems,{frame=edge,gradient=gradient,phase=phase})
end
makeRgbEdge("__RGBEdgeTop",UDim2.new(0,14,0,1),UDim2.new(1,-28,0,3),0,0)
makeRgbEdge("__RGBEdgeRight",UDim2.new(1,-4,0,14),UDim2.new(0,3,1,-28),90,.25)
makeRgbEdge("__RGBEdgeBottom",UDim2.new(0,14,1,-4),UDim2.new(1,-28,0,3),180,.5)
makeRgbEdge("__RGBEdgeLeft",UDim2.new(0,1,0,14),UDim2.new(0,3,1,-28),270,.75)

local function themeApply()
    local selected
    if Theme.mode=="RGB" then
        selected=Color3.fromHSV(Theme._rgbHue%1,1,1)
    elseif Theme.mode=="Neon" then
        selected=themeNeon(Theme.color,Theme.intensity,Theme.brightness)
    else
        selected=Theme.color
    end
    local oldAccent=T.Accent
    local oldAccent2=T.Accent2
    local oldOn=T.On
    local DEFAULT_A1 = Color3.fromRGB(59,130,246)
    local DEFAULT_A2 = Color3.fromRGB(37,99,235)
    local oh,os,ov=Color3.toHSV(selected)
    local accent2=Color3.fromHSV(oh,math.clamp(os*.90,0,1),math.clamp(ov*.72,0,1))

    T.Accent=selected
    T.Accent2=accent2
    T.On=selected

    for d in pairs(ThemeTracked) do
        if d and d.Parent and d.Name~="__rgbBorder" then
            if d:IsA("UIStroke") then
                if themeSame(d.Color,oldAccent) or themeSame(d.Color,oldOn) or themeSame(d.Color,DEFAULT_A1) then
                    d.Color=selected
                elseif themeSame(d.Color,oldAccent2) or themeSame(d.Color,DEFAULT_A2) then
                    d.Color=accent2
                end
            elseif d:IsA("GuiObject") then
                if themeSame(d.BackgroundColor3,oldAccent) or themeSame(d.BackgroundColor3,oldOn) or themeSame(d.BackgroundColor3,DEFAULT_A1) then
                    d.BackgroundColor3=selected
                elseif themeSame(d.BackgroundColor3,oldAccent2) or themeSame(d.BackgroundColor3,DEFAULT_A2) then
                    d.BackgroundColor3=accent2
                end
            end
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                if themeSame(d.TextColor3,oldAccent) or themeSame(d.TextColor3,oldOn) or themeSame(d.TextColor3,DEFAULT_A1) then
                    d.TextColor3=selected
                elseif themeSame(d.TextColor3,oldAccent2) or themeSame(d.TextColor3,DEFAULT_A2) then
                    d.TextColor3=accent2
                end
            end
            if d:IsA("UIGradient") then
                local changed=false
                local keys={}
                for _,kp in ipairs(d.Color.Keypoints) do
                    local c=kp.Value
                    local nc=c
                    if themeSame(c,oldAccent) or themeSame(c,oldOn) or themeSame(c,DEFAULT_A1) then
                        nc=selected
                    elseif themeSame(c,oldAccent2) or themeSame(c,DEFAULT_A2) then
                        nc=accent2
                    end
                    if not themeSame(nc,c) then changed=true end
                    keys[#keys+1]=ColorSequenceKeypoint.new(kp.Time,nc)
                end
                if changed then d.Color=ColorSequence.new(keys) end
            end
        end
    end

    rgbBorder.Color=selected
    if Theme.mode=="RGB" then
        rgbBorder.Thickness = 3.5
        rgbBorder.Transparency = 0
        -- Keep a cycling base stroke and animate real gradient strips over it.
        rgbGrad.Enabled = false
        rgbBorder.Color = Color3.fromHSV(Theme._rgbHue % 1, 1, 1)
        for _,item in ipairs(rgbEdgeItems) do
            item.frame.Visible=true
            item.gradient.Enabled=true
            item.gradient.Color=themeRainbowSequence((Theme._rgbHue+item.phase)%1)
        end
    else
        rgbBorder.Thickness = 2
        rgbBorder.Transparency = .05
        rgbGrad.Enabled=false
        for _,item in ipairs(rgbEdgeItems) do
            item.frame.Visible=false
            item.gradient.Enabled=false
        end
    end
    if Theme.previewFrame and Theme.previewFrame.Parent then
        Theme.previewFrame.BackgroundColor3=Theme.color
    end
    if Theme.previewLabel and Theme.previewLabel.Parent then
        Theme.previewLabel.Text=themeHex(Theme.color)
    end

    ImageThemeActive = (Theme.mode=="Ảnh nền" and Theme.imageId~="")
    ThemeImageBackground.Image = Theme.imageId
    ThemeImageBackground.ImageTransparency = Theme.imageTransparency
    ThemeImageBackground.Visible = ImageThemeActive
    if apAll then apAll() end
end

local function openThemeColorPicker()
    if ThemeColorOverlay and ThemeColorOverlay.Parent then return end
    local overlay=Instance.new("Frame",GUI)
    overlay.Name="ThemeColorOverlay"
    overlay.Size=UDim2.fromScale(1,1)
    overlay.BackgroundColor3=Color3.new(0,0,0)
    overlay.BackgroundTransparency=.5
    overlay.BorderSizePixel=0
    overlay.ZIndex=9050
    overlay.Active=true
    overlay:SetAttribute("__NoPressScale",true)
    ThemeColorOverlay=overlay

    local modal=Instance.new("Frame",overlay)
    modal.Name="ThemeColorPicker"
    modal.AnchorPoint=Vector2.new(.5,.5)
    modal.Position=UDim2.fromScale(.5,.5)
    modal.Size=UDim2.fromOffset(340,440)
    modal.BackgroundColor3=Color3.fromRGB(26,30,45)
    modal.BorderSizePixel=0
    modal.ZIndex=9051
    modal.Active=true
    modal:SetAttribute("__NoPressScale",true)
    cr(modal,16); sk(modal,Color3.fromRGB(80,100,160),1.5)

    local title=Instance.new("TextLabel",modal)
    title.Size=UDim2.new(1,-100,0,48)
    title.Position=UDim2.fromOffset(18,0)
    title.BackgroundTransparency=1
    title.Text="🎨 Chọn màu Theme"
    title.TextColor3=Color3.fromRGB(240,245,255)
    title.Font=Enum.Font.GothamBold
    title.TextSize=16
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=9052

    local closeBtn=Instance.new("TextButton",modal)
    closeBtn.Size=UDim2.fromOffset(32,32)
    closeBtn.AnchorPoint=Vector2.new(1,.5)
    closeBtn.Position=UDim2.new(1,-18,.5,0)
    closeBtn.BackgroundColor3=Color3.fromRGB(60,65,90)
    closeBtn.Text="X"
    closeBtn.TextColor3=Color3.fromRGB(240,245,255)
    closeBtn.Font=Enum.Font.GothamBold
    closeBtn.TextSize=13
    closeBtn.AutoButtonColor=false
    closeBtn.BorderSizePixel=0
    closeBtn.ZIndex=9052
    closeBtn:SetAttribute("__NoPressScale",true)
    cr(closeBtn,8)

    local hexLabel=Instance.new("TextLabel",modal)
    hexLabel.Size=UDim2.new(1,-36,0,18)
    hexLabel.Position=UDim2.fromOffset(18,52)
    hexLabel.BackgroundTransparency=1
    hexLabel.Text="Mã màu HEX"
    hexLabel.TextColor3=Color3.fromRGB(140,155,190)
    hexLabel.Font=Enum.Font.GothamMedium
    hexLabel.TextSize=11
    hexLabel.TextXAlignment=Enum.TextXAlignment.Left
    hexLabel.ZIndex=9052

    local hex=Instance.new("TextBox",modal)
    hex.Size=UDim2.new(1,-36,0,42)
    hex.Position=UDim2.fromOffset(18,72)
    hex.BackgroundColor3=Color3.fromRGB(19,23,38)
    hex.TextColor3=Color3.fromRGB(240,245,255)
    hex.PlaceholderText="#RRGGBB"
    hex.PlaceholderColor3=Color3.fromRGB(120,130,160)
    hex.TextXAlignment=Enum.TextXAlignment.Left
    hex.Font=Enum.Font.GothamMedium
    hex.TextSize=15
    hex.ClearTextOnFocus=false
    hex.BorderSizePixel=0
    hex.ZIndex=9052
    hex.Active=true
    hex:SetAttribute("__NoPressScale",true)
    cr(hex,10); sk(hex,Color3.fromRGB(60,75,120),1)

    local svLabel=Instance.new("TextLabel",modal)
    svLabel.Size=UDim2.new(1,-36,0,18)
    svLabel.Position=UDim2.fromOffset(18,124)
    svLabel.BackgroundTransparency=1
    svLabel.Text="Độ bão hòa / Độ sáng"
    svLabel.TextColor3=Color3.fromRGB(140,155,190)
    svLabel.Font=Enum.Font.GothamMedium
    svLabel.TextSize=11
    svLabel.TextXAlignment=Enum.TextXAlignment.Left
    svLabel.ZIndex=9052

    local picker=Instance.new("Frame",modal)
    picker.Size=UDim2.new(1,-36,0,170)
    picker.Position=UDim2.fromOffset(18,144)
    picker.BorderSizePixel=0
    picker.ClipsDescendants=true
    picker.ZIndex=9051
    picker.Active=true
    picker:SetAttribute("__NoPressScale",true)
    cr(picker,10); sk(picker,Color3.fromRGB(60,75,120),1)

    local white=Instance.new("Frame",picker)
    white.Size=UDim2.fromScale(1,1)
    white.BackgroundColor3=Color3.new(1,1,1)
    white.BorderSizePixel=0
    white.ZIndex=9052
    local wg=Instance.new("UIGradient",white)
    wg.Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1))
    wg.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0),
        NumberSequenceKeypoint.new(1,1)
    })

    local black=Instance.new("Frame",picker)
    black.Size=UDim2.fromScale(1,1)
    black.BackgroundColor3=Color3.new(0,0,0)
    black.BorderSizePixel=0
    black.ZIndex=9053
    local bg2=Instance.new("UIGradient",black)
    bg2.Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0))
    bg2.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(1,0)
    })
    bg2.Rotation=90

    local satKnob=Instance.new("Frame",picker)
    satKnob.Size=UDim2.fromOffset(20,20)
    satKnob.AnchorPoint=Vector2.new(.5,.5)
    satKnob.BackgroundColor3=Color3.new(1,1,1)
    satKnob.BorderSizePixel=0
    satKnob.ZIndex=9054
    cr(satKnob,10); sk(satKnob,Color3.new(0,0,0),2)

    local hueLabel=Instance.new("TextLabel",modal)
    hueLabel.Size=UDim2.new(1,-36,0,18)
    hueLabel.Position=UDim2.fromOffset(18,320)
    hueLabel.BackgroundTransparency=1
    hueLabel.Text="Màu sắc (Hue)"
    hueLabel.TextColor3=Color3.fromRGB(140,155,190)
    hueLabel.Font=Enum.Font.GothamMedium
    hueLabel.TextSize=11
    hueLabel.TextXAlignment=Enum.TextXAlignment.Left
    hueLabel.ZIndex=9052

    local hueBar=Instance.new("Frame",modal)
    hueBar.Size=UDim2.new(1,-36,0,24)
    hueBar.Position=UDim2.fromOffset(18,340)
    hueBar.BorderSizePixel=0
    hueBar.ZIndex=9051
    hueBar.Active=true
    hueBar:SetAttribute("__NoPressScale",true)
    cr(hueBar,10); sk(hueBar,Color3.fromRGB(60,75,120),1)

    local hg=Instance.new("UIGradient",hueBar)
    hg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(.166,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(.333,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(.666,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(.833,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local hueKnob=Instance.new("Frame",hueBar)
    hueKnob.Size=UDim2.fromOffset(12,32)
    hueKnob.AnchorPoint=Vector2.new(.5,.5)
    hueKnob.BackgroundColor3=Theme.color
    hueKnob.BorderSizePixel=0
    hueKnob.ZIndex=9053
    cr(hueKnob,6); sk(hueKnob,Color3.new(1,1,1),2.5)

    local preview=Instance.new("Frame",modal)
    preview.Size=UDim2.fromOffset(60,32)
    preview.AnchorPoint=Vector2.new(1,0)
    preview.Position=UDim2.new(1,-18,0,386)
    preview.BorderSizePixel=0
    preview.BackgroundColor3=Theme.color
    preview.ZIndex=9052
    cr(preview,8); sk(preview,Color3.fromRGB(80,100,160),1.5)

    local apply=Instance.new("TextButton",modal)
    apply.Size=UDim2.fromOffset(88,32)
    apply.AnchorPoint=Vector2.new(1,0)
    apply.Position=UDim2.new(1,-92,0,386)
    apply.BackgroundColor3=T.Accent
    apply.Text="Áp dụng"
    apply.Font=Enum.Font.GothamBold
    apply.TextSize=12
    apply.TextColor3=Color3.fromRGB(255,255,255)
    apply.AutoButtonColor=false
    apply.BorderSizePixel=0
    apply.ZIndex=9052
    cr(apply,8)

    local current=Theme.color
    local h,s,v=Color3.toHSV(current)
    local draggingSV=false
    local draggingH=false
    local closed=false
    local connections={}

    local function connect(sig,fn)
        local c=sig:Connect(fn)
        table.insert(connections,c)
        return c
    end

    local function setColor(c)
        current=c
        h,s,v=Color3.toHSV(c)
        picker.BackgroundColor3=Color3.fromHSV(h,1,1)
        satKnob.Position=UDim2.fromScale(s,1-v)
        hueKnob.Position=UDim2.fromScale(h,.5)
        hueKnob.BackgroundColor3=c
        preview.BackgroundColor3=c
        hex.Text=themeHex(c)
    end

    local function updateSV(x,y)
        if closed then return end
        local sz=picker.AbsoluteSize
        if sz.X<=0 or sz.Y<=0 then return end
        local ns=math.clamp((x-picker.AbsolutePosition.X)/sz.X,0,1)
        local nv=1-math.clamp((y-picker.AbsolutePosition.Y)/sz.Y,0,1)
        setColor(Color3.fromHSV(h,ns,nv))
    end

    local function updateH(x)
        if closed then return end
        local sz=hueBar.AbsoluteSize
        if sz.X<=0 then return end
        h=math.clamp((x-hueBar.AbsolutePosition.X)/sz.X,0,1)
        setColor(Color3.fromHSV(h,s,v))
    end

    connect(picker.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingSV=true
            updateSV(i.Position.X,i.Position.Y)
        end
    end)
    connect(picker.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingSV=false
        end
    end)
    connect(hueBar.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingH=true
            updateH(i.Position.X)
        end
    end)
    connect(hueBar.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingH=false
        end
    end)
    connect(UIS.InputChanged,function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            if draggingSV then
                updateSV(i.Position.X,i.Position.Y)
            elseif draggingH then
                updateH(i.Position.X)
            end
        end
    end)
    connect(hex.FocusLost,function()
        local c=themeParseHex(hex.Text)
        if c then setColor(c) else hex.Text=themeHex(current) end
    end)

    local function close(commit)
        if closed then return end
        closed=true
        draggingSV=false
        draggingH=false
        if commit then
            Theme.color=current
            themeApply()
        end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        table.clear(connections)
        if overlay and overlay.Parent then
            overlay.Visible=false
            task.defer(function()
                if overlay and overlay.Parent then overlay:Destroy() end
            end)
        end
        if ThemeColorOverlay==overlay then ThemeColorOverlay=nil end
    end

    apply.MouseButton1Click:Connect(function() close(true) end)
    closeBtn.MouseButton1Click:Connect(function() close(false) end)
    setColor(current)
end

_G.__themeHeartbeat=function(dt)
    if Theme.mode~="RGB" then
        if rgbGrad.Enabled then rgbGrad.Enabled=false end
        return
    end
    if rgbGrad.Enabled then rgbGrad.Enabled=false end
    local speed=math.clamp(tonumber(Theme.rgbSpeed) or 100,10,300)
    local step=math.min(math.max(tonumber(dt) or 0,0),0.05)
    -- A time-based hue shift gives frame-rate-independent, smooth color flow.
    Theme._rgbHue=(Theme._rgbHue + (speed/100)*0.22*step)%1
    rgbBorder.Color=Color3.fromHSV(Theme._rgbHue,1,1)
    rgbBorder.Transparency=0
    for _,item in ipairs(rgbEdgeItems) do
        if item.frame.Parent then
            item.gradient.Color=themeRainbowSequence((Theme._rgbHue+item.phase)%1)
        end
    end
end
themeApply()

-- ═══════════════ MACRO ENGINE ═══════════════
local WN = {"Vo","Kiem","Sung","Trai"}
local WSK = {Vo={"Z","X","C","V","F"},Kiem={"Z","X"},Sung={"Z","X"},Trai={"Z","X","C","V","F"}}
local WDIS = {Vo="Cận chiến",Kiem="Kiếm",Sung="Súng",Trai="Trái ác quỷ"}
local WDISK = {["Cận chiến"]="Vo",["Kiếm"]="Kiem",["Súng"]="Sung",["Trái ác quỷ"]="Trai"}
local TM = {Vo="Melee",Kiem="Sword",Sung="Gun",Trai="Blox Fruit"}
local KM = {Z=Enum.KeyCode.Z,X=Enum.KeyCode.X,C=Enum.KeyCode.C,V=Enum.KeyCode.V,F=Enum.KeyCode.F}
local function vSk(w,s) for _,x in ipairs(WSK[w] or {}) do if x==s then return true end end return false end
local function gTT(t)
    if not t or not t:IsA("Tool") then return end
    local a=t:GetAttribute("ToolType")
    if a then local s=tostring(a)
        if s=="Melee" or s=="Sword" or s=="Gun" or s=="Blox Fruit" then return s end end
    local tp=t.ToolTip
    if tp and tp~="" then local s=string.lower(tp)
        if s:find("melee") or s:find("fighting") then return "Melee" end
        if s:find("sword") then return "Sword" end
        if s:find("gun") then return "Gun" end
        if s:find("fruit") or s:find("blox") then return "Blox Fruit" end end
    local n=string.lower(t.Name)
    if n:find("sword") or n:find("katana") or n:find("blade") or n:find("saber") or n:find("cutlass") or n:find("dagger") then return "Sword" end
    if n:find("gun") or n:find("pistol") or n:find("rifle") or n:find("musket") or n:find("flintlock") then return "Gun" end
    return nil
end
local function eqL(lb)
    local tt=TM[lb]; if not tt then return end
    local ch=LP.Character; if not ch then return end
    local h=ch:FindFirstChildOfClass("Humanoid"); if not h then return end
    for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") and gTT(x)==tt then return end end
    if ch:FindFirstChildOfClass("Tool") then pcall(function() h:UnequipTools() end); task.wait(.08) end
    local bp=LP:FindFirstChild("Backpack")
    if bp then for _,x in ipairs(bp:GetChildren()) do
        if x:IsA("Tool") and gTT(x)==tt then pcall(function() h:EquipTool(x) end); task.wait(.15); return end
    end end
end
local function pk(kc,hd)
    pcall(function() VIM:SendKeyEvent(true,kc,false,game) end)
    task.wait(hd and hd>0 and hd or .03)
    pcall(function() VIM:SendKeyEvent(false,kc,false,game) end)
end
local M = {}; local RUN=false; local STP=false; local RM=nil; local OnFin=nil; local FBs={}
local function addM(n) local m={name=n,bl={},on=false,open=true}; table.insert(M,m); return m end
local function runM(m)
    if RUN or not m.on or #m.bl==0 then return end
    RUN=true; STP=false; RM=m
    if OnFin then OnFin(m,true) end
    for _,b in ipairs(m.bl) do
        if STP then break end
        if not vSk(b.w,b.s) then b.s=(WSK[b.w] or {"Z"})[1] end
        eqL(b.w)
        if KM[b.s] then pk(KM[b.s],b.h) end
        if b.d>0 then task.wait(b.d) end
    end
    RUN=false; RM=nil
    if OnFin then OnFin(m,false) end
end
local function upFB(m)
    local e=FBs[m]; if not e then return end
    local run=(RM==m and RUN)
    if run then
        TW:Create(e.sw,TweenInfo.new(.18),{BackgroundColor3=T.On}):Play()
        TW:Create(e.kn,TweenInfo.new(.18),{Position=UDim2.new(1,-20,.5,0)}):Play()
        TW:Create(e.bd,TweenInfo.new(.18),{Color=T.Accent,Transparency=0}):Play()
        e.ic.Text="DỪNG"; e.ic.TextColor3=T.Red
    else
        TW:Create(e.sw,TweenInfo.new(.18),{BackgroundColor3=T.Off}):Play()
        TW:Create(e.kn,TweenInfo.new(.18),{Position=UDim2.new(0,2,.5,0)}):Play()
        TW:Create(e.bd,TweenInfo.new(.18),{Color=T.Stroke,Transparency=.3}):Play()
        e.ic.Text="CHẠY"; e.ic.TextColor3=T.Green
    end
end
local function crFB(m)
    if FBs[m] then return end
    local c=0; for _ in pairs(FBs) do c=c+1 end
    local fb=Instance.new("TextButton",GUI)
    fb.Size=UDim2.fromOffset(210,48); fb.Position=UDim2.new(0,20,0,180+c*58)
    fb.BackgroundColor3=Color3.fromRGB(14,22,42); fb.BackgroundTransparency=.05
    fb.Text=""; fb.AutoButtonColor=false; fb.BorderSizePixel=0; cr(fb,12)
    local bd=Instance.new("UIStroke",fb); bd.Color=T.Stroke; bd.Thickness=1.5; bd.Transparency=.3; dg(fb)
    local ic=Instance.new("TextLabel",fb)
    ic.Size=UDim2.fromOffset(52,20); ic.Position=UDim2.fromOffset(8,14)
    ic.BackgroundTransparency=1; ic.Text="CHẠY"; ic.Font=Enum.Font.GothamBold
    ic.TextSize=10; ic.TextColor3=T.Green
    local nl=Instance.new("TextLabel",fb)
    nl.Size=UDim2.new(1,-108,1,0); nl.Position=UDim2.fromOffset(66,0)
    nl.BackgroundTransparency=1; nl.Text=m.name; nl.Font=Enum.Font.GothamBold
    nl.TextSize=12; nl.TextColor3=T.Text; nl.TextXAlignment=Enum.TextXAlignment.Left
    nl.TextTruncate=Enum.TextTruncate.AtEnd
    local sw=Instance.new("Frame",fb)
    sw.Size=UDim2.fromOffset(42,22); sw.AnchorPoint=Vector2.new(1,.5)
    sw.Position=UDim2.new(1,-14,.5,0); sw.BackgroundColor3=T.Off
    sw.BorderSizePixel=0; cr(sw,11)
    local kn=Instance.new("Frame",sw)
    kn.Size=UDim2.fromOffset(18,18); kn.AnchorPoint=Vector2.new(0,.5)
    kn.Position=UDim2.new(0,2,.5,0); kn.BackgroundColor3=Color3.fromRGB(245,245,250)
    kn.BorderSizePixel=0; cr(kn,9)
    FBs[m]={fb=fb,sw=sw,kn=kn,ic=ic,bd=bd}
    fb.MouseButton1Click:Connect(function()
        if RM==m and RUN then STP=true
        else task.spawn(function() runM(m) end) end
    end)
    fb.MouseEnter:Connect(function() TW:Create(fb,TweenInfo.new(.15),{BackgroundTransparency=0}):Play() end)
    fb.MouseLeave:Connect(function() TW:Create(fb,TweenInfo.new(.15),{BackgroundTransparency=.05}):Play() end)
    upFB(m)
end
local function rmFB(m) local e=FBs[m]; if e then e.fb:Destroy(); FBs[m]=nil end end
OnFin=function(m) if FBs[m] then upFB(m) end end

local Ov=Instance.new("TextButton",GUI)
Ov.Size=UDim2.new(1,0,1,0); Ov.BackgroundTransparency=1; Ov.Text=""
Ov.AutoButtonColor=false; Ov.Visible=false; Ov.ZIndex=500
local Pp=Instance.new("Frame",GUI)
Pp.BackgroundColor3=T.Card; Pp.BorderSizePixel=0; Pp.Visible=false
Pp.ZIndex=501; cr(Pp,8); sk(Pp,T.Accent,1)
local Pl=Instance.new("UIListLayout",Pp); Pl.Padding=UDim.new(0,2)
local pp=Instance.new("UIPadding",Pp)
pp.PaddingTop=UDim.new(0,4); pp.PaddingBottom=UDim.new(0,4)
pp.PaddingLeft=UDim.new(0,4); pp.PaddingRight=UDim.new(0,4)
Ov.MouseButton1Click:Connect(function() Ov.Visible=false; Pp.Visible=false end)
local function openDD(b,opts,cb)
    for _,c in ipairs(Pp:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _,o in ipairs(opts) do
        local ob=Instance.new("TextButton",Pp)
        ob.Size=UDim2.new(1,0,0,26); ob.BackgroundColor3=T.Card
        ob.Text=o; ob.TextColor3=T.Text; ob.TextSize=12
        ob.Font=Enum.Font.GothamMedium; ob.AutoButtonColor=false; ob.ZIndex=502; cr(ob,5)
        ob.MouseButton1Click:Connect(function() cb(o); Ov.Visible=false; Pp.Visible=false end)
    end
    local w=math.max(b.AbsoluteSize.X,90)
    Pp.Size=UDim2.fromOffset(w,#opts*28+8)
    local ax=b.AbsolutePosition.X
    local ay=b.AbsolutePosition.Y+b.AbsoluteSize.Y+4
    if ax+w>GUI.AbsoluteSize.X-10 then ax=GUI.AbsoluteSize.X-w-10 end
    Pp.Position=UDim2.fromOffset(ax,ay)
    Ov.Visible=true; Pp.Visible=true
end
local function mkDD(par,gO,init,cb)
    local b=Instance.new("TextButton",par)
    b.Size=UDim2.new(1,0,1,0); b.BackgroundColor3=T.Input; b.Text=""
    b.AutoButtonColor=false; cr(b,6); sk(b,T.Stroke,1)
    local l=Instance.new("TextLabel",b)
    l.Size=UDim2.new(1,-20,1,0); l.Position=UDim2.fromOffset(8,0)
    l.BackgroundTransparency=1; l.Text=init; l.TextColor3=T.Text; l.TextSize=12
    l.Font=Enum.Font.GothamMedium; l.TextXAlignment=Enum.TextXAlignment.Left
    b.MouseButton1Click:Connect(function()
        openDD(b,gO(),function(v) l.Text=v; cb(v) end)
    end)
    return function(v) l.Text=v end
end

local refreshM = nil
local function mkBl(par,m,b,bi,mi)
    if not vSk(b.w,b.s) then b.s=(WSK[b.w] or {"Z"})[1] end
    local r=Instance.new("Frame",par)
    r.Size=UDim2.new(1,-4,0,62); r.BackgroundColor3=T.Card
    r.LayoutOrder=mi*100+bi; cr(r,8); sk(r,T.Stroke,1)
    local lb=Instance.new("TextLabel",r)
    lb.Size=UDim2.fromOffset(80,14); lb.Position=UDim2.fromOffset(12,4)
    lb.BackgroundTransparency=1; lb.Text="Khối "..bi; lb.TextColor3=T.Accent
    lb.TextSize=10; lb.Font=Enum.Font.GothamBold; lb.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextButton",r)
    dl.Size=UDim2.fromOffset(20,18); dl.Position=UDim2.new(1,-26,0,4)
    dl.BackgroundColor3=Color3.fromRGB(50,20,28); dl.Text="X"
    dl.TextColor3=T.Red; dl.TextSize=10; dl.AutoButtonColor=false; cr(dl,4)
    local fd=Instance.new("Frame",r)
    fd.Size=UDim2.new(1,-20,0,28); fd.Position=UDim2.fromOffset(10,26); fd.BackgroundTransparency=1
    local wS=Instance.new("Frame",fd); wS.BackgroundTransparency=1
    wS.Size=UDim2.new(.25,-4,1,0); wS.Position=UDim2.new(0,0,0,0)
    local sS=Instance.new("Frame",fd); sS.BackgroundTransparency=1
    sS.Size=UDim2.new(.25,-4,1,0); sS.Position=UDim2.new(.25,2,0,0)
    local hS=Instance.new("Frame",fd)
    hS.BackgroundColor3=T.Input; hS.Size=UDim2.new(.25,-4,1,0)
    hS.Position=UDim2.new(.5,4,0,0); cr(hS,5); sk(hS,T.Stroke,1)
    local dS=Instance.new("Frame",fd)
    dS.BackgroundColor3=T.Input; dS.Size=UDim2.new(.25,-4,1,0)
    dS.Position=UDim2.new(.75,6,0,0); cr(dS,5); sk(dS,T.Stroke,1)
    local sL
    mkDD(wS,function()
        local o={}
        for _,k in ipairs(WN) do table.insert(o,WDIS[k] or k) end
        return o
    end,WDIS[b.w] or b.w,function(v)
        local k=WDISK[v] or v; b.w=k
        if not vSk(k,b.s) then b.s=(WSK[k] or {"Z"})[1]; if sL then sL(b.s) end end
    end)
    sL=mkDD(sS,function() return WSK[b.w] or {"Z"} end,b.s,function(v) b.s=v end)
    local hB=Instance.new("TextBox",hS)
    hB.Size=UDim2.new(1,-8,1,0); hB.Position=UDim2.fromOffset(4,0)
    hB.BackgroundTransparency=1; hB.Text=string.format("%.2f",b.h)
    hB.TextColor3=T.Text; hB.TextSize=12; hB.Font=Enum.Font.Gotham; hB.ClearTextOnFocus=false
    hB.FocusLost:Connect(function()
        local n=tonumber(hB.Text); if n and n>=0 then b.h=n end
        hB.Text=string.format("%.2f",b.h)
    end)
    local dB=Instance.new("TextBox",dS)
    dB.Size=UDim2.new(1,-8,1,0); dB.Position=UDim2.fromOffset(4,0)
    dB.BackgroundTransparency=1; dB.Text=string.format("%.2f",b.d)
    dB.TextColor3=T.Text; dB.TextSize=12; dB.Font=Enum.Font.Gotham; dB.ClearTextOnFocus=false
    dB.FocusLost:Connect(function()
        local n=tonumber(dB.Text); if n and n>=0 then b.d=n end
        dB.Text=string.format("%.2f",b.d)
    end)
    dl.MouseButton1Click:Connect(function() table.remove(m.bl,bi); if refreshM then refreshM() end end)
end

local function mkHd(par,m,mi)
    local r=Instance.new("Frame",par)
    r.Size=UDim2.new(1,-4,0,52); r.BackgroundColor3=T.Card
    r.LayoutOrder=mi*100; cr(r,10)
    sk(r,m.on and T.Accent or T.Stroke,m.on and 1.2 or 1)
    local t=Instance.new("TextLabel",r)
    t.Size=UDim2.new(0,250,1,0); t.Position=UDim2.fromOffset(60,0)
    t.BackgroundTransparency=1; t.Text=m.name; t.TextColor3=T.Text
    t.TextSize=14; t.Font=Enum.Font.GothamBold; t.TextXAlignment=Enum.TextXAlignment.Left
    local a=Instance.new("TextLabel",r)
    a.Size=UDim2.fromOffset(24,24); a.Position=UDim2.fromOffset(16,14)
    a.BackgroundTransparency=1; a.Text=m.open and "v" or ">"
    a.TextColor3=T.Sub; a.TextSize=16; a.Font=Enum.Font.GothamBold
    local rn=Instance.new("TextButton",r)
    rn.Size=UDim2.fromOffset(30,26); rn.Position=UDim2.new(1,-152,0,13)
    rn.BackgroundColor3=Color3.fromRGB(10,40,35); rn.Text=">"
    rn.TextColor3=T.Green; rn.TextSize=14; rn.Font=Enum.Font.GothamBold
    rn.AutoButtonColor=false; cr(rn,6); sk(rn,T.Green,.8)
    rn.MouseButton1Click:Connect(function() task.spawn(function() runM(m) end) end)
    local d=Instance.new("TextButton",r)
    d.Size=UDim2.fromOffset(26,26); d.Position=UDim2.new(1,-116,0,13)
    d.BackgroundColor3=Color3.fromRGB(45,20,30); d.Text="X"
    d.TextColor3=T.Red; d.TextSize=11; d.Font=Enum.Font.GothamBold
    d.AutoButtonColor=false; cr(d,6)
    d.MouseButton1Click:Connect(function()
        rmFB(m)
        for i,x in ipairs(M) do if x==m then table.remove(M,i); break end end
        if refreshM then refreshM() end
    end)
    local tg=Instance.new("TextButton",r)
    tg.Size=UDim2.fromOffset(44,24); tg.Position=UDim2.new(1,-62,0,14)
    tg.AutoButtonColor=false; tg.BackgroundColor3=m.on and T.On or T.Off
    tg.Text=""; cr(tg,12)
    local tk=Instance.new("Frame",tg)
    tk.Size=UDim2.fromOffset(18,18)
    tk.Position=m.on and UDim2.new(1,-21,0,3) or UDim2.new(0,3,0,3)
    tk.BackgroundColor3=Color3.fromRGB(255,255,255); tk.BorderSizePixel=0; cr(tk,9)
    tg.MouseButton1Click:Connect(function()
        m.on=not m.on
        if m.on then crFB(m) else rmFB(m) end
        if refreshM then refreshM() end
    end)
    local ca=Instance.new("TextButton",r)
    ca.Size=UDim2.new(1,-160,1,0); ca.BackgroundTransparency=1
    ca.Text=""; ca.AutoButtonColor=false; ca.ZIndex=2
    ca.MouseButton1Click:Connect(function() m.open=not m.open; if refreshM then refreshM() end end)
end

function refreshM()
    Ov.Visible=false; Pp.Visible=false
    for _,c in ipairs(pMacro:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local tc=Instance.new("Frame",pMacro)
    tc.Size=UDim2.new(1,0,0,60); tc.BackgroundColor3=T.Panel
    tc.LayoutOrder=-1; cr(tc,12); sk(tc,T.Stroke,1)
    local tt=Instance.new("TextLabel",tc)
    tt.Size=UDim2.new(.5,0,0,22); tt.Position=UDim2.fromOffset(14,10)
    tt.BackgroundTransparency=1; tt.Text="Macro"; tt.Font=Enum.Font.GothamBold
    tt.TextSize=14; tt.TextColor3=T.Text; tt.TextXAlignment=Enum.TextXAlignment.Left
    local sb=Instance.new("TextLabel",tc)
    sb.Size=UDim2.new(.5,0,0,16); sb.Position=UDim2.fromOffset(14,32)
    sb.BackgroundTransparency=1; sb.Text="Tự động hóa thao tác combo"
    sb.Font=Enum.Font.Gotham; sb.TextSize=11; sb.TextColor3=T.Sub
    sb.TextXAlignment=Enum.TextXAlignment.Left
    local tb=Instance.new("TextButton",tc)
    tb.Size=UDim2.fromOffset(140,36); tb.AnchorPoint=Vector2.new(1,.5)
    tb.Position=UDim2.new(1,-14,.5,0); tb.BackgroundColor3=T.Accent2
    tb.Text="+ Tạo Macro"; tb.Font=Enum.Font.GothamBold; tb.TextSize=12
    tb.TextColor3=Color3.fromRGB(255,255,255); tb.BorderSizePixel=0
    tb.AutoButtonColor=false; cr(tb,9)
    tb.MouseButton1Click:Connect(function() addM("Macro "..#M+1); refreshM() end)
    if #M==0 then
        local em=Instance.new("Frame",pMacro)
        em.Size=UDim2.new(1,0,0,160); em.BackgroundTransparency=1; em.LayoutOrder=10
        local ci=Instance.new("Frame",em)
        ci.Size=UDim2.fromOffset(64,64); ci.Position=UDim2.new(.5,-32,0,30)
        ci.BackgroundColor3=T.Card; ci.BorderSizePixel=0; cr(ci,32); sk(ci,T.Accent,1.2)
        local ic=Instance.new("TextLabel",ci)
        ic.Size=UDim2.fromScale(1,1); ic.BackgroundTransparency=1
        ic.Text="🎯"; ic.Font=Enum.Font.GothamBold; ic.TextSize=32; ic.TextColor3=T.Accent
        local t1=Instance.new("TextLabel",em)
        t1.Size=UDim2.new(1,0,0,22); t1.Position=UDim2.new(0,0,0,108)
        t1.BackgroundTransparency=1; t1.Text="Chưa có Macro nào"; t1.TextColor3=T.Text
        t1.TextSize=14; t1.Font=Enum.Font.GothamBold
        local t2=Instance.new("TextLabel",em)
        t2.Size=UDim2.new(1,0,0,18); t2.Position=UDim2.new(0,0,0,130)
        t2.BackgroundTransparency=1; t2.Text="Bấm '+ Tạo Macro' để bắt đầu"
        t2.TextColor3=T.Sub; t2.TextSize=11; t2.Font=Enum.Font.Gotham
        return
    end
    for i,m in ipairs(M) do
        mkHd(pMacro,m,i)
        if m.open then
            for bi,b in ipairs(m.bl) do mkBl(pMacro,m,b,bi,i) end
            local ar=Instance.new("Frame",pMacro)
            ar.Size=UDim2.new(1,-4,0,30); ar.BackgroundTransparency=1
            ar.LayoutOrder=i*100+99
            local ab=Instance.new("TextButton",ar)
            ab.Size=UDim2.new(1,0,1,0); ab.BackgroundColor3=Color3.fromRGB(12,18,32)
            ab.AutoButtonColor=false; ab.Text="+ Thêm khối"; ab.TextColor3=T.Accent
            ab.TextSize=12; ab.Font=Enum.Font.GothamBold; cr(ab,8)
            sk(ab,Color3.fromRGB(0,150,200),.8)
            ab.MouseButton1Click:Connect(function() table.insert(m.bl,{w="Vo",s="Z",h=0,d=.15}); refreshM() end)
        end
    end
end
refreshM()

-- ═══════════════ ESP ═══════════════
local ESP = {on=false,name=true,dist=true,hp=true,color=Color3.fromRGB(255,80,100),trans=.7}
local espC = {}
local function mkESP(p)
    if espC[p] then return espC[p] end
    local ch=p.Character; if not ch then return end
    local hrp=ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hl=Instance.new("Highlight",ch)
    hl.FillColor=ESP.color; hl.FillTransparency=ESP.trans
    hl.OutlineColor=ESP.color; hl.OutlineTransparency=0
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    local bb=Instance.new("BillboardGui",ch)
    bb.Size=UDim2.fromOffset(140,64); bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.AlwaysOnTop=true; bb.Adornee=hrp
    local nl=Instance.new("TextLabel",bb); nl.Name="Name"
    nl.Size=UDim2.new(1,0,0,16); nl.Position=UDim2.new(0,0,0,0)
    nl.BackgroundTransparency=1; nl.Text=p.Name; nl.TextColor3=ESP.color
    nl.TextStrokeTransparency=.3; nl.TextSize=13; nl.Font=Enum.Font.GothamBold
    local dl=Instance.new("TextLabel",bb); dl.Name="Dist"
    dl.Size=UDim2.new(1,0,0,14); dl.Position=UDim2.new(0,0,0,16)
    dl.BackgroundTransparency=1; dl.Text="0m"; dl.TextColor3=Color3.fromRGB(200,220,255)
    dl.TextStrokeTransparency=.3; dl.TextSize=11; dl.Font=Enum.Font.Gotham
    local hl2=Instance.new("TextLabel",bb); hl2.Name="HpText"
    hl2.Size=UDim2.new(1,0,0,14); hl2.Position=UDim2.new(0,0,0,30)
    hl2.BackgroundTransparency=1; hl2.Text="100 / 100"; hl2.TextColor3=Color3.fromRGB(80,240,130)
    hl2.TextStrokeTransparency=.3; hl2.TextSize=11; hl2.Font=Enum.Font.GothamBold
    espC[p]={hl=hl,bb=bb}
    return espC[p]
end
local function rmESP(p)
    local c=espC[p]
    if c then pcall(function() c.hl:Destroy() end); pcall(function() c.bb:Destroy() end); espC[p]=nil end
end
local espAccum=0
local espRenderConn=trackPersistent(RS.RenderStepped:Connect(function(dt)
    if not ESP.on then return end
    espAccum=espAccum+dt
    if espAccum<0.05 then return end
    espAccum=0
    local myChar=LP.Character
    local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local tChar=p.Character
            if tChar then
                local tHRP=tChar:FindFirstChild("HumanoidRootPart")
                local tHum=tChar:FindFirstChildOfClass("Humanoid")
                if tHRP then
                    local e=espC[p]
                    if not e then e=mkESP(p) end
                    if e and e.bb and e.bb.Parent then
                        e.hl.FillColor=ESP.color; e.hl.FillTransparency=ESP.trans; e.hl.OutlineColor=ESP.color
                        local bb=e.bb
                        local nameL=bb:FindFirstChild("Name")
                        local distL=bb:FindFirstChild("Dist")
                        local hpL=bb:FindFirstChild("HpText")
                        if nameL then nameL.Visible=ESP.name; nameL.Text=p.Name; nameL.TextColor3=ESP.color end
                        if distL then
                            distL.Visible=ESP.dist
                            if myHRP then local d=(tHRP.Position-myHRP.Position).Magnitude
                                distL.Text=tostring(math.floor(d)).."m" else distL.Text="--" end
                        end
                        if hpL then
                            hpL.Visible=ESP.hp
                            if tHum then
                                local cur=math.floor(tHum.Health); local max=math.floor(tHum.MaxHealth)
                                local ratio=tHum.Health/math.max(tHum.MaxHealth,1)
                                hpL.Text=tostring(cur).." / "..tostring(max)
                                hpL.TextColor3=ratio>.5 and Color3.fromRGB(80,240,130)
                                    or ratio>.25 and Color3.fromRGB(240,200,60)
                                    or Color3.fromRGB(240,80,80)
                            end
                        end
                    end
                end
            end
        end
    end
    for p in pairs(espC) do
        if not p.Parent or not p.Character or not p.Character.Parent then rmESP(p) end
    end
end))
trackPersistent(Players.PlayerRemoving:Connect(function(p) rmESP(p) end))
trackPersistent(Players.PlayerAdded:Connect(function(p)
    trackPersistent(p.CharacterAdded:Connect(function()
        task.wait(.5); if espC[p] then rmESP(p) end; if ESP.on then mkESP(p) end
    end))
end))
trackPersistent(LP.CharacterAdded:Connect(function()
    task.wait(.5)
    for p in pairs(espC) do if p~=LP then rmESP(p) end end
end))

-- ═══════════════ IMMEDIATE EXT CORE (no Remotes/Modules dependency) ═══════════════
tbl = {
        TweenSpeed = 250,
        CamLock = false,
        SpectatePlayer = false,
        SelectPlayer = "Nearest",
        AntiAFK = true,
        AttackNPC = true,
        AttackPlayer = true,
        FastAttackDelay = 0,
        AutoKen = false,
    }

function fn23(arg)
    if not (arg and arg.Character and arg.Character:FindFirstChild("HumanoidRootPart") and arg.Character:FindFirstChild("Humanoid")) then
        return false
    end
    local humanoidRootPart3 = arg.Character.HumanoidRootPart
    if arg.Character:FindFirstChild("ForceField") ~= nil then return true end
    for _, child in ipairs(WS:GetChildren()) do
        if child:IsA("BasePart") and (child.Name:find("SafeZone") or child.Name:find("PeaceZone")) then
            if (humanoidRootPart3.Position - child.Position).Magnitude < child.Size.Magnitude / 2 + 10 then return true end
        end
    end
    return false
end

function findNearestPlayer()
    local character2 = LP.Character
    if character2 then
        character2 = character2:FindFirstChild("HumanoidRootPart") or character2.PrimaryPart
    end
    if not character2 then return nil end
    local position2 = character2.Position
    local huge = math.huge
    local best = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character.Parent then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart
            if hum and hum.Health > 0 and hrp and not fn23(player) then
                local d = (hrp.Position - position2).Magnitude
                if d < huge then huge = d; best = player end
            end
        end
    end
    return best
end

-- ═══════════════ CAM LOCK ═══════════════
-- Forward declarations keep Camera modes in the same local scope.
FlyCam = nil
flycamStop = nil
OnSpectateToggle = nil
camLockConn = nil
camLockSavedAutoRotate = true

function OnCamLockToggle(camLock)
    tbl.CamLock = camLock
    if camLockConn then camLockConn:Disconnect(); camLockConn = nil end
    if camLock then
        if tbl.SpectatePlayer then pcall(function() OnSpectateToggle(false) end) end
        if FlyCam.enabled then pcall(function() flycamStop() end) end
        if Mv.Fly.enabled then pcall(function() flyStop() end) end
        pcall(function() if FeatureControl.stopTargetTween then FeatureControl.stopTargetTween() end end)
        pcall(function() if FeatureControl.stopManualTween then FeatureControl.stopManualTween() end end)
        pcall(function() if FeatureControl.ui.Spectate then FeatureControl.ui.Spectate:Sync(false) end end)
        pcall(function() if FeatureControl.ui.FlyCam then FeatureControl.ui.FlyCam:Sync(false) end end)
        pcall(function() if FeatureControl.ui.Fly then FeatureControl.ui.Fly:Sync(false) end end)
    end

    if not camLock then
        if camLockConn then pcall(function() camLockConn:Disconnect() end); camLockConn=nil end
        pcall(function() if FeatureControl.ui.CamLock then FeatureControl.ui.CamLock:Sync(false) end end)
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum and camLockSavedAutoRotate ~= nil then hum.AutoRotate = camLockSavedAutoRotate end
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam and hum then
                cam.CameraSubject = hum
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
        return
    end

    local ch0 = LP.Character
    local hum0 = ch0 and ch0:FindFirstChildOfClass("Humanoid")
    if hum0 then camLockSavedAutoRotate = hum0.AutoRotate end

    camLockConn = RS.RenderStepped:Connect(function()
        if not tbl.CamLock then
            if camLockConn then camLockConn:Disconnect(); camLockConn = nil end
            return
        end
        pcall(function()
            local nearestPlayer = (tbl.SelectPlayer == "Nearest" or not tbl.SelectPlayer)
                and findNearestPlayer()
                or Players:FindFirstChild(tbl.SelectPlayer)
            nearestPlayer = nearestPlayer and nearestPlayer.Character
            local hum = nearestPlayer and nearestPlayer:FindFirstChildOfClass("Humanoid")
            local targetPart
            if nearestPlayer then
                targetPart = nearestPlayer:FindFirstChild("HumanoidRootPart") or nearestPlayer.PrimaryPart
            end
            if targetPart and hum and hum.Health > 0 then
                local cam = workspace.CurrentCamera or workspace.Camera
                if cam then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
                end
                local myChar = LP.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if myHRP and myHum then
                    local flat = Vector3.new(targetPart.Position.X - myHRP.Position.X, 0, targetPart.Position.Z - myHRP.Position.Z)
                    if flat.Magnitude > 0.1 then
                        myHum.AutoRotate = false
                        myHRP.CFrame = CFrame.new(myHRP.Position, myHRP.Position + flat.Unit)
                    end
                end
            end
        end)
    end)
end

-- ═══════════════ FLYCAM ═══════════════
FlyCam = {
    enabled = false, speed = 100, conns = {},
    savedCamType = nil, savedSubject = nil,
    savedAnchored = nil, savedWS = 16, savedJP = 50, savedAutoRotate = true,
    rotYaw = 0, rotPitch = 0, pos = Vector3.zero,
    keysDown = {}, dragTouch = nil, flyControls = nil,
}

function ensureFlyControls()
    if FlyCam.flyControls then return FlyCam.flyControls end
    pcall(function()
        local ps = LP:FindFirstChild("PlayerScripts") or LP:WaitForChild("PlayerScripts", 5)
        if ps then
            local pm = require(ps:WaitForChild("PlayerModule", 5))
            FlyCam.flyControls = pm:GetControls()
        end
    end)
    return FlyCam.flyControls
end
ensureFlyControls()

flycamStop = function()
    if not FlyCam.enabled then
        syncFeatureUI("FlyCam",false)
        return
    end
    FlyCam.enabled = false
    for _, c in ipairs(FlyCam.conns) do pcall(function() c:Disconnect() end) end
    FlyCam.conns = {}
    FlyCam.keysDown = {}
    FlyCam.dragTouch = nil
    local ch = LP.Character
    if ch then
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hrp and FlyCam.savedAnchored ~= nil then hrp.Anchored = FlyCam.savedAnchored end
        if hum then
            if FlyCam.savedWS then hum.WalkSpeed = FlyCam.savedWS end
            if FlyCam.savedJP then hum.JumpPower = FlyCam.savedJP; hum.UseJumpPower = true end
            hum.AutoRotate = FlyCam.savedAutoRotate
        end
    end
    local cam = workspace.CurrentCamera
    if cam then
        if FlyCam.savedCamType then pcall(function() cam.CameraType = FlyCam.savedCamType end) end
        local ch2 = LP.Character
        local hum2 = ch2 and ch2:FindFirstChildOfClass("Humanoid")
        if hum2 then cam.CameraSubject = hum2 elseif FlyCam.savedSubject then cam.CameraSubject = FlyCam.savedSubject end
    end
    pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
    syncFeatureUI("FlyCam",false)
end

function flycamStart()
    if FlyCam.enabled then return end
    if tbl.CamLock then pcall(function() OnCamLockToggle(false) end) end
    if tbl.SpectatePlayer then pcall(function() OnSpectateToggle(false) end) end
    if Mv.Fly.enabled then pcall(function() flyStop() end) end
    if Mv.Noclip.enabled then pcall(function() noclipStop() end) end
    pcall(function() if FeatureControl.stopTargetTween then FeatureControl.stopTargetTween() end end)
    pcall(function() if FeatureControl.stopManualTween then FeatureControl.stopManualTween() end end)
    pcall(function() if FeatureControl.ui.CamLock then FeatureControl.ui.CamLock:Sync(false) end end)
    pcall(function() if FeatureControl.ui.Spectate then FeatureControl.ui.Spectate:Sync(false) end end)
    pcall(function() if FeatureControl.ui.Fly then FeatureControl.ui.Fly:Sync(false) end end)
    local cam = workspace.CurrentCamera
    if not cam then return end
    FlyCam.enabled = true
    FlyCam.savedCamType = cam.CameraType
    FlyCam.savedSubject = cam.CameraSubject
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CameraSubject = nil

    local ch = LP.Character
    if ch then
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hrp then
            FlyCam.savedAnchored = hrp.Anchored
            hrp.Anchored = true
        end
        if hum then
            FlyCam.savedWS = hum.WalkSpeed
            FlyCam.savedJP = hum.JumpPower
            FlyCam.savedAutoRotate = hum.AutoRotate
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.AutoRotate = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        end
    end

    local cf = cam.CFrame
    local yaw, pitch = cf:ToOrientation()
    FlyCam.rotYaw = yaw
    FlyCam.rotPitch = pitch
    FlyCam.pos = cf.Position
    FlyCam.keysDown = {}
    FlyCam.dragTouch = nil

    ensureFlyControls()

    local keyMap = {
        [Enum.KeyCode.W]="W",[Enum.KeyCode.S]="S",[Enum.KeyCode.A]="A",[Enum.KeyCode.D]="D",
        [Enum.KeyCode.Space]="UP",[Enum.KeyCode.LeftShift]="DN",[Enum.KeyCode.LeftControl]="DN",
        [Enum.KeyCode.E]="UP",[Enum.KeyCode.Q]="DN",
    }
    table.insert(FlyCam.conns, UIS.InputBegan:Connect(function(input, gp)
        if not FlyCam.enabled or gp then return end
        if keyMap[input.KeyCode] then FlyCam.keysDown[keyMap[input.KeyCode]] = true end
    end))
    table.insert(FlyCam.conns, UIS.InputEnded:Connect(function(input)
        if keyMap[input.KeyCode] then FlyCam.keysDown[keyMap[input.KeyCode]] = nil end
    end))

    table.insert(FlyCam.conns, UIS.InputChanged:Connect(function(input)
        if not FlyCam.enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
               or UIS.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
                local dx, dy = input.Delta.X, input.Delta.Y
                if dx ~= 0 then
                    FlyCam.rotYaw = FlyCam.rotYaw - math.rad(dx * 0.35)
                end
                if dy ~= 0 then
                    FlyCam.rotPitch = math.clamp(
                        FlyCam.rotPitch - math.rad(dy * 0.35),
                        -math.rad(88), math.rad(88)
                    )
                end
            end
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if FlyCam.dragTouch and input == FlyCam.dragTouch then
                local dx, dy = input.Delta.X, input.Delta.Y
                if dx ~= 0 then
                    FlyCam.rotYaw = FlyCam.rotYaw - math.rad(dx * 0.45)
                end
                if dy ~= 0 then
                    FlyCam.rotPitch = math.clamp(
                        FlyCam.rotPitch - math.rad(dy * 0.45),
                        -math.rad(88), math.rad(88)
                    )
                end
            end
        end
    end))

    table.insert(FlyCam.conns, UIS.InputBegan:Connect(function(input, gp)
        if not FlyCam.enabled or gp then return end
        if input.UserInputType == Enum.UserInputType.Touch and not FlyCam.dragTouch then
            local vp = cam.ViewportSize
            local inJoystick = input.Position.X < vp.X * 0.35 and input.Position.Y > vp.Y * 0.35
            if not inJoystick then
                FlyCam.dragTouch = input
            end
        end
    end))
    table.insert(FlyCam.conns, UIS.InputEnded:Connect(function(input)
        if input == FlyCam.dragTouch then FlyCam.dragTouch = nil end
    end))

    if not UIS.TouchEnabled then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        table.insert(FlyCam.conns, UIS:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
            if FlyCam.enabled and not UIS.TouchEnabled and UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end))
    end

    table.insert(FlyCam.conns, RS.RenderStepped:Connect(function(dt)
        if not FlyCam.enabled then return end
        local c = workspace.CurrentCamera
        if not c then return end

        local speed = FlyCam.speed
        local cf = CFrame.fromOrientation(FlyCam.rotPitch, FlyCam.rotYaw, 0)
        local look = cf.LookVector
        local right = cf.RightVector

        local move = Vector3.zero

        local controls = FlyCam.flyControls
        if controls then
            local ok, mv = pcall(function() return controls:GetMoveVector() end)
            if ok and mv and mv.Magnitude > 0.05 then
                move = move + look * (-mv.Z) + right * mv.X
            end
        end

        if FlyCam.keysDown.W then move = move + look end
        if FlyCam.keysDown.S then move = move - look end
        if FlyCam.keysDown.A then move = move - right end
        if FlyCam.keysDown.D then move = move + right end
        if FlyCam.keysDown.UP then move = move + Vector3.new(0, 1, 0) end
        if FlyCam.keysDown.DN then move = move - Vector3.new(0, 1, 0) end

        if move.Magnitude > 1 then move = move.Unit end

        if move.Magnitude > 0.01 then
            FlyCam.pos = FlyCam.pos + move * speed * dt
        end

        c.CFrame = CFrame.new(FlyCam.pos) * cf
    end))
end

function resetSelf()
    pcall(function()
        local currentCamera = workspace.CurrentCamera or workspace.Camera
        local humanoid2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if currentCamera and humanoid2 then currentCamera.CameraSubject = humanoid2 end
    end)
end
function spectatePlayer()
    pcall(function()
        local nearestPlayer = (tbl.SelectPlayer == "Nearest" or not tbl.SelectPlayer) and findNearestPlayer() or Players:FindFirstChild(tbl.SelectPlayer)
        local humanoid2 = nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
        local currentCamera = workspace.CurrentCamera or workspace.Camera
        if currentCamera then
            if humanoid2 and humanoid2.Health > 0 then
                currentCamera.CameraSubject = humanoid2
            else
                local humanoid3 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if humanoid3 then currentCamera.CameraSubject = humanoid3 end
            end
        end
    end)
end
spectateConnection = nil
OnSpectateToggle = function(spectateOn)
    tbl.SpectatePlayer = spectateOn
    if spectateConnection then spectateConnection:Disconnect(); spectateConnection = nil end
    if spectateOn then
        if tbl.CamLock then pcall(function() OnCamLockToggle(false) end) end
        if FlyCam.enabled then pcall(function() flycamStop() end) end
        if Mv.Fly.enabled then pcall(function() flyStop() end) end
        pcall(function() if FeatureControl.stopTargetTween then FeatureControl.stopTargetTween() end end)
        pcall(function() if FeatureControl.stopManualTween then FeatureControl.stopManualTween() end end)
        pcall(function() if FeatureControl.ui.CamLock then FeatureControl.ui.CamLock:Sync(false) end end)
        pcall(function() if FeatureControl.ui.FlyCam then FeatureControl.ui.FlyCam:Sync(false) end end)
        pcall(function() if FeatureControl.ui.Fly then FeatureControl.ui.Fly:Sync(false) end end)
    end
    if not spectateOn then
        if spectateConnection then pcall(function() spectateConnection:Disconnect() end); spectateConnection=nil end
        pcall(function() if FeatureControl.ui.Spectate then FeatureControl.ui.Spectate:Sync(false) end end)
        resetSelf()
    else
        spectateConnection = RS.RenderStepped:Connect(function()
            if not tbl.SpectatePlayer then
                if spectateConnection then spectateConnection:Disconnect(); spectateConnection = nil end
                return
            end
            spectatePlayer()
        end)
    end
end

antiThread = nil
function ToggleAntiAFK(antiAFK)
    tbl.AntiAFK = antiAFK
    if antiThread then
        pcall(function() task.cancel(antiThread) end)
        antiThread = nil
    end
    if antiAFK then
        antiThread = task.spawn(function()
            while tbl.AntiAFK do
                -- Use the platform's idle signal rather than clicking an arbitrary UI coordinate.
                task.wait(300)
                if not tbl.AntiAFK then break end
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new(1, 1))
                end)
            end
        end)
    end
end

Hitbox = {Enabled = false, Size = 15, conns = {}, backups = {}}
function applyHitbox(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not Hitbox.backups[hrp] then
        Hitbox.backups[hrp] = {Size=hrp.Size, Transparency=hrp.Transparency, CanCollide=hrp.CanCollide, Massless=hrp.Massless}
    end
    local s = Hitbox.Size
    hrp.Size = Vector3.new(s, s, s); hrp.Transparency = 0.7
    hrp.CanCollide = false; hrp.Massless = true
end
function restoreHitbox(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local b = Hitbox.backups[hrp]
    if b then
        pcall(function()
            hrp.Size = b.Size; hrp.Transparency = b.Transparency
            if not Mv.Noclip.enabled then hrp.CanCollide = b.CanCollide end; hrp.Massless = b.Massless
        end)
        Hitbox.backups[hrp] = nil
    end
end
function hitboxStart()
    if Hitbox.Enabled then return end
    Hitbox.Enabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if p.Character then applyHitbox(p) end
            table.insert(Hitbox.conns, p.CharacterAdded:Connect(function()
                task.wait(0.4); if Hitbox.Enabled then applyHitbox(p) end
            end))
        end
    end
    table.insert(Hitbox.conns, Players.PlayerAdded:Connect(function(p)
        table.insert(Hitbox.conns, p.CharacterAdded:Connect(function()
            task.wait(0.4); if Hitbox.Enabled then applyHitbox(p) end
        end))
    end))
    table.insert(Hitbox.conns, RS.Heartbeat:Connect(function()
        if not Hitbox.Enabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Size.X ~= Hitbox.Size then applyHitbox(p) end
            end
        end
    end))
end
function hitboxStop()
    Hitbox.Enabled = false
    for _, c in ipairs(Hitbox.conns) do pcall(function() c:Disconnect() end) end
    Hitbox.conns = {}
    for _, p in ipairs(Players:GetPlayers()) do restoreHitbox(p) end
    Hitbox.backups = {}
end


tweenConn = nil

-- ═══════════════ TWEEN MOVEMENT SAFETY — lock physics while traveling ═══════════════
-- Prevent gravity / terrain physics from forcing the character downward while tweening.
local TweenKinematics = {
    active=false,
    root=nil,
    hum=nil,
    rootAnchored=nil,
    autoRotate=nil,
}

local function tweenKinematicsStart()
    local ch=LP.Character
    if not ch or not ch.Parent then return false end
    local root=ch:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local hum=ch:FindFirstChildOfClass("Humanoid")

    TweenKinematics.active=true
    TweenKinematics.root=root
    TweenKinematics.hum=hum
    TweenKinematics.rootAnchored=root.Anchored
    TweenKinematics.autoRotate=hum and hum.AutoRotate or nil

    pcall(function() root.Anchored=true end)
    pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
    pcall(function() root.AssemblyAngularVelocity=Vector3.zero end)
    if hum then pcall(function() hum.AutoRotate=false end) end
    return true
end

local function tweenKinematicsMaintain()
    if not TweenKinematics.active then return end
    local root=TweenKinematics.root
    if root and root.Parent then
        pcall(function() root.Anchored=true end)
        pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        pcall(function() root.AssemblyAngularVelocity=Vector3.zero end)
    end
end

local function tweenKinematicsStop()
    if not TweenKinematics.active then return end
    TweenKinematics.active=false
    local root=TweenKinematics.root
    local hum=TweenKinematics.hum
    if root and root.Parent then
        pcall(function() root.Anchored=(TweenKinematics.rootAnchored==true) end)
        pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        pcall(function() root.AssemblyAngularVelocity=Vector3.zero end)
    end
    if hum and hum.Parent and TweenKinematics.autoRotate~=nil then
        pcall(function() hum.AutoRotate=TweenKinematics.autoRotate end)
    end
    TweenKinematics.root=nil
    TweenKinematics.hum=nil
    TweenKinematics.rootAnchored=nil
    TweenKinematics.autoRotate=nil
end

-- ═══════════════ TWEEN NOCLIP — temporary collision suppression ═══════════════
local TweenNoClip = {active=false, parts={}, conns={}, acc=0}

local function tweenNoClipApply(ch)
    if not ch or not ch.Parent then return end
    for _, part in ipairs(ch:GetDescendants()) do
        if part:IsA("BasePart") then
            if TweenNoClip.parts[part]==nil then TweenNoClip.parts[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
end

local function tweenNoClipStart()
    if TweenNoClip.active then tweenNoClipApply(LP.Character); return end
    TweenNoClip.active=true; TweenNoClip.parts={}; TweenNoClip.acc=0
    tweenNoClipApply(LP.Character)
    for _,c in ipairs(TweenNoClip.conns) do pcall(function() c:Disconnect() end) end
    TweenNoClip.conns={}
    table.insert(TweenNoClip.conns,LP.CharacterAdded:Connect(function(ch)
        task.defer(function() if TweenNoClip.active then tweenNoClipApply(ch) end end)
    end))
    table.insert(TweenNoClip.conns,RS.Heartbeat:Connect(function(dt)
        if not TweenNoClip.active then return end
        TweenNoClip.acc=TweenNoClip.acc+dt
        if TweenNoClip.acc<0.08 then return end
        TweenNoClip.acc=0
        tweenNoClipApply(LP.Character)
    end))
end

local function tweenNoClipStop()
    if not TweenNoClip.active then return end
    TweenNoClip.active=false
    for _,c in ipairs(TweenNoClip.conns) do pcall(function() c:Disconnect() end) end
    TweenNoClip.conns={}; TweenNoClip.acc=0
    local keepDisabled=Mv.Noclip.enabled
    for part,original in pairs(TweenNoClip.parts) do
        if part and part.Parent then
            pcall(function() part.CanCollide=keepDisabled and false or original end)
        end
    end
    TweenNoClip.parts={}
end

-- Teleport feature removed. Keep a no-op compatibility hook for existing cleanup calls.
function tweenStop(_silent)
    return false
end

Escape = {
    enabled=false, hpThreshold=30, tpDist=200,
    lastTP=0, cooldown=1, conn=nil,
}
function startEscape()
    if Escape.conn then Escape.conn:Disconnect(); Escape.conn = nil end
    Escape.conn = RS.Heartbeat:Connect(function()
        if not Escape.enabled then return end
        if Mv.Fly.enabled then return end
        local ch = LP.Character; if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end
        local pct = (hum.Health / math.max(hum.MaxHealth, 1)) * 100
        if pct < Escape.hpThreshold then
            local now = tick()
            if now - Escape.lastTP < Escape.cooldown then return end
            Escape.lastTP = now
            local angle = math.random() * math.pi * 2
            local d = Escape.tpDist
            local newPos = hrp.Position + Vector3.new(math.cos(angle)*d, 150, math.sin(angle)*d)
            pcall(function() hrp.CFrame = CFrame.new(newPos) end)
        end
    end)
end
function stopEscape()
    Escape.enabled = false
    if Escape.conn then Escape.conn:Disconnect(); Escape.conn = nil end
    syncFeatureUI("AutoEscape",false)
end

-- ═══════════════ HEADER TELEMETRY / FPS & PING ═══════════════
FPSCounter = {
    enabled=false, conn=nil, gui=nil,
    fpsAcc=0, fpsFrames=0, fps=0, ping=nil,
}
local HeaderTelemetry={acc=0,frames=0,fps=0,ping=nil}
local headerMetricsConn=RS.Heartbeat:Connect(function(dt)
    HeaderTelemetry.acc=HeaderTelemetry.acc+dt
    HeaderTelemetry.frames=HeaderTelemetry.frames+1
    if HeaderTelemetry.acc<0.5 then return end
    HeaderTelemetry.fps=HeaderTelemetry.frames/math.max(HeaderTelemetry.acc,0.001)
    HeaderTelemetry.acc=0; HeaderTelemetry.frames=0
    local pingOk,pingValue=pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if pingOk and type(pingValue)=="number" then HeaderTelemetry.ping=pingValue end

    local fpsN=math.floor(HeaderTelemetry.fps+0.5)
    local pingN=HeaderTelemetry.ping and math.floor(HeaderTelemetry.ping+0.5) or nil
    Hfps.Text=string.format("FPS %d",fpsN)
    Hfps.TextColor3=(fpsN>=50) and T.Green or (fpsN>=30) and Color3.fromRGB(240,200,60) or T.Red
    Hping.Text=pingN and string.format("PING %dms",pingN) or "PING --"
    Hping.TextColor3=(pingN and pingN<=100) and T.Green or (pingN and pingN<=200) and Color3.fromRGB(240,200,60) or T.Red
    FPSCounter.fps=HeaderTelemetry.fps; FPSCounter.ping=HeaderTelemetry.ping
    if FPSCounter.enabled and FPSCounter.gui and FPSCounter.gui.Parent then
        FPSCounter.gui.Text=string.format("FPS: %d | Ping: %s",fpsN,pingN and (tostring(pingN).." ms") or "-- ms")
        FPSCounter.gui.TextColor3=(fpsN>=45 and pingN and pingN<=100) and T.Green
            or (fpsN>=25 and pingN and pingN<=200) and Color3.fromRGB(240,200,60) or T.Red
    end
end)
function startFPSCounter()
    if FPSCounter.enabled then return end
    FPSCounter.enabled = true
    if not FPSCounter.gui or not FPSCounter.gui.Parent then
        local lb = Instance.new("TextLabel", GUI)
        lb.Size = UDim2.fromOffset(220, 34)
        lb.Position = UDim2.new(0, 16, 0, 16)
        lb.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
        lb.BackgroundTransparency = 0.25
        lb.BorderSizePixel = 0
        lb.Font = Enum.Font.GothamBold
        lb.TextSize = 13
        lb.TextColor3 = T.Green
        lb.Text = "FPS: -- | Ping: -- ms"
        lb.ZIndex = 8500
        lb:SetAttribute("__NoPressScale", true)
        cr(lb, 10); sk(lb, T.Accent, 1.2, 0.2)
        FPSCounter.gui = lb
    end
    FPSCounter.gui.Visible = true
    local fpsN=math.floor(HeaderTelemetry.fps+0.5)
    local pingN=HeaderTelemetry.ping and math.floor(HeaderTelemetry.ping+0.5) or nil
    FPSCounter.gui.Text=string.format("FPS: %d | Ping: %s",fpsN,pingN and (tostring(pingN).." ms") or "-- ms")
end
function stopFPSCounter()
    FPSCounter.enabled = false
    if FPSCounter.gui then FPSCounter.gui.Visible = false end
    syncFeatureUI("FPS",false)
end


local SIMPLE_SHADER_SOURCE = [=[local v0=string.char;local v1=string.byte;local v2=string.sub;local v3=bit32 or bit ;local v4=v3.bxor;local v5=table.concat;local v6=table.insert;local function v7(v24,v25) local v26={};for v41=1, #v24 do v6(v26,v0(v4(v1(v2(v24,v41,v41 + 1 )),v1(v2(v25,1 + (v41% #v25) ,1 + (v41% #v25) + 1 )))%256 ));end return v5(v26);end local v8=tonumber;local v9=string.byte;local v10=string.char;local v11=string.sub;local v12=string.gsub;local v13=string.rep;local v14=table.concat;local v15=table.insert;local v16=math.ldexp;local v17=getfenv or function() return _ENV;end ;local v18=setmetatable;local v19=pcall;local v20=select;local v21=unpack or table.unpack ;local v22=tonumber;local function v23(v27,v28,...) local v29=1;local v30;v27=v12(v11(v27,5),v7("\240\186","\227\222\148\99\37"),function(v42) if (v9(v42,2)==(253 -172)) then v30=v8(v11(v42,1,1));return "";else local v94=0;local v95;while true do if (v94==0) then v95=v10(v8(v42,16));if v30 then local v120=0;local v121;while true do if (v120==1) then return v121;end if (v120==0) then v121=v13(v95,v30);v30=nil;v120=1;end end else return v95;end break;end end end end);local function v31(v43,v44,v45) if v45 then local v96=0;local v97;while true do if (v96==0) then v97=(v43/(2^(v44-(2 -1))))%(2^(((v45-1) -(v44-1)) + 1)) ;return v97-(v97%1) ;end end else local v98=2^(v44-1) ;return (((v43%(v98 + v98))>=v98) and 1) or 0 ;end end local function v32() local v46=0;local v47;while true do if (v46==0) then v47=v9(v27,v29,v29);v29=v29 + 1 ;v46=1;end if (1==v46) then return v47;end end end local function v33() local v48=0;local v49;local v50;while true do if (v48==0) then v49,v50=v9(v27,v29,v29 + 2 );v29=v29 + 2 ;v48=1;end if (v48==1) then return (v50 * 256) + v49 ;end end end local function v34() local v51=0;local v52;local v53;local v54;local v55;while true do if (v51==1) then return (v55 * (16777835 -(555 + 64))) + (v54 * (66467 -(857 + 74))) + (v53 * 256) + v52 ;end if (v51==0) then v52,v53,v54,v55=v9(v27,v29,v29 + (5 -2) );v29=v29 + (10 -6) ;v51=1;end end end local function v35() local v56=0;local v57;local v58;local v59;local v60;local v61;local v62;while true do if (1==v56) then v59=1;v60=(v31(v58,1,588 -(367 + 201) ) * (2^(959 -(214 + 713)))) + v57 ;v56=2;end if (v56==2) then v61=v31(v58,21,31);v62=((v31(v58,32)==1) and  -1) or 1 ;v56=3;end if (v56==3) then if (v61==0) then if (v60==(0 + 0)) then return v62 * 0 ;else v61=1;v59=0;end elseif (v61==2047) then return ((v60==0) and (v62 * (1/(0 + 0)))) or (v62 * NaN) ;end return v16(v62,v61-1023 ) * (v59 + (v60/(2^52))) ;end if (v56==0) then v57=v34();v58=v34();v56=1;end end end local function v36(v63) local v64=0;local v65;local v66;while true do if (2==v64) then v66={};for v102=1, #v65 do v66[v102]=v10(v9(v11(v65,v102,v102)));end v64=3;end if (v64==3) then return v14(v66);end if (0==v64) then v65=nil;if  not v63 then local v117=0;while true do if (v117==0) then v63=v34();if (v63==0) then return "";end break;end end end v64=1;end if (v64==1) then v65=v11(v27,v29,(v29 + v63) -(878 -(282 + 595)) );v29=v29 + v63 ;v64=2;end end end local v37=v34;local function v38(...) return {...},v20("#",...);end local function v39() local v67=0;local v68;local v69;local v70;local v71;local v72;local v73;while true do if (v67==1) then v72=v34();v73={};for v104=1,v72 do local v105=0;local v106;local v107;while true do if (0==v105) then v106=v32();v107=nil;v105=1;end if (v105==1) then if (v106==(1 + 0)) then v107=v32()~=0 ;elseif (v106==2) then v107=v35();elseif (v106==3) then v107=v36();end v73[v104]=v107;break;end end end v71[3 -0 ]=v32();v67=2;end if (v67==0) then v68={};v69={};v70={};v71={v68,v69,nil,v70};v67=1;end if (v67==2) then for v108=1,v34() do local v109=0;local v110;while true do if (v109==0) then v110=v32();if (v31(v110,1,1)==0) then local v123=0;local v124;local v125;local v126;while true do if (v123==2) then if (v31(v125,118 -(32 + 85) ,1)==1) then v126[2]=v73[v126[2]];end if (v31(v125,2,2)==1) then v126[3]=v73[v126[3]];end v123=3;end if (v123==3) then if (v31(v125,3,3)==(1 + 0)) then v126[4]=v73[v126[4]];end v68[v108]=v126;break;end if (1==v123) then v126={v33(),v33(),nil,nil};if (v124==0) then local v134=0;while true do if (v134==0) then v126[3]=v33();v126[4]=v33();break;end end elseif (v124==1) then v126[12 -9 ]=v34();elseif (v124==2) then v126[3]=v34() -(2^16) ;elseif (v124==3) then v126[3]=v34() -(2^16) ;v126[4]=v33();end v123=2;end if (v123==0) then v124=v31(v110,2,3);v125=v31(v110,4,6);v123=1;end end end break;end end end for v111=1,v34() do v69[v111-1 ]=v39();end return v71;end end end local function v40(v74,v75,v76) local v77=v74[1];local v78=v74[2];local v79=v74[3];return function(...) local v80=v77;local v81=v78;local v82=v79;local v83=v38;local v84=1;local v85= -1;local v86={};local v87={...};local v88=v20("#",...) -1 ;local v89={};local v90={};for v99=0,v88 do if (v99>=v82) then v86[v99-v82 ]=v87[v99 + 1 ];else v90[v99]=v87[v99 + 1 ];end end local v91=(v88-v82) + 1 ;local v92;local v93;while true do local v100=0;while true do if (v100==0) then v92=v80[v84];v93=v92[1];v100=1;end if (v100==1) then if (v93<=41) then if (v93<=20) then if (v93<=(2 + 7)) then if (v93<=4) then if (v93<=1) then if (v93==(957 -(892 + 65))) then v90[v92[2]][v92[3]]=v90[v92[4]];else v90[v92[2]]();end elseif (v93<=(4 -2)) then local v140=0;local v141;local v142;local v143;while true do if (0==v140) then v141=v92[2];v142={v90[v141](v21(v90,v141 + 1 ,v85))};v140=1;end if (v140==1) then v143=0;for v360=v141,v92[4] do local v361=0;while true do if (v361==0) then v143=v143 + 1 ;v90[v360]=v142[v143];break;end end end break;end end elseif (v93>(5 -2)) then v90[v92[2]]=v90[v92[3]];else local v244=0;local v245;local v246;while true do if (v244==0) then v245=v92[2];v246={};v244=1;end if (v244==1) then for v418=1, #v89 do local v419=0;local v420;while true do if (v419==0) then v420=v89[v418];for v469=0, #v420 do local v470=0;local v471;local v472;local v473;while true do if (v470==1) then v473=v471[2];if ((v472==v90) and (v473>=v245)) then local v489=0;while true do if (v489==0) then v246[v473]=v472[v473];v471[1]=v246;break;end end end break;end if (0==v470) then v471=v420[v469];v472=v471[1 -0 ];v470=1;end end end break;end end end break;end end end elseif (v93<=6) then if (v93>5) then v90[v92[2]]=v76[v92[3]];else v90[v92[2]]=v92[3];end elseif (v93<=7) then local v148=v92[2];v90[v148]=v90[v148](v90[v148 + 1 ]);elseif (v93>8) then local v247=0;local v248;local v249;local v250;local v251;while true do if (v247==0) then v248=v92[2];v249,v250=v83(v90[v248](v21(v90,v248 + 1 ,v92[3])));v247=1;end if (v247==1) then v85=(v250 + v248) -1 ;v251=0;v247=2;end if (2==v247) then for v421=v248,v85 do v251=v251 + 1 ;v90[v421]=v249[v251];end break;end end else local v252=0;local v253;local v254;local v255;while true do if (v252==1) then v255=0;for v424=v253,v92[4] do local v425=0;while true do if (v425==0) then v255=v255 + (351 -(87 + 263)) ;v90[v424]=v254[v255];break;end end end break;end if (v252==0) then v253=v92[2];v254={v90[v253](v21(v90,v253 + 1 ,v85))};v252=1;end end end elseif (v93<=14) then if (v93<=11) then if (v93>10) then local v150=v92[2];local v151=v92[184 -(67 + 113) ];local v152=v150 + 2 ;local v153={v90[v150](v90[v150 + 1 ],v90[v152])};for v224=1,v151 do v90[v152 + v224 ]=v153[v224];end local v154=v153[1];if v154 then local v256=0;while true do if (v256==0) then v90[v152]=v154;v84=v92[3];break;end end else v84=v84 + 1 ;end else v90[v92[2]]=v75[v92[3 + 0 ]];end elseif (v93<=12) then local v157=0;local v158;while true do if (v157==0) then v158=v92[2];v90[v158]=v90[v158](v21(v90,v158 + 1 ,v85));break;end end elseif (v93>13) then v90[v92[2]]=v92[7 -4 ] + v90[v92[4]] ;elseif  not v90[v92[2]] then v84=v84 + 1 ;else v84=v92[3];end elseif (v93<=17) then if (v93<=15) then v90[v92[2 + 0 ]]();elseif (v93>16) then if v90[v92[2]] then v84=v84 + 1 ;else v84=v92[3];end else v90[v92[2]]=v75[v92[3]];end elseif (v93<=(71 -53)) then if (v90[v92[2]]==v92[4]) then v84=v84 + 1 ;else v84=v92[3];end elseif (v93>19) then v90[v92[2]]=v90[v92[3]]%v90[v92[956 -(802 + 150) ]] ;else local v262=0;local v263;local v264;local v265;while true do if (v262==1) then v265=v90[v263 + 2 ];if (v265>0) then if (v264>v90[v263 + 1 ]) then v84=v92[3];else v90[v263 + (7 -4) ]=v264;end elseif (v264<v90[v263 + 1 ]) then v84=v92[5 -2 ];else v90[v263 + 3 ]=v264;end break;end if (v262==0) then v263=v92[2];v264=v90[v263];v262=1;end end end elseif (v93<=30) then if (v93<=25) then if (v93<=22) then if (v93==21) then v90[v92[2]]={};else local v160=v81[v92[3]];local v161;local v162={};v161=v18({},{[v7("\12\109\91\248\253\54\74","\153\83\50\50\150")]=function(v227,v228) local v229=0;local v230;while true do if (v229==0) then v230=v162[v228];return v230[1][v230[2]];end end end,[v7("\98\73\125\25\100\162\67\89\115\107","\45\61\22\19\124\19\203")]=function(v231,v232,v233) local v234=v162[v232];v234[1][v234[2]]=v233;end});for v236=1,v92[4] do local v237=0;local v238;while true do if (v237==0) then v84=v84 + 1 ;v238=v80[v84];v237=1;end if (1==v237) then if (v238[1]==4) then v162[v236-1 ]={v90,v238[3]};else v162[v236-1 ]={v75,v238[3]};end v89[ #v89 + 1 ]=v162;break;end end end v90[v92[2 + 0 ]]=v40(v160,v161,v76);end elseif (v93<=23) then local v164=0;local v165;local v166;while true do if (v164==1) then for v367=1, #v89 do local v368=0;local v369;while true do if (0==v368) then v369=v89[v367];for v447=0, #v369 do local v448=0;local v449;local v450;local v451;while true do if (v448==1) then v451=v449[2];if ((v450==v90) and (v451>=v165)) then local v488=0;while true do if (v488==0) then v166[v451]=v450[v451];v449[1]=v166;break;end end end break;end if (0==v448) then v449=v369[v447];v450=v449[1];v448=1;end end end break;end end end break;end if (v164==0) then v165=v92[2];v166={};v164=1;end end elseif (v93>(1021 -(915 + 82))) then local v266=0;local v267;local v268;local v269;local v270;while true do if (v266==2) then for v428=v267,v85 do local v429=0;while true do if (v429==0) then v270=v270 + 1 ;v90[v428]=v268[v270];break;end end end break;end if (0==v266) then v267=v92[2];v268,v269=v83(v90[v267](v21(v90,v267 + 1 ,v85)));v266=1;end if (v266==1) then v85=(v269 + v267) -1 ;v270=0;v266=2;end end elseif (v90[v92[5 -3 ]]==v92[4]) then v84=v84 + 1 ;else v84=v92[3];end elseif (v93<=27) then if (v93>26) then v90[v92[2]]=v90[v92[3]] + v92[4] ;else v90[v92[2 + 0 ]]=v92[3]~=0 ;end elseif (v93<=28) then local v169=0;local v170;while true do if (v169==0) then v170=v92[2];v90[v170]=v90[v170](v21(v90,v170 + (1 -0) ,v85));break;end end elseif (v93>29) then local v271=0;local v272;while true do if (v271==0) then v272=v92[1189 -(1069 + 118) ];v90[v272](v21(v90,v272 + 1 ,v85));break;end end else v90[v92[4 -2 ]]=v90[v92[3]][v92[8 -4 ]];end elseif (v93<=(7 + 28)) then if (v93<=32) then if (v93==(54 -23)) then local v171=0;local v172;local v173;while true do if (v171==0) then v172=v92[2];v173=v90[v92[3 + 0 ]];v171=1;end if (v171==1) then v90[v172 + 1 ]=v173;v90[v172]=v173[v92[4]];break;end end else v84=v92[3];end elseif (v93<=33) then local v175=0;local v176;local v177;local v178;while true do if (v175==0) then v176=v92[2];v177=v90[v176 + 2 ];v175=1;end if (2==v175) then if (v177>0) then if (v178<=v90[v176 + 1 ]) then local v440=0;while true do if (v440==0) then v84=v92[794 -(368 + 423) ];v90[v176 + 3 ]=v178;break;end end end elseif (v178>=v90[v176 + 1 ]) then local v441=0;while true do if (v441==0) then v84=v92[3];v90[v176 + 3 ]=v178;break;end end end break;end if (v175==1) then v178=v90[v176] + v177 ;v90[v176]=v178;v175=2;end end elseif (v93==34) then local v275=0;local v276;while true do if (0==v275) then v276=v92[2];v90[v276]=v90[v276](v21(v90,v276 + 1 ,v92[3]));break;end end else v90[v92[2]][v92[3]]=v90[v92[4]];end elseif (v93<=38) then if (v93<=36) then if (v92[2]==v90[v92[4]]) then v84=v84 + 1 ;else v84=v92[9 -6 ];end elseif (v93>37) then do return v90[v92[2]]();end else local v280=0;local v281;while true do if (v280==0) then v281=v92[2];v90[v281](v90[v281 + 1 ]);break;end end end elseif (v93<=39) then if  not v90[v92[2]] then v84=v84 + 1 ;else v84=v92[3];end elseif (v93==40) then v90[v92[2]]=v92[3] + v90[v92[4]] ;else do return;end end elseif (v93<=62) then if (v93<=51) then if (v93<=46) then if (v93<=43) then if (v93==42) then local v179=0;local v180;while true do if (0==v179) then v180=v92[2];v90[v180]=v90[v180](v21(v90,v180 + 1 ,v92[3]));break;end end else local v181=0;local v182;local v183;local v184;while true do if (v181==2) then for v371=1,v92[4] do v84=v84 + (19 -(10 + 8)) ;local v372=v80[v84];if (v372[1]==4) then v184[v371-1 ]={v90,v372[3]};else v184[v371-1 ]={v75,v372[3]};end v89[ #v89 + 1 ]=v184;end v90[v92[444 -(416 + 26) ]]=v40(v182,v183,v76);break;end if (v181==1) then v184={};v183=v18({},{[v7("\254\45\4\251\6\117\161","\217\161\114\109\149\98\16")]=function(v374,v375) local v376=0;local v377;while true do if (v376==0) then v377=v184[v375];return v377[1][v377[2]];end end end,[v7("\45\31\54\121\171\125\28\36\61\100","\20\114\64\88\28\220")]=function(v378,v379,v380) local v381=0;local v382;while true do if (0==v381) then v382=v184[v379];v382[1][v382[2]]=v380;break;end end end});v181=2;end if (v181==0) then v182=v81[v92[3]];v183=nil;v181=1;end end end elseif (v93<=(140 -96)) then do return;end elseif (v93>45) then v90[v92[2]]={};else local v285=v92[1 + 1 ];local v286,v287=v83(v90[v285](v90[v285 + 1 ]));v85=(v287 + v285) -1 ;local v288=0;for v347=v285,v85 do local v348=0;while true do if (v348==0) then v288=v288 + 1 ;v90[v347]=v286[v288];break;end end end end elseif (v93<=48) then if (v93==47) then v90[v92[2]][v92[3]]=v92[4];else local v187=0;local v188;while true do if (v187==0) then v188=v92[2];do return v90[v188](v21(v90,v188 + (1 -0) ,v92[3]));end break;end end end elseif (v93<=49) then v90[v92[2]]= #v90[v92[3]];elseif (v93>50) then if v90[v92[2]] then v84=v84 + (439 -(145 + 293)) ;else v84=v92[3];end else local v289=0;local v290;local v291;local v292;while true do if (0==v289) then v290=v92[2];v291=v90[v290];v289=1;end if (v289==1) then v292=v90[v290 + 2 ];if (v292>0) then if (v291>v90[v290 + 1 ]) then v84=v92[3];else v90[v290 + 3 ]=v291;end elseif (v291<v90[v290 + 1 ]) then v84=v92[3];else v90[v290 + 3 ]=v291;end break;end end end elseif (v93<=56) then if (v93<=53) then if (v93==52) then v90[v92[2]]=v90[v92[3]]%v92[4] ;else v90[v92[2]][v92[3]]=v92[4];end elseif (v93<=54) then do return v90[v92[2]]();end elseif (v93>55) then local v293=0;local v294;while true do if (v293==0) then v294=v92[2];v90[v294](v90[v294 + 1 ]);break;end end else local v295=0;local v296;local v297;local v298;local v299;while true do if (v295==2) then for v434=v296,v85 do local v435=0;while true do if (0==v435) then v299=v299 + 1 ;v90[v434]=v297[v299];break;end end end break;end if (v295==0) then v296=v92[2];v297,v298=v83(v90[v296](v90[v296 + 1 ]));v295=1;end if (v295==1) then v85=(v298 + v296) -1 ;v299=0;v295=2;end end end elseif (v93<=59) then if (v93<=(487 -(44 + 386))) then v90[v92[2]]=v90[v92[3]];elseif (v93>(1544 -(998 + 488))) then local v300=v92[2];local v301=v90[v92[3]];v90[v300 + 1 ]=v301;v90[v300]=v301[v92[4]];else v90[v92[2]]=v90[v92[1 + 2 ]][v92[4]];end elseif (v93<=60) then local v195=0;local v196;local v197;local v198;local v199;while true do if (v195==1) then v85=(v198 + v196) -1 ;v199=0;v195=2;end if (2==v195) then for v384=v196,v85 do local v385=0;while true do if (0==v385) then v199=v199 + 1 ;v90[v384]=v197[v199];break;end end end break;end if (v195==0) then v196=v92[2];v197,v198=v83(v90[v196](v21(v90,v196 + 1 ,v92[3])));v195=1;end end elseif (v93>61) then local v307=0;local v308;while true do if (0==v307) then v308=v92[2];v90[v308]=v90[v308](v90[v308 + 1 ]);break;end end else for v351=v92[2 + 0 ],v92[3] do v90[v351]=nil;end end elseif (v93<=72) then if (v93<=(839 -(201 + 571))) then if (v93<=64) then if (v93>63) then local v200=0;local v201;local v202;local v203;local v204;while true do if (v200==0) then v201=v92[2];v202,v203=v83(v90[v201](v21(v90,v201 + 1 ,v85)));v200=1;end if (v200==1) then v85=(v203 + v201) -1 ;v204=0;v200=2;end if (v200==2) then for v386=v201,v85 do v204=v204 + 1 ;v90[v386]=v202[v204];end break;end end else local v205=v92[2];v90[v205](v21(v90,v205 + 1 ,v92[3]));end elseif (v93<=65) then local v206=0;local v207;local v208;while true do if (v206==0) then v207=v92[2];v208=v90[v207];v206=1;end if (v206==1) then for v389=v207 + 1 ,v85 do v15(v208,v90[v389]);end break;end end elseif (v93==66) then for v356=v92[2],v92[1141 -(116 + 1022) ] do v90[v356]=nil;end else local v309=0;local v310;local v311;while true do if (v309==0) then v310=v92[2];v311=v90[v310];v309=1;end if (v309==1) then for v436=v310 + 1 ,v85 do v15(v311,v90[v436]);end break;end end end elseif (v93<=69) then if (v93==68) then if (v92[2]==v90[v92[16 -12 ]]) then v84=v84 + 1 + 0 ;else v84=v92[3];end else local v209=v92[2];local v210=v92[4];local v211=v209 + 2 ;local v212={v90[v209](v90[v209 + 1 ],v90[v211])};for v239=1,v210 do v90[v211 + v239 ]=v212[v239];end local v213=v212[1];if v213 then local v313=0;while true do if (v313==0) then v90[v211]=v213;v84=v92[3];break;end end else v84=v84 + 1 ;end end elseif (v93<=70) then local v214=v92[2];do return v21(v90,v214,v85);end elseif (v93>(259 -188)) then v90[v92[2]]=v92[3]~=(0 -0) ;else v90[v92[2]]=v76[v92[3]];end elseif (v93<=77) then if (v93<=74) then if (v93>73) then local v215=0;local v216;while true do if (0==v215) then v216=v92[2];do return v90[v216](v21(v90,v216 + (860 -(814 + 45)) ,v92[3]));end break;end end else v90[v92[2]]=v90[v92[3]]%v90[v92[4]] ;end elseif (v93<=75) then v90[v92[2]]=v92[7 -4 ];elseif (v93==76) then v90[v92[2]]=v90[v92[3]]%v92[4] ;else v90[v92[2]]=v90[v92[3]] + v92[1 + 3 ] ;end elseif (v93<=80) then if (v93<=78) then local v220=v92[2];do return v21(v90,v220,v85);end elseif (v93>79) then local v319=0;local v320;while true do if (v319==0) then v320=v92[2];v90[v320](v21(v90,v320 + 1 ,v92[3]));break;end end else v84=v92[3];end elseif (v93<=81) then local v221=0;local v222;while true do if (v221==0) then v222=v92[2];v90[v222](v21(v90,v222 + 1 ,v85));break;end end elseif (v93>82) then local v322=0;local v323;local v324;local v325;while true do if (v322==0) then v323=v92[2];v324=v90[v323 + 2 ];v322=1;end if (v322==2) then if (v324>0) then if (v325<=v90[v323 + 1 ]) then local v467=0;while true do if (v467==0) then v84=v92[3];v90[v323 + 3 ]=v325;break;end end end elseif (v325>=v90[v323 + 1 ]) then local v468=0;while true do if (v468==0) then v84=v92[3];v90[v323 + 3 ]=v325;break;end end end break;end if (v322==1) then v325=v90[v323] + v324 ;v90[v323]=v325;v322=2;end end else v90[v92[2]]= #v90[v92[3]];end v84=v84 + 1 ;break;end end end end;end return v40(v39(),{},v28)(...);end return v23("LOL!0D3Q0003063Q00737472696E6703043Q006368617203043Q00627974652Q033Q0073756203053Q0062697433322Q033Q0062697403043Q0062786F7203053Q007461626C6503063Q00636F6E63617403063Q00696E7365727403053Q006D6174636803083Q00746F6E756D62657203053Q007063612Q6C00243Q0012063Q00013Q00201D5Q0002001206000100013Q00201D000100010003001206000200013Q00201D000200020004001206000300053Q00060D0003000A0001000100044F3Q000A0001001206000300063Q00201D000400030007001206000500083Q00201D000500050009001206000600083Q00201D00060006000A00062B00073Q000100062Q00043Q00064Q00048Q00043Q00044Q00043Q00014Q00043Q00024Q00043Q00053Q001206000800013Q00201D00080008000B0012060009000C3Q001206000A000D3Q00062B000B0001000100052Q00043Q00074Q00043Q00094Q00043Q00084Q00043Q000A4Q00043Q000B4Q0039000C000B4Q0026000C00014Q0046000C6Q00293Q00013Q00023Q00023Q00026Q00F03F026Q00704002264Q001500025Q001205000300014Q005200045Q001205000500013Q0004130003002100012Q001000076Q0039000800024Q0010000900014Q0010000A00024Q0010000B00034Q0010000C00044Q0039000D6Q0039000E00063Q00204D000F000600012Q003C000C000F4Q000C000B3Q00022Q0010000C00034Q0010000D00044Q0039000E00014Q0052000F00014Q0014000F0006000F001028000F0001000F2Q0052001000014Q001400100006001000102800100001001000204D0010001000012Q003C000D00104Q0019000C6Q000C000A3Q0002002034000A000A00022Q00370009000A4Q005100073Q00010004210003000500012Q0010000300054Q0039000400024Q004A000300044Q004600036Q00293Q00017Q00043Q00027Q004003053Q003A25642B3A2Q033Q0025642B026Q00F03F001C3Q00062B5Q000100012Q000A8Q0010000100014Q0010000200024Q0010000300024Q001500046Q0010000500034Q003900066Q003D000700074Q003C000500074Q004300043Q000100201D000400040001001205000500024Q0022000300050002001205000400034Q003C000200044Q000C00013Q0002002612000100180001000400044F3Q001800012Q003900016Q001500026Q004A000100024Q004600015Q00044F3Q001B00012Q0010000100044Q0026000100014Q004600016Q00293Q00013Q00013Q00503Q0003083Q00496E7374616E63652Q033Q006E657703093Q0030DE2BB706D31EA70A03043Q00D263BD5903043Q004E616D6503073Q00B559EC3914FF9503063Q008DE6318D5D7103063Q00506172656E7403043Q0067616D6503073Q00436F726547756903053Q0057E40DFE7403043Q009311966C03043Q0053697A6503053Q005544696D32028Q00026Q00694003083Q00506F736974696F6E03103Q004261636B67726F756E64436F6C6F723303063Q00436F6C6F723303073Q0066726F6D524742026Q004240030C3Q00426F72646572436F6C6F7233030F3Q00426F7264657253697A65506978656C026Q00F03F03063Q004163746976652Q0103163Q004261636B67726F756E645472616E73706172656E637903093Q004472612Q6761626C6503083Q00DD2685226DE1ED1D03063Q008F886FC64D1F030C3Q00436F726E657252616469757303043Q005544696D026Q00244003093Q009D0711B37A86AB070503063Q00E7C96269C73603043Q0054657874030D3Q0024C4A1A9008661D71FCCA8BC1E03083Q008477ADCCD96CE341030A3Q0054657874436F6C6F7233025Q00E06F4003043Q00466F6E7403043Q00456E756D030A3Q00476F7468616D426F6C6403083Q005465787453697A65026Q003240030E3Q00DEC34CCC39E1C950C413FFC153C603053Q00558DA03EA3026Q0044C0025Q008050C0026Q003440026Q00474003123Q005363726F2Q6C426172546869636B6E652Q7303053Q00436C6F6E6503083Q001917F0C2B2EA273B03063Q00854C5EA3B6C003053Q00436F6C6F7203093Q00546869636B6E652Q73030C3Q0013DC182F133B0AF42D29153B03063Q004F469554466003133Q00486F72697A6F6E74616C416C69676E6D656E7403063Q0043656E74657203093Q00536F72744F72646572030B3Q004C61796F75744F7264657203073Q0050612Q64696E67026Q001440030A3Q004765745365727669636503083Q00C1310105AFC854EA03073Q003A8D58666DDBA103093Q00776F726B737061636503073Q0054652Q7261696E03073Q0061A9ACC883B74003063Q00DA25C8D5BCEA03063Q00C0162703874C03083Q001693634970E2387803053Q00233832751903063Q001E6D51551D6D03063Q00EB5601381DC103083Q00E3A83A6E4D79B8CF03053Q00EDAC545E4103073Q0028BEC43B2C24BC0111012Q0006333Q000F2Q013Q00044F3Q000F2Q01001206000100013Q00201D0001000100022Q001000025Q001205000300033Q001205000400044Q003C000200044Q000C00013Q00022Q001000025Q001205000300063Q001205000400074Q0022000200040002001023000100050002001206000200093Q00201D00020002000A001023000100080002001206000200013Q00201D0002000200022Q001000035Q0012050004000B3Q0012050005000C4Q003C000300054Q000C00023Q00020012060003000E3Q00201D0003000300020012050004000F3Q001205000500103Q0012050006000F3Q001205000700104Q00220003000700020010230002000D00030012060003000E3Q00201D0003000300020012050004000F3Q0012050005000F3Q0012050006000F3Q0012050007000F4Q0022000300070002001023000200110003001206000300133Q00201D000300030014001205000400153Q001205000500153Q001205000600154Q0022000300060002001023000200120003001206000300133Q00201D0003000300020012050004000F3Q0012050005000F3Q0012050006000F4Q002200030006000200102300020016000300303500020017001800303500020019001A0030350002001B000F0030350002001C001A001023000200080001001206000300013Q00201D0003000300022Q001000045Q0012050005001D3Q0012050006001E4Q003C000400064Q000C00033Q0002001206000400203Q00201D0004000400020012050005000F3Q001205000600214Q00220004000600020010230003001F0004001023000300080002001206000400013Q00201D0004000400022Q001000055Q001205000600223Q001205000700234Q003C000500074Q000C00043Q00020012060005000E3Q00201D000500050002001205000600183Q0012050007000F3Q0012050008000F3Q001205000900154Q00220005000900020010230004000D0005001206000500133Q00201D0005000500020012050006000F3Q0012050007000F3Q0012050008000F4Q0022000500080002001023000400120005001206000500133Q00201D0005000500020012050006000F3Q0012050007000F3Q0012050008000F4Q00220005000800020010230004001600050030350004001700182Q001000055Q001205000600253Q001205000700264Q00220005000700020010230004002400050030350004001B0018001206000500133Q00201D000500050002001205000600283Q001205000700283Q001205000800284Q00220005000800020010230004002700050012060005002A3Q00201D00050005002900201D00050005002B0010230004002900050030350004002C002D001023000400080002001206000500013Q00201D0005000500022Q001000065Q0012050007002E3Q0012050008002F4Q003C000600084Q000C00053Q00020012060006000E3Q00201D000600060002001205000700183Q001205000800303Q001205000900183Q001205000A00314Q00220006000A00020010230005000D00060012060006000E3Q00201D0006000600020012050007000F3Q001205000800323Q0012050009000F3Q001205000A00334Q00220006000A0002001023000500110006001206000600133Q00201D000600060002001205000700183Q001205000800183Q001205000900184Q0022000600090002001023000500120006001206000600133Q00201D0006000600020012050007000F3Q0012050008000F3Q0012050009000F4Q00220006000900020010230005001600060030350005001700180030350005003400180010230005000800020030350005001B001800201F0006000300352Q003E000600020002001023000600080005001206000600013Q00201D0006000600022Q001000075Q001205000800363Q001205000900374Q003C000700094Q000C00063Q0002001206000700133Q00201D0007000700020012050008000F3Q0012050009000F3Q001205000A000F4Q00220007000A0002001023000600380007003035000600390018001023000600080005001206000700013Q00201D0007000700022Q001000085Q0012050009003A3Q001205000A003B4Q003C0008000A4Q000C00073Q00020012060008002A3Q00201D00080008003C00201D00080008003D0010230007003C00080012060008002A3Q00201D00080008003E00201D00080008003F0010230007003E0008001206000800203Q00201D0008000800020012050009000F3Q001205000A00414Q00220008000A0002001023000700400008001023000700080005001206000800093Q00201F0008000800422Q0010000A5Q001205000B00433Q001205000C00444Q003C000A000C4Q000C00083Q0002001206000900453Q00201D00090009004600062B000A3Q000100052Q00043Q00054Q00043Q00034Q000A8Q00043Q00084Q00043Q00094Q0039000B000A4Q0010000C5Q001205000D00473Q001205000E00484Q0022000C000E000200062B000D0001000100032Q000A8Q00043Q00094Q00043Q00084Q0050000B000D00012Q0039000B000A4Q0010000C5Q001205000D00493Q001205000E004A4Q0022000C000E000200062B000D0002000100032Q00043Q00084Q000A8Q00043Q00094Q0050000B000D00012Q0039000B000A4Q0010000C5Q001205000D004B3Q001205000E004C4Q0022000C000E000200062B000D0003000100032Q000A8Q00043Q00084Q00043Q00094Q0050000B000D00012Q0039000B000A4Q0010000C5Q001205000D004D3Q001205000E004E4Q0022000C000E000200062B000D0004000100032Q00043Q00084Q00043Q00094Q000A8Q0050000B000D00012Q0039000B000A4Q0010000C5Q001205000D004F3Q001205000E00504Q0022000C000E000200062B000D0005000100032Q00043Q00084Q000A8Q00043Q00094Q0050000B000D00012Q001700015Q00044F3Q00102Q0100201D00013Q00182Q00293Q00013Q00063Q001D3Q00028Q00026Q00F03F027Q004003043Q00466F6E7403043Q00456E756D030E3Q00476F7468616D53656D69626F6C6403083Q005465787453697A65026Q002A4003063Q00506172656E7403053Q00436C6F6E65026Q00084003083Q00496E7374616E63652Q033Q006E6577030A3Q00FE750229775C3C47C57E03083Q0033AA107A5D35294803043Q0053697A6503053Q005544696D32026Q00414003103Q004261636B67726F756E64436F6C6F723303063Q00436F6C6F723303073Q0066726F6D524742026Q004940030C3Q00426F72646572436F6C6F723303163Q004261636B67726F756E645472616E73706172656E6379030A3Q0054657874436F6C6F7233030F3Q00426F7264657253697A65506978656C03043Q005465787403113Q004D6F75736542752Q746F6E31436C69636B03073Q00436F2Q6E65637402753Q001205000200014Q003D000300043Q0026120002006E0001000200044F3Q006E00010026120003001D0001000300044F3Q001D0001001205000500013Q000E440001000F0001000500044F3Q000F0001001206000600053Q00201D00060006000400201D000600060006001023000400040006003035000400070008001205000500023Q002612000500180001000200044F3Q001800012Q001000065Q0010230004000900062Q0010000600013Q00201F00060006000A2Q003E000600020002001023000600090004001205000500033Q000E44000300070001000500044F3Q000700010012050003000B3Q00044F3Q001D000100044F3Q00070001002612000300490001000100044F3Q00490001001205000500013Q002612000500240001000300044F3Q00240001001205000300023Q00044F3Q00490001002612000500370001000100044F3Q003700010012060006000C3Q00201D00060006000D2Q0010000700023Q0012050008000E3Q0012050009000F4Q003C000700094Q000C00063Q00022Q0039000400063Q001206000600113Q00201D00060006000D001205000700023Q001205000800013Q001205000900013Q001205000A00124Q00220006000A0002001023000400100006001205000500023Q002612000500200001000200044F3Q00200001001206000600143Q00201D000600060015001205000700163Q001205000800163Q001205000900164Q0022000600090002001023000400130006001206000600143Q00201D00060006000D001205000700013Q001205000800013Q001205000900014Q0022000600090002001023000400170006001205000500033Q00044F3Q00200001002612000300610001000200044F3Q00610001001205000500013Q002612000500570001000200044F3Q00570001003035000400180001001206000600143Q00201D00060006000D001205000700023Q001205000800023Q001205000900024Q0022000600090002001023000400190006001205000500033Q0026120005005C0001000100044F3Q005C00010030350004001A00020010230004001B3Q001205000500023Q0026120005004C0001000300044F3Q004C0001001205000300033Q00044F3Q0061000100044F3Q004C0001002612000300040001000B00044F3Q0004000100201D00050004001C00201F00050005001D00062B00073Q000100042Q00043Q00014Q000A3Q00034Q000A3Q00024Q000A3Q00044Q005000050007000100044F3Q0074000100044F3Q0004000100044F3Q00740001002612000200020001000100044F3Q00020001001205000300014Q003D000400043Q001205000200023Q00044F3Q000200012Q00293Q00013Q00013Q00143Q00028Q00026Q00F03F03053Q007061697273030B3Q004765744368696C6472656E2Q033Q00497341030A3Q0093163E496944A6B7103603073Q00CED26253261A342Q033Q0075530E03063Q002C263877479403153Q00CC57DAFCFD7BD9E1FD5DD5E7E657D8D6E95ED3F0FB03043Q00938F38B6030B3Q00FDDA8EF024FAD087FA2ACB03053Q0049BFB6E19F030A3Q00E02707D0E72D14C7C13F03043Q002QA24B72030D3Q00B8921A305492943104538E840003053Q0035EBE7746203073Q0044657374726F7903063Q0067EE5C9334B703083Q005C248233E650C479005F3Q0012053Q00013Q0026123Q00060001000200044F3Q000600012Q001000016Q000100010001000100044F3Q005E00010026123Q00010001000100044F3Q00010001001205000100013Q002612000100580001000100044F3Q00580001001206000200034Q0010000300013Q00201F0003000300042Q0037000300044Q000800023Q000400044F3Q0043000100201F0007000600052Q0010000900023Q001205000A00063Q001205000B00074Q003C0009000B4Q000C00073Q000200060D000700410001000100044F3Q0041000100201F0007000600052Q0010000900023Q001205000A00083Q001205000B00094Q003C0009000B4Q000C00073Q000200060D000700410001000100044F3Q0041000100201F0007000600052Q0010000900023Q001205000A000A3Q001205000B000B4Q003C0009000B4Q000C00073Q000200060D000700410001000100044F3Q0041000100201F0007000600052Q0010000900023Q001205000A000C3Q001205000B000D4Q003C0009000B4Q000C00073Q000200060D000700410001000100044F3Q0041000100201F0007000600052Q0010000900023Q001205000A000E3Q001205000B000F4Q003C0009000B4Q000C00073Q000200060D000700410001000100044F3Q0041000100201F0007000600052Q0010000900023Q001205000A00103Q001205000B00114Q003C0009000B4Q000C00073Q00020006330007004300013Q00044F3Q0043000100201F0007000600122Q0038000700020001000645000200110001000200044F3Q00110001001206000200034Q0010000300033Q00201F0003000300042Q0037000300044Q000800023Q000400044F3Q0055000100201F0007000600052Q0010000900023Q001205000A00133Q001205000B00144Q003C0009000B4Q000C00073Q00020006330007005500013Q00044F3Q0055000100201F0007000600122Q00380007000200010006450002004B0001000200044F3Q004B0001001205000100023Q000E44000200090001000100044F3Q000900010012053Q00023Q00044F3Q0001000100044F3Q0009000100044F3Q000100012Q00293Q00017Q00B93Q00028Q00026Q00144003083Q00536B79626F78446E03173Q00107D530F60117A5F07775830045827562B13562755271E03053Q0013621F2B6E03083Q00536B79626F78467403173Q00141D4AC6BF618E1216569DE33DDD524B069FF426D8554803073Q00EB667F32A7CC1203083Q00536B79626F784C6603173Q0042A3ED22573D55B5FC271E611FF7A177107608F5A6701303063Q004E30C195432403083Q00536B79626F78527403173Q00221C981952231B9411456A51CF4E15644AD84015634DD703053Q0021507EE07803083Q00536B79626F78557003173Q00FEAA1BC54FFFAD17CD58B6E74C9208BDFA56940FBAF95003053Q003C8CC863A403093Q0053746172436F756E74030E3Q0053756E416E67756C617253697A65026Q002640026Q001840026Q00204003103Q005365744D6174657269616C436F6C6F7203043Q00456E756D03083Q004D6174657269616C03043Q0053616C7403063Q00436F6C6F723303073Q0066726F6D524742025Q00206840026Q006740025Q00E0644003053Q004772612Q73025Q00805A40025Q00C05F40025Q00804F40030B3Q00437261636B65644C617661026Q006D40025Q00806340025Q00805240030A3Q00572Q6F64506C616E6B73025Q00606140025Q00405B40025Q00C05340030A3Q004C656166794772612Q73025Q00C05C40025Q008060402Q033Q00496365025Q00206040025Q00406840026Q006C4003073Q0041737068616C74025Q00C05E40025Q00C05A40026Q002240026Q000840030E3Q0057617465725761766553702Q6564026Q00244003113Q0073657468692Q64656E70726F7065727479030A3Q00A3F10729B086E00D29AC03053Q00C2E7946446030B3Q00615EC0B0E5E44342C6B7FE03063Q00A8262CA1C396026Q66E63F03083Q00496E7374616E63652Q033Q006E6577030B3Q00A2F08D793DCDB01085FF9603083Q0076E09CE2165088D603093Q00496E74656E73697479026Q00F03F03043Q0053697A65025Q0080564003093Q005468726573686F6C64027Q0040026Q00104003073Q00456E61626C65642Q0103063Q00506172656E742Q033Q0071E54003043Q00E0228E3903143Q0043656C65737469616C426F6469657353686F776E0100030F3Q004D2Q6F6E416E67756C617253697A65030D3Q004D2Q6F6E54657874757265496403173Q00CCA5DDDC60E2581AD7A39F923CA7095A8AF4978D26A80F03083Q006EBEC7A5BD13913D03083Q00536B79626F78426B03173Q00C8E96FE998D4DFFF7EECD18895BD23BCDF9F82BF24BBDC03063Q00A7BA8B1788EB03073Q00416D6269656E74030A3Q004272696768746E652Q73020AD7A3703D0A094003093Q00436C6F636B54696D65026Q002D4003113Q00436F6C6F7253686966745F426F2Q746F6D030E3Q00436F6C6F7253686966745F546F70025Q00806740025Q00A0614003173Q00456E7669726F6E6D656E7444692Q667573655363616C65020E2DB29DEFA7E23F03183Q00456E7669726F6E6D656E7453706563756C61725363616C6503053Q00427269636B025Q00406140025Q00805540026Q004F402Q033Q004D7564026Q004D40026Q004740026Q00424003083Q00506176656D656E74025Q00806240025Q0080614003043Q00536E6F77025Q00606840025Q00E06840025Q00406B4003083Q00436F6E6372657465025Q0080594003053Q00536C61746503063Q00426173616C74026Q003E40025Q0080424003043Q00526F636B026Q005B40025Q00C05B4003043Q0053616E64025Q00E06F40025Q00E06D40025Q00206D40030E3Q00536861646F77536F66746E652Q73027B14AE47E17AA43F03093Q0054696D654F6644617903083Q004BE1D25E4AEFD85D03043Q006D7AD5E8030A3Q00DAF2A138E0F8AE3FE9EE03043Q00508E97C2030A3Q00546563686E6F6C6F677903093Q00536861646F774D6170030A3Q005761746572436F6C6F7203103Q0057617465725265666C656374616E6365029A5Q99E13F03113Q0057617465725472616E73706172656E6379030D3Q0057617465725761766553697A65026Q001C4003093Q0053616E6473746F6E65025Q00406F40025Q00206C4003093Q004C696D6573746F6E65025Q00C05940025Q00405540025Q0080534003063Q0047726F756E64026Q005740025Q00804D4003073Q00476C6163696572025Q00E06940025Q00606740025Q00206540030B3Q00436F2Q626C6573746F6E65025Q00C06040025Q00805D40030C3Q0053756E54657874757265496403173Q0011C46F4D10D572580AC22D034C9727145795221D529F2703043Q002C63A61703153Q005FF82539218773E53B3330B075F8271335A279F43D03063Q00C41C9749565303083Q00436F6E74726173740252B81E85EB51C83F030A3Q0053617475726174696F6E02B81E85EB51B8BE3F03093Q0054696E74436F6C6F7203143Q004578706F73757265436F6D70656E736174696F6E03083Q00466F67436F6C6F72025Q00406240026Q006A4003063Q00466F67456E64025Q0070A74003083Q00466F675374617274025Q00C0724003123Q0047656F677261706869634C61746974756465025Q00E06140030D3Q00476C6F62616C536861646F7773030E3Q004F7574642Q6F72416D6269656E74025Q00206240026Q006040025Q00C0574000E6012Q0012053Q00014Q003D000100033Q0026123Q00200001000200044F3Q002000012Q001000045Q001205000500043Q001205000600054Q00220004000600020010230002000300042Q001000045Q001205000500073Q001205000600084Q00220004000600020010230002000600042Q001000045Q0012050005000A3Q0012050006000B4Q00220004000600020010230002000900042Q001000045Q0012050005000D3Q0012050006000E4Q00220004000600020010230002000C00042Q001000045Q001205000500103Q001205000600114Q00220004000600020010230002000F00040030350002001200010030350002001300140012053Q00153Q0026123Q00770001001600044F3Q007700012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006001A0012060007001B3Q00201D00070007001C0012050008001D3Q0012050009001E3Q001205000A001F4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600200012060007001B3Q00201D00070007001C001205000800213Q001205000900223Q001205000A00234Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600240012060007001B3Q00201D00070007001C001205000800253Q001205000900263Q001205000A00274Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600280012060007001B3Q00201D00070007001C001205000800293Q0012050009002A3Q001205000A002B4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006002C0012060007001B3Q00201D00070007001C0012050008002D3Q0012050009002E3Q001205000A00274Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006002F0012060007001B3Q00201D00070007001C001205000800303Q001205000900313Q001205000A00324Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600330012060007001B3Q00201D00070007001C0012050008002D3Q001205000900343Q001205000A00354Q003C0007000A4Q005100043Q00010012053Q00363Q0026123Q00970001003700044F3Q009700012Q0010000400013Q0030350004003800390012060004003A4Q0010000500014Q001000065Q0012050007003B3Q0012050008003C4Q00220006000800022Q0048000700014Q00500004000700010012060004003A4Q0010000500014Q001000065Q0012050007003D3Q0012050008003E4Q00220006000800020012050007003F4Q0050000400070001001206000400403Q00201D0004000400412Q001000055Q001205000600423Q001205000700434Q003C000500074Q000C00043Q00022Q0039000100043Q0030350001004400450030350001004600470030350001004800490012053Q004A3Q000E44004A00B100013Q00044F3Q00B100010030350001004B004C2Q0010000400023Q0010230001004D0004001206000400403Q00201D0004000400412Q001000055Q0012050006004E3Q0012050007004F4Q003C000500074Q000C00043Q00022Q0039000200043Q0030350002005000510030350002005200142Q001000045Q001205000500543Q001205000600554Q00220004000600020010230002005300042Q001000045Q001205000500573Q001205000600584Q00220004000600020010230002005600040012053Q00023Q0026123Q00D40001000100044F3Q00D400012Q0010000400023Q0012060005001B3Q00201D00050005001C001205000600013Q001205000700013Q001205000800014Q00220005000800020010230004005900052Q0010000400023Q0030350004005A005B2Q0010000400023Q0030350004005C005D2Q0010000400023Q0012060005001B3Q00201D00050005001C001205000600013Q001205000700013Q001205000800014Q00220005000800020010230004005E00052Q0010000400023Q0012060005001B3Q00201D00050005001C001205000600603Q001205000700613Q001205000800454Q00220005000800020010230004005F00052Q0010000400023Q0030350004006200632Q0010000400023Q0030350004006400450012053Q00453Q0026123Q002B2Q01003600044F3Q002B2Q012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600650012060007001B3Q00201D00070007001C001205000800663Q001205000900673Q001205000A00684Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600690012060007001B3Q00201D00070007001C0012050008006A3Q0012050009006B3Q001205000A006C4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006006D0012060007001B3Q00201D00070007001C0012050008006E3Q0012050009006E3Q001205000A006F4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600700012060007001B3Q00201D00070007001C001205000800713Q001205000900723Q001205000A00734Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600740012060007001B3Q00201D00070007001C001205000800223Q001205000900753Q001205000A00234Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600760012060007001B3Q00201D00070007001C0012050008001D3Q0012050009001E3Q001205000A001F4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600770012060007001B3Q00201D00070007001C001205000800783Q001205000900783Q001205000A00794Q003C0007000A4Q005100043Q00010012053Q00393Q0026123Q00462Q01003900044F3Q00462Q012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006007A0012060007001B3Q00201D00070007001C001205000800753Q0012050009007B3Q001205000A007C4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006007D0012060007001B3Q00201D00070007001C0012050008007E3Q0012050009007F3Q001205000A00804Q003C0007000A4Q005100043Q000100044F3Q00E52Q01000E44004900692Q013Q00044F3Q00692Q012Q0010000400023Q0030350004008100822Q0010000400024Q001000055Q001205000600843Q001205000700854Q00220005000700020010230004008300050012060004003A4Q0010000500024Q001000065Q001205000700863Q001205000800874Q0022000600080002001206000700183Q00201D00070007008800201D0007000700892Q00500004000700012Q0010000400013Q0012060005001B3Q00201D00050005001C001205000600013Q001205000700013Q001205000800014Q00220005000800020010230004008A00052Q0010000400013Q0030350004008B008C2Q0010000400013Q0030350004008D00012Q0010000400013Q0030350004008E00010012053Q00373Q0026123Q00AB2Q01008F00044F3Q00AB2Q010030350003004B004C2Q0010000400023Q0010230003004D00042Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600900012060007001B3Q00201D00070007001C0012050008007E3Q001205000900913Q001205000A00924Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600930012060007001B3Q00201D00070007001C001205000800943Q001205000900953Q001205000A00964Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D0006000600970012060007001B3Q00201D00070007001C001205000800753Q001205000900983Q001205000A00994Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006009A0012060007001B3Q00201D00070007001C0012050008009B3Q0012050009009C3Q001205000A009D4Q003C0007000A4Q005100043Q00012Q0010000400013Q00201F000400040017001206000600183Q00201D00060006001900201D00060006009E0012060007001B3Q00201D00070007001C0012050008009F3Q0012050009009F3Q001205000A00A04Q003C0007000A4Q005100043Q00010012053Q00163Q0026123Q00C72Q01001500044F3Q00C72Q012Q001000045Q001205000500A23Q001205000600A34Q0022000400060002001023000200A100042Q0010000400023Q0010230002004D0004001206000400403Q00201D0004000400412Q001000055Q001205000600A43Q001205000700A54Q003C000500074Q000C00043Q00022Q0039000300043Q0030350003005A0082003035000300A600A7003035000300A800A90012060004001B3Q00201D00040004001C0012050005007E3Q0012050006007E3Q0012050007007E4Q0022000400070002001023000300AA00040012053Q008F3Q0026123Q00020001004500044F3Q000200012Q0010000400023Q003035000400AB00012Q0010000400023Q0012060005001B3Q00201D00050005001C001205000600AD3Q001205000700AE3Q0012050008007E4Q0022000500080002001023000400AC00052Q0010000400023Q003035000400AF00B02Q0010000400023Q003035000400B100B22Q0010000400023Q003035000400B300B42Q0010000400023Q003035000400B5004C2Q0010000400023Q0012060005001B3Q00201D00050005001C001205000600B73Q001205000700B83Q001205000800B94Q0022000500080002001023000400B600050012053Q00493Q00044F3Q000200012Q00293Q00017Q00C83Q00028Q00027Q0040026Q000840026Q001840026Q00F03F030A3Q004272696768746E652Q7303083Q00436F6E7472617374029A5Q99B93F03063Q00506172656E7403083Q00496E7374616E63652Q033Q006E657703153Q009B7AEEFA9F9B7AF0E788BB61EBFA839D73E4F08EAC03053Q00EDD8158295026Q001040026Q001C4003073Q00456E61626C65642Q01030A3Q0053617475726174696F6E029A5Q99C9BF03093Q0054696E74436F6C6F7203063Q00436F6C6F723303073Q0066726F6D524742025Q00E06F40030F3Q004D2Q6F6E416E67756C617253697A65030D3Q004D2Q6F6E54657874757265496403173Q00904C475EA3DA5B96142Q10A3C247CD432Q50BE8754924903073Q003EE22E2Q3FD0A903083Q00536B79626F78426B03173Q00F71B4D820C1E2A4AEC1D0FCC505C7F0EBC490DD14F5E7E03083Q003E857935E37F6D4F03083Q00536B79626F78446E03173Q0002162AF4C5BDA7041D36AF99E1F340446BA58EFCF6484303073Q00C270745295B6CE03083Q00536B79626F78467403173Q002BAA5419D3F10B2DA148428FAD5F69F8154898B05C6CFA03073Q006E59C82C78A08203083Q00536B79626F784C6603173Q00B9C1534750593E59A2C711090C1B6B1DF293131412196C03083Q002DCBA32B26232A5B03083Q00536B79626F78527403173Q00C087C42294BA51C68CD879C8E60582D58573DFF80D86D303073Q0034B2E5BC43E7C903083Q00536B79626F78557003173Q0033434805E44F263548545EB8137271110954AF0E77731903073Q004341213064973C026Q0014402Q033Q002QECB703053Q0093BF87CEB803143Q0043656C65737469616C426F6469657353686F776E03043Q0053697A65026Q004C4003093Q005468726573686F6C6402C976BE9F1A2FFD3F030B3Q00A624A9CED576B4822DA5D503073Q00D2E448C6A1B83303093Q00496E74656E7369747903093Q0053746172436F756E74025Q0070A740030E3Q0053756E416E67756C617253697A65026Q002240030C3Q0053756E54657874757265496403163Q00244BEB1160DD335DA95F3CDD3D50BC0366C07843E31703063Q00AE5629937013030D3Q00681583392416028E5D0688083103083Q00CB3B60ED6B456F71020AD7A3703D0AC73F03063Q0053707265616402B81E85EB51B8BE3F030A3Q000502A1EE22E0DF2104A903073Q00B74476CC81519003053Q00436F6C6F72025Q00E06840025Q00406540025Q00C05A40026Q00204003063Q004F2Q6673657403053Q004465636179026Q005740026Q004E40026Q002A4003073Q0044656E7369747902E17A14AE47E1DA3F03053Q00476C61726503043Q0048617A6503113Q0073657468692Q64656E70726F7065727479030A3Q003AA873EC058D02A277FD03063Q00E26ECD10846B03043Q00456E756D030A3Q00546563686E6F6C6F677903063Q00467574757265030A3Q005761746572436F6C6F72025Q00805240025Q0040554003103Q0057617465725265666C656374616E636503113Q0057617465725472616E73706172656E6379030D3Q0057617465725761766553697A65026Q00E03F030E3Q0057617465725761766553702Q6564026Q002440030A3Q00CFC6E3D653EAD7E9D64F03053Q00218BA380B9030B3Q00704A05CD447401D0504C0C03043Q00BE373864026Q66E63F03083Q00466F67436F6C6F7203063Q00466F67456E64024Q0084D79741030D3Q00476C6F62616C536861646F7773030E3Q004F7574642Q6F72416D6269656E7403083Q00466F675374617274026Q00344003123Q0047656F677261706869634C61746974756465026Q005240030E3Q00536861646F77536F66746E652Q7303093Q0054696D654F6644617903083Q0006F8664E45B9A30603073Q009336CF5C7E738303103Q005365744D6174657269616C436F6C6F7203083Q004D6174657269616C03083Q00436F6E6372657465025Q00C05F40025Q00805940025Q00804F4003053Q004772612Q73026Q005540025Q00C0514003083Q00506176656D656E74025Q00806240025Q0080614003073Q0041737068616C74026Q005F4003043Q0053616C74025Q00C06840025Q00A06740025Q00A0664003043Q0053616E64025Q00E06140025Q00805F40025Q00C0574003093Q004C696D6573746F6E65025Q00C06940025Q00A0654003073Q00476C6163696572025Q00405940026Q006640025Q00406D40030A3Q004C656166794772612Q73025Q00C05C40025Q008060402Q033Q00496365025Q00206040025Q00406840026Q006C4003063Q0047726F756E64025Q00C05540026Q00514003043Q00536E6F77025Q00606840025Q00406B40030B3Q00437261636B65644C617661026Q006D40025Q00806340030A3Q00572Q6F64506C616E6B73025Q00606140025Q00405B40025Q00C0534003053Q00427269636B025Q00406140025Q00805540026Q004F402Q033Q004D7564026Q004840025Q00405640025Q0080504003063Q00426173616C74026Q003E40025Q0080424003053Q00536C61746503043Q00526F636B025Q00C05240030B3Q00436F2Q626C6573746F6E65025Q00C05E40025Q0080564003093Q0053616E6473746F6E65025Q0020614003073Q00416D6269656E74025Q00806540026Q660E4003183Q00456E7669726F6E6D656E7453706563756C61725363616C6502B81E85EB51B8AE3F03143Q004578706F73757265436F6D70656E736174696F6E02B81E85EB51B8CEBF030E3Q00436F6C6F7253686966745F546F70025Q00C06540025Q0080454003173Q00456E7669726F6E6D656E7444692Q667573655363616C65026Q33D33F03093Q00436C6F636B54696D65026Q661C4003113Q00436F6C6F7253686966745F426F2Q746F6D0097022Q0012053Q00014Q003D000100063Q000E440002000600013Q00044F3Q000600012Q003D000500063Q0012053Q00033Q0026123Q008C0201000300044F3Q008C0201000E44000400330001000100044F3Q00330001001205000700013Q002612000700100001000500044F3Q00100001003035000500060001003035000500070008001205000700023Q0026120007001D0001000100044F3Q001D00012Q001000085Q0010230004000900080012060008000A3Q00201D00080008000B2Q0010000900013Q001205000A000C3Q001205000B000D4Q003C0009000B4Q000C00083Q00022Q0039000500083Q001205000700053Q002612000700210001000E00044F3Q002100010012050001000F3Q00044F3Q00330001000E44000300270001000700044F3Q002700010030350005001000112Q001000085Q0010230005000900080012050007000E3Q0026120007000B0001000200044F3Q000B0001003035000500120013001206000800153Q00201D000800080016001205000900173Q001205000A00173Q001205000B00174Q00220008000B0002001023000500140008001205000700033Q00044F3Q000B00010026120001005A0001000E00044F3Q005A00010030350003001800012Q0010000700013Q0012050008001A3Q0012050009001B4Q00220007000900020010230003001900072Q0010000700013Q0012050008001D3Q0012050009001E4Q00220007000900020010230003001C00072Q0010000700013Q001205000800203Q001205000900214Q00220007000900020010230003001F00072Q0010000700013Q001205000800233Q001205000900244Q00220007000900020010230003002200072Q0010000700013Q001205000800263Q001205000900274Q00220007000900020010230003002500072Q0010000700013Q001205000800293Q0012050009002A4Q00220007000900020010230003002800072Q0010000700013Q0012050008002C3Q0012050009002D4Q00220007000900020010230003002B00070012050001002E3Q002612000100850001000300044F3Q00850001001205000700013Q002612000700690001000300044F3Q006900010012060008000A3Q00201D00080008000B2Q0010000900013Q001205000A002F3Q001205000B00304Q003C0009000B4Q000C00083Q00022Q0039000300083Q0030350003003100110012050007000E3Q0026120007006E0001000500044F3Q006E0001003035000200320033003035000200340035001205000700023Q002612000700740001000200044F3Q007400010030350002001000112Q001000085Q001023000200090008001205000700033Q002612000700780001000E00044F3Q007800010012050001000E3Q00044F3Q008500010026120007005D0001000100044F3Q005D00010012060008000A3Q00201D00080008000B2Q0010000900013Q001205000A00363Q001205000B00374Q003C0009000B4Q000C00083Q00022Q0039000200083Q003035000200380005001205000700053Q00044F3Q005D00010026120001009C0001002E00044F3Q009C000100303500030039003A0030350003003B003C2Q0010000700013Q0012050008003E3Q0012050009003F4Q00220007000900020010230003003D00072Q001000075Q0010230003000900070012060007000A3Q00201D00070007000B2Q0010000800013Q001205000900403Q001205000A00414Q003C0008000A4Q000C00073Q00022Q0039000400073Q003035000400380042003035000400430044003035000400100011001205000100043Q002612000100CC0001000F00044F3Q00CC0001001205000700013Q002612000700B10001000100044F3Q00B100010012060008000A3Q00201D00080008000B2Q0010000900013Q001205000A00453Q001205000B00464Q003C0009000B4Q000C00083Q00022Q0039000600083Q001206000800153Q00201D000800080016001205000900483Q001205000A00493Q001205000B004A4Q00220008000B0002001023000600470008001205000700053Q002612000700B50001000E00044F3Q00B500010012050001004B3Q00044F3Q00CC0001002612000700BB0001000300044F3Q00BB00010030350006004C00012Q001000085Q0010230006000900080012050007000E3Q002612000700C60001000500044F3Q00C60001001206000800153Q00201D0008000800160012050009004E3Q001205000A004F3Q001205000B00504Q00220008000B00020010230006004D0008003035000600510052001205000700023Q0026120007009F0001000200044F3Q009F0001003035000600530001003035000600540001001205000700033Q00044F3Q009F0001000E44000200F90001000100044F3Q00F90001001206000700554Q001000086Q0010000900013Q001205000A00563Q001205000B00574Q00220009000B0002001206000A00583Q00201D000A000A005900201D000A000A005A2Q00500007000A00012Q0010000700023Q001206000800153Q00201D0008000800160012050009005C3Q001205000A005D3Q001205000B004E4Q00220008000B00020010230007005B00082Q0010000700023Q0030350007005E00052Q0010000700023Q0030350007005F00052Q0010000700023Q0030350007006000612Q0010000700023Q003035000700620063001206000700554Q0010000800024Q0010000900013Q001205000A00643Q001205000B00654Q00220009000B00022Q0048000A00014Q00500007000A0001001206000700554Q0010000800024Q0010000900013Q001205000A00663Q001205000B00674Q00220009000B0002001205000A00684Q00500007000A0001001205000100033Q0026120001002D2Q01000500044F3Q002D2Q01001205000700013Q00261200072Q002Q01000E00044F4Q002Q01001205000100023Q00044F3Q002D2Q01000E440001000D2Q01000700044F3Q000D2Q012Q001000085Q001206000900153Q00201D000900090016001205000A00013Q001205000B00013Q001205000C00014Q00220009000C00020010230008006900092Q001000085Q0030350008006A006B001205000700053Q000E440002001A2Q01000700044F3Q001A2Q012Q001000085Q0030350008006C00112Q001000085Q001206000900153Q00201D000900090016001205000A00013Q001205000B00013Q001205000C00014Q00220009000C00020010230008006D0009001205000700033Q000E44000500212Q01000700044F3Q00212Q012Q001000085Q0030350008006E006F2Q001000085Q003035000800700071001205000700023Q000E44000300FC0001000700044F3Q00FC00012Q001000085Q0030350008007200082Q001000086Q0010000900013Q001205000A00743Q001205000B00754Q00220009000B00020010230008007300090012050007000E3Q00044F3Q00FC0001002612000100A12Q01003C00044F3Q00A12Q01001205000700013Q0026120007004B2Q01000100044F3Q004B2Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A0078001206000B00153Q00201D000B000B0016001205000C00793Q001205000D007A3Q001205000E007B4Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A007C001206000B00153Q00201D000B000B0016001205000C007D3Q001205000D007A3Q001205000E007E4Q003C000B000E4Q005100083Q0001001205000700053Q002612000700662Q01000300044F3Q00662Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A007F001206000B00153Q00201D000B000B0016001205000C00803Q001205000D00803Q001205000E00814Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A0082001206000B00153Q00201D000B000B0016001205000C00833Q001205000D00833Q001205000E00834Q003C000B000E4Q005100083Q00010012050007000E3Q0026120007006A2Q01000E00044F3Q006A2Q01001205000100633Q00044F3Q00A12Q01002612000700852Q01000200044F3Q00852Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A0084001206000B00153Q00201D000B000B0016001205000C00853Q001205000D00863Q001205000E00874Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A0088001206000B00153Q00201D000B000B0016001205000C00893Q001205000D008A3Q001205000E008B4Q003C000B000E4Q005100083Q0001001205000700033Q002612000700302Q01000500044F3Q00302Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A008C001206000B00153Q00201D000B000B0016001205000C008D3Q001205000D008E3Q001205000E00804Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A008F001206000B00153Q00201D000B000B0016001205000C00903Q001205000D00913Q001205000E00924Q003C000B000E4Q005100083Q0001001205000700023Q00044F3Q00302Q01002612000100E02Q01006300044F3Q00E02Q012Q0010000700023Q00201F000700070076001206000900583Q00201D00090009007700201D000900090093001206000A00153Q00201D000A000A0016001205000B00943Q001205000C00953Q001205000D005C4Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F000700070076001206000900583Q00201D00090009007700201D000900090096001206000A00153Q00201D000A000A0016001205000B00973Q001205000C00983Q001205000D00994Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F000700070076001206000900583Q00201D00090009007700201D00090009009A001206000A00153Q00201D000A000A0016001205000B008B3Q001205000C009B3Q001205000D009C4Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F000700070076001206000900583Q00201D00090009007700201D00090009009D001206000A00153Q00201D000A000A0016001205000B009E3Q001205000C00483Q001205000D009F4Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F000700070076001206000900583Q00201D00090009007700201D0009000900A0001206000A00153Q00201D000A000A0016001205000B00A13Q001205000C00A23Q001205000D005C4Q003C000A000D4Q005100073Q000100044F3Q00960201002612000100540201004B00044F3Q00540201001205000700013Q002612000700FE2Q01000500044F3Q00FE2Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00A3001206000B00153Q00201D000B000B0016001205000C00A43Q001205000D00A53Q001205000E00A64Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00A7001206000B00153Q00201D000B000B0016001205000C00A83Q001205000D00A93Q001205000E00AA4Q003C000B000E4Q005100083Q0001001205000700023Q002612000700190201000300044F3Q001902012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00AB001206000B00153Q00201D000B000B0016001205000C00AC3Q001205000D00AD3Q001205000E00AE4Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00AF001206000B00153Q00201D000B000B0016001205000C00B03Q001205000D00B03Q001205000E00B14Q003C000B000E4Q005100083Q00010012050007000E3Q002612000700340201000100044F3Q003402012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00B2001206000B00153Q00201D000B000B0016001205000C00A53Q001205000D00A53Q001205000E00A54Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00B3001206000B00153Q00201D000B000B0016001205000C00B43Q001205000D00B43Q001205000E00B44Q003C000B000E4Q005100083Q0001001205000700053Q002612000700380201000E00044F3Q003802010012050001003C3Q00044F3Q00540201002612000700E32Q01000200044F3Q00E32Q012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00B5001206000B00153Q00201D000B000B0016001205000C00953Q001205000D00B63Q001205000E00B74Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F000800080076001206000A00583Q00201D000A000A007700201D000A000A00B8001206000B00153Q00201D000B000B0016001205000C00B93Q001205000D00B73Q001205000E007E4Q003C000B000E4Q005100083Q0001001205000700033Q00044F3Q00E32Q01000E44000100080001000100044F3Q00080001001205000700013Q002612000700640201000100044F3Q006402012Q001000085Q001206000900153Q00201D000900090016001205000A00BB3Q001205000B00BB3Q001205000C00BB4Q00220009000C0002001023000800BA00092Q001000085Q0030350008000600BC001205000700053Q002612000700680201000E00044F3Q00680201001205000100053Q00044F3Q000800010026120007006F0201000300044F3Q006F02012Q001000085Q003035000800BD00BE2Q001000085Q003035000800BF00C00012050007000E3Q0026120007007C0201000200044F3Q007C02012Q001000085Q001206000900153Q00201D000900090016001205000A00173Q001205000B00C23Q001205000C00C34Q00220009000C0002001023000800C100092Q001000085Q003035000800C400C5001205000700033Q002612000700570201000500044F3Q005702012Q001000085Q003035000800C600C72Q001000085Q001206000900153Q00201D000900090016001205000A00013Q001205000B00013Q001205000C00014Q00220009000C0002001023000800C80009001205000700023Q00044F3Q0057020100044F3Q0008000100044F3Q009602010026123Q00910201000100044F3Q00910201001205000100014Q003D000200023Q0012053Q00053Q0026123Q00020001000500044F3Q000200012Q003D000300043Q0012053Q00023Q00044F3Q000200012Q00293Q00017Q00B03Q00028Q00026Q00104003083Q00496E7374616E63652Q033Q006E6577030A3Q00DD7D41A413D82QFA724003073Q009C9F1134D656BE03043Q0053697A65026Q00F03F026Q000840026Q00144003073Q00456E61626C65642Q0103063Q00506172656E74027Q00402Q033Q009DE4A403043Q00DCCE8FDD03143Q0043656C65737469616C426F6469657353686F776E03103Q0057617465725265666C656374616E636503113Q0057617465725472616E73706172656E6379026Q33D33F030D3Q0057617465725761766553697A65026Q33C33F030E3Q0057617465725761766553702Q6564026Q00244003113Q0073657468692Q64656E70726F7065727479030A3Q00A2782E18CACDC68F722303073Q00B2E61D4D77B8AC030B3Q00D2AC0B0864D4F0B00D0F7F03063Q009895DE6A7B17026Q66E63F026Q00204003063Q004F2Q6673657403103Q005365744D6174657269616C436F6C6F7203043Q00456E756D03083Q004D6174657269616C03053Q00427269636B03063Q00436F6C6F723303073Q0066726F6D524742025Q00406140025Q00805540026Q004F40030B3Q00437261636B65644C617661026Q006D40025Q00806340025Q00805240026Q0022402Q033Q00496365025Q00206040025Q00406840026Q006C4003053Q004772612Q73025Q00805A40025Q00C05F40025Q00804F40030F3Q004D2Q6F6E416E67756C617253697A65026Q002640030D3Q004D2Q6F6E54657874757265496403173Q00CF24EE42A6CE23E219FA9235FD5AFAD029F94DFBD736F103053Q00D5BD46962303083Q00536B79626F78426B03253Q005D576C095C46711C151A3B1C4A4D601D5D5067475C5E6D475C5E6D5D1E074B0A441B600D5703043Q00682F351403083Q00536B79626F78446E03253Q00B14E991DAF1CA658DB53F31BA6549509AE0AB0039217A540B0479849ED5D9C488F52A80ABB03063Q006FC32CE17CDC03083Q00536B79626F78467403253Q00CA4418722QB8DD525A3CE4BFDD5E1466B9AECB091378B2E4CB4D1926FAF9E740143DBFAEC003063Q00CBB8266013CB03083Q00536B79626F784C6603253Q002B716140DD2A766D1B8176677C59DA2C617C52812A78600EDD326A2C109C062Q7F0FDA3C6B03053Q00AE59131921026Q00184003073Q00416D6269656E74030A3Q004272696768746E652Q73030E3Q00436F6C6F7253686966745F546F7003173Q00456E7669726F6E6D656E7444692Q667573655363616C6503093Q00436C6F636B54696D6503113Q00436F6C6F7253686966745F426F2Q746F6D03093Q0053616E6473746F6E65025Q00206140025Q00805640025Q00C0514003093Q004C696D6573746F6E65025Q00C06940025Q00A06540025Q0080624003043Q0053616C74025Q00C06840025Q00A06740025Q00A0664003053Q00536C617465025Q00C05A40030A3Q004C656166794772612Q73025Q00C05C40025Q0080604003063Q0047726F756E64025Q00805940026Q005740025Q00804D4003083Q00536B79626F78527403253Q003D104A4FE4940E3B481D01E382133B07404BE4C818240B1D5DFC9E5E7E406D5CE3C91F2A0A03073Q006B4F72322E97E703083Q00536B79626F78557003253Q002BA4AD28992AB2D463E9FA3D8F21A3D52BA3A6669932AE8F2AADAC7CDB6B88D529E8A12C9203083Q00A059C6D549EA59D703093Q0053746172436F756E74025Q0088B340030E3Q0053756E416E67756C617253697A65026Q003540026Q001C40030C3Q0053756E54657874757265496403163Q005A73ACFFD65B74A0A48A0762BFE78A5B64BAB0CF587603053Q00A52811D49E03083Q00436F6E637265746503083Q00506176656D656E74025Q00806140030A3Q00572Q6F64506C616E6B73025Q00606140025Q00405B40025Q00C0534003043Q0053616E64025Q00E06140025Q00805F40025Q00C0574003043Q00536E6F77025Q00606840025Q00E06840025Q00406B4003063Q00426173616C74026Q003E40025Q0080424003183Q00456E7669726F6E6D656E7453706563756C61725363616C6503143Q004578706F73757265436F6D70656E736174696F6E03083Q00466F67436F6C6F7203063Q00466F67456E64025Q00E0854003083Q00466F675374617274024Q00A086EA4003123Q0047656F677261706869634C6174697475646502E7FBA9F1D2DD4440030E3Q00536861646F77536F66746E652Q73029A5Q99C93F03093Q0054696D654F6644617903083Q00B58A526376BF895803053Q004685B96853030D3Q00476C6F62616C536861646F7773030E3Q004F7574642Q6F72416D6269656E74030A3Q0030404722C70B494B2DD003053Q00A96425244A030A3Q00546563686E6F6C6F677903063Q00467574757265030A3Q005761746572436F6C6F72026Q002840026Q005540030B3Q00436F2Q626C6573746F6E65025Q00C05E4003073Q0041737068616C7403073Q00476C6163696572025Q00405940026Q006640025Q00406D402Q033Q004D7564026Q004D40026Q004740026Q00424003043Q00526F636B026Q005B40025Q00C05B4003053Q00476C61726503043Q0048617A65030A3Q002193AF5F1397AA55128203043Q003060E7C203053Q00436F6C6F7203053Q00446563617903073Q0044656E7369747902EC51B81E85EBE13F005E022Q0012053Q00014Q003D000100033Q0026123Q00280001000200044F3Q00280001001205000400013Q002612000400110001000100044F3Q00110001001206000500033Q00201D0005000500042Q001000065Q001205000700053Q001205000800064Q003C000600084Q000C00053Q00022Q0039000100053Q003035000100070001001205000400083Q002612000400150001000900044F3Q001500010012053Q000A3Q00044F3Q002800010026120004001B0001000800044F3Q001B00010030350001000B000C2Q0010000500013Q0010230001000D00050012050004000E3Q002612000400050001000E00044F3Q00050001001206000500033Q00201D0005000500042Q001000065Q0012050007000F3Q001205000800104Q003C000600084Q000C00053Q00022Q0039000200053Q00303500020011000C001205000400093Q00044F3Q000500010026123Q00430001000900044F3Q004300012Q0010000400023Q0030350004001200082Q0010000400023Q0030350004001300142Q0010000400023Q0030350004001500162Q0010000400023Q003035000400170018001206000400194Q0010000500024Q001000065Q0012050007001A3Q0012050008001B4Q00220006000800022Q004800076Q0050000400070001001206000400194Q0010000500024Q001000065Q0012050007001C3Q0012050008001D4Q00220006000800020012050007001E4Q00500004000700010012053Q00023Q0026123Q00870001001F00044F3Q00870001001205000400013Q0026120004004C0001000100044F3Q004C00010030350003002000012Q0010000500013Q0010230003000D0005001205000400083Q002612000400670001000800044F3Q006700012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070024001206000800253Q00201D000800080026001205000900273Q001205000A00283Q001205000B00294Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007002A001206000800253Q00201D0008000800260012050009002B3Q001205000A002C3Q001205000B002D4Q003C0008000B4Q005100053Q00010012050004000E3Q000E440009006B0001000400044F3Q006B00010012053Q002E3Q00044F3Q00870001002612000400460001000E00044F3Q004600012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007002F001206000800253Q00201D000800080026001205000900303Q001205000A00313Q001205000B00324Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070033001206000800253Q00201D000800080026001205000900343Q001205000A00353Q001205000B00364Q003C0008000B4Q005100053Q0001001205000400093Q00044F3Q00460001000E44000A00A400013Q00044F3Q00A400010030350002003700382Q001000045Q0012050005003A3Q0012050006003B4Q00220004000600020010230002003900042Q001000045Q0012050005003D3Q0012050006003E4Q00220004000600020010230002003C00042Q001000045Q001205000500403Q001205000600414Q00220004000600020010230002003F00042Q001000045Q001205000500433Q001205000600444Q00220004000600020010230002004200042Q001000045Q001205000500463Q001205000600474Q00220004000600020010230002004500040012053Q00483Q0026123Q00D30001000100044F3Q00D30001001205000400013Q002612000400B40001000100044F3Q00B400012Q0010000500013Q001206000600253Q00201D000600060026001205000700013Q001205000800013Q001205000900014Q00220006000900020010230005004900062Q0010000500013Q0030350005004A000E001205000400083Q002612000400B80001000900044F3Q00B800010012053Q00083Q00044F3Q00D30001002612000400C50001000E00044F3Q00C500012Q0010000500013Q001206000600253Q00201D000600060026001205000700013Q001205000800013Q001205000900014Q00220006000900020010230005004B00062Q0010000500013Q0030350005004C0001001205000400093Q002612000400A70001000800044F3Q00A700012Q0010000500013Q0030350005004D00092Q0010000500013Q001206000600253Q00201D000600060026001205000700013Q001205000800013Q001205000900014Q00220006000900020010230005004E00060012050004000E3Q00044F3Q00A700010026123Q002C2Q01002E00044F3Q002C2Q01001205000400013Q002612000400F10001000800044F3Q00F100012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007004F001206000800253Q00201D000800080026001205000900503Q001205000A00513Q001205000B00524Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070053001206000800253Q00201D000800080026001205000900543Q001205000A00553Q001205000B00564Q003C0008000B4Q005100053Q00010012050004000E3Q0026120004000C2Q01000E00044F3Q000C2Q012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070057001206000800253Q00201D000800080026001205000900583Q001205000A00593Q001205000B005A4Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007005B001206000800253Q00201D000800080026001205000900363Q001205000A00353Q001205000B005C4Q003C0008000B4Q005100053Q0001001205000400093Q002612000400272Q01000100044F3Q00272Q012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007005D001206000800253Q00201D0008000800260012050009005E3Q001205000A005F3Q001205000B002D4Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070060001206000800253Q00201D000800080026001205000900613Q001205000A00623Q001205000B00634Q003C0008000B4Q005100053Q0001001205000400083Q002612000400D60001000900044F3Q00D600010012053Q00183Q00044F3Q002C2Q0100044F3Q00D600010026123Q00502Q01004800044F3Q00502Q01001205000400013Q0026120004003C2Q01000100044F3Q003C2Q012Q001000055Q001205000600653Q001205000700664Q00220005000700020010230002006400052Q001000055Q001205000600683Q001205000700694Q0022000500070002001023000200670005001205000400083Q002612000400412Q01000800044F3Q00412Q010030350002006A006B0030350002006C006D0012050004000E3Q002612000400452Q01000900044F3Q00452Q010012053Q006E3Q00044F3Q00502Q010026120004002F2Q01000E00044F3Q002F2Q012Q001000055Q001205000600703Q001205000700714Q00220005000700020010230002006F00052Q0010000500013Q0010230002000D0005001205000400093Q00044F3Q002F2Q010026123Q00A92Q01001800044F3Q00A92Q01001205000400013Q0026120004006E2Q01000100044F3Q006E2Q012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070072001206000800253Q00201D000800080026001205000900353Q001205000A00613Q001205000B00364Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070073001206000800253Q00201D000800080026001205000900563Q001205000A00563Q001205000B00744Q003C0008000B4Q005100053Q0001001205000400083Q002612000400722Q01000900044F3Q00722Q010012053Q00383Q00044F3Q00A92Q010026120004008D2Q01000800044F3Q008D2Q012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070075001206000800253Q00201D000800080026001205000900763Q001205000A00773Q001205000B00784Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070079001206000800253Q00201D0008000800260012050009007A3Q001205000A007B3Q001205000B007C4Q003C0008000B4Q005100053Q00010012050004000E3Q002612000400532Q01000E00044F3Q00532Q012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D00070007007D001206000800253Q00201D0008000800260012050009007E3Q001205000A007F3Q001205000B00804Q003C0008000B4Q005100053Q00012Q0010000500023Q00201F000500050021001206000700223Q00201D00070007002300201D000700070081001206000800253Q00201D000800080026001205000900823Q001205000A00823Q001205000B00834Q003C0008000B4Q005100053Q0001001205000400093Q00044F3Q00532Q010026123Q00BE2Q01000800044F3Q00BE2Q012Q0010000400013Q0030350004008400012Q0010000400013Q0030350004008500012Q0010000400013Q001206000500253Q00201D000500050026001205000600013Q001205000700013Q001205000800014Q00220005000800020010230004008600052Q0010000400013Q0030350004008700882Q0010000400013Q00303500040089008A2Q0010000400013Q0030350004008B008C0012053Q000E3Q0026123Q00F32Q01000E00044F3Q00F32Q01001205000400013Q002612000400CC2Q01000800044F3Q00CC2Q012Q0010000500013Q0030350005008D008E2Q0010000500014Q001000065Q001205000700903Q001205000800914Q00220006000800020010230005008F00060012050004000E3Q002612000400D92Q01000100044F3Q00D92Q012Q0010000500013Q00303500050092000C2Q0010000500013Q001206000600253Q00201D000600060026001205000700013Q001205000800013Q001205000900014Q0022000600090002001023000500930006001205000400083Q002612000400DD2Q01000900044F3Q00DD2Q010012053Q00093Q00044F3Q00F32Q01002612000400C12Q01000E00044F3Q00C12Q01001206000500194Q0010000600014Q001000075Q001205000800943Q001205000900954Q0022000700090002001206000800223Q00201D00080008009600201D0008000800972Q00500005000800012Q0010000500023Q001206000600253Q00201D000600060026001205000700993Q0012050008009A3Q001205000900624Q0022000600090002001023000500980006001205000400093Q00044F3Q00C12Q010026123Q00320201003800044F3Q003202012Q0010000400023Q00201F000400040021001206000600223Q00201D00060006002300201D00060006009B001206000700253Q00201D0007000700260012050008005F3Q0012050009009C3Q001205000A00514Q003C0007000A4Q005100043Q00012Q0010000400023Q00201F000400040021001206000600223Q00201D00060006002300201D00060006009D001206000700253Q00201D0007000700260012050008005E3Q0012050009009C3Q001205000A005C4Q003C0007000A4Q005100043Q00012Q0010000400023Q00201F000400040021001206000600223Q00201D00060006002300201D00060006009E001206000700253Q00201D0007000700260012050008009F3Q001205000900A03Q001205000A00A14Q003C0007000A4Q005100043Q00012Q0010000400023Q00201F000400040021001206000600223Q00201D00060006002300201D0006000600A2001206000700253Q00201D000700070026001205000800A33Q001205000900A43Q001205000A00A54Q003C0007000A4Q005100043Q00012Q0010000400023Q00201F000400040021001206000600223Q00201D00060006002300201D0006000600A6001206000700253Q00201D000700070026001205000800613Q001205000900A73Q001205000A00A84Q003C0007000A4Q005100043Q000100044F3Q005D0201000E44006E000200013Q00044F3Q00020001001205000400013Q0026120004003A0201000E00044F3Q003A0201003035000300A90001003035000300AA0001001205000400093Q000E440009003E0201000400044F3Q003E02010012053Q001F3Q00044F3Q00020001002612000400500201000100044F3Q00500201001206000500033Q00201D0005000500042Q001000065Q001205000700AB3Q001205000800AC4Q003C000600084Q000C00053Q00022Q0039000300053Q001206000500253Q00201D000500050026001205000600013Q001205000700013Q001205000800014Q0022000500080002001023000300AD0005001205000400083Q002612000400350201000800044F3Q00350201001206000500253Q00201D000500050026001205000600013Q001205000700013Q001205000800014Q0022000500080002001023000300AE0005003035000300AF00B00012050004000E3Q00044F3Q0035020100044F3Q000200012Q00293Q00017Q00CD3Q00028Q00026Q00F03F026Q00084003093Q00436C6F636B54696D650254742497FFA0314003113Q00436F6C6F7253686966745F426F2Q746F6D03063Q00436F6C6F723303073Q0066726F6D524742027Q004003183Q00456E7669726F6E6D656E7453706563756C61725363616C65030E3Q00436F6C6F7253686966745F546F70025Q00E06940025Q00805C4003173Q00456E7669726F6E6D656E7444692Q667573655363616C65020E2DB29DEFA7E23F03073Q00416D6269656E74030A3Q004272696768746E652Q730285EB51B81E851640026Q00244003103Q005365744D6174657269616C436F6C6F7203043Q00456E756D03083Q004D6174657269616C2Q033Q00496365025Q00206040025Q00406840026Q006C40026Q00264003053Q00536C617465025Q00206840026Q006740025Q00E0644003043Q0053616E64025Q00E06F40025Q00E06D40025Q00206D4003073Q00476C6163696572025Q00606740025Q0020654003053Q00427269636B025Q00406140025Q00805540026Q004F40030A3Q00572Q6F64506C616E6B73025Q00606140025Q00405B40025Q00C0534003043Q00536E6F77025Q00606840025Q00E06840025Q00406B40030E3Q00536861646F77536F66746E652Q73027B14AE47E17AA43F03093Q0054696D654F6644617903083Q002A6BE513E68125F103083Q00C51B5CDF20D1BB1103113Q0073657468692Q64656E70726F7065727479030A3Q00375AC0F30D50CFF4044603043Q009B633FA3030A3Q00546563686E6F6C6F677903093Q00536861646F774D6170030A3Q005761746572436F6C6F7203103Q0057617465725265666C656374616E6365029A5Q99E13F03113Q0057617465725472616E73706172656E6379030D3Q0057617465725761766553697A65026Q00104003093Q0054696E74436F6C6F72026Q00144003083Q00496E7374616E63652Q033Q006E657703153Q00A1DEAD82ABA78DC3B388BA908BDEAFA8BF8287D2B503063Q00E4E2B1C1EDD903083Q00436F6E7472617374026Q33C33F030A3Q0053617475726174696F6E029A5Q99C93F03073Q00456E61626C65642Q0103063Q00506172656E7403093Q004C696D6573746F6E65025Q00C05940025Q00405540025Q0080534003043Q0053616C7403083Q00436F6E6372657465025Q00C05F40025Q00805940025Q00804F4003073Q0041737068616C74025Q00C05C40025Q00C05E40025Q00C05A4003063Q0047726F756E64026Q005740025Q00804D402Q033Q004D7564026Q004D40026Q004740026Q00424003043Q00526F636B026Q005B40025Q00C05B40026Q002840030B3Q00437261636B65644C617661026Q006D40025Q00806340025Q00805240030E3Q004F7574642Q6F72416D6269656E74025Q00405640026Q005140025Q0080474003063Q00466F67456E64025Q0070A74003083Q00466F675374617274025Q00C0724003123Q0047656F677261706869634C61746974756465026688635DDC963540030D3Q00476C6F62616C536861646F777303143Q004578706F73757265436F6D70656E736174696F6E02295C8FC2F528E43F03083Q00466F67436F6C6F72025Q00406240026Q006A402Q033Q0007BB3A03043Q008654D04303143Q0043656C65737469616C426F6469657353686F776E030F3Q004D2Q6F6E416E67756C617253697A65026Q00F83F030D3Q004D2Q6F6E54657874757265496403173Q0001AE9E5D00BF83481AA8DC135CFDD60B46FCDE0B44FAD603043Q003C73CCE603083Q00536B79626F78426B03173Q00F538F371F429EE64EE3EB13FA868BA27B063BD29B36AB803043Q0010875A8B026Q001840026Q001C40030C3Q0053756E54657874757265496403163Q0046761E325D477D402E497C5D5F611B67133D005E685303073Q0018341466532E34030D3Q00F73A2F160EDD3C042209C12C3503053Q006FA44F414403093Q00496E74656E7369747902FCA9F1D24D62703F03063Q0053707265616402C74B37894160C53F026Q002040030A3Q00E7CD8ED13DFACEDC91DB03063Q008AA6B9E3BE4E03053Q00436F6C6F72025Q00A0644003053Q004465636179026Q00304003073Q0044656E73697479020C022B8716D9D63F03053Q00476C61726502E17A14AE47E1CA3F03043Q0048617A65025C8FC2F5285CF73F03063Q004F2Q66736574026Q00224003043Q0053697A65025Q0080564003093Q005468726573686F6C64030E3Q0057617465725761766553702Q6564030A3Q00EF71C63840220DC27BCB03073Q0079AB14A5573243030B3Q00E12AB825AA2EC336BE22B103063Q0062A658D956D9026Q66E63F030B3Q00D4FA760E8BF92QF07C029203063Q00BC2Q961961E603083Q00536B79626F784C6603173Q00C88B47031FFEDF9D560656A295DB0E555BB48CD007515A03063Q008DBAE93F626C03083Q00536B79626F78527403173Q00E3E834B736E2EF38BF21ABA563E474A6BD75E07DA9B87F03053Q0045918A4CD603083Q00536B79626F78446E03173Q0062CD9188AC0575DB808DE5593F9DD8DEE84F279DDDD9E903063Q007610AF2QE9DF03083Q00536B79626F78467403173Q0099862DBAFD98789F8D31E1A1C42FDAD362E2B9DB2FDED503073Q001DEBE455DB8EEB03083Q00536B79626F78557003173Q002FD6A2DC645D224634D0E092381C76056A8DED8C241E7203083Q00325DB4DABD172E4703093Q0053746172436F756E74025Q00407F40030E3Q0053756E416E67756C617253697A65030A3Q004C656166794772612Q73025Q0080604003083Q00506176656D656E74025Q00806240025Q00806140030B3Q00436F2Q626C6573746F6E65025Q00C06040025Q00805D4003093Q0053616E6473746F6E65025Q00406F40025Q00206C4003063Q00426173616C74026Q003E40025Q0080424003053Q004772612Q73025Q00805A400088022Q0012053Q00014Q003D000100063Q0026123Q00070001000100044F3Q00070001001205000100014Q003D000200023Q0012053Q00023Q0026123Q007E0201000300044F3Q007E02010026120001003A0001000100044F3Q003A0001001205000700013Q000E44000200190001000700044F3Q001900012Q001000085Q0030350008000400052Q001000085Q001206000900073Q00201D000900090008001205000A00013Q001205000B00013Q001205000C00014Q00220009000C0002001023000800060009001205000700093Q0026120007001F0001000300044F3Q001F00012Q001000085Q0030350008000A0002001205000100023Q00044F3Q003A00010026120007002C0001000900044F3Q002C00012Q001000085Q001206000900073Q00201D000900090008001205000A000C3Q001205000B000D3Q001205000C00014Q00220009000C00020010230008000B00092Q001000085Q0030350008000E000F001205000700033Q0026120007000C0001000100044F3Q000C00012Q001000085Q001206000900073Q00201D000900090008001205000A00013Q001205000B00013Q001205000C00014Q00220009000C00020010230008001000092Q001000085Q003035000800110012001205000700023Q00044F3Q000C0001000E440013009F0001000100044F3Q009F0001001205000700013Q000E440003004D0001000700044F3Q004D00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A0017001206000B00073Q00201D000B000B0008001205000C00183Q001205000D00193Q001205000E001A4Q003C000B000E4Q005100083Q00010012050001001B3Q00044F3Q009F0001002612000700680001000200044F3Q006800012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A001C001206000B00073Q00201D000B000B0008001205000C001D3Q001205000D001E3Q001205000E001F4Q003C000B000E4Q005100083Q00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A0020001206000B00073Q00201D000B000B0008001205000C00213Q001205000D00223Q001205000E00234Q003C000B000E4Q005100083Q0001001205000700093Q000E44000900830001000700044F3Q008300012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A0024001206000B00073Q00201D000B000B0008001205000C000C3Q001205000D00253Q001205000E00264Q003C000B000E4Q005100083Q00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A0027001206000B00073Q00201D000B000B0008001205000C00283Q001205000D00293Q001205000E002A4Q003C000B000E4Q005100083Q0001001205000700033Q0026120007003D0001000100044F3Q003D00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A002B001206000B00073Q00201D000B000B0008001205000C002C3Q001205000D002D3Q001205000E002E4Q003C000B000E4Q005100083Q00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A002F001206000B00073Q00201D000B000B0008001205000C00303Q001205000D00313Q001205000E00324Q003C000B000E4Q005100083Q0001001205000700023Q00044F3Q003D0001002612000100C20001000900044F3Q00C200012Q001000075Q0030350007003300342Q001000076Q0010000800023Q001205000900363Q001205000A00374Q00220008000A0002001023000700350008001206000700384Q001000086Q0010000900023Q001205000A00393Q001205000B003A4Q00220009000B0002001206000A00153Q00201D000A000A003B00201D000A000A003C2Q00500007000A00012Q0010000700013Q001206000800073Q00201D000800080008001205000900013Q001205000A00013Q001205000B00014Q00220008000B00020010230007003D00082Q0010000700013Q0030350007003E003F2Q0010000700013Q0030350007004000012Q0010000700013Q003035000700410001001205000100033Q002612000100E80001004200044F3Q00E80001001205000700013Q000E44000300D00001000700044F3Q00D00001001206000800073Q00201D000800080008001205000900213Q001205000A00213Q001205000B00214Q00220008000B0002001023000300430008001205000100443Q00044F3Q00E80001002612000700DC0001000200044F3Q00DC0001001206000800453Q00201D0008000800462Q0010000900023Q001205000A00473Q001205000B00484Q003C0009000B4Q000C00083Q00022Q0039000300083Q003035000300110034001205000700093Q002612000700E10001000900044F3Q00E1000100303500030049004A0030350003004B004C001205000700033Q002612000700C50001000100044F3Q00C500010030350002004D004E2Q001000085Q0010230002004F0008001205000700023Q00044F3Q00C500010026120001003F2Q01001B00044F3Q003F2Q012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090050001206000A00073Q00201D000A000A0008001205000B00513Q001205000C00523Q001205000D00534Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090054001206000A00073Q00201D000A000A0008001205000B001D3Q001205000C001E3Q001205000D001F4Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090055001206000A00073Q00201D000A000A0008001205000B00563Q001205000C00573Q001205000D00584Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090059001206000A00073Q00201D000A000A0008001205000B005A3Q001205000C005B3Q001205000D005C4Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D00090009005D001206000A00073Q00201D000A000A0008001205000B00573Q001205000C005E3Q001205000D005F4Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090060001206000A00073Q00201D000A000A0008001205000B00613Q001205000C00623Q001205000D00634Q003C000A000D4Q005100073Q00012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090064001206000A00073Q00201D000A000A0008001205000B00573Q001205000C00653Q001205000D00664Q003C000A000D4Q005100073Q0001001205000100673Q0026120001004E2Q01006700044F3Q004E2Q012Q0010000700013Q00201F000700070014001206000900153Q00201D00090009001600201D000900090068001206000A00073Q00201D000A000A0008001205000B00693Q001205000C006A3Q001205000D006B4Q003C000A000D4Q005100073Q000100044F3Q00870201002612000100792Q01000200044F3Q00792Q01001205000700013Q0026120007005D2Q01000300044F3Q005D2Q012Q001000085Q001206000900073Q00201D000900090008001205000A006D3Q001205000B006E3Q001205000C006F4Q00220009000C00020010230008006C0009001205000100093Q00044F3Q00792Q01002612000700642Q01000200044F3Q00642Q012Q001000085Q0030350008007000712Q001000085Q003035000800720073001205000700093Q000E440009006B2Q01000700044F3Q006B2Q012Q001000085Q0030350008007400752Q001000085Q00303500080076004E001205000700033Q002612000700512Q01000100044F3Q00512Q012Q001000085Q0030350008007700782Q001000085Q001206000900073Q00201D000900090008001205000A007A3Q001205000B007B3Q001205000C00214Q00220009000C0002001023000800790009001205000700023Q00044F3Q00512Q01002612000100932Q01004400044F3Q00932Q010030350003004D004E2Q001000075Q0010230003004F0007001206000700453Q00201D0007000700462Q0010000800023Q0012050009007C3Q001205000A007D4Q003C0008000A4Q000C00073Q00022Q0039000400073Q0030350004007E004E0030350004007F00802Q0010000700023Q001205000800823Q001205000900834Q00220007000900020010230004008100072Q0010000700023Q001205000800853Q001205000900864Q0022000700090002001023000400840007001205000100873Q002612000100AA2Q01008800044F3Q00AA2Q012Q0010000700023Q0012050008008A3Q0012050009008B4Q00220007000900020010230004008900072Q001000075Q0010230004004F0007001206000700453Q00201D0007000700462Q0010000800023Q0012050009008C3Q001205000A008D4Q003C0008000A4Q000C00073Q00022Q0039000500073Q0030350005008E008F0030350005009000910030350005004D004E2Q001000075Q0010230005004F0007001205000100923Q002612000100C72Q01009200044F3Q00C72Q01001206000700453Q00201D0007000700462Q0010000800023Q001205000900933Q001205000A00944Q003C0008000A4Q000C00073Q00022Q0039000600073Q001206000700073Q00201D000700070008001205000800963Q001205000900963Q001205000A00964Q00220007000A0002001023000600950007001206000700073Q00201D000700070008001205000800983Q001205000900983Q001205000A00984Q00220007000A000200102300060097000700303500060099009A0030350006009B009C0030350006009D009E0030350006009F0001001205000100A03Q002612000100F52Q01000300044F3Q00F52Q01001205000700013Q000E44000900CF2Q01000700044F3Q00CF2Q010030350002008E0002003035000200A100A2001205000700033Q002612000700D42Q01000300044F3Q00D42Q01003035000200A30009001205000100423Q00044F3Q00F52Q01002612000700E12Q01000100044F3Q00E12Q012Q0010000800013Q003035000800A40013001206000800384Q0010000900014Q0010000A00023Q001205000B00A53Q001205000C00A64Q0022000A000C00022Q0048000B00014Q00500008000B0001001205000700023Q002612000700CA2Q01000200044F3Q00CA2Q01001206000800384Q0010000900014Q0010000A00023Q001205000B00A73Q001205000C00A84Q0022000A000C0002001205000B00A94Q00500008000B0001001206000800453Q00201D0008000800462Q0010000900023Q001205000A00AA3Q001205000B00AB4Q003C0009000B4Q000C00083Q00022Q0039000200083Q001205000700093Q00044F3Q00CA2Q01002612000100210201008700044F3Q00210201001205000700013Q002612000700050201000200044F3Q000502012Q0010000800023Q001205000900AD3Q001205000A00AE4Q00220008000A0002001023000400AC00082Q0010000800023Q001205000900B03Q001205000A00B14Q00220008000A0002001023000400AF0008001205000700093Q002612000700120201000100044F3Q001202012Q0010000800023Q001205000900B33Q001205000A00B44Q00220008000A0002001023000400B200082Q0010000800023Q001205000900B63Q001205000A00B74Q00220008000A0002001023000400B50008001205000700023Q0026120007001B0201000900044F3Q001B02012Q0010000800023Q001205000900B93Q001205000A00BA4Q00220008000A0002001023000400B80008003035000400BB00BC001205000700033Q000E44000300F82Q01000700044F3Q00F82Q01003035000400BD0003001205000100883Q00044F3Q0021020100044F3Q00F82Q0100261200010009000100A000044F3Q00090001001205000700013Q002612000700350201000100044F3Q003502012Q001000085Q0010230006004F00082Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00BE001206000B00073Q00201D000B000B0008001205000C005A3Q001205000D00BF3Q001205000E006B4Q003C000B000E4Q005100083Q0001001205000700023Q002612000700450201000300044F3Q004502012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00C0001206000B00073Q00201D000B000B0008001205000C00C13Q001205000D00C13Q001205000E00C24Q003C000B000E4Q005100083Q0001001205000100133Q00044F3Q00090001002612000700600201000900044F3Q006002012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00C3001206000B00073Q00201D000B000B0008001205000C00C43Q001205000D00C43Q001205000E00C54Q003C000B000E4Q005100083Q00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00C6001206000B00073Q00201D000B000B0008001205000C00213Q001205000D00C73Q001205000E00C84Q003C000B000E4Q005100083Q0001001205000700033Q000E44000200240201000700044F3Q002402012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00C9001206000B00073Q00201D000B000B0008001205000C00CA3Q001205000D00CA3Q001205000E00CB4Q003C000B000E4Q005100083Q00012Q0010000800013Q00201F000800080014001206000A00153Q00201D000A000A001600201D000A000A00CC001206000B00073Q00201D000B000B0008001205000C00CD3Q001205000D00563Q001205000E00584Q003C000B000E4Q005100083Q0001001205000700093Q00044F3Q0024020100044F3Q0009000100044F3Q008702010026123Q00820201000200044F3Q008202012Q003D000300043Q0012053Q00093Q0026123Q00020001000900044F3Q000200012Q003D000500063Q0012053Q00033Q00044F3Q000200012Q00293Q00017Q00D53Q00028Q00026Q00224003063Q00506172656E7403083Q00496E7374616E63652Q033Q006E6577030A3Q001E49C9A6DF7B0B3946C803073Q006D5C25BCD49A1D03043Q0053697A65026Q00104003073Q00456E61626C6564010003103Q005365744D6174657269616C436F6C6F7203043Q00456E756D03083Q004D6174657269616C03043Q00536E6F7703063Q00436F6C6F723303073Q0066726F6D524742025Q00606D40025Q00A06F40025Q00E06F4003063Q00426173616C74025Q00C05240025Q00805240026Q002440026Q00284003093Q0053616E6473746F6E65025Q00806240026Q005F40025Q00C0574003043Q0053616E64025Q00E06940025Q00606940025Q00E06440030A3Q00572Q6F64506C616E6B73025Q00806540026Q005B40030B3Q00437261636B65644C617661026Q003840025Q00C0504003083Q00436F6E6372657465026Q006340026Q002640027Q004003093Q004C696D6573746F6E65025Q00606E40026Q0068402Q033Q004D7564025Q00405E40026Q005C40025Q00805840026Q0008402Q033Q00496365025Q00806940025Q00406A40025Q00E06B4003043Q0053616C74025Q00C06F40026Q00F03F03053Q00427269636B025Q00406140025Q00405840025Q0040524003083Q00506176656D656E74025Q00E06140026Q006240025Q00E0604003073Q0041737068616C74026Q005440026Q005540030E3Q0057617465725761766553702Q6564026Q00184003113Q0073657468692Q64656E70726F7065727479030A3Q0020EAA7CC235B10E6ABCD03063Q003A648FC4A351030B3Q003D5022B02C65E0001D562B03083Q006E7A2243C35F2985026Q00E03F030D3Q0046A45578D76CA27E4CD070B24F03053Q00B615D13B2A03093Q00496E74656E7369747902FA7E6ABC7493983F03063Q00537072656164026F1283C0CAA1DD3F2Q0103143Q004578706F73757265436F6D70656E736174696F6E029A5Q99C9BF03083Q00466F67436F6C6F7203063Q00466F67456E64025Q006AF84003083Q00466F67537461727403123Q0047656F677261706869634C61746974756465030D3Q00476C6F62616C536861646F7773030E3Q004F7574642Q6F72416D6269656E74026Q004240025Q00804740026Q004D40030D3Q0057617465725761766553697A65029A5Q99C93F030A3Q008352C6152FB1BB58C20403063Q00DED737A57D41030A3Q00546563686E6F6C6F677903093Q00536861646F774D6170030A3Q005761746572436F6C6F72025Q00405540030E3Q00536861646F77536F66746E652Q73026Q00D03F03093Q0054696D654F6644617903093Q0061819040A092B71F7503083Q002A4CB1A67A92A18D03103Q0057617465725265666C656374616E636503113Q0057617465725472616E73706172656E637903083Q00536B79626F78426B031B3Q00B7881DCF6A65A09E0CCA2339EAD25D9B2123F6DD55972E25F6D35D03063Q0016C5EA65AE1903083Q00536B79626F78446E031C3Q003F36BDDD65BCD2922430FF9339FE85DE7D65F18925FA85D67861F78503083Q00E64D54C5BC16CFB7030F3Q004D2Q6F6E416E67756C617253697A65030D3Q004D2Q6F6E54657874757265496403173Q00EB16DEFD9FB2F521A35B89EF87B8BF38F61BC8B286B1F703083Q00559974A69CECC19003083Q00536B79626F784674031B3Q00B6E255B2F713A1F444B7BE4FEBB818E0B653F2B118E3B052F6B41903063Q0060C4802DD384026Q001C402Q033Q0006866203083Q00B855ED1B3FB2CFD403143Q0043656C65737469616C426F6469657353686F776E03093Q00436C6F636B54696D65027E3A1E33509919C003113Q00436F6C6F7253686966745F426F2Q746F6D026Q006F40025Q00A06440025Q00E0634003073Q00416D6269656E74025Q00405B40025Q00405D40030A3Q004272696768746E652Q730223DBF97E6ABCFE3F030E3Q00436F6C6F7253686966745F546F70025Q00406C4003173Q00456E7669726F6E6D656E7444692Q667573655363616C65026ABC74931804C63F03183Q00456E7669726F6E6D656E7453706563756C61725363616C6502D122DBF97E6AE43F026Q00144003083Q00436F6E7472617374030A3Q0053617475726174696F6E03093Q0054696E74436F6C6F7203153Q002B5605501A7A064D1A5C0A4B0156077A0E5F0C5C1C03043Q003F68396903093Q005468726573686F6C6402F8C264AA60540240026Q004940030B3Q00298BAB4B062QA2420E84B003043Q00246BE7C4026Q00204003053Q00476C61726502C3F5285C8FC2074003043Q0048617A650252B81E85EB51F83F03053Q004465636179025Q00C05E40025Q00E06240025Q00C0664003073Q0044656E736974790260E5D022DBF9D63F03063Q004F2Q66736574030A3Q007CA1AF884EA5AA824FB003043Q00E73DD5C203053Q00436F6C6F72026Q006B40025Q0040684003073Q00476C6163696572025Q00A06B40025Q00806C40025Q00A06C40030B3Q00436F2Q626C6573746F6E65025Q00C06040025Q00805D4003063Q0047726F756E64025Q00806140025Q00406040026Q005A4003043Q00526F636B025Q00C05840026Q005940025Q0080594003053Q004772612Q73025Q00A06540025Q0060664003053Q00536C617465026Q005640025Q00405640025Q00805540030A3Q004C656166794772612Q73025Q00805A40026Q00504003083Q00536B79626F784C66031B3Q001BAF25721ABE386700A9673C46FA6A2758F86A2A5EF9682350FC6E03043Q001369CD5D03083Q00536B79626F785274031C3Q00BB0AC6802CBA0DCA883BF34791D06DFE5D88D766FA5988D16DFA5F8F03053Q005FC968BEE103083Q00536B79626F785570031C3Q00BDC9D9CFBCD8C4DAA6CF9B81E09A919CFC999197F79A9197F79B979E03043Q00AECFABA103093Q0053746172436F756E74025Q0088B340030E3Q0053756E416E67756C617253697A65030C3Q0053756E54657874757265496403163Q00FFFC15F2EBC4E8EA57BCB7C4E6E742E0EDD9A3F41DF403063Q00B78D9E6D93980091022Q0012053Q00014Q003D000100063Q0026123Q002B0001000200044F3Q002B00012Q001000075Q001023000500030007001206000700043Q00201D0007000700052Q0010000800013Q001205000900063Q001205000A00074Q003C0008000A4Q000C00073Q00022Q0039000600073Q0030350006000800090030350006000A000B2Q001000075Q0010230006000300072Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D00090009000F001206000A00103Q00201D000A000A0011001205000B00123Q001205000C00133Q001205000D00144Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D000900090015001206000A00103Q00201D000A000A0011001205000B00163Q001205000C00173Q001205000D00174Q003C000A000D4Q005100073Q00010012053Q00183Q0026123Q006A0001001900044F3Q006A00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D00090009001A001206000A00103Q00201D000A000A0011001205000B001B3Q001205000C001C3Q001205000D001D4Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D00090009001E001206000A00103Q00201D000A000A0011001205000B001F3Q001205000C00203Q001205000D00214Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D000900090022001206000A00103Q00201D000A000A0011001205000B00233Q001205000C001B3Q001205000D00244Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D000900090025001206000A00103Q00201D000A000A0011001205000B00143Q001205000C00263Q001205000D00274Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D000900090028001206000A00103Q00201D000A000A0011001205000B00293Q001205000C00293Q001205000D00294Q003C000A000D4Q005100073Q000100044F3Q00900201000E44002A00CF00013Q00044F3Q00CF0001001205000700013Q000E44002B00880001000700044F3Q008800012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A002C001206000B00103Q00201D000B000B0011001205000C00143Q001205000D002D3Q001205000E002E4Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A002F001206000B00103Q00201D000B000B0011001205000C00303Q001205000D00313Q001205000E00324Q003C000B000E4Q005100083Q0001001205000700333Q002612000700A30001000100044F3Q00A300012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A0034001206000B00103Q00201D000B000B0011001205000C00353Q001205000D00363Q001205000E00374Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A0038001206000B00103Q00201D000B000B0011001205000C00143Q001205000D00143Q001205000E00394Q003C000B000E4Q005100083Q00010012050007003A3Q002612000700B30001003300044F3Q00B300012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A003B001206000B00103Q00201D000B000B0011001205000C003C3Q001205000D003D3Q001205000E003E4Q003C000B000E4Q005100083Q00010012053Q00193Q00044F3Q00CF0001000E44003A006D0001000700044F3Q006D00012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A003F001206000B00103Q00201D000B000B0011001205000C00403Q001205000D00413Q001205000E00424Q003C000B000E4Q005100083Q00012Q0010000800023Q00201F00080008000C001206000A000D3Q00201D000A000A000E00201D000A000A0043001206000B00103Q00201D000B000B0011001205000C00443Q001205000D00453Q001205000E00454Q003C000B000E4Q005100083Q00010012050007002B3Q00044F3Q006D0001000E44003300EF00013Q00044F3Q00EF00012Q0010000700023Q003035000700460047001206000700484Q0010000800024Q0010000900013Q001205000A00493Q001205000B004A4Q00220009000B00022Q0048000A00014Q00500007000A0001001206000700484Q0010000800024Q0010000900013Q001205000A004B3Q001205000B004C4Q00220009000B0002001205000A004D4Q00500007000A0001001206000700043Q00201D0007000700052Q0010000800013Q0012050009004E3Q001205000A004F4Q003C0008000A4Q000C00073Q00022Q0039000100073Q0030350001005000510030350001005200530030350001000A00540012053Q00093Q0026123Q000C2Q01003A00044F3Q000C2Q012Q001000075Q0030350007005500562Q001000075Q001206000800103Q00201D0008000800110012050009002E3Q001205000A002E3Q001205000B002E4Q00220008000B00020010230007005700082Q001000075Q0030350007005800592Q001000075Q0030350007005A00012Q001000075Q0030350007005B00012Q001000075Q0030350007005C00542Q001000075Q001206000800103Q00201D0008000800110012050009005E3Q001205000A005F3Q001205000B00604Q00220008000B00020010230007005D00080012053Q002B3Q0026123Q003D2Q01002B00044F3Q003D2Q01001205000700013Q000E44003300152Q01000700044F3Q00152Q012Q0010000800023Q0030350008006100620012053Q00333Q00044F3Q003D2Q010026120007002A2Q01003A00044F3Q002A2Q01001206000800484Q001000096Q0010000A00013Q001205000B00633Q001205000C00644Q0022000A000C0002001206000B000D3Q00201D000B000B006500201D000B000B00662Q00500008000B00012Q0010000800023Q001206000900103Q00201D000900090011001205000A00603Q001205000B00173Q001205000C00684Q00220009000C00020010230008006700090012050007002B3Q002612000700352Q01000100044F3Q00352Q012Q001000085Q00303500080069006A2Q001000086Q0010000900013Q001205000A006C3Q001205000B006D4Q00220009000B00020010230008006B00090012050007003A3Q0026120007000F2Q01002B00044F3Q000F2Q012Q0010000800023Q0030350008006E003A2Q0010000800023Q0030350008006F003A001205000700333Q00044F3Q000F2Q010026123Q006C2Q01004700044F3Q006C2Q01001205000700013Q0026120007004D2Q01002B00044F3Q004D2Q012Q0010000800013Q001205000900713Q001205000A00724Q00220008000A00020010230004007000082Q0010000800013Q001205000900743Q001205000A00754Q00220008000A0002001023000400730008001205000700333Q002612000700562Q01003A00044F3Q00562Q010030350004007600012Q0010000800013Q001205000900783Q001205000A00794Q00220008000A00020010230004007700080012050007002B3Q0026120007005F2Q01003300044F3Q005F2Q012Q0010000800013Q0012050009007B3Q001205000A007C4Q00220008000A00020010230004007A00080012053Q007D3Q00044F3Q006C2Q01002612000700402Q01000100044F3Q00402Q01001206000800043Q00201D0008000800052Q0010000900013Q001205000A007E3Q001205000B007F4Q003C0009000B4Q000C00083Q00022Q0039000400083Q0030350004008000540012050007003A3Q00044F3Q00402Q010026123Q009D2Q01000100044F3Q009D2Q01001205000700013Q0026120007007C2Q01003A00044F3Q007C2Q012Q001000085Q0030350008008100822Q001000085Q001206000900103Q00201D000900090011001205000A00843Q001205000B00853Q001205000C00864Q00220009000C00020010230008008300090012050007002B3Q002612000700892Q01000100044F3Q00892Q012Q001000085Q001206000900103Q00201D000900090011001205000A00883Q001205000B00893Q001205000C00424Q00220009000C00020010230008008700092Q001000085Q0030350008008A008B0012050007003A3Q002612000700962Q01002B00044F3Q00962Q012Q001000085Q001206000900103Q00201D000900090011001205000A008D3Q001205000B00163Q001205000C00014Q00220009000C00020010230008008C00092Q001000085Q0030350008008E008F001205000700333Q000E440033006F2Q01000700044F3Q006F2Q012Q001000085Q0030350008009000910012053Q003A3Q00044F3Q009D2Q0100044F3Q006F2Q010026123Q00C32Q01009200044F3Q00C32Q01001205000700013Q000E44003A00A52Q01000700044F3Q00A52Q010030350003009300620030350003009400010012050007002B3Q000E44002B00B02Q01000700044F3Q00B02Q01001206000800103Q00201D000800080011001205000900143Q001205000A00143Q001205000B00144Q00220008000B00020010230003009500080030350003000A0054001205000700333Q002612000700BC2Q01000100044F3Q00BC2Q01001206000800043Q00201D0008000800052Q0010000900013Q001205000A00963Q001205000B00974Q003C0009000B4Q000C00083Q00022Q0039000300083Q0030350003008A00010012050007003A3Q002612000700A02Q01003300044F3Q00A02Q012Q001000085Q0010230003000300080012053Q00473Q00044F3Q00C32Q0100044F3Q00A02Q010026123Q00E42Q01000900044F3Q00E42Q01001205000700013Q002612000700CB2Q01002B00044F3Q00CB2Q010030350002009800990030350002000A0054001205000700333Q002612000700D12Q01003300044F3Q00D12Q012Q001000085Q0010230002000300080012053Q00923Q00044F3Q00E42Q01002612000700D62Q01003A00044F3Q00D62Q0100303500020050003A00303500020008009A0012050007002B3Q002612000700C62Q01000100044F3Q00C62Q012Q001000085Q001023000100030008001206000800043Q00201D0008000800052Q0010000900013Q001205000A009B3Q001205000B009C4Q003C0009000B4Q000C00083Q00022Q0039000200083Q0012050007003A3Q00044F3Q00C62Q010026123Q000F0201009D00044F3Q000F0201001205000700013Q002612000700EC2Q01002B00044F3Q00EC2Q010030350005009E009F003035000500A000A1001205000700333Q000E44003A00F72Q01000700044F3Q00F72Q01001206000800103Q00201D000800080011001205000900A33Q001205000A00A43Q001205000B00A54Q00220008000B0002001023000500A20008003035000500A600A70012050007002B3Q002612000700FC2Q01003300044F3Q00FC2Q01003035000500A800010012053Q00023Q00044F3Q000F0201002612000700E72Q01000100044F3Q00E72Q01001206000800043Q00201D0008000800052Q0010000900013Q001205000A00A93Q001205000B00AA4Q003C0009000B4Q000C00083Q00022Q0039000500083Q001206000800103Q00201D000800080011001205000900143Q001205000A00AC3Q001205000B00AD4Q00220008000B0002001023000500AB00080012050007003A3Q00044F3Q00E72Q01000E440018006602013Q00044F3Q006602012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900AE001206000A00103Q00201D000A000A0011001205000B00AF3Q001205000C00B03Q001205000D00B14Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900B2001206000A00103Q00201D000A000A0011001205000B00B33Q001205000C00B33Q001205000D00B44Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900B5001206000A00103Q00201D000A000A0011001205000B00B63Q001205000C00B73Q001205000D00B84Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900B9001206000A00103Q00201D000A000A0011001205000B00BA3Q001205000C00BB3Q001205000D00BC4Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900BD001206000A00103Q00201D000A000A0011001205000B00BE3Q001205000C00BF3Q001205000D00204Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900C0001206000A00103Q00201D000A000A0011001205000B00C13Q001205000C00C23Q001205000D00C34Q003C000A000D4Q005100073Q00012Q0010000700023Q00201F00070007000C0012060009000D3Q00201D00090009000E00201D0009000900C4001206000A00103Q00201D000A000A0011001205000B00C53Q001205000C00B33Q001205000D00C64Q003C000A000D4Q005100073Q00010012053Q002A3Q0026123Q00020001007D00044F3Q00020001001205000700013Q000E44000100760201000700044F3Q007602012Q0010000800013Q001205000900C83Q001205000A00C94Q00220008000A0002001023000400C700082Q0010000800013Q001205000900CB3Q001205000A00CC4Q00220008000A0002001023000400CA00080012050007003A3Q000E44003A007F0201000700044F3Q007F02012Q0010000800013Q001205000900CE3Q001205000A00CF4Q00220008000A0002001023000400CD0008003035000400D000D10012050007002B3Q000E44003300850201000700044F3Q008502012Q001000085Q0010230004000300080012053Q009D3Q00044F3Q00020001002612000700690201002B00044F3Q00690201003035000400D200092Q0010000800013Q001205000900D43Q001205000A00D54Q00220008000A0002001023000400D30008001205000700333Q00044F3Q0069020100044F3Q000200012Q00293Q00017Q00",v17(),...);
]=]

SimpleShader = {
    enabled = false,
    runningThread = nil,
    cleanupConn = nil,
    watchdogConn = nil,
    lightingBackup = {props={}, children={}},
    terrainBackup = {},
    guiNamesBefore = {},
    status = "Tắt",
    generation = 0,
    retryCount = 0,
    sourceStarted = false,
    fallbackApplied = false,
}

SIMPLE_LIGHTING_PROPS = {
    "Ambient", "Brightness", "ClockTime", "ColorShift_Bottom", "ColorShift_Top",
    "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation",
    "FogColor", "FogEnd", "FogStart", "GeographicLatitude", "GlobalShadows",
    "OutdoorAmbient", "ShadowSoftness", "Technology",
}

SIMPLE_EFFECT_CLASSES = {
    Sky=true, Atmosphere=true, BloomEffect=true, ColorCorrectionEffect=true,
    SunRaysEffect=true, DepthOfFieldEffect=true, BlurEffect=true,
}

function rememberShaderGuis()
    SimpleShader.guiNamesBefore = {}
    local roots = {}
    pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
    pcall(function() table.insert(roots, GUI_PARENT) end)
    pcall(function() table.insert(roots, LP:FindFirstChildOfClass("PlayerGui")) end)
    for _, root in ipairs(roots) do
        if root then
            pcall(function()
                for _, x in ipairs(root:GetDescendants()) do
                    if x:IsA("ScreenGui") then
                        SimpleShader.guiNamesBefore[x] = true
                    end
                end
            end)
        end
    end
end

function captureSimpleShaderState()
    SimpleShader.lightingBackup = {props={}, children={}}
    for _, prop in ipairs(SIMPLE_LIGHTING_PROPS) do
        pcall(function() SimpleShader.lightingBackup.props[prop] = LT[prop] end)
    end
    for _, child in ipairs(LT:GetChildren()) do
        if SIMPLE_EFFECT_CLASSES[child.ClassName] then
            local ok, clone = pcall(function() return child:Clone() end)
            if ok and clone then
                table.insert(SimpleShader.lightingBackup.children, clone)
            end
        end
    end

    SimpleShader.terrainBackup = {}
    local terrain = WS:FindFirstChildOfClass("Terrain")
    if terrain then
        for _, mat in ipairs(Enum.Material:GetEnumItems()) do
            pcall(function()
                SimpleShader.terrainBackup[mat] = terrain:GetMaterialColor(mat)
            end)
        end
    end
    rememberShaderGuis()
end

function destroyNewShaderChildren()
    -- Remove only clearly script-owned effects. Never delete unrelated game/effect instances.
    for _, child in ipairs(LT:GetChildren()) do
        local n=string.lower(child.Name)
        if SIMPLE_EFFECT_CLASSES[child.ClassName] and (n:find("dungdxsimpleshaderfallback",1,true) or n:find("dungdx_shader",1,true) or n:find("dungdxsimple",1,true)) then
            pcall(function() child:Destroy() end)
        end
    end
end

function restoreSimpleShaderState()
    -- Stop the loader thread when possible.
    if SimpleShader.runningThread then
        pcall(function()
            if task.cancel then task.cancel(SimpleShader.runningThread) end
        end)
        SimpleShader.runningThread = nil
    end
    if SimpleShader.cleanupConn then
        pcall(function() SimpleShader.cleanupConn:Disconnect() end)
        SimpleShader.cleanupConn = nil
    end

    destroyNewShaderChildren()

    -- Restore Lighting service properties.
    for prop, value in pairs(SimpleShader.lightingBackup.props or {}) do
        pcall(function() LT[prop] = value end)
    end

    -- Re-add only original effects that disappeared. Keep unrelated effects created later.
    for _, clone in ipairs(SimpleShader.lightingBackup.children or {}) do
        local found=false
        for _, child in ipairs(LT:GetChildren()) do
            if child.ClassName==clone.ClassName and child.Name==clone.Name then found=true; break end
        end
        if not found then pcall(function() clone.Parent=LT end) else pcall(function() clone:Destroy() end) end
    end

    -- Restore Terrain material colors touched by the shader.
    local terrain = WS:FindFirstChildOfClass("Terrain")
    if terrain then
        for mat, value in pairs(SimpleShader.terrainBackup or {}) do
            pcall(function() terrain:SetMaterialColor(mat, value) end)
        end
    end

    -- Remove newly-created shader UI if it used an identifiable name.
    local roots = {}
    pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
    pcall(function() table.insert(roots, GUI_PARENT) end)
    pcall(function() table.insert(roots, LP:FindFirstChildOfClass("PlayerGui")) end)
    for _, root in ipairs(roots) do
        if root then
            pcall(function()
                for _, x in ipairs(root:GetDescendants()) do
                    if x:IsA("ScreenGui") and not SimpleShader.guiNamesBefore[x] then
                        local n = x.Name:lower()
                        if n:find("shader") or n:find("simpleshader") then
                            x:Destroy()
                        end
                    end
                end
            end)
        end
    end
    SimpleShader.status = "Tắt"
end

local function shaderGuiExists()
    local roots={}
    pcall(function() table.insert(roots,game:GetService("CoreGui")) end)
    pcall(function() if GUI_PARENT then table.insert(roots,GUI_PARENT) end end)
    pcall(function() local pg=LP:FindFirstChildOfClass("PlayerGui"); if pg then table.insert(roots,pg) end end)
    for _,root in ipairs(roots) do
        local found=false
        pcall(function()
            for _,sg in ipairs(root:GetDescendants()) do
                if sg:IsA("ScreenGui") then
                    for _,d in ipairs(sg:GetDescendants()) do
                        if d:IsA("TextLabel") and tostring(d.Text):find("Simple Shader",1,true) then found=true; break end
                    end
                end
                if found then break end
            end
        end)
        if found then return true end
    end
    return false
end

local function ensureShaderCompatibility()
    local env=nil
    pcall(function() if getfenv then env=getfenv() end end)
    env=env or _G
    if env and not env.bit32 then env.bit32={} end
    if env and env.bit32 and type(env.bit32.bxor)~="function" then
        env.bit32.bxor=function(a,b)
            a=math.floor(tonumber(a) or 0); b=math.floor(tonumber(b) or 0)
            local r,bit=0,1
            while a>0 or b>0 do
                local aa,bb=a%2,b%2
                if aa~=bb then r=r+bit end
                a=math.floor(a/2); b=math.floor(b/2); bit=bit*2
            end
            return r
        end
    end
end

local function launchSimpleShaderSource()
    ensureShaderCompatibility()
    local loadOk,fn=pcall(function()
        if type(loadstring)~="function" then error("Executor thiếu loadstring") end
        return loadstring(SIMPLE_SHADER_SOURCE,"@Dungdx_SimpleShader")
    end)
    if not loadOk or type(fn)~="function" then return false,tostring(fn) end
    local ok,err=pcall(fn)
    if not ok then return false,tostring(err) end
    return true
end

-- Fallback shader built from native Lighting effects. This keeps the toggle usable
-- when an executor rejects the embedded/obfuscated shader loader.
local function applySimpleShaderFallback()
    -- The original Lighting state is captured by startSimpleShader() before this runs.
    LT.Brightness = 2
    LT.ClockTime = 17.4
    LT.Ambient = Color3.fromRGB(105, 120, 165)
    LT.OutdoorAmbient = Color3.fromRGB(125, 145, 185)
    LT.ColorShift_Top = Color3.fromRGB(90, 130, 255)
    LT.ColorShift_Bottom = Color3.fromRGB(30, 45, 95)
    LT.EnvironmentDiffuseScale = 0.45
    LT.EnvironmentSpecularScale = 0.6
    LT.ExposureCompensation = 0.05

    local color = Instance.new("ColorCorrectionEffect")
    color.Name = "DungdxSimpleShaderFallback_Color"
    color.TintColor = Color3.fromRGB(205, 220, 255)
    color.Contrast = 0.12
    color.Saturation = 0.08
    color.Brightness = 0.02
    color.Parent = LT

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "DungdxSimpleShaderFallback_Bloom"
    bloom.Intensity = 0.18
    bloom.Size = 24
    bloom.Threshold = 1.1
    bloom.Parent = LT
end

local function updateSimpleShaderStatusLabel()
    local label = SimpleShader.statusLabel
    if not label or not label.Parent then return end
    pcall(function()
        label.Text = "Trạng thái: " .. tostring(SimpleShader.status)
        if tostring(SimpleShader.status):find("Lỗi", 1, true) then
            label.TextColor3 = T.Danger
        elseif tostring(SimpleShader.status):find("không xác minh", 1, true) then
            label.TextColor3 = T.Accent
        else
            label.TextColor3 = T.Green
        end
    end)
end

-- Chỉ xác minh trạng thái một lần. Không tự chạy lại toàn bộ script shader khi
-- không tìm được nhãn GUI dự kiến, vì shader nguồn có thể dùng cấu trúc GUI khác
-- và việc nạp lại nhiều lần có thể khởi tạo lại/reset trạng thái của shader.
local function startSimpleShaderWatchdog()
    if SimpleShader.watchdogConn then
        pcall(function() SimpleShader.watchdogConn:Disconnect() end)
        SimpleShader.watchdogConn = nil
    end
    local token = SimpleShader.generation
    local elapsed = 0
    SimpleShader.watchdogConn = RS.Heartbeat:Connect(function(dt)
        if not SimpleShader.enabled or SimpleShader.generation ~= token then
            if SimpleShader.watchdogConn then
                pcall(function() SimpleShader.watchdogConn:Disconnect() end)
                SimpleShader.watchdogConn = nil
            end
            return
        end
        elapsed = elapsed + dt
        if elapsed < 2.5 then return end

        -- If the bundled loader hangs instead of returning, cancel it and enable
        -- the native fallback so the toggle does not remain stuck in Loading.
        if SimpleShader.status == "Đang tải..." and not SimpleShader.sourceStarted and not SimpleShader.fallbackApplied then
            if SimpleShader.runningThread then
                pcall(function() if task.cancel then task.cancel(SimpleShader.runningThread) end end)
                SimpleShader.runningThread = nil
            end
            local fallbackOk, fallbackErr = pcall(applySimpleShaderFallback)
            if fallbackOk then
                SimpleShader.fallbackApplied = true
                SimpleShader.status = "Đang bật (shader tích hợp)"
            else
                SimpleShader.status = "Lỗi shader: " .. tostring(fallbackErr):sub(1, 100)
                warn("[SimpleShader Fallback] " .. tostring(fallbackErr))
            end
            updateSimpleShaderStatusLabel()
        end

        if SimpleShader.sourceStarted and not shaderGuiExists() then
            -- The embedded source may create its GUI under an executor-specific root.
            -- Apply the native fallback once so the visual effect still works.
            if not SimpleShader.fallbackApplied then
                local fallbackOk, fallbackErr = pcall(applySimpleShaderFallback)
                if fallbackOk then
                    SimpleShader.fallbackApplied = true
                    SimpleShader.status = "Đang bật (shader tích hợp)"
                else
                    SimpleShader.status = "Đã nạp; GUI không xác minh được"
                    warn("[SimpleShader Fallback] " .. tostring(fallbackErr))
                end
            end
            updateSimpleShaderStatusLabel()
        end
        if SimpleShader.watchdogConn then
            pcall(function() SimpleShader.watchdogConn:Disconnect() end)
            SimpleShader.watchdogConn = nil
        end
    end)
end

function startSimpleShader()
    if SimpleShader.enabled then return true,SimpleShader.status end
    local backupOk,backupErr=pcall(captureSimpleShaderState)
    if not backupOk then
        warn("[SimpleShader Backup] "..tostring(backupErr))
        SimpleShader.status="Lỗi sao lưu trạng thái: "..tostring(backupErr):sub(1,90)
        updateSimpleShaderStatusLabel()
        return false,backupErr
    end

    SimpleShader.generation=SimpleShader.generation+1
    local token=SimpleShader.generation
    SimpleShader.retryCount=0
    SimpleShader.sourceStarted=false
    SimpleShader.fallbackApplied=false
    SimpleShader.enabled=true
    SimpleShader.status="Đang tải..."
    updateSimpleShaderStatusLabel()

    -- Try the bundled original shader only when the user enables it. If its
    -- obfuscated loader errors or hangs, the watchdog enables the reversible
    -- built-in fallback instead of leaving the toggle stuck in Loading.
    startSimpleShaderWatchdog()
    SimpleShader.runningThread=task.spawn(function()
        local loadOk,loadErr=launchSimpleShaderSource()
        if not SimpleShader.enabled or SimpleShader.generation~=token then return end
        SimpleShader.runningThread=nil
        if loadOk then
            SimpleShader.sourceStarted=true
            SimpleShader.status="Đang bật (shader gốc)"
            updateSimpleShaderStatusLabel()
        else
            warn("[SimpleShader Source] "..tostring(loadErr))
            local fallbackOk,fallbackErr=pcall(applySimpleShaderFallback)
            if fallbackOk then
                SimpleShader.fallbackApplied=true
                SimpleShader.status="Đang bật (hiệu ứng tích hợp dự phòng)"
            else
                SimpleShader.enabled=false
                SimpleShader.status="Lỗi shader: "..tostring(fallbackErr):sub(1,100)
                pcall(restoreSimpleShaderState)
                syncFeatureUI("Shader",false)
                warn("[SimpleShader Fallback] "..tostring(fallbackErr))
            end
            updateSimpleShaderStatusLabel()
        end
    end)
    return true,SimpleShader.status
end
function stopSimpleShader()
    if not SimpleShader.enabled and SimpleShader.status=="Tắt" then syncFeatureUI("Shader",false); return end
    SimpleShader.enabled=false
    SimpleShader.generation=SimpleShader.generation+1
    SimpleShader.sourceStarted=false
    SimpleShader.retryCount=0
    SimpleShader.status="Đang tắt..."
    if SimpleShader.watchdogConn then pcall(function() SimpleShader.watchdogConn:Disconnect() end); SimpleShader.watchdogConn=nil end
    restoreSimpleShaderState()
    syncFeatureUI("Shader",false)
end

-- POV / FOV controller.

POV = {
    enabled=false, fov=70, saved=nil, camConn=nil,
    bindName="DungdxPOVLock", useHook=false,
}

function povApply()
    local cam = WS.CurrentCamera
    if cam then pcall(function() cam.FieldOfView = math.clamp(POV.fov, 40, 120) end) end
end

function povStart()
    if POV.enabled then povApply(); return end
    local cam = WS.CurrentCamera
    POV.saved = cam and cam.FieldOfView or 70
    POV.enabled = true
    POV_Hook.target = math.clamp(POV.fov, 40, 120)

    -- Thử hook trước (mượt nhất)
    POV.useHook = installPOVHook()
    POV_Hook.active = POV.useHook

    if not POV.useHook then
        -- Fallback: đè mỗi frame sau camera update
        pcall(function() RS:UnbindFromRenderStep(POV.bindName) end)
        RS:BindToRenderStep(POV.bindName, Enum.RenderPriority.Camera.Value + 1, function()
            if not POV.enabled then return end
            local c = WS.CurrentCamera
            if not c then return end
            local target = math.clamp(tonumber(POV.fov) or 70, 40, 120)
            if math.abs(c.FieldOfView - target) > 0.01 then
                c.FieldOfView = target
            end
        end)
    end

    -- Áp 1 lần ngay để chắc chắn
    povApply()

    if POV.camConn then pcall(function() POV.camConn:Disconnect() end) end
    POV.camConn = WS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if POV.enabled then
            task.wait()
            POV_Hook.target = math.clamp(POV.fov, 40, 120)
            povApply()
        end
    end)
end

function povStop()
    POV.enabled = false
    POV_Hook.active = false
    pcall(function() RS:UnbindFromRenderStep(POV.bindName) end)
    if POV.camConn then pcall(function() POV.camConn:Disconnect() end); POV.camConn=nil end
    local cam = WS.CurrentCamera
    if cam and POV.saved then pcall(function() cam.FieldOfView = POV.saved end) end
    POV.saved=nil
    syncFeatureUI("POV",false)
end

function povSet(v)
    POV.fov = math.clamp(tonumber(v) or 70, 40, 120)
    POV_Hook.target = POV.fov
    if POV.enabled then povApply() end
end

ExtShared.tbl = tbl
ExtShared.FlyCam = FlyCam
ExtShared.flycamStop = flycamStop
ExtShared.flycamReady.start = flycamStart
ExtShared.flycamReady.stop = flycamStop
ExtShared.povReady.start = povStart
ExtShared.povReady.stop = povStop
ExtShared.povReady.set = povSet
FeatureControl.stopTargetTween = tweenStop

local function buildRefactoredTabs()

-- ═══════════════ BUILD VISUAL TAB ═══════════════
local vCam=mSec(pVisual,"Camera / Góc nhìn","POV, Zoom vô hạn và FlyCam",1)
local cameraMaxZoomDistance = LP.CameraMaxZoomDistance
FeatureControl.restoreZoom=function()
    pcall(function() LP.CameraMaxZoomDistance=cameraMaxZoomDistance end)
end
FeatureControl.ui.InfiniteZoom=mTog(vCam,"Zoom vô hạn","Cho phép camera zoom ra không giới hạn",false,1,function(v)
    LP.CameraMaxZoomDistance = v and math.huge or cameraMaxZoomDistance
end)
FeatureControl.ui.POV=mTog(vCam,"Bật POV","Bật/tắt FOV tùy chỉnh",false,2,function(v)
    if v then
        if ExtShared.povReady.start then ExtShared.povReady.start() end
    else
        if ExtShared.povReady.stop then ExtShared.povReady.stop() end
    end
end)
mSld(vCam,"FOV","Góc nhìn camera (40–120)",40,120,70,3,function(v)
    if ExtShared.povReady.set then ExtShared.povReady.set(v) end
end)
mBtn(vCam,"Reset FOV","Đưa FOV về mức mặc định 70","Reset",4,function()
    if ExtShared.povReady.set then ExtShared.povReady.set(70) end
end)
FeatureControl.ui.FlyCam=mTog(vCam,"Bật FlyCam","Camera bay tự do — mobile joystick / PC WASD + Space/Shift",false,5,function(v)
    if v then flycamStart() else flycamStop() end
end)
mSld(vCam,"Tốc độ FlyCam","Tốc độ di chuyển camera (studs/s)",20,500,100,6,function(v)
    FlyCam.speed=v
end)
mBtn(vCam,"Reset FlyCam","Tắt FlyCam và trả camera về nhân vật","Reset",7,function()
    flycamStop()
end,true)

local v1=mSec(pVisual,"ESP Người chơi","Hiển thị thông tin người chơi",2)
FeatureControl.ui.ESP=mTog(v1,"Bật ESP Người chơi","Bật/tắt hiển thị người chơi",false,1,function(v)
    ESP.on=v
    if not v then
        for p, _ in pairs(espC) do
            rmESP(p)
        end
    end
end)
mTog(v1,"Tên người chơi","Hiển thị tên người chơi",true,2,function(v) ESP.name=v end)
mTog(v1,"Khoảng cách","Hiển thị khoảng cách",true,3,function(v) ESP.dist=v end)
mTog(v1,"Số máu","Hiển thị số máu còn lại",true,4,function(v) ESP.hp=v end)
local vESP=mSec(pVisual,"Kiểu ESP","Tùy chỉnh kiểu hiển thị",3)
mBtn(vESP,"Đổi màu","Xoay vòng màu đối thủ","Đổi",1,function()
    local pool={Color3.fromRGB(255,80,100),Color3.fromRGB(255,200,60),
        Color3.fromRGB(80,240,130),Color3.fromRGB(0,220,255)}
    local ix=1
    for k,c in ipairs(pool) do if c==ESP.color then ix=k%#pool+1; break end end
    ESP.color=pool[ix]
end)
mSld(vESP,"Độ trong suốt","Điều chỉnh độ trong suốt ESP",0,100,70,2,function(v) ESP.trans=v/100 end)

-- ═══════════════ BUILD MOVE TAB ═══════════════
local spOn,spV=false,60
local jpOn,jpV=false,120
local bsp=16
local jumpBase={UseJumpPower=true,JumpPower=50,JumpHeight=7.2}
local function gH() local ch=LP.Character; return ch and ch:FindFirstChildOfClass("Humanoid") or nil end
local function rBase()
    local h=gH()
    if h then
        bsp=h.WalkSpeed
        jumpBase={UseJumpPower=h.UseJumpPower,JumpPower=h.JumpPower,JumpHeight=h.JumpHeight}
    end
end
rBase()
trackPersistent(LP.CharacterAdded:Connect(function() task.wait(.3); rBase() end))
local movementHeartbeatConn=RS.Heartbeat:Connect(function()
    local h = gH(); if not h then return end
    if Mv.Fly.enabled then return end
    if spOn and h.WalkSpeed ~= spV then h.WalkSpeed = spV end
    if jpOn then
        h.UseJumpPower = true
        if h.JumpPower ~= jpV then h.JumpPower = jpV end
    end
end)
FeatureControl.cleanupMovement=function()
    spOn=false; jpOn=false
    if movementHeartbeatConn then pcall(function() movementHeartbeatConn:Disconnect() end); movementHeartbeatConn=nil end
    local h=gH()
    if h then
        pcall(function() h.WalkSpeed=bsp end)
        pcall(function() h.UseJumpPower=jumpBase.UseJumpPower; h.JumpPower=jumpBase.JumpPower; h.JumpHeight=jumpBase.JumpHeight end)
    end
end
local function hookWS(h)
    if not h then return end
    h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if spOn and h.WalkSpeed ~= spV then h.WalkSpeed = spV end
    end)
    h:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if jpOn and h.JumpPower ~= jpV then h.JumpPower = jpV end
    end)
end
if LP.Character then hookWS(LP.Character:FindFirstChildOfClass("Humanoid")) end
trackPersistent(LP.CharacterAdded:Connect(function(ch) task.wait(.3); hookWS(ch:FindFirstChildOfClass("Humanoid")) end))
local function ap()
    local h=gH(); if not h then return end
    if spOn then h.WalkSpeed=spV end
    if jpOn then h.UseJumpPower=true; h.JumpPower=jpV end
end
local m1=mSec(pMove,"Di chuyển","Tối ưu tốc độ & nhảy",1)
mTog(m1,"Tốc độ","Bật tăng tốc độ chạy",false,1,function(v)
    spOn=v; ap()
    if not v then local h=gH(); if h then h.WalkSpeed=bsp end end
end)
mSld(m1,"Giá trị tốc độ","Tốc độ chạy",16,200,60,2,function(v) spV=v; if spOn then ap() end end)
mTog(m1,"Nhảy","Bật tăng lực nhảy",false,3,function(v)
    jpOn=v; ap()
    if not v then
        local h=gH()
        if h then
            h.UseJumpPower=jumpBase.UseJumpPower
            h.JumpPower=jumpBase.JumpPower
            h.JumpHeight=jumpBase.JumpHeight
        end
    end
end)
mSld(m1,"Giá trị nhảy","Lực nhảy",50,500,120,4,function(v) jpV=v; if jpOn then ap() end end)

local m2=mSec(pMove,"Bay & Xuyên vật thể","Fly, đi trên nước và Noclip",2)
FeatureControl.ui.Fly=mTog(m2,"Fly","Bay tự do theo hướng camera",false,1,function(v)
    if v then flyStart() else flyStop() end
end)
mSld(m2,"Tốc độ bay","Tốc độ bay",20,300,80,2,function(v) Mv.Fly.speed=v end)
FeatureControl.ui.Water=mTog(m2,"Đi trên nước","Đi bộ trên mặt nước",false,3,function(v)
    if v then waterStart() else waterStop() end
end)
FeatureControl.ui.Noclip=mTog(m2,"Noclip","Xuyên qua vật thể",false,4,function(v)
    if v then noclipStart() else noclipStop() end
end)

-- ═══════════════ FIX LAG ═══════════════
local FIX = {enabled=false,conns={},processed={},objectBackup={},lightingBackup=nil,count=0,scanToken=0,scanRunning=false,scanQueued=false,scanComplete=false}
local function optimizeObj(obj)
    if not FIX.enabled or not obj or FIX.processed[obj] then return end
    if not obj.Parent then return end
    if SimpleShader and SimpleShader.enabled and obj:IsDescendantOf(LT) then return end
    local backup={class=obj.ClassName}
    local changed=false
    local ok=pcall(function()
        if obj:IsA("BasePart") then
            backup.Material=obj.Material; backup.Reflectance=obj.Reflectance
            obj.Material=Enum.Material.SmoothPlastic; obj.Reflectance=0; changed=true
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            backup.Transparency=obj.Transparency; obj.Transparency=1; changed=true
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
            or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
            local par=obj.Parent
            while par and par~=WS do
                if Players:GetPlayerFromCharacter(par) then return end
                par=par.Parent
            end
            backup.Enabled=obj.Enabled
            if obj:IsA("ParticleEmitter") then backup.Rate=obj.Rate; obj.Rate=0 end
            obj.Enabled=false; changed=true
        elseif obj:IsA("Explosion") then
            backup.BlastPressure=obj.BlastPressure; backup.BlastRadius=obj.BlastRadius
            obj.BlastPressure=0; obj.BlastRadius=0; changed=true
        elseif obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BloomEffect")
            or obj:IsA("DepthOfFieldEffect") or obj:IsA("ColorCorrectionEffect") then
            if obj.Name:sub(1,7)=="Dungdx_" or obj.Name:find("DungdxSimpleShaderFallback") then return end
            backup.Enabled=obj.Enabled; obj.Enabled=false; changed=true
        elseif obj:IsA("Atmosphere") then
            -- Atmosphere has no Enabled property; keep it intact to allow full restore.
            backup.Parent=obj.Parent; obj.Parent=nil; changed=true
        end
    end)
    if ok and changed then
        FIX.processed[obj]=true
        FIX.objectBackup[obj]=backup
        FIX.count=FIX.count+1
    end
end
local function initialScan()
    if FIX.scanRunning then FIX.scanQueued=true; return false end
    FIX.scanRunning=true; FIX.scanQueued=false; FIX.scanComplete=false
    local token=FIX.scanToken
    local ok,err=pcall(function()
        local list=WS:GetDescendants()
        local total=#list
        -- Smaller batches avoid a large per-frame spike on low-end mobile devices.
        local batch=64
        for i=1,total,batch do
            if not FIX.enabled or FIX.scanToken~=token then return end
            for j=i,math.min(i+batch-1,total) do optimizeObj(list[j]) end
            if i+batch<=total then task.wait() end
        end
        if not (SimpleShader and SimpleShader.enabled) then
            for _,obj in ipairs(LT:GetChildren()) do
                if not FIX.enabled or FIX.scanToken~=token then return end
                optimizeObj(obj)
            end
        end
        FIX.scanComplete=FIX.enabled and FIX.scanToken==token
    end)
    FIX.scanRunning=false
    if not ok then warn("[Fix Lag] Quét gặp lỗi: "..tostring(err)) end
    if FIX.scanQueued and FIX.enabled then
        FIX.scanQueued=false
        task.defer(initialScan)
    end
    return ok
end
local function enableFix()
    if FIX.enabled then return end
    FIX.enabled=true; FIX.count=0; FIX.processed={}; FIX.objectBackup={}; FIX.scanComplete=false; FIX.scanToken=FIX.scanToken+1
    pcall(function()
        FIX.lightingBackup={quality=settings().Rendering.QualityLevel}
    end)
    -- Avoid changing Lighting properties here: Shader and Fix Lag must not fight over them.
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    task.spawn(initialScan)
    table.insert(FIX.conns,WS.DescendantAdded:Connect(function(obj)
        if not FIX.enabled then return end
        task.defer(function() if FIX.enabled and obj and obj.Parent then optimizeObj(obj) end end)
    end))
    table.insert(FIX.conns,LT.DescendantAdded:Connect(function(obj)
        if not FIX.enabled or (SimpleShader and SimpleShader.enabled) then return end
        task.defer(function() if FIX.enabled and obj and obj.Parent then optimizeObj(obj) end end)
    end))
end
local function disableFix()
    if not FIX.enabled then return end
    FIX.enabled=false; FIX.scanToken=FIX.scanToken+1; FIX.scanQueued=false; FIX.scanComplete=false
    for _,conn in ipairs(FIX.conns) do pcall(function() conn:Disconnect() end) end
    table.clear(FIX.conns)
    for obj,b in pairs(FIX.objectBackup) do
        pcall(function()
            if b.class=="BasePart" and obj.Parent then obj.Material=b.Material; obj.Reflectance=b.Reflectance
            elseif (b.class=="Decal" or b.class=="Texture") and obj.Parent then obj.Transparency=b.Transparency
            elseif b.class=="ParticleEmitter" or b.class=="Trail" or b.class=="Smoke" or b.class=="Fire" or b.class=="Sparkles" or b.class=="Beam" then
                if obj.Parent then if b.Rate~=nil then obj.Rate=b.Rate end; obj.Enabled=b.Enabled end
            elseif b.class=="Explosion" and obj.Parent then obj.BlastPressure=b.BlastPressure; obj.BlastRadius=b.BlastRadius
            elseif b.class=="BlurEffect" or b.class=="SunRaysEffect" or b.class=="BloomEffect" or b.class=="DepthOfFieldEffect" or b.class=="ColorCorrectionEffect" then
                if obj.Parent then obj.Enabled=b.Enabled end
            elseif b.class=="Atmosphere" and obj.Parent==nil then
                -- Reattach only if it was detached by this feature.
                if b.Parent then obj.Parent=b.Parent end
            end
        end)
    end
    if FIX.lightingBackup then
        local b=FIX.lightingBackup
        pcall(function() settings().Rendering.QualityLevel=b.quality end)
    end
    FIX.processed={}; FIX.objectBackup={}; FIX.lightingBackup=nil; FIX.count=0
end
FeatureControl.FIX=FIX
FeatureControl.disableFix=disableFix
local UA = {v=0}
local function apA(i)
    if i:IsA("GuiObject") then
        if i:GetAttribute("__uob")==nil then i:SetAttribute("__uob",i.BackgroundTransparency) end
        local o=i:GetAttribute("__uob")
        local value=o+(1-o)*UA.v
        -- Reveal the image subtly through opaque panels while preserving the
        -- user's UI-transparency slider and every control's original alpha.
        if ImageThemeActive and i~=ThemeImageBackground and o<1 then
            value=math.max(value,0.58)
        end
        i.BackgroundTransparency=value
    end
end
apAll=function() for _,i in ipairs(Main:GetDescendants()) do if i:IsA("GuiObject") then apA(i) end end; apA(Main) end
Main.DescendantAdded:Connect(function(i) if i:IsA("GuiObject") then task.defer(function() apA(i) end) end end)

-- ═══════════════ BUILD SETTINGS TAB ═══════════════
local s1=mSec(pSet,"Giao diện","Tùy chỉnh giao diện",1)
local uiAlphaSlider=mSld(s1,"Độ trong suốt nền UI","Điều chỉnh độ trong suốt nền các khung",0,100,0,1,function(v) UA.v=(v/100)*.9; apAll() end)
local uiScaleSlider=mSld(s1,"Kích thước UI","Phóng to / thu nhỏ",60,150,100,2,function(v) if _G.__setUS then _G.__setUS(v) end end)
local uiLayoutDrop=mDrop(s1,"Bố cục UI","Ngang: thanh tab bên trái · Dọc: khung cao, tab vuốt ngang",{"Ngang","Dọc"},"Ngang",3,function(v)
    UI.Orientation = (v == "Dọc") and "Doc" or "Ngang"
    R.orientation=UI.Orientation
    if applyScale then applyScale() elseif applyLayout then applyLayout() end
end)
-- ═══════════════ THEME UI SECTION ═══════════════
local themeSec=mSec(pSet,"🎨 Theme UI","Màu sắc và hiệu ứng giao diện",2)
local themeColorRow=mRow(themeSec,1)
local themeColorSwatch=Instance.new("Frame",themeColorRow)
themeColorSwatch.Size=UDim2.fromOffset(44,34)
themeColorSwatch.Position=UDim2.fromOffset(8,5)
themeColorSwatch.BackgroundColor3=Theme.color
themeColorSwatch.BorderSizePixel=0
cr(themeColorSwatch,8); sk(themeColorSwatch,T.Stroke,1)
local themeHexLabel=Instance.new("TextLabel",themeColorRow)
themeHexLabel.Size=UDim2.new(1,-170,0,20)
themeHexLabel.Position=UDim2.fromOffset(60,12)
themeHexLabel.BackgroundTransparency=1
themeHexLabel.Text=themeHex(Theme.color)
themeHexLabel.Font=Enum.Font.GothamMedium
themeHexLabel.TextSize=12
themeHexLabel.TextColor3=T.Text
themeHexLabel.TextXAlignment=Enum.TextXAlignment.Left
local themeColorBtn=mBtn(themeSec,"Màu Theme hiện tại","Chọn màu HEX / SV / Hue","Chọn màu",2,openThemeColorPicker)
local themeColorBtnRow=themeColorBtn.Parent
themeColorBtn.Parent=themeColorRow
themeColorBtn.Size=UDim2.fromOffset(100,28)
themeColorBtn.AnchorPoint=Vector2.new(1,.5)
themeColorBtn.Position=UDim2.new(1,-8,.5,0)
themeColorBtnRow:Destroy()
local themeColorClick=Instance.new("TextButton",themeColorSwatch)
themeColorClick.Size=UDim2.fromScale(1,1)
themeColorClick.BackgroundTransparency=1
themeColorClick.Text=""
themeColorClick.AutoButtonColor=false
themeColorClick.MouseButton1Click:Connect(openThemeColorPicker)
Theme.previewFrame=themeColorSwatch
Theme.previewLabel=themeHexLabel

local themeIntensitySlider, themeBrightnessSlider, themeRGBSlider
local themeImageRow,themeImageStatusRow,themeImageStatus
local function updateThemeControlVisibility()
    local mode=Theme.mode
    local neon=(mode=="Neon")
    local image=(mode=="Ảnh nền")

    if themeIntensitySlider and themeIntensitySlider.Frame then
        themeIntensitySlider.Frame.Visible=neon
    end
    if themeBrightnessSlider and themeBrightnessSlider.Frame then
        themeBrightnessSlider.Frame.Visible=neon
    end
    if themeRGBSlider and themeRGBSlider.Frame then
        themeRGBSlider.Frame.Visible=(mode=="RGB")
    end
    if themeImageRow then themeImageRow.Visible=image end
    if themeImageStatusRow then themeImageStatusRow.Visible=image end
end

local themeModeDrop=mDrop(themeSec,"Chế độ Theme","Bình thường / Neon / RGB / Ảnh nền",{"Bình thường","Neon","RGB","Ảnh nền"},Theme.mode,2,function(v)
    Theme.mode=v
    if v=="RGB" then Theme._rgbHue=0; Theme._rgbAcc=0 end
    updateThemeControlVisibility()
    themeApply()
    if v=="Ảnh nền" and Theme.imageId=="" then
        themeImageStatus.Text="Nhập ID ảnh Roblox rồi nhấn Áp dụng"
        themeImageStatus.TextColor3=T.Sub
    end
end)

themeIntensitySlider=mSld(themeSec,"Độ đậm nhạt","Cường độ màu Theme",50,150,100,3,function(v)
    Theme.intensity=v
    themeApply()
end)
themeBrightnessSlider=mSld(themeSec,"Độ sáng","Độ sáng màu Theme",50,150,100,4,function(v)
    Theme.brightness=v
    themeApply()
end)
themeRGBSlider=mSld(themeSec,"Tốc độ RGB","Tốc độ chuyển màu RGB",10,300,100,5,function(v)
    Theme.rgbSpeed=v
end)

themeImageRow=mRow(themeSec,6)
themeImageRow.Size=UDim2.new(1,0,0,58)
local themeImageTitle=Instance.new("TextLabel",themeImageRow)
themeImageTitle.Size=UDim2.new(1,-170,0,18)
themeImageTitle.Position=UDim2.fromOffset(12,5)
themeImageTitle.BackgroundTransparency=1
themeImageTitle.Text="Ảnh nền Roblox"
themeImageTitle.Font=Enum.Font.GothamMedium
themeImageTitle.TextSize=12
themeImageTitle.TextColor3=T.Text
themeImageTitle.TextXAlignment=Enum.TextXAlignment.Left
local themeImageDesc=Instance.new("TextLabel",themeImageRow)
themeImageDesc.Size=UDim2.new(1,-170,0,14)
themeImageDesc.Position=UDim2.fromOffset(12,25)
themeImageDesc.BackgroundTransparency=1
themeImageDesc.Text="Nhập ID ảnh rồi nhấn Áp dụng"
themeImageDesc.Font=Enum.Font.Gotham
themeImageDesc.TextSize=10
themeImageDesc.TextColor3=T.Sub
themeImageDesc.TextXAlignment=Enum.TextXAlignment.Left
local themeImageInput=Instance.new("TextBox",themeImageRow)
themeImageInput.Name="ThemeImageAssetId"
themeImageInput.Size=UDim2.new(.42,0,0,28)
themeImageInput.AnchorPoint=Vector2.new(1,.5)
themeImageInput.Position=UDim2.new(1,-82,.5,0)
themeImageInput.BackgroundColor3=T.Input
themeImageInput.TextColor3=T.Text
themeImageInput.PlaceholderColor3=T.Sub
themeImageInput.PlaceholderText="ID ảnh..."
themeImageInput.Text=tostring(Theme.imageId or "")
themeImageInput.ClearTextOnFocus=false
themeImageInput.Font=Enum.Font.GothamMedium
themeImageInput.TextSize=11
themeImageInput.BorderSizePixel=0
themeImageInput.TextXAlignment=Enum.TextXAlignment.Center
cr(themeImageInput,7); sk(themeImageInput,T.Stroke,1)
local themeImageApply=Instance.new("TextButton",themeImageRow)
themeImageApply.Size=UDim2.fromOffset(68,28)
themeImageApply.AnchorPoint=Vector2.new(1,.5)
themeImageApply.Position=UDim2.new(1,-8,.5,0)
themeImageApply.BackgroundColor3=T.Accent
themeImageApply.Text="Áp dụng"
themeImageApply.TextColor3=Color3.fromRGB(255,255,255)
themeImageApply.Font=Enum.Font.GothamBold
themeImageApply.TextSize=10
themeImageApply.BorderSizePixel=0
themeImageApply.AutoButtonColor=false
cr(themeImageApply,7)
themeImageStatusRow=mRow(themeSec,7)
themeImageStatusRow.Size=UDim2.new(1,0,0,32)
themeImageStatus=Instance.new("TextLabel",themeImageStatusRow)
themeImageStatus.Size=UDim2.new(1,-20,1,0)
themeImageStatus.Position=UDim2.fromOffset(10,0)
themeImageStatus.BackgroundTransparency=1
themeImageStatus.Text="Chưa chọn ảnh nền"
themeImageStatus.Font=Enum.Font.Gotham
themeImageStatus.TextSize=10
themeImageStatus.TextColor3=T.Sub
themeImageStatus.TextXAlignment=Enum.TextXAlignment.Left

themeImageApply.MouseButton1Click:Connect(function()
    local raw=tostring(themeImageInput.Text or ""):gsub("%s+","")
    local id=raw:match("^rbxassetid://(%d+)$") or raw:match("^(%d+)$")
        or raw:match("[?&]id=(%d+)") or raw:match("/library/(%d+)")
    if not id or #id>20 or not tonumber(id) or tonumber(id)<=0 then
        themeImageStatus.Text="ID ảnh không hợp lệ — hãy nhập ID số của ảnh Roblox"
        themeImageStatus.TextColor3=T.Danger
        return
    end
    Theme.imageId="rbxassetid://"..id
    themeImageInput.Text=id
    Theme.mode="Ảnh nền"
    if themeModeDrop and themeModeDrop.Sync then themeModeDrop:Sync("Ảnh nền") end
    updateThemeControlVisibility()
    themeApply()
    themeImageStatus.Text="Đang tải ảnh "..id.."..."
    themeImageStatus.TextColor3=T.Accent
    task.spawn(function()
        local preloadOk,preloadErr=pcall(function() CP:PreloadAsync({ThemeImageBackground}) end)
        task.wait(.15)
        if not themeImageStatus.Parent then return end
        if preloadOk and ThemeImageBackground.IsLoaded then
            themeImageStatus.Text="Đã áp dụng ảnh nền · ID "..id
            themeImageStatus.TextColor3=T.Green
        else
            themeImageStatus.Text="Đã đặt ID; Roblox chưa tải được ảnh này"
            themeImageStatus.TextColor3=T.Danger
            if not preloadOk then warn("[Dungdx Theme Image] "..tostring(preloadErr)) end
        end
    end)
end)

themeImageRow.Visible=false
themeImageStatusRow.Visible=false

updateThemeControlVisibility()

local s2=mSec(pSet,"Tối ưu hiệu suất","Tăng FPS toàn diện",3)
local fixRow=Instance.new("Frame",s2)
fixRow.Size=UDim2.new(1,0,0,72); fixRow.BackgroundColor3=T.Card
fixRow.BorderSizePixel=0; fixRow.LayoutOrder=1; cr(fixRow,10); sk(fixRow,T.Accent,1.5,.3)
local fixTitle=Instance.new("TextLabel",fixRow)
fixTitle.Size=UDim2.new(1,-140,0,22); fixTitle.Position=UDim2.fromOffset(14,10)
fixTitle.BackgroundTransparency=1; fixTitle.Text="Fix Lag (Tăng FPS)"
fixTitle.Font=Enum.Font.GothamBold; fixTitle.TextSize=14; fixTitle.TextColor3=T.Text
fixTitle.TextXAlignment=Enum.TextXAlignment.Left
local fixStatus=Instance.new("TextLabel",fixRow)
fixStatus.Size=UDim2.new(1,-140,0,16); fixStatus.Position=UDim2.fromOffset(14,32)
fixStatus.BackgroundTransparency=1; fixStatus.Text="Chưa tối ưu - bấm BẬT để bắt đầu"
fixStatus.Font=Enum.Font.Gotham; fixStatus.TextSize=11; fixStatus.TextColor3=T.Sub
fixStatus.TextXAlignment=Enum.TextXAlignment.Left
local fixTip=Instance.new("TextLabel",fixRow)
fixTip.Size=UDim2.new(1,-140,0,14); fixTip.Position=UDim2.fromOffset(14,50)
fixTip.BackgroundTransparency=1; fixTip.Text="Có thể tắt và khôi phục trạng thái đã lưu"
fixTip.Font=Enum.Font.Gotham; fixTip.TextSize=9; fixTip.TextColor3=T.Sub
fixTip.TextXAlignment=Enum.TextXAlignment.Left
local fixBtn=Instance.new("TextButton",fixRow)
fixBtn.Size=UDim2.fromOffset(100,34); fixBtn.AnchorPoint=Vector2.new(1,.5)
fixBtn.Position=UDim2.new(1,-14,.5,0)
fixBtn.BackgroundColor3=T.Accent; fixBtn.Text="BẬT"
fixBtn.Font=Enum.Font.GothamBold; fixBtn.TextSize=13
fixBtn.TextColor3=Color3.fromRGB(255,255,255)
fixBtn.BorderSizePixel=0; fixBtn.AutoButtonColor=false
cr(fixBtn,9); sk(fixBtn,T.Accent,1,.2)
local fixOn=false
local function renderFixButton(on)
    fixOn=on
    fixBtn.Text=on and "TẮT" or "BẬT"
    fixBtn.BackgroundColor3=on and T.Green or T.Accent
    fixStatus.TextColor3=on and T.Green or T.Sub
end
fixBtn.MouseButton1Click:Connect(function()
    if fixOn then
        disableFix(); renderFixButton(false)
        fixStatus.Text="Đã tắt và khôi phục các thay đổi có thể khôi phục"
        return
    end
    renderFixButton(true)
    fixStatus.Text="Đang tối ưu..."; fixStatus.TextColor3=T.Accent
    task.spawn(function()
        if not fixOn then return end
        enableFix()
        if not fixOn then disableFix(); return end
        task.wait(1.5)
        if FIX.enabled and fixOn then
            if FIX.scanComplete then
                fixStatus.Text="Đã tối ưu "..FIX.count.." vật thể — bấm TẮT để khôi phục"
                fixStatus.TextColor3=T.Green
            else
                fixStatus.Text="Đang tối ưu dần: "..FIX.count.." vật thể đã xử lý"
                fixStatus.TextColor3=T.Accent
            end
        else
            renderFixButton(false); fixStatus.Text="Không thể bật Fix Lag"; fixStatus.TextColor3=T.Danger
        end
    end)
end)
mBtn(s2,"Quét lại","Quét theo từng đợt nhỏ để giảm khựng hình","Quét",2,function()
    if FIX.enabled then
        if FIX.scanRunning then
            fixStatus.Text="Đang quét dần — đợi quét hiện tại hoàn tất"
            fixStatus.TextColor3=T.Accent
            return
        end
        task.spawn(function()
            initialScan()
            if FIX.enabled then
                if FIX.scanComplete then
                    fixStatus.Text="Đã quét xong — "..FIX.count.." vật thể đang tối ưu"
                    fixStatus.TextColor3=T.Green
                else
                    fixStatus.Text="Đang tối ưu dần — "..FIX.count.." vật thể đã xử lý"
                    fixStatus.TextColor3=T.Accent
                end
            end
        end)
    else
        fixStatus.Text="Bật Fix Lag trước khi quét!"
        fixStatus.TextColor3=T.Danger
        task.delay(2,function()
            if not FIX.enabled and fixStatus.Parent then
                fixStatus.Text="Chưa tối ưu - bấm BẬT để bắt đầu"
                fixStatus.TextColor3=T.Sub
            end
        end)
    end
end)
local s3=mSec(pSet,"Hành động","Lưu và khôi phục",5)
mBtn(s3,"Đặt lại về mặc định","Reset toàn bộ tùy chỉnh giao diện về mặc định","Reset",1,function()
    Main.Position=UDim2.fromScale(.5,.5)
    UI.Orientation="Ngang"
    R.orientation="Ngang"
    UA.v=0
    if uiAlphaSlider and uiAlphaSlider.Sync then uiAlphaSlider:Sync(0) end
    if uiScaleSlider and uiScaleSlider.Sync then uiScaleSlider:Sync(100) end
    if uiLayoutDrop and uiLayoutDrop.Sync then uiLayoutDrop:Sync("Ngang") end
    Theme.color=Color3.fromRGB(59,130,246)
    Theme.mode="Bình thường"
    Theme.imageId=""
    Theme.imageTransparency=0.05
    ThemeImageBackground.Image=""
    ThemeImageBackground.Visible=false
    themeImageInput.Text=""
    themeImageStatus.Text="Chưa chọn ảnh nền"
    themeImageStatus.TextColor3=T.Sub
    Theme.intensity=100
    Theme.brightness=100
    Theme.rgbSpeed=100
    Theme._rgbHue=0
    Theme._rgbAcc=0
    if themeModeDrop and themeModeDrop.Sync then themeModeDrop:Sync("Bình thường") end
    if themeIntensitySlider and themeIntensitySlider.Sync then themeIntensitySlider:Sync(100) end
    if themeBrightnessSlider and themeBrightnessSlider.Sync then themeBrightnessSlider:Sync(100) end
    if themeRGBSlider and themeRGBSlider.Sync then themeRGBSlider:Sync(100) end
    updateThemeControlVisibility()
    if ThemeColorOverlay and ThemeColorOverlay.Parent then pcall(function() ThemeColorOverlay:Destroy() end); ThemeColorOverlay=nil end
    themeApply()
    if applyScale then applyScale() end
    Main.AnchorPoint=Vector2.new(.5,.5)
    Main.Position=UDim2.fromScale(.5,.5)
    for _,pg in pairs(Pgs) do
        if pg:IsA("ScrollingFrame") then pg.CanvasPosition=Vector2.zero end
    end
end,true)

-- ═══════════════ BUILD INFO TAB ═══════════════
for _,c in ipairs(pInfo:GetChildren()) do
    if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
end
local function bIS(par,title,desc,ord)
    local c=Instance.new("Frame",par)
    c.Size=UDim2.new(1,0,0,0); c.AutomaticSize=Enum.AutomaticSize.Y
    c.BackgroundColor3=T.Panel; c.BorderSizePixel=0; c.LayoutOrder=ord
    cr(c,12); sk(c,T.Stroke,1)
    local hf=Instance.new("Frame",c)
    hf.Size=UDim2.new(1,0,0,48); hf.BackgroundTransparency=1
    local tl=Instance.new("TextLabel",hf)
    tl.Size=UDim2.new(1,-20,0,20); tl.Position=UDim2.fromOffset(14,6)
    tl.BackgroundTransparency=1; tl.Text=title; tl.Font=Enum.Font.GothamBold
    tl.TextSize=14; tl.TextColor3=T.Text; tl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",hf)
    dl.Size=UDim2.new(1,-20,0,16); dl.Position=UDim2.fromOffset(14,26)
    dl.BackgroundTransparency=1; dl.Text=desc or ""; dl.Font=Enum.Font.Gotham
    dl.TextSize=11; dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    local r=Instance.new("Frame",c)
    r.Size=UDim2.new(1,-20,0,0); r.Position=UDim2.fromOffset(10,48)
    r.BackgroundTransparency=1; r.AutomaticSize=Enum.AutomaticSize.Y
    local rl=Instance.new("UIListLayout",r)
    rl.Padding=UDim.new(0,4); rl.SortOrder=Enum.SortOrder.LayoutOrder
    local pd=Instance.new("Frame",c)
    pd.Size=UDim2.new(1,0,0,10); pd.Position=UDim2.new(0,0,1,0)
    pd.AnchorPoint=Vector2.new(0,1); pd.BackgroundTransparency=1
    return r
end
local iR=bIS(pInfo,"Thông tin Script","Tất cả thông tin về Dungdx PvP",1)
local function aIR(par,lbl,val,ord,cp)
    local r=Instance.new("Frame",par)
    r.Size=UDim2.new(1,0,0,40); r.BackgroundColor3=T.Card
    r.BorderSizePixel=0; r.LayoutOrder=ord; cr(r,8)
    local lL=Instance.new("TextLabel",r)
    lL.Size=UDim2.new(.45,-20,1,0); lL.Position=UDim2.fromOffset(12,0)
    lL.BackgroundTransparency=1; lL.Text=lbl; lL.Font=Enum.Font.GothamMedium
    lL.TextSize=12; lL.TextColor3=T.Sub; lL.TextXAlignment=Enum.TextXAlignment.Left
    local vL=Instance.new("TextLabel",r)
    vL.AnchorPoint=Vector2.new(1,.5)
    vL.Position=UDim2.new(1,cp and -46 or -12,.5,0)
    vL.Size=UDim2.new(.55,cp and -40 or -20,1,0)
    vL.BackgroundTransparency=1; vL.Text=val; vL.Font=Enum.Font.GothamBold
    vL.TextSize=12; vL.TextColor3=T.Text; vL.TextXAlignment=Enum.TextXAlignment.Right
    vL.TextTruncate=Enum.TextTruncate.AtEnd
    if cp then
        local cc=Instance.new("TextButton",r)
        cc.Size=UDim2.fromOffset(28,28); cc.AnchorPoint=Vector2.new(1,.5)
        cc.Position=UDim2.new(1,-8,.5,0); cc.BackgroundColor3=T.Panel
        cc.Text="📔"; cc.Font=Enum.Font.GothamBold; cc.TextSize=16
        cc.TextColor3=T.Accent; cc.BorderSizePixel=0; cc.AutoButtonColor=false
        cr(cc,6); sk(cc,T.Accent,1,.5)
        cc.MouseButton1Click:Connect(function()
            if setclipboard then pcall(function() setclipboard(val) end) end
            cc.Text="✅"; cc.TextColor3=T.Green
            task.wait(1.2); cc.Text="📔"; cc.TextColor3=T.Accent
        end)
    end
end
aIR(iR,"Tên Script","Dungdx PvP",1)
aIR(iR,"Phiên bản","v1.2",2)
aIR(iR,"Game hỗ trợ","Blox Fruits (Roblox)",3)
aIR(iR,"Chủ sở hữu","Dungdx",4)
aIR(iR,"Credit","by Dungdx",5)
aIR(iR,"Discord Server","Blox Community VN",6)
aIR(iR,"Link Discord","https://discord.gg/Hwwa3VYxW6",7,true)
local bC=Instance.new("Frame",pInfo)
bC.Size=UDim2.new(1,0,0,150); bC.BackgroundColor3=Color3.fromRGB(15,22,45)
bC.BorderSizePixel=0; bC.LayoutOrder=2; bC.ClipsDescendants=true
cr(bC,16); sk(bC,T.Accent,1,0.5)
local bG=Instance.new("UIGradient",bC)
bG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(37,99,235)),
    ColorSequenceKeypoint.new(0.45,Color3.fromRGB(30,42,76)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(15,22,45))
})
bG.Rotation=120
local sigBox=Instance.new("Frame",bC)
sigBox.Size=UDim2.fromOffset(92,92)
sigBox.Position=UDim2.new(0,24,.5,-46)
sigBox.BackgroundColor3=Color3.fromRGB(250,250,252)
sigBox.BorderSizePixel=0; cr(sigBox,20)
local sigStroke=Instance.new("UIStroke",sigBox)
sigStroke.Color=Color3.fromRGB(255,255,255)
sigStroke.Thickness=2; sigStroke.Transparency=.35
local sigImg=Instance.new("ImageLabel",sigBox)
sigImg.Size=UDim2.fromScale(1,1); sigImg.BackgroundTransparency=1
sigImg.Image=LOGO_IMG; sigImg.ScaleType=Enum.ScaleType.Fit
sigImg.ZIndex=2; cr(sigImg,20)
local nmL=Instance.new("TextLabel",bC)
nmL.Size=UDim2.new(1,-150,0,32)
nmL.Position=UDim2.fromOffset(132,34); nmL.BackgroundTransparency=1
nmL.Text="Dungdx"; nmL.Font=Enum.Font.GothamBlack; nmL.TextSize=26
nmL.TextColor3=Color3.fromRGB(255,255,255)
nmL.TextXAlignment=Enum.TextXAlignment.Left; nmL.ZIndex=2
local tgL=Instance.new("TextLabel",bC)
tgL.Size=UDim2.new(1,-150,0,18)
tgL.Position=UDim2.fromOffset(132,72); tgL.BackgroundTransparency=1
tgL.Text="Script PvP cho Blox Fruits"; tgL.Font=Enum.Font.GothamMedium
tgL.TextSize=13; tgL.TextColor3=T.Accent
tgL.TextXAlignment=Enum.TextXAlignment.Left; tgL.ZIndex=2
local vB=Instance.new("TextLabel",bC)
vB.Size=UDim2.fromOffset(64,24)
vB.AnchorPoint=Vector2.new(1,0); vB.Position=UDim2.new(1,-14,0,14)
vB.BackgroundColor3=Color3.fromRGB(255,255,255); vB.BackgroundTransparency=.88
vB.Text="v1.2"; vB.Font=Enum.Font.GothamBold; vB.TextSize=10
vB.TextColor3=Color3.fromRGB(255,255,255); vB.BorderSizePixel=0
vB.ZIndex=2; cr(vB,12)
local fR=bIS(pInfo,"Tính năng hiện có","Những tính năng chính của script",3)
local feats={
    {ic="⚔️", n="Combat",  d="Mục tiêu, FastAttack, Hitbox, AutoKen và hỗ trợ", c=Color3.fromRGB(239,68,68)},
    {ic="🎯", n="Macro",   d="Macro theo Melee, Sword, Gun và Demon Fruit", c=Color3.fromRGB(96,165,250)},
    {ic="🏃", n="Move",    d="Fly, Đi trên nước, Noclip, Tốc độ, Nhảy", c=Color3.fromRGB(52,211,153)},
    {ic="👁️", n="Visual",  d="Zoom vô hạn, Camera, ESP, Shader và VFX", c=Color3.fromRGB(167,139,250)},
    {ic="📂", n="Extend",  d="Emote và các chức năng mở rộng", c=Color3.fromRGB(167,139,250)},
    {ic="⚙️", n="Settings",d="Giao diện, Theme UI, Fix Lag và tùy chỉnh", c=Color3.fromRGB(251,191,36)},
    {ic="💠", n="Info",    d="Thông tin script và các mục điều hướng", c=Color3.fromRGB(244,114,182)},
}
for i,f in ipairs(feats) do
    local c=Instance.new("TextButton",fR)
    c.Size=UDim2.new(1,0,0,60); c.BackgroundColor3=T.Card
    c.Text=""; c.AutoButtonColor=false; c.BorderSizePixel=0
    c.BorderSizePixel=0; c.LayoutOrder=i; cr(c,10); sk(c,f.c,1.2,.3)
    local icF=Instance.new("Frame",c)
    icF.Size=UDim2.fromOffset(36,36); icF.Position=UDim2.fromOffset(10,12)
    icF.BackgroundColor3=f.c; icF.BackgroundTransparency=.82
    icF.BorderSizePixel=0; cr(icF,9)
    local icL=Instance.new("TextLabel",icF)
    icL.Size=UDim2.fromScale(1,1); icL.BackgroundTransparency=1
    icL.Text=f.ic; icL.Font=Enum.Font.GothamBold; icL.TextSize=20; icL.TextColor3=f.c
    local nL=Instance.new("TextLabel",c)
    nL.Size=UDim2.new(1,-90,0,16); nL.Position=UDim2.fromOffset(56,12)
    nL.BackgroundTransparency=1; nL.Text=f.n; nL.Font=Enum.Font.GothamBold
    nL.TextSize=13; nL.TextColor3=T.Text; nL.TextXAlignment=Enum.TextXAlignment.Left
    local dL=Instance.new("TextLabel",c)
    dL.Size=UDim2.new(1,-90,0,14); dL.Position=UDim2.fromOffset(56,30)
    dL.BackgroundTransparency=1; dL.Text=f.d; dL.Font=Enum.Font.Gotham
    dL.TextSize=10; dL.TextColor3=T.Sub; dL.TextXAlignment=Enum.TextXAlignment.Left
    dL.TextTruncate=Enum.TextTruncate.AtEnd
    local aL=Instance.new("TextLabel",c)
    aL.Size=UDim2.fromOffset(24,24); aL.AnchorPoint=Vector2.new(1,.5)
    aL.Position=UDim2.new(1,-10,.5,0); aL.BackgroundTransparency=1
    aL.Text=">"; aL.Font=Enum.Font.GothamBold; aL.TextSize=18; aL.TextColor3=T.Sub
    c.MouseButton1Click:Connect(function()
        local tabId = f.n
        if not Pgs[tabId] then return end
        for k,p in pairs(Pgs) do p.Visible=(k==tabId) end
        for k,fn in pairs(NBs) do fn(k==tabId) end
    end)
end
local foC=Instance.new("Frame",pInfo)
foC.Size=UDim2.new(1,0,0,88); foC.BackgroundColor3=T.Panel
foC.BorderSizePixel=0; foC.LayoutOrder=4; cr(foC,12); sk(foC,T.Stroke,1)
local hF=Instance.new("Frame",foC)
hF.Size=UDim2.fromOffset(44,44); hF.Position=UDim2.fromOffset(16,22)
hF.BackgroundColor3=T.Accent2; hF.BackgroundTransparency=.7
hF.BorderSizePixel=0; cr(hF,22); sk(hF,T.Accent,1,.4)
local hL=Instance.new("TextLabel",hF)
hL.Size=UDim2.fromScale(1,1); hL.BackgroundTransparency=1
hL.Text="❤️"; hL.Font=Enum.Font.GothamBold; hL.TextSize=22; hL.TextColor3=T.Accent
local tkL=Instance.new("TextLabel",foC)
tkL.Size=UDim2.new(1,-80,0,18); tkL.Position=UDim2.fromOffset(72,18)
tkL.BackgroundTransparency=1; tkL.Text="Cảm ơn bạn đã sử dụng script!"
tkL.Font=Enum.Font.GothamBold; tkL.TextSize=12; tkL.TextColor3=T.Text
tkL.TextXAlignment=Enum.TextXAlignment.Left
local wsL=Instance.new("TextLabel",foC)
wsL.Size=UDim2.new(1,-80,0,16); wsL.Position=UDim2.fromOffset(72,38)
wsL.BackgroundTransparency=1; wsL.Text="Chúc bạn có những trận PvP thật tuyệt vời!"
wsL.Font=Enum.Font.Gotham; wsL.TextSize=10; wsL.TextColor3=T.Sub
wsL.TextXAlignment=Enum.TextXAlignment.Left
local snL=Instance.new("TextLabel",foC)
snL.Size=UDim2.new(1,-80,0,14); snL.Position=UDim2.fromOffset(72,58)
snL.BackgroundTransparency=1; snL.Text="-- Dungdx"
snL.Font=Enum.Font.GothamMedium; snL.TextSize=11; snL.TextColor3=T.Accent
snL.TextXAlignment=Enum.TextXAlignment.Left

end

buildRefactoredTabs()
task.defer(function()
    if themeApply then themeApply() end
end)

-- Teleport tab and its UI have been removed as requested.

-- ═══════════════ EXTEND TAB ═══════════════
local function InitExtendTab(combatPage, extendPage, settingsPage)
    local v4 = game:GetService("ReplicatedStorage")

    local remotes
    for i=1,40 do
        remotes = v4:FindFirstChild("Remotes")
        if remotes then break end
        task.wait(0.5)
    end
    if not remotes then warn("[Extend] Không tìm thấy Remotes"); return false end
    local function safeWait(parent, name, timeout)
        if not parent then return nil end
        local ok, res = pcall(function() return parent:WaitForChild(name, timeout or 20) end)
        if ok and res then return res end
        return parent:FindFirstChild(name)
    end
    local commF = safeWait(remotes, "CommF_", 20)
    local commE = safeWait(remotes, "CommE", 20)
    local modules
    for i=1,40 do
        modules = v4:FindFirstChild("Modules")
        if modules then break end
        task.wait(0.5)
    end
    if not modules then warn("[Extend] Không tìm thấy Modules"); return false end
    local net = safeWait(modules, "Net", 20)
    local Net = net and require(net) or nil
    local RegisterHit = Net and Net:RemoteEvent("RegisterHit", true) or nil
    local reRegisterAttack = net and safeWait(net, "RE/RegisterAttack", 15) or nil
    pcall(function()
        local CombatUtil = require(modules:WaitForChild("CombatUtil", 15))
        if CombatUtil and CombatUtil.CanAttack and hookfunction then
            hookfunction(CombatUtil.CanAttack, function() return true end)
        end
    end)
    -- ═══════════════ AUTO KEN ═══════════════
    local autoKenConn = nil
    local autoKenDetectConn = nil
    local autoKenLast = 0
    local autoKenInterval = 0.5
    local autoKenDetectOn = false
    local autoKenRadius = 50

    local ATTACK_KEYWORDS = {"roar","slam","spin","bite","charge","breath","beam","laser","smash"}
    local function IsEntityAttacking(ent)
        if not ent or not ent.Parent then return false end
        local h = ent:FindFirstChildOfClass("Humanoid") or ent:FindFirstChildOfClass("AnimationController")
        h = h and h:FindFirstChildOfClass("Animator")
        if not h then return false end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do
            if t.IsPlaying and (t.WeightCurrent or 1) > 0.3 then
                local n = t.Name:lower()
                local a = t.Animation
                a = a and a.Name:lower() or ""
                for _, kw in ipairs(ATTACK_KEYWORDS) do
                    if n:find(kw) or a:find(kw) then return true end
                end
            end
        end
        return false
    end

    local function detectNearby(radius)
        local myChar = LP.Character
        if not myChar then return false end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return false end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character.Parent then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - myHRP.Position).Magnitude <= radius then
                    if IsEntityAttacking(p.Character) then return true end
                end
            end
        end
        return false
    end

    local function startAutoKen()
        if autoKenConn then autoKenConn:Disconnect(); autoKenConn = nil end
        if autoKenDetectConn then autoKenDetectConn:Disconnect(); autoKenDetectConn = nil end
        autoKenLast = 0
        autoKenConn = RS.Heartbeat:Connect(function()
            if not tbl.AutoKen then return end
            local now = tick()
            if now - autoKenLast < autoKenInterval then return end
            autoKenLast = now
            if commE then
                pcall(function() commE:FireServer("Ken", true) end)
            end
        end)
        autoKenDetectConn = RS.Heartbeat:Connect(function()
            if not tbl.AutoKen or not autoKenDetectOn then return end
            if detectNearby(autoKenRadius) and commE then
                pcall(function() commE:FireServer("Ken", true) end)
            end
        end)
    end
    local function stopAutoKen()
        tbl.AutoKen = false
        if autoKenConn then autoKenConn:Disconnect(); autoKenConn = nil end
        if autoKenDetectConn then autoKenDetectConn:Disconnect(); autoKenDetectConn = nil end
        syncFeatureUI("AutoKen",false)
    end

    -- Hitbox
    -- Fast Attack
    local BODY_PARTS = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
    local function tryEquipWeapon()
        local ch = LP.Character; if not ch then return nil end
        local cur = ch:FindFirstChildOfClass("Tool"); if cur then return cur end
        local bp = LP:FindFirstChild("Backpack"); if not bp then return nil end
        local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum then return nil end
        for _, tip in ipairs({"Melee","Sword","Blox Fruit","Gun"}) do
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == tip then
                    pcall(function() hum:EquipTool(tool) end); task.wait(0.05); return tool
                end
            end
        end
        return nil
    end
    local function getBodyHits(radius)
        local hits = {}
        local ch = LP.Character; if not ch then return hits end
        local myHRP = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart; if not myHRP then return hits end
        radius = radius or 50
        local bpName = BODY_PARTS[math.random(#BODY_PARTS)]
        local maxHits = 2
        if myHRP:FindFirstChild("Buddha") then maxHits = 10 end
        local pool = {}
        if tbl.AttackNPC then
            local enemies = WS:FindFirstChild("Enemies")
            if enemies then
                for _, npc in ipairs(enemies:GetChildren()) do
                    if not npc:GetAttribute("IsBoat") then
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                        if hum and hum.Health > 0 and hrp then
                            local d = (hrp.Position - myHRP.Position).Magnitude
                            if d <= radius then
                                local hitPart = npc:FindFirstChild(bpName) or hrp
                                table.insert(pool, {npc, hitPart, d})
                            end
                        end
                    end
                end
            end
        end
        if tbl.AttackPlayer then
            local tgt
            if tbl.SelectPlayer == "Nearest" or not tbl.SelectPlayer then
                local huge = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and hrp and not fn23(p) then
                            local d = (hrp.Position - myHRP.Position).Magnitude
                            if d < huge then huge = d; tgt = p end
                        end
                    end
                end
            else tgt = Players:FindFirstChild(tbl.SelectPlayer) end
            if tgt and tgt ~= LP and tgt.Character then
                local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
                local hrp = tgt.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d <= radius then
                        local hitPart = tgt.Character:FindFirstChild(bpName) or hrp
                        table.insert(pool, {tgt.Character, hitPart, d})
                    end
                end
            end
        end
        table.sort(pool, function(a, b) return a[3] < b[3] end)
        for i = 1, math.min(#pool, maxHits) do
            table.insert(hits, {pool[i][1], pool[i][2]})
        end
        return hits
    end
    local function doFastAttack()
        local ch = LP.Character; if not ch then return end
        local tool = ch:FindFirstChildOfClass("Tool")
        if not tool then tool = tryEquipWeapon() end
        if not tool then return end
        local tip = tool.ToolTip
        if not table.find({"Melee","Blox Fruit","Sword","Gun"}, tip) then return end
        local hits = getBodyHits(50)
        if #hits == 0 then return end
        if reRegisterAttack then pcall(function() reRegisterAttack:FireServer(tbl.FastAttackDelay or 0) end) end
        if tool:FindFirstChild("LeftClickRemote") then
            pcall(function() tool.LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true) end)
        end
        if RegisterHit then
            local tbl9 = {}
            local v20 = nil
            for _, v21 in ipairs(hits) do
                if v21[1] and v21[2] then table.insert(tbl9, v21); v20 = v20 or v21[2] end
            end
            if v20 then
                local uid = tostring(LP.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
                pcall(function() RegisterHit:FireServer(v20, tbl9, nil, nil, uid) end)
            end
        end
    end
    local fastAtkConn = nil
    local fastAtkInterval = 0.05
    local fastAtkLast = 0
    local function startFastAttack()
        if fastAtkConn then return end
        fastAtkConn = RS.Heartbeat:Connect(function()
            local now = tick()
            if now - fastAtkLast < fastAtkInterval then return end
            fastAtkLast = now
            pcall(doFastAttack)
        end)
    end
    local function stopFastAttack()
        if fastAtkConn then pcall(function() fastAtkConn:Disconnect() end); fastAtkConn = nil end
        syncFeatureUI("FastAttack",false)
    end

    local function switchTeam(team)
        if commF then pcall(function() commF:InvokeServer("SetTeam", team) end) end
    end

    -- ═══════════════ AUTO ESCAPE ═══════════════
    -- ═══════════════ SIMPLE SHADER (replaces original preset shader) ═══════════════
    -- Source below is the supplied SimpleShader.lua.txt, embedded unchanged.
    

    -- ═══════════════ EMOTE SYSTEM — Load 7yd7 Hub ═══════════════
    local EmoteLoader = {
        loaded = false,
        loading = false,
        scriptUrl = "https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua",
    }

    local function load7yd7Emotes()
        if EmoteLoader.loading then return false, "Đang tải..." end
        EmoteLoader.loading = true

        local missing = {}
        if not pcall(function() return game.HttpGet end) then table.insert(missing, "HttpGet") end
        if not pcall(function() return loadstring end) then table.insert(missing, "loadstring") end
        if #missing > 0 then
            EmoteLoader.loading = false
            return false, "Executor thiếu: " .. table.concat(missing, ", ")
        end

        local src = nil
        local dlOk = pcall(function()
            src = game:HttpGet(EmoteLoader.scriptUrl, true)
        end)
        if not dlOk or not src then
            EmoteLoader.loading = false
            return false, "Tải source thất bại (mạng? URL?)"
        end
        if type(src) ~= "string" or #src < 200 then
            EmoteLoader.loading = false
            return false, "Source quá ngắn: " .. tostring(#(src or "")) .. " bytes"
        end
        if src:find("404: Not Found") or src:sub(1, 15):find("<!DOCTYPE") then
            EmoteLoader.loading = false
            return false, "URL 404 — script 7yd7 dời chỗ rồi"
        end

        local fn = nil
        local compileOk, compileErr = pcall(function()
            fn = loadstring(src, "@Dungdx_7yd7_Loader")
        end)
        if not compileOk or not fn then
            EmoteLoader.loading = false
            return false, "Compile lỗi: " .. tostring(compileErr):sub(1, 100)
        end

        local execOk, execErr = pcall(fn)
        EmoteLoader.loading = false
        if not execOk then
            return false, "Runtime lỗi: " .. tostring(execErr):sub(1, 130)
        end

        EmoteLoader.loaded = true
        return true, nil
    end

    -- ═══════════════ UI SECTIONS ═══════════════
    local function getPlayersList()
        local t = {"Nearest"}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then table.insert(t, p.Name) end end
        return t
    end

    local e1 = mSec(combatPage, "Chọn mục tiêu", "Chọn người chơi để tác động", 1)
    local tRow = mRow(e1, 1); tRow.Size = UDim2.new(1, 0, 0, 44)
    local tLbl = Instance.new("TextLabel", tRow)
    tLbl.Size = UDim2.new(.5, 0, 1, 0); tLbl.Position = UDim2.fromOffset(12, 0)
    tLbl.BackgroundTransparency = 1; tLbl.Text = "Chọn người chơi"
    tLbl.Font = Enum.Font.GothamMedium; tLbl.TextSize = 12
    tLbl.TextColor3 = T.Text; tLbl.TextXAlignment = Enum.TextXAlignment.Left
    local tFrame = Instance.new("Frame", tRow)
    tFrame.Size = UDim2.fromOffset(160, 30)
    tFrame.Position = UDim2.new(1, -172, .5, -15)
    tFrame.BackgroundTransparency = 1
    local targetSetter = mkDD(tFrame, getPlayersList, "Nearest", function(v) tbl.SelectPlayer = v end)
    mBtn(e1, "Làm mới danh sách", "Cập nhật danh sách người chơi", "Làm mới", 2, function()
        if targetSetter then targetSetter(tbl.SelectPlayer) end
    end)

    local e2 = mSec(combatPage, "Khóa Camera & Xem người chơi", "Camera tự động hướng về mục tiêu", 5)
    FeatureControl.ui.CamLock = mTog(e2, "Khóa Camera", "Camera tự động hướng về mục tiêu", false, 1, function(v) OnCamLockToggle(v) end)
    FeatureControl.ui.Spectate = mTog(e2, "Xem người chơi", "Xem góc nhìn của người chơi được chọn", false, 2, function(v) OnSpectateToggle(v) end)

    local e3 = mSec(combatPage, "Mở rộng Hitbox", "Mở rộng hitbox để đánh trúng dễ hơn", 4)
    mTog(e3, "Mở rộng Hitbox", "Mở rộng Hitbox người chơi khác", false, 1, function(v)
        if v then hitboxStart() else hitboxStop() end
    end)
    mSld(e3, "Kích thước Hitbox", "Kích thước hitbox (studs)", 5, 50, 15, 2, function(v)
        Hitbox.Size = v
        if Hitbox.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.Size = Vector3.new(v, v, v) end
                end
            end
        end
    end)

    local e4 = mSec(combatPage, "Đánh nhanh", "Đánh nhanh người chơi và NPC", 2)
    FeatureControl.ui.FastAttack=mTog(e4, "Đánh nhanh", "Bật đánh nhanh", false, 1, function(v)
        if v then startFastAttack() else stopFastAttack() end
    end)
    mTog(e4, "Đánh NPC", "Đánh NPC trong bán kính", true, 2, function(v) tbl.AttackNPC = v end)
    mTog(e4, "Đánh người chơi", "Đánh người chơi mục tiêu", true, 3, function(v) tbl.AttackPlayer = v end)
    mSld(e4, "Tốc độ đánh (Hz)", "Số lần đánh mỗi giây", 1, 30, 20, 4, function(v) fastAtkInterval = 1 / v end)
    mSld(e4, "Độ trễ đánh nhanh (ms)", "Độ trễ trước khi tấn công", 0, 500, 0, 5, function(v) tbl.FastAttackDelay = v / 1000 end)

    local e5 = mSec(combatPage, "Auto Ken", "Tự động bật Ken liên tục", 3)
    FeatureControl.ui.AutoKen=mTog(e5, "Bật Auto Ken", "Fire Ken mỗi 0.5s", false, 1, function(v)
        if v then
            tbl.AutoKen = true
            startAutoKen()
        else
            stopAutoKen()
        end
    end)
    mTog(e5, "Ken khi có đòn tấn công", "Ken thêm khi phát hiện animation tấn công", false, 2, function(v) autoKenDetectOn = v end)
    mSld(e5, "Khoảng thời gian Ken (x100ms)", "Chu kỳ fire Ken (x0.1s)", 1, 30, 5, 3, function(v) autoKenInterval = v / 10 end)
    mSld(e5, "Bán kính phát hiện", "Bán kính phát hiện đối thủ", 20, 200, 50, 4, function(v) autoKenRadius = v end)

    local e7 = mSec(combatPage, "Chống AFK", "Chống bị kick AFK", 12)
    FeatureControl.ui.AntiAFK=mTog(e7, "Chống AFK", "Chỉ chạy khi bạn chủ động bật", false, 1, function(v) ToggleAntiAFK(v) end)
    ToggleAntiAFK(false)

    local e8 = mSec(combatPage, "Đội & Camera", "Đổi phe", 11)
    mBtn(e8, "Vào Hải Tặc", "Đổi sang phe Hải Tặc", "Hải Tặc", 1, function() switchTeam("Pirates") end)
    mBtn(e8, "Vào Hải Quân", "Đổi sang phe Hải Quân", "Hải Quân", 2, function() switchTeam("Marines") end)

    local e12 = mSec(combatPage, "Auto Escape", "Tự động chạy trốn khi HP thấp", 10)
    FeatureControl.ui.AutoEscape=mTog(e12, "Bật Auto Escape", "Khi HP thấp tự động teleport đi xa", false, 1, function(v)
        Escape.enabled = v
        if v then startEscape() else stopEscape() end
    end)
    mSld(e12, "Ngưỡng HP (%)", "Kích hoạt khi HP dưới mức này", 10, 90, 30, 2, function(v) Escape.hpThreshold = v end)
    mSld(e12, "Khoảng cách TP", "Khoảng cách teleport khi trốn (studs)", 50, 500, 200, 3, function(v) Escape.tpDist = v end)
    mSld(e12, "Cooldown (x100ms)", "Thời gian chờ giữa các lần TP", 1, 30, 10, 4, function(v) Escape.cooldown = v/10 end)

    local e13 = mSec(settingsPage, "FPS & Ping", "Hiển thị FPS và Ping trên màn hình", 14)
    FeatureControl.ui.FPS=mTog(e13, "Hiển thị FPS & Ping", "Bật/tắt bộ đếm FPS và Ping", false, 1, function(v)
        if v then startFPSCounter() else stopFPSCounter() end
    end)

    local e14 = mSec(pVisual, "Shader — Simple Shader", "Shader gốc và hiệu ứng dự phòng có thể khôi phục", 4)
    local shaderStatusRow = mRow(e14, 1); shaderStatusRow.Size = UDim2.new(1,0,0,44)
    local shaderStatusLbl = Instance.new("TextLabel", shaderStatusRow)
    shaderStatusLbl.Size = UDim2.new(1,-24,1,0); shaderStatusLbl.Position = UDim2.fromOffset(12,0)
    shaderStatusLbl.BackgroundTransparency = 1; shaderStatusLbl.Text = "Trạng thái: Tắt"
    shaderStatusLbl.Font = Enum.Font.GothamMedium; shaderStatusLbl.TextSize = 11
    shaderStatusLbl.TextColor3 = T.Sub; shaderStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    SimpleShader.statusLabel = shaderStatusLbl
    FeatureControl.ui.Shader=mTog(e14, "Bật Shader ổn định", "Bật/tắt hiệu ứng Lighting tích hợp", false, 2, function(v)
        if v then
            local callOk, started, detail = pcall(startSimpleShader)
            if not callOk then
                detail = started
                started = false
            end
            if not started then
                SimpleShader.enabled = false
                SimpleShader.status = "Lỗi shader: " .. tostring(detail):sub(1,100)
                updateSimpleShaderStatusLabel()
                shaderStatusLbl.Text = "Trạng thái: " .. tostring(SimpleShader.status)
                shaderStatusLbl.TextColor3 = T.Danger
                warn("[SimpleShader] Không bật được: " .. tostring(detail))
                task.defer(function()
                    if FeatureControl.ui.Shader and not SimpleShader.enabled then
                        FeatureControl.ui.Shader:Sync(false)
                    end
                end)
            else
                SimpleShader.enabled = true
                updateSimpleShaderStatusLabel()
                shaderStatusLbl.Text = "Trạng thái: " .. tostring(SimpleShader.status)
                shaderStatusLbl.TextColor3 = T.Green
            end
        else
            local stopOk, stopErr = pcall(stopSimpleShader)
            if not stopOk then
                SimpleShader.enabled = false
                SimpleShader.status = "Lỗi khi tắt shader: " .. tostring(stopErr):sub(1,90)
                warn("[SimpleShader Stop] " .. tostring(stopErr))
            end
            updateSimpleShaderStatusLabel()
            shaderStatusLbl.Text = "Trạng thái: " .. tostring(SimpleShader.status)
            shaderStatusLbl.TextColor3 = (SimpleShader.status == "Tắt") and T.Sub or T.Danger
        end
    end)
    local shaderToggle=FeatureControl.ui.Shader
    mBtn(e14, "Tắt & khôi phục", "Dừng shader và khôi phục Lighting/Terrain đã lưu", "Tắt", 3, function()
        shaderToggle.Set(false)
        stopSimpleShader()
        shaderStatusLbl.Text = "Trạng thái: Tắt"
        shaderStatusLbl.TextColor3 = T.Sub
    end, true)


    local eVFX = mSec(pVisual, "🌈 Đổi màu VFX", "Đổi màu VFX skill của nhân vật", 5)
    FeatureControl.ui.VFX=mTog(eVFX, "🌈 Đổi màu VFX", "Đổi màu VFX skill của nhân vật", false, 1, function(v)
        if v then startVFX() else stopVFX() end
    end)
    mTog(eVFX, "Ảnh hưởng người khác", "Cho phép bắt VFX gần người chơi khác/NPC", false, 2, function(v)
        VFXColor.tintOthers=v
    end)
    local cRow=mRow(eVFX,3)
    cRow.Size=UDim2.new(1,0,0,76)
    local cTitle=Instance.new("TextLabel",cRow)
    cTitle.Size=UDim2.new(1,-140,0,18); cTitle.Position=UDim2.fromOffset(12,7)
    cTitle.BackgroundTransparency=1; cTitle.Text="Màu VFX hiện tại"
    cTitle.Font=Enum.Font.GothamMedium; cTitle.TextSize=11; cTitle.TextColor3=T.Sub
    cTitle.TextXAlignment=Enum.TextXAlignment.Left
    local previewButton=Instance.new("TextButton",cRow)
    previewButton.Size=UDim2.fromOffset(44,34); previewButton.Position=UDim2.fromOffset(12,32)
    previewButton.BackgroundColor3=VFXColor.color; previewButton.Text=""
    previewButton.AutoButtonColor=false; previewButton.BorderSizePixel=0
    cr(previewButton,9); sk(previewButton,T.Stroke,1)
    local previewLabel=Instance.new("TextLabel",cRow)
    previewLabel.Size=UDim2.new(1,-180,0,34); previewLabel.Position=UDim2.fromOffset(68,32)
    previewLabel.BackgroundTransparency=1
    previewLabel.Text=string.format("#%02X%02X%02X",
        math.floor(VFXColor.color.R*255+.5),math.floor(VFXColor.color.G*255+.5),math.floor(VFXColor.color.B*255+.5))
    previewLabel.Font=Enum.Font.GothamBold; previewLabel.TextSize=14; previewLabel.TextColor3=T.Text
    previewLabel.TextXAlignment=Enum.TextXAlignment.Left
    local chooseColor=Instance.new("TextButton",cRow)
    chooseColor.Size=UDim2.fromOffset(96,34); chooseColor.Position=UDim2.new(1,-108,0,32)
    chooseColor.BackgroundColor3=T.CardHi; chooseColor.Text="Chọn màu"
    chooseColor.TextColor3=T.Text; chooseColor.Font=Enum.Font.GothamBold
    chooseColor.TextSize=11; chooseColor.AutoButtonColor=false; chooseColor.BorderSizePixel=0
    cr(chooseColor,9); sk(chooseColor,T.Stroke,1)
    VFXColor.previewFrame=previewButton
    VFXColor.previewLabel=previewLabel
    previewButton.MouseButton1Click:Connect(openVFXColorPicker)
    chooseColor.MouseButton1Click:Connect(openVFXColorPicker)

    -- ═══════════════ EMOTE SYSTEM — 7yd7 ═══════════════
    local e16 = mSec(extendPage, "🎭 Emote System (7yd7)", "Mở menu emote 7yd7 — Full emote + animation UGC", 16)

    local eStatusRow = mRow(e16, 1); eStatusRow.Size = UDim2.new(1, 0, 0, 60)
    local eStatusLbl = Instance.new("TextLabel", eStatusRow)
    eStatusLbl.Size = UDim2.new(.55, -20, 1, 0); eStatusLbl.Position = UDim2.fromOffset(12, 0)
    eStatusLbl.BackgroundTransparency = 1
    eStatusLbl.Text = "Chưa mở menu 7yd7"
    eStatusLbl.Font = Enum.Font.GothamBold; eStatusLbl.TextSize = 12
    eStatusLbl.TextColor3 = T.Sub; eStatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    local eStatusSub = Instance.new("TextLabel", eStatusRow)
    eStatusSub.Size = UDim2.new(.55, -20, 0, 14); eStatusSub.Position = UDim2.fromOffset(12, 28)
    eStatusSub.BackgroundTransparency = 1
    eStatusSub.Text = "Bấm nút để mở menu emote"
    eStatusSub.Font = Enum.Font.Gotham; eStatusSub.TextSize = 10
    eStatusSub.TextColor3 = T.Sub; eStatusSub.TextXAlignment = Enum.TextXAlignment.Left

    local eOpenBtn = Instance.new("TextButton", eStatusRow)
    eOpenBtn.Size = UDim2.fromOffset(140, 36); eOpenBtn.AnchorPoint = Vector2.new(1, .5)
    eOpenBtn.Position = UDim2.new(1, -12, .5, 0)
    eOpenBtn.BackgroundColor3 = T.Accent2
    eOpenBtn.Text = "🎭 Mở menu Emote"
    eOpenBtn.Font = Enum.Font.GothamBold; eOpenBtn.TextSize = 12
    eOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    eOpenBtn.BorderSizePixel = 0; eOpenBtn.AutoButtonColor = false
    cr(eOpenBtn, 9); sk(eOpenBtn, T.Accent, 1.2, 0.2)

    eOpenBtn.MouseButton1Click:Connect(function()
        if EmoteLoader.loading then return end
        eOpenBtn.Text = "⏳ Đang mở..."
        eOpenBtn.BackgroundColor3 = T.Sub
        eStatusLbl.Text = "Đang tải menu 7yd7..."
        eStatusLbl.TextColor3 = T.Accent
        eStatusSub.Text = "Emotes.lua từ 7yd7 Hub"
        eStatusSub.TextColor3 = T.Sub
        task.spawn(function()
            local ok, err = load7yd7Emotes()
            if ok then
                eOpenBtn.Text = "✓ Đã mở"
                eOpenBtn.BackgroundColor3 = T.Green
                eStatusLbl.Text = "Menu 7yd7 đã mở — Nhấn phím emote game để xem"
                eStatusLbl.TextColor3 = T.Green
                eStatusSub.Text = "Nhấn phím B (hoặc phím Emote) để mở wheel"
                eStatusSub.TextColor3 = T.Green
            else
                eOpenBtn.Text = "⚠ Lỗi"
                eOpenBtn.BackgroundColor3 = T.Danger
                eStatusLbl.Text = "Không tải được script 7yd7"
                eStatusLbl.TextColor3 = T.Danger
                eStatusSub.Text = tostring(err):sub(1, 200)
                eStatusSub.TextColor3 = T.Danger
                eStatusSub.TextWrapped = true
                eStatusSub.Size = UDim2.new(.55, -20, 0, 30)
                warn("[Dungdx Emote] " .. tostring(err))
            end
            task.wait(3)
            eOpenBtn.Text = "🎭 Mở menu Emote"
            eOpenBtn.BackgroundColor3 = T.Accent2
        end)
    end)

    mBtn(e16, "🔄 Tải lại menu Emote", "Bấm nếu menu bị lỗi hoặc không hiện", "Reload", 2, function()
        if EmoteLoader.loading then return end
        eStatusLbl.Text = "Đang reload..."
        eStatusLbl.TextColor3 = T.Accent
        task.spawn(function()
            local ok, err = load7yd7Emotes()
            if ok then
                eStatusLbl.Text = "Đã reload menu 7yd7"
                eStatusLbl.TextColor3 = T.Green
            else
                eStatusLbl.Text = "Reload thất bại: " .. tostring(err):sub(1, 60)
                eStatusLbl.TextColor3 = T.Danger
            end
        end)
    end)

    mBtn(e16, "📖 Hướng dẫn sử dụng", "Cách dùng menu emote 7yd7", "Xem", 3, function()
        local overlay = Instance.new("Frame", GUI)
        overlay.Name = "EmoteHelpOverlay"
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 0.5
        overlay.BorderSizePixel = 0
        overlay.ZIndex = 9100
        overlay:SetAttribute("__NoPressScale", true)

        local modal = Instance.new("Frame", overlay)
        modal.AnchorPoint = Vector2.new(.5, .5)
        modal.Position = UDim2.fromScale(.5, .5)
        modal.Size = UDim2.fromOffset(400, 340)
        modal.BackgroundColor3 = Color3.fromRGB(26, 30, 45)
        modal.BorderSizePixel = 0
        modal.ZIndex = 9101
        modal:SetAttribute("__NoPressScale", true)
        cr(modal, 14); sk(modal, Color3.fromRGB(80, 100, 160), 1.5)

        local title = Instance.new("TextLabel", modal)
        title.Size = UDim2.new(1, -24, 0, 30)
        title.Position = UDim2.fromOffset(12, 12)
        title.BackgroundTransparency = 1
        title.Text = "📖 Hướng dẫn dùng menu Emote"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextColor3 = T.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = 9102

        local content = Instance.new("TextLabel", modal)
        content.Size = UDim2.new(1, -24, 1, -80)
        content.Position = UDim2.fromOffset(12, 48)
        content.BackgroundTransparency = 1
        content.Text = [[Bước 1: Bấm "🎭 Mở menu Emote" để load script 7yd7.

Bước 2: Chờ 3-5 giây cho menu load xong.

Bước 3: Trong game, nhấn nút Emote (thường là "B" trên PC, hoặc nút Emote trên mobile) để mở Emote Wheel.

Bước 4: Menu 7yd7 sẽ thay thế wheel mặc định. Bạn có thể:
   • Bấm emote để phát
   • Tìm kiếm theo tên / ID
   • Đánh dấu yêu thích (Favorite)
   • Đổi theme, chỉnh speed
   • Tạo Custom Animation Set
   • Edit HUD vị trí các nút

Lưu ý:
• Một số game chặn script → menu có thể không hiện
• Nếu menu lỗi, bấm "🔄 Tải lại menu Emote"
• Nếu vẫn lỗi, thử rejoin game rồi bấm lại

Cần nhấn phím emote của game (không phải script) để menu bật lên!]]
        content.Font = Enum.Font.Gotham
        content.TextSize = 11
        content.TextColor3 = T.Text
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = true
        content.ZIndex = 9102

        local closeBtn = Instance.new("TextButton", modal)
        closeBtn.Size = UDim2.new(1, -24, 0, 36)
        closeBtn.Position = UDim2.fromOffset(12, 290)
        closeBtn.BackgroundColor3 = T.Accent
        closeBtn.Text = "Đã hiểu"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 12
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = false
        closeBtn.ZIndex = 9102
        cr(closeBtn, 8)

        closeBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)
        overlay.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch
                or i.UserInputType == Enum.UserInputType.MouseButton1 then
                local mPos = modal.AbsolutePosition
                local mSize = modal.AbsoluteSize
                local p = i.Position
                if p.X < mPos.X or p.X > mPos.X + mSize.X
                    or p.Y < mPos.Y or p.Y > mPos.Y + mSize.Y then
                    overlay:Destroy()
                end
            end
        end)
    end)

    mBtn(e16, "⚡ Mở wheel ngay", "Tự nhấn phím B để mở emote wheel", "Mở", 4, function()
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.B, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.B, false, game)
        end)
    end)

    -- Auto reset khi respawn
    trackPersistent(LP.CharacterAdded:Connect(function()
        task.wait(0.5)
        if FlyCam.enabled then pcall(function() flycamStop() end) end
    end))
    trackPersistent(LP.CharacterAdded:Connect(function()
        task.wait(0.3)
        if Escape.enabled then Escape.lastTP = tick() end
    end))

    FeatureControl.stopTargetTween = tweenStop
    FeatureControl.stopManualTween = function()
        end
    ExtShared.tbl = tbl
    ExtShared.FlyCam = FlyCam
    ExtShared.flycamStop = flycamStop
    ExtShared.flycamReady.start = flycamStart
    ExtShared.flycamReady.stop = flycamStop
    ExtShared.povReady.start = povStart
    ExtShared.povReady.stop = povStop
    ExtShared.povReady.set = povSet
        ExtShared.cleanup = function()
        pcall(function() OnCamLockToggle(false) end)
        pcall(function() OnSpectateToggle(false) end)
        pcall(function() flycamStop() end)
        pcall(function() hitboxStop() end)
        pcall(function() stopAutoKen() end)
        pcall(function() tbl.AntiAFK = false end)
        pcall(function() tweenStop() end)
        pcall(function() stopFastAttack() end)
        pcall(function() if VFXColor.enabled then stopVFX() end end)
        pcall(function() stopEscape() end)
        pcall(function() stopFPSCounter() end)
        pcall(function() stopSimpleShader() end)
        pcall(function() povStop() end)
        FeatureControl.stopTargetTween = nil
        if FPSCounter.gui then pcall(function() FPSCounter.gui:Destroy() end) end
    end
    return true
end

local extOk, extErr = pcall(InitExtendTab, pCombat, pExt, pSet)
if not extOk then
    warn("[Extend Error] " .. tostring(extErr))
    local errLbl = Instance.new("TextLabel", pExt)
    errLbl.Size = UDim2.new(1,0,0,80)
    errLbl.BackgroundColor3 = T.Danger
    errLbl.Text = "Lỗi Extend Tab:\n"..tostring(extErr):sub(1,200)
    errLbl.TextColor3 = Color3.new(1,1,1)
    errLbl.Font = Enum.Font.GothamBold; errLbl.TextSize = 11
    errLbl.TextWrapped = true; errLbl.LayoutOrder = 1
    cr(errLbl, 10)
end

-- ═══════════════ NEON + PRESS ═══════════════
local Ne = {en=false,pr=true,tb=.8,pu=true}
local function nz(c)
    local h,s,v=Color3.toHSV(c)
    s=math.min(1,s*1.4+.15); v=math.min(1,v*1.15+.25)
    return Color3.fromHSV(h,s,v)
end
local function nSt(st)
    if not st or not st.Parent then return end
    if st:GetAttribute("__n") then return end
    st:SetAttribute("__n",true)
    local b=st.Color; local br=nz(b); st.Transparency=0
    if st.Thickness<1.5+Ne.tb then st.Thickness=1.5+Ne.tb end
    st.Color=br
    local g=Instance.new("UIGradient",st); g.Name="__ng"
    g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,br),
        ColorSequenceKeypoint.new(.5,Color3.new(math.min(1,br.R+.3),math.min(1,br.G+.3),math.min(1,br.B+.3))),
        ColorSequenceKeypoint.new(1,br),
    })
    g.Rotation=45
end
local function atP(b)
    if not b or not b.Parent then return end
    if b:GetAttribute("__NoPressScale") then return end
    if b:FindFirstAncestor("VFXColorOverlay") then return end
    if not b:IsDescendantOf(Main) then return end
    if b:GetAttribute("__p") then return end
    b:SetAttribute("__p",true)
    local t=b
    if b:IsA("GuiObject") and b.BackgroundTransparency>=.9 then
        local p=b.Parent
        if p and p:IsA("GuiObject") then t=p end
    end
    if t:GetAttribute("__NoPressScale") then return end
    if t:FindFirstAncestor("VFXColorOverlay") then return end
    local s=t:FindFirstChildOfClass("UIScale")
    if not s then s=Instance.new("UIScale",t); s.Scale=1 end
    local pr=false
    local function dn() pr=true; TW:Create(s,TweenInfo.new(.07),{Scale=.93}):Play() end
    local function up() if not pr then return end; pr=false; TW:Create(s,TweenInfo.new(.18,Enum.EasingStyle.Back),{Scale=1}):Play() end
    b.MouseButton1Down:Connect(dn); b.MouseButton1Up:Connect(up); b.MouseLeave:Connect(up)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then dn() end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then up() end end)
end
local function scN()
    for _,i in ipairs(GUI:GetDescendants()) do
        if i:IsA("UIStroke") and Ne.en then nSt(i)
        elseif (i:IsA("TextButton") or i:IsA("ImageButton")) and Ne.pr then atP(i) end
    end
end
local uiDescendantAddedConn=trackPersistent(GUI.DescendantAdded:Connect(function(i)
    task.defer(function()
        if i:IsA("UIStroke") and Ne.en then nSt(i)
        elseif (i:IsA("TextButton") or i:IsA("ImageButton")) and Ne.pr then atP(i) end
    end)
end))
scN()

local Tgl=Instance.new("TextButton",GUI)
Tgl.Size=UDim2.fromOffset(58,58); Tgl.Position=UDim2.new(0,16,.5,-29)
Tgl.BackgroundColor3=T.Accent2; Tgl.Text=""; Tgl.BorderSizePixel=0
Tgl.AutoButtonColor=false; Tgl.Visible=false; cr(Tgl,29)
sk(Tgl,T.Accent,2,.3)
gr(Tgl,Color3.fromRGB(96,165,250),Color3.fromRGB(37,99,235))
dg(Tgl)
local tImg=Instance.new("ImageLabel",Tgl)
tImg.Size=UDim2.fromScale(1,1); tImg.BackgroundTransparency=1
tImg.Image=AVATAR; tImg.ScaleType=Enum.ScaleType.Crop; tImg.ZIndex=2; cr(tImg,29)
-- Only the floating reopen button remains when the main UI is hidden.
-- The external "by Dungdx" label was removed; credit remains in the Info tab.
_G.__tgl=Tgl
Tgl.MouseButton1Click:Connect(function()
    Main.Visible=true; Tgl.Visible=false
    if Theme.mode=="RGB" then themeApply() end
end)
Cl.MouseButton1Click:Connect(function()
    local api=_G.DungdxPvP
    if api and api.Destroy then pcall(function() api:Destroy() end) else GUI:Destroy() end
end)
Mn.MouseButton1Click:Connect(function() Main.Visible=false; Tgl.Visible=true end)
trackPersistent(UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        Main.Visible=not Main.Visible
        Tgl.Visible=not Main.Visible
    end
end))
task.defer(applyScale); task.delay(.1,applyScale)

trackPersistent(RS.RenderStepped:Connect(function(dt)
    if _G.__themeHeartbeat then _G.__themeHeartbeat(dt) end
end))

task.spawn(function()
    pcall(function() CP:PreloadAsync({AVATAR,LOGO_IMG}) end)
    task.wait(.3)
    for _,inst in ipairs(GUI:GetDescendants()) do
        if inst:IsA("ImageLabel") and (inst.Image==AVATAR or inst.Image==LOGO_IMG) then
            local old=inst.Image; inst.Image=""; task.wait(.05); inst.Image=old
        end
    end
end)

trackPersistent(UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.F then
        if Mv.Fly.enabled then flyStop() else flyStart() end
    end
end))

_G.DungdxPvP = {
    GUI=GUI, Main=Main, Theme=T, Macros=M, Refresh=refreshM, FixLag=FeatureControl.FIX,
    Movement=Mv, UI=UI, VFXColor=VFXColor, Extend=ExtShared.tbl,
    FlyCam = ExtShared.FlyCam,
    FlyCamStop = ExtShared.flycamStop,
    POV = POV,
    POVStart = povStart,
    POVStop = povStop,
    Destroy=function()
        STP=true
        RUN=false
        RM=nil
        for _,p in ipairs(Players:GetPlayers()) do rmESP(p) end
        pcall(function() if Mv.Fly.enabled then flyStop() end end)
        pcall(function() if Mv.Water.enabled then waterStop() end end)
        pcall(function() if Mv.Noclip.enabled then noclipStop() end end)
        pcall(function() tweenStop() end)
            pcall(function() tweenNoClipStop() end)
        pcall(function() if VFXColor.enabled then stopVFX() end end)
        pcall(function() if FeatureControl.disableFix then FeatureControl.disableFix() end end)
        pcall(function() ToggleAntiAFK(false) end)
        pcall(function() if FeatureControl.cleanupMovement then FeatureControl.cleanupMovement() end end)
        pcall(function() stopSimpleShader() end)
        pcall(function() povStop() end)
        pcall(function() if FeatureControl.restoreZoom then FeatureControl.restoreZoom() end end)
        pcall(function() if cameraViewportConn then cameraViewportConn:Disconnect(); cameraViewportConn=nil end end)
        pcall(function() if headerMetricsConn then headerMetricsConn:Disconnect(); headerMetricsConn=nil end end)
        pcall(function() if themeTrackAddedConn then themeTrackAddedConn:Disconnect(); themeTrackAddedConn=nil end end)
        if ExtShared.cleanup then pcall(ExtShared.cleanup) end
        for _, conn in ipairs(persistentConnections) do pcall(function() conn:Disconnect() end) end
        table.clear(persistentConnections)
        if espRenderConn then pcall(function() espRenderConn:Disconnect() end); espRenderConn=nil end
        if uiDescendantAddedConn then pcall(function() uiDescendantAddedConn:Disconnect() end); uiDescendantAddedConn=nil end
        if themeTrackRemovingConn then pcall(function() themeTrackRemovingConn:Disconnect() end); themeTrackRemovingConn=nil end
        pcall(function()
            for _, c in ipairs(GUI:GetChildren()) do
                if c.Name == "VFXColorOverlay" or c.Name == "ThemeColorOverlay" or c.Name == "EmoteHelpOverlay" then c:Destroy() end
            end
            ThemeColorOverlay=nil
            _G.__themeHeartbeat=nil
        end)
        pcall(function() GUI:Destroy() end)
        _G.DungdxPvP=nil; _G.__tgl=nil
    end
}

print("[Dungdx PvP] UI/Performance update loaded · 7 tabs")
