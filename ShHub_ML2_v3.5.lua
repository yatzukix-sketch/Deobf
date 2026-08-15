-- ══════════════════════════════════════════════════════════════
-- nuggiez private • Muscle Legends 2
-- ══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- EXECUTOR UYUMLULUK
-- ════════════════════════════════════════════════════════════

local getnil = rawget(getfenv(), "getnilinstances")
 or rawget(getfenv(), "get_nil_instances")
 or rawget(getfenv(), "getnilinstance")
if type(getnil) ~= "function" then getnil = function() return {} end end

local function httpGet(url)
 if syn and syn.request then
 local r = syn.request({ Url = url, Method = "GET" })
 return r and r.Body
 end
 return game:HttpGet(url)
end

-- ════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ════════════════════════════════════════════════════════════

local CLR = {
 zemin="#030a14", baslik="#22aaff", grad1="#70c8ff", grad2="#1e88ff",
 grad3="#003d8f", alt="#57a0c2", barZemin="#0a1a2a", bar1="#52a2ff",
 bar2="#0066d6", durum="#4a7fa0", yuzde="#40a0ff", ipucu="#3d6f8a",
 stroke="#2e8eff", sari="#ffcc00", hata="#ff4d4d",
}

local function getGuiParent()
 if gethui then local ok,r = pcall(gethui); if ok and r then return r end end
 if pcall(function() return game:GetService("CoreGui").Name end) then return game:GetService("CoreGui") end
 return LocalPlayer:WaitForChild("PlayerGui")
end

local function resolveTexture(id,w,h)
 return "rbxthumb://type=Asset&id="..tostring(id).."&w="..(w or 420).."&h="..(h or 420)
end

local Loading, LOGO_TEXTURE
do
local function createLoading()
 local gui = Instance.new("ScreenGui")
 gui.Name="nuggiezLoading"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=9999

 local bg = Instance.new("Frame")
 bg.Size=UDim2.fromScale(1,1); bg.BackgroundColor3=Color3.fromHex(CLR.zemin)
 bg.BackgroundTransparency=1; bg.BorderSizePixel=0; bg.Parent=gui

 local ct = Instance.new("Frame")
 ct.AnchorPoint=Vector2.new(0.5,0.5); ct.Position=UDim2.fromScale(0.5,0.43)
 ct.Size=UDim2.fromOffset(340,260); ct.BackgroundTransparency=1; ct.Parent=bg

 local logo = Instance.new("ImageLabel")
 logo.AnchorPoint=Vector2.new(0.5,0); logo.Position=UDim2.new(0.5,0,0,0)
 logo.Size=UDim2.fromOffset(96,96); logo.BackgroundTransparency=1
 logo.Image="rbxthumb://type=Asset&id=133925002151622&w=420&h=420"
 logo.ImageTransparency=1; logo.ScaleType=Enum.ScaleType.Fit; logo.Parent=ct
 Instance.new("UICorner",logo).CornerRadius=UDim.new(0,20)
 local ls=Instance.new("UIStroke"); ls.Color=Color3.fromHex(CLR.stroke)
 ls.Thickness=1.5; ls.Transparency=1; ls.Parent=logo
 local lsc=Instance.new("UIScale"); lsc.Scale=0.6; lsc.Parent=logo

 local title=Instance.new("TextLabel")
 title.Position=UDim2.new(0,0,0,108); title.Size=UDim2.new(1,0,0,42)
 title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack
 title.TextSize=34; title.TextColor3=Color3.fromHex(CLR.baslik)
 title.Text="nuggiez"; title.TextTransparency=1; title.Parent=ct
 local tg=Instance.new("UIGradient")
 tg.Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromHex(CLR.grad1)),
 ColorSequenceKeypoint.new(0.5,Color3.fromHex(CLR.grad2)),
 ColorSequenceKeypoint.new(1,Color3.fromHex(CLR.grad3)),
 }); tg.Parent=title

 local sub=Instance.new("TextLabel")
 sub.Position=UDim2.new(0,0,0,152); sub.Size=UDim2.new(1,0,0,16)
 sub.BackgroundTransparency=1; sub.Font=Enum.Font.Gotham; sub.TextSize=13
 sub.TextColor3=Color3.fromHex(CLR.alt)
 sub.Text="Muscle Legends 2 • WindUI • v3.5"
 sub.TextTransparency=1; sub.Parent=ct

 local cr=Instance.new("TextLabel")
 cr.Position=UDim2.new(0,0,0,170); cr.Size=UDim2.new(1,0,0,14)
 cr.BackgroundTransparency=1; cr.Font=Enum.Font.Gotham; cr.TextSize=11
 cr.TextColor3=Color3.fromHex(CLR.sari)
 cr.Text="Made by molokoz/yatzukix • For nuggiez6244"
 cr.TextTransparency=1; cr.Parent=ct

 local barBG=Instance.new("Frame")
 barBG.Position=UDim2.new(0,0,0,205); barBG.Size=UDim2.new(1,0,0,8)
 barBG.BackgroundColor3=Color3.fromHex(CLR.barZemin)
 barBG.BackgroundTransparency=1; barBG.BorderSizePixel=0; barBG.Parent=ct
 Instance.new("UICorner",barBG).CornerRadius=UDim.new(1,0)

 local barFill=Instance.new("Frame")
 barFill.Size=UDim2.new(0,0,1,0); barFill.BackgroundColor3=Color3.fromHex(CLR.baslik)
 barFill.BackgroundTransparency=1; barFill.BorderSizePixel=0; barFill.Parent=barBG
 Instance.new("UICorner",barFill).CornerRadius=UDim.new(1,0)
 local fg=Instance.new("UIGradient")
 fg.Color=ColorSequence.new(Color3.fromHex(CLR.bar1),Color3.fromHex(CLR.bar2))
 fg.Parent=barFill

 local st=Instance.new("TextLabel")
 st.Position=UDim2.new(0,0,0,220); st.Size=UDim2.new(0.7,0,0,16)
 st.BackgroundTransparency=1; st.Font=Enum.Font.Gotham; st.TextSize=12
 st.TextXAlignment=Enum.TextXAlignment.Left; st.TextColor3=Color3.fromHex(CLR.durum)
 st.Text="Starting..."; st.TextTransparency=1; st.Parent=ct

 local pc=Instance.new("TextLabel")
 pc.Position=UDim2.new(0.7,0,0,220); pc.Size=UDim2.new(0.3,0,0,16)
 pc.BackgroundTransparency=1; pc.Font=Enum.Font.GothamBold; pc.TextSize=12
 pc.TextXAlignment=Enum.TextXAlignment.Right; pc.TextColor3=Color3.fromHex(CLR.yuzde)
 pc.Text="0%"; pc.TextTransparency=1; pc.Parent=ct

 local tip=Instance.new("TextLabel")
 tip.AnchorPoint=Vector2.new(0.5,1); tip.Position=UDim2.new(0.5,0,1,-40)
 tip.Size=UDim2.new(0,540,0,18); tip.BackgroundTransparency=1
 tip.Font=Enum.Font.Gotham; tip.TextSize=13; tip.TextColor3=Color3.fromHex(CLR.ipucu)
 tip.Text=" Tip: Turn on Very Fast Rep, evolve your pets!"
 tip.TextTransparency=1; tip.Parent=bg

 gui.Parent = getGuiParent()

 local fi=TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
 TweenService:Create(bg,fi,{BackgroundTransparency=0}):Play()
 local function fadeIn(o,p,d) task.delay(d or 0,function() TweenService:Create(o,fi,{[p]=0}):Play() end) end
 fadeIn(logo,"ImageTransparency",0.05)
 task.delay(0.05,function()
 TweenService:Create(lsc,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 TweenService:Create(ls,fi,{Transparency=0.15}):Play()
 end)
 fadeIn(title,"TextTransparency",0.15); fadeIn(sub,"TextTransparency",0.25)
 fadeIn(cr,"TextTransparency",0.30); fadeIn(barBG,"BackgroundTransparency",0.35)
 fadeIn(barFill,"BackgroundTransparency",0.35); fadeIn(st,"TextTransparency",0.45)
 fadeIn(pc,"TextTransparency",0.45); fadeIn(tip,"TextTransparency",0.55)

 local L={}
 function L:SetLogo(t) if logo and logo.Parent and t and t~="" then logo.Image=t end end
 L.SetLogoImage = L.SetLogo
 local lv=0
 function L:SetProgress(v,t)
 if t then st.Text=t end
 v = v and math.clamp(v,0,1) or lv
 pc.Text = math.floor(v*100).."%"
 if v~=lv then lv=v
 TweenService:Create(barFill,TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(v,0,1,0)}):Play()
 end
 end
 function L:SetError(m)
 st.TextColor3=Color3.fromHex(CLR.hata); st.Text=tostring(m)
 pc.TextColor3=Color3.fromHex(CLR.hata); warn("[nuggiez] "..tostring(m))
 end
 function L:Close()
 local oi=TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
 TweenService:Create(bg,oi,{BackgroundTransparency=1}):Play()
 for _,o in ipairs(bg:GetDescendants()) do
 if o:IsA("TextLabel") then TweenService:Create(o,oi,{TextTransparency=1}):Play()
 elseif o:IsA("ImageLabel") then TweenService:Create(o,oi,{ImageTransparency=1}):Play()
 elseif o:IsA("UIStroke") then TweenService:Create(o,oi,{Transparency=1}):Play()
 elseif o:IsA("GuiObject") then TweenService:Create(o,oi,{BackgroundTransparency=1}):Play() end
 end
 task.wait(0.55); if gui then gui:Destroy() end
 end
 return L
end

pcall(function()
 local p=getGuiParent()
 for _,n in ipairs({"nuggiezLoading","nuggiez","WindUI"}) do
 local o=p:FindFirstChild(n); if o then o:Destroy() end
 end
end)

Loading = createLoading()
Loading:SetProgress(0.05,"Starting...")
task.wait(0.25)
LOGO_TEXTURE = resolveTexture(133925002151622,420,420)
Loading:SetLogo(LOGO_TEXTURE)
end

-- ════════════════════════════════════════════════════════════
-- LOAD WINDUI
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.15,"Downloading WindUI...")
local WindUI
do
 local dots=true
 task.spawn(function() local d=0
 while dots do d=(d+1)%4; Loading:SetProgress(nil,"Downloading WindUI"..string.rep(".",d)); task.wait(0.4) end
 end)
 local urls={
 "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
 "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
 }
 for _=1,3 do
 for _,u in ipairs(urls) do
 local ok,s = pcall(httpGet,u)
 if ok and type(s)=="string" and #s>1000 then
 Loading:SetProgress(nil,"Compiling WindUI...")
 local c = loadstring(s)
 if c then local ok2,lib = pcall(c); if ok2 and type(lib)=="table" then WindUI=lib break end end
 end
 end
 if WindUI then break end
 task.wait(0.6)
 end
 dots=false
end
if not WindUI then
 Loading:SetProgress(1); Loading:SetError("WindUI indirilemedi!")
 task.wait(4); Loading:Close(); return
end

-- ════════════════════════════════════════════════════════════
-- THEME
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.30,"Preparing theme...")
pcall(function()
WindUI:AddTheme({
 Name="NuggiezBlue",
 Accent=Color3.fromHex("#0a1a2e"), Dialog=Color3.fromHex("#0a1520"),
 Outline=Color3.fromHex("#2e8eff"), Text=Color3.fromHex("#3baaff"),
 Placeholder=Color3.fromHex("#57a0c2"), Background=Color3.fromHex("#050e1a"),
 Button=Color3.fromHex("#1e88ff"), Icon=Color3.fromHex("#4dabff"),
 Toggle=Color3.fromHex("#ffcc00"), Slider=Color3.fromHex("#2e8eff"),
 Checkbox=Color3.fromHex("#ffcc00"),
 PanelBackground=Color3.fromHex("#0088ff"), PanelBackgroundTransparency=0.95,
 SliderIcon=Color3.fromHex("#80c8ff"), Primary=Color3.fromHex("#ffcc00"),
 LabelBackground=Color3.fromHex("#000000"), LabelBackgroundTransparency=0.83,
 ElementBackground=Color3.fromHex("#14243a"), ElementBackgroundTransparency=0,
})
end)

-- ════════════════════════════════════════════════════════════
-- REMOTES (based on the real list you provided)
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.42,"Connecting remotes...")

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 15)
local R = {} -- all remotes here
local MISSING = {}

local function grab(key, parent, name, timeout)
 if not parent then table.insert(MISSING, name); return nil end
 local o = parent:WaitForChild(name, timeout or 5)
 if o then R[key] = o else table.insert(MISSING, name) end
 return o
end

if rEvents then
 -- main ones used
 grab("areaTravel", rEvents, "areaTravelRemote")
 grab("petEvolve", rEvents, "petEvolveEvent")
 grab("autoEvolve", rEvents, "autoEvolveRemote")
 grab("sellPet", rEvents, "sellPetEvent")
 grab("equipPet", rEvents, "equipPetEvent")
 grab("showPets", rEvents, "showPetsEvent")
 grab("openCrystal", rEvents, "openCrystalRemote")
 grab("machineInteract", rEvents, "machineInteractRemote") -- rep
 grab("brawl", rEvents, "brawlEvent") -- combat
 grab("purchase", rEvents, "purchaseEvent")
 grab("code", rEvents, "codeRemote")
 grab("freeGift", rEvents, "freeGiftClaimRemote")
 grab("fortuneWheel", rEvents, "openFortuneWheelRemote")
 grab("quests", rEvents, "questsEvent")
 grab("checkChest", rEvents, "checkChestRemote")
 grab("ultimates", rEvents, "ultimatesRemote")
 grab("sellPowerUp", rEvents, "sellPowerUpEvent")
 grab("evolvePowerUp", rEvents, "evolvePowerUpEvent")
 grab("changeSpeedSize", rEvents, "changeSpeedSizeRemote")
 grab("savePlayerSize", rEvents, "savePlayerSizeEvent")
 grab("guiDamage", rEvents, "guiDamageEvent")
 grab("unlockChar", rEvents, "unlockCharacterEvent")
 grab("trading", rEvents, "tradingEvent")
 grab("gifted", rEvents, "giftedEvent")
 grab("serverChat", rEvents, "serverChatEvent")
 grab("petGenNotif", rEvents, "petGeneratorNotificationEvent")
 grab("getServerTime", rEvents, "getServerTimeRemote")
 grab("rename", rEvents, "renameRemote")
 grab("group", rEvents, "groupRemote")
 grab("gift", rEvents, "giftRemote")
 grab("playerNamePack", rEvents, "playerNamePackRemote")
 grab("nameGiftSpin", rEvents, "playerNameGiftSpinRemote")
 grab("nameGiftOffer", rEvents, "playerNameGiftSpecialOfferRemote")
 grab("nameGiftJungle", rEvents, "playerNameGiftJungleCaptainRemote")
 -- remote under crossServerUpdateFolder
 grab("countdownReward", ReplicatedStorage:WaitForChild("crossServerUpdateFolder", 5), "giveCountdownRewardEvent")
 -- remotes at the ReplicatedStorage root
 grab("getDecision", ReplicatedStorage, "GetDecision")
 grab("cPetShop", ReplicatedStorage, "cPetShopRemote")
else
 table.insert(MISSING, "rEvents")
end

-- muscleEvent oyunda YOK -> otomatik tespit
local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
 or ReplicatedStorage:FindFirstChild("muscleEvent")
local REP_MODE = muscleEvent and "muscleEvent" or "machineInteract"

-- safe call wrappers
local function fire(remote, ...)
 if not remote then return false end
 local a = table.pack(...)
 return pcall(function() remote:FireServer(table.unpack(a,1,a.n)) end)
end
local function invoke(remote, ...)
 if not remote then return nil end
 local a = table.pack(...)
 local ok,res = pcall(function() return remote:InvokeServer(table.unpack(a,1,a.n)) end)
 if ok then return res end
end
-- If we don't know whether it's a RemoteEvent or RemoteFunction, try both
local function send(remote, ...)
 if not remote then return end
 if remote:IsA("RemoteFunction") then return invoke(remote, ...) end
 return fire(remote, ...)
end

-- ════════════════════════════════════════════════════════════
-- PET FINDER (6 different sources)
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.52,"Scanning pets...")

local PET_SOURCE = "?" -- where pets are stored

-- Guess if an object is a "pet"
local function looksLikePet(o)
 local cls = o.ClassName
 if cls ~= "StringValue" and cls ~= "Folder" and cls ~= "Configuration"
 and cls ~= "Model" and cls ~= "ObjectValue" then return false end
 if o.Name == "" then return false end
 return true
end

-- Collect pet objects from all possible sources
local function collectPetObjects()
 local out = {}
 local seen = {}
 local src = nil

 local function add(o, tag)
 if o and not seen[o] then seen[o]=true; table.insert(out,o); src = src or tag end
 end

 -- 1) nil instances (StringValue)
 pcall(function()
 for _,v in pairs(getnil()) do
 local ok = pcall(function() return v.ClassName end)
 if ok and v.ClassName=="StringValue" and v.Name~="" then add(v,"nil") end
 end
 end)

 -- 2) pet folders under LocalPlayer
 for _,n in ipairs({"Pets","pets","petFolder","PetFolder","Inventory","inventory","petsFolder"}) do
 local f = LocalPlayer:FindFirstChild(n)
 if f then for _,c in ipairs(f:GetDescendants()) do if looksLikePet(c) then add(c,"LP."..n) end end end
 end

 -- 3) ReplicatedStorage playerData / petFolders
 for _,n in ipairs({"playerData","PlayerData","playerFolders","petFolders","pets","Pets","inventories"}) do
 local f = ReplicatedStorage:FindFirstChild(n)
 if f then
 local mine = f:FindFirstChild(LocalPlayer.Name) or f
 for _,c in ipairs(mine:GetDescendants()) do
 if looksLikePet(c) then add(c,"RS."..n) end
 end
 end
 end

 -- 4) player folder under workspace
 pcall(function()
 local wf = workspace:FindFirstChild(LocalPlayer.Name)
 if wf then
 local pf = wf:FindFirstChild("Pets") or wf:FindFirstChild("pets")
 if pf then for _,c in ipairs(pf:GetDescendants()) do if looksLikePet(c) then add(c,"workspace") end end end
 end
 end)

 -- 5) pull names from PlayerGui inventory frames (no objects, just names)
 -- (these objects can't be sent to the remote but fill the list)

 PET_SOURCE = src or "not found"
 return out
end

-- Only pet NAMES from PlayerGui (if no objects found)
local function collectPetNamesFromGui()
 local names, seen = {}, {}
 pcall(function()
 local pg = LocalPlayer:FindFirstChild("PlayerGui")
 if not pg then return end
 for _,o in ipairs(pg:GetDescendants()) do
 local p = o.Parent
 if (o:IsA("TextLabel") or o:IsA("TextButton")) and p
 and (p.Name:lower():find("pet") or (p.Parent and p.Parent.Name:lower():find("pet"))) then
 local t = o.Text
 if t and #t > 2 and #t < 60 and not t:find("^%d") and not seen[t] then
 seen[t]=true; table.insert(names,t)
 end
 end
 end
 end)
 return names
end

local function scanPets()
 local objs = collectPetObjects()
 local pets, counts = {}, {}
 for _,v in ipairs(objs) do
 local n = v.Name
 if not counts[n] then counts[n]=0; table.insert(pets,n) end
 counts[n] = counts[n]+1
 end
 -- if no object, pull name from GUI
 if #pets == 0 then
 for _,n in ipairs(collectPetNamesFromGui()) do
 if not counts[n] then counts[n]=1; table.insert(pets,n) end
 end
 if #pets > 0 then PET_SOURCE = "PlayerGui (sadece isim)" end
 end
 table.sort(pets)
 return pets, counts, objs
end

local function forEachPetObject(filterList, fn)
 local useFilter = filterList and #filterList>0
 local set = {}
 if useFilter then for _,n in ipairs(filterList) do set[n]=true end end
 local n = 0
 for _,v in ipairs(collectPetObjects()) do
 if (not useFilter) or set[v.Name] then fn(v); n = n + 1 end
 end
 return n
end

-- ARGUMENT FORMAT UNKNOWN -> try them all
local function tryAllFormats(remote, action, petObj)
 if not remote then return end
 local name = petObj and petObj.Name or tostring(petObj)
 send(remote, action, petObj) -- 1: ("sellPet", obj)
 send(remote, petObj) -- 2: (obj)
 send(remote, action, name) -- 3: ("sellPet", "Name")
 send(remote, name) -- 4: ("Name")
 send(remote, {petObj}) -- 5: ({obj})
 send(remote, action, {petObj}) -- 6: ("sellPet", {obj})
end

-- ════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.60,"Setting up features...")

local Config = {
 VeryFastRep=false, FastRepSpeed=0.15,
 AutoDumbbell=false, AutoPushups=false, AutoHandstand=false,
 AutoSitups=false, ExerciseSpeed=0.3,
 AutoKillAll=false, KillAuraSpeed=0.2,
 AntiAttack=false,
 AutoEvolvePets=false, AutoSellPets=false,
 SellPetList={}, EvolvePetList={}, SelectedPets={},
 AutoEquipBest=false, MaxEquipSlots=6,
 AutoHatchCrystal=false, SelectedCrystal="Secret Void Crystal", HatchDelay=0.1,
 AutoQuests=false, AutoFreeGift=false, AutoChest=false,
 -- Player
 WalkSpeed=16, JumpPower=50, DefaultSpeed=16, DefaultJump=50,
 SpeedEnabled=false, JumpEnabled=false,
 InfiniteJump=false, FlyEnabled=false, FlySpeed=60,
 NoClip=false, Godmode=false, BlockDamage=false, AntiVoid=false,
 NotifyRare=true,
 -- Evolve speed
 EvolveTickRate=0.1,
 -- Pet Hunt (hedefli hatch)
 HuntEnabled=false, HuntTargets={}, HuntAutoSell=true, HuntStopOnFind=true,
 HuntDelay=0.08,
 -- Exploit Detector
 DetectorEnabled=false, DetectorAutoHop=true, DetectorSensitivity=3,
 DetectorStrictMode=false, DetectorWhitelist={},
 VisualStrength=false, VisualStrengthVal="999999999",
 VisualGems=false, VisualGemsVal="999999999",
 VisualCoins=false, VisualCoinsVal="999999999",
 VisualRebirths=false, VisualRebirthsVal="999999999",
 VisualLevel=false, VisualLevelVal="999999999",
 VisualWin=false, VisualWinVal="999999999",
 AntiAFK=true,
}

-- ════════════════════════════════════════════════════════════
-- LANGUAGE SYSTEM
-- ════════════════════════════════════════════════════════════

local LangCode = "en"
pcall(function()
 local saved = (readfile and readfile("nuggiez_private/lang.txt")) or (isfolder and isfolder("nuggiez_private") and "")
 if saved and saved ~= "" then
  saved = saved:gsub("%s","")
  if saved == "tr" or saved == "en" or saved == "pt" then LangCode = saved end
 end
end)
if getgenv().__nuggiezLang and (getgenv().__nuggiezLang == "tr" or getgenv().__nuggiezLang == "en" or getgenv().__nuggiezLang == "pt") then
 LangCode = getgenv().__nuggiezLang
end

local LANGS = {
 en = {
  -- Main
  status="Status", repSystem="Rep System", defense="Defense",
  repFound="muscleEvent found", repMissing="muscleEvent NOT found -> ",
  repUsingMachine="machineInteractRemote in use", repNotFound="REP REMOTE NOT FOUND",
  remoteStatus="Remote Status", remoteAll="All remotes OK", remoteMissing="Missing: ",
  antiAttack="Anti Attack (ForceField + NoClip)",
  -- Player
  movement="Movement", speedMult="Speed Multiplier", speedMultDesc="Locks WalkSpeed (game can't reset)",
  walkSpeed="Walk Speed", walkSpeedDesc="Normal = 16 | 100+ risks anticheat",
  speedMultVal="Speed Multiplier (x)", speedMultValDesc="Applies multiplier to base 16",
  jumpPower="Jump Power", jumpPowerVal="Jump Power Value", jumpPowerValDesc="Normal = 50",
  infJump="Infinite Jump", infJumpDesc="Unlimited mid-air jumps (Space / mobile jump)",
  fly="Fly", flyDesc="PC: WASD + Space/Shift | Mobile: joystick + buttons",
  flySpeed="Fly Speed", flyUp="Go Up (fly direction)", flyDown="Go Down (fly direction)",
  noclip="NoClip (pass through walls)", immortality="Immortality",
  godmode="GODMODE", godmodeDesc="ForceField + health lock + death state block",
  blockDamage="Block Damage Packets", blockDamageDesc="Blocks guiDamageEvent/brawlEvent (strongest)",
  notSupported="Not supported", blockNotif="Executor hook not supported",
  antiVoid="Anti Void", antiVoidDesc="Auto-teleports up if you fall off the map",
  healFull="Full Heal", healed="Healed", healthRestored="Health restored",
  resetSection="Reset", resetPlayer="Reset All Player Settings",
  playerReset="Player settings reset to normal",
  -- Farm
  killAura="Kill Aura", autoKill="Auto Kill All (TP + Multi-Punch)",
  killSpeed="Kill Speed", repSection="Rep",
  fastRep="Very Fast Rep (animated)", fastRepDesc="Fires 5x per frame - speeds up animation",
  repSpeed="Rep Speed (seconds)", repSpeedDesc="0.01 = max speed",
  exercises="Exercises", autoDumbbell="Auto Dumbbell", autoPushups="Auto Pushups",
  autoHandstand="Auto Handstand", autoSitups="Auto Situps", exerciseSpeed="Exercise Speed",
  autoRewards="Auto Rewards", autoQuests="Auto Quests Claim", autoFreeGift="Auto Free Gift",
  autoChest="Auto Chest",
  -- Pets
  scanSection="1) Scan First", scanInv="Scan Inventory",
  noPets="No pets", noPetsDesc="Earn pets in-game first, then Scan",
  scanned="Scanned", scannedDesc=" pets found (", petList="Pet List", scanFirst="Scan first",
  evolveSection="2) Evolve", autoEvolve="AUTO EVOLVE (TURBO)",
  autoEvolveDesc="Evolves everything - no delay, full speed",
  turboEvolveOn="Turbo Evolve ON", turboEvolveOnDesc=" pets | Format #",
  evolveRate="Evolve Repeat Rate (sec)", evolveRateDesc="0.1 = fastest | increase if lag",
  evolveNow="Evolve All Now", turboEvolve="Turbo Evolve", petsProcessed=" pets processed",
  learnFormat="Learn Correct Format (press once)", learnFormatDesc="Finds which argument format works 20x faster",
  learning="Learning...", fewSeconds="A few seconds...",
  formatFound="Format found", formatNotFound="Not found",
  formatFoundDesc="Format #", formatSpeed=" - now much faster",
  formatNotFoundDesc="Will keep trying all formats",
  equipBestSection="2b) Equip Best", autoEquipBest="AUTO EQUIP BEST",
  autoEquipBestDesc="Auto-equips strongest pets by rarity",
  error="Error", equipBestOn="Equip Best ON", equipBestOnDesc=" pets equipped (refreshes every 5s)",
  equipSlots="How many pets to equip?", equipSlotsDesc="Top N strongest pets selected",
  equipNow="Equip Best Now", equipNowDesc="One-time - equips strongest pets",
  equipped="Equipped", equippedDesc=" best pets equipped",
  printRank="Print Pet Power Ranking", printRankDesc="Writes all pet scores to F9 console",
  noPetsScan="No pets", noPetsScanDesc="Scan first",
  ranking="Ranking", rankingDesc=" pets written to F9",
  unequipAll="Unequip All Pets", unequipAllDesc="Removes all equipped pets",
  unequipped="Unequipped", unequippedDesc=" pets removed",
  sellSection="3) Sell", autoSell="Auto Sell (listed)", addToSell="Add Selected to Sell List",
  noSelection="No selection", noSelectionDesc="Select pets first",
  added="Added", addedDesc=" pets in list",
  manualAdd="Add Pet Manually", petName="Pet name",
  sellSelectedNow="Sell Selected Now", sold="Sold", soldDesc=" pets attempted",
  clearSellList="Clear Sell List", cleared="Cleared", clearedDesc="Sell list empty",
  crystalSection="Crystal Selection", crystalSelect="Select Crystal",
  crystalDesc="Not scanned yet. Press 'Scan Crystals' button.",
  scanCrystals="Scan Crystals and Pets", scanning="Scanning", scanningDesc="Reading game data...",
  found="Found", foundDesc=" crystals (", partial="Partial", partialDesc=" pets from history",
  notFound="Not found", notFoundDesc="Do some hatches then scan again",
  workspaceFound=" crystals found", readyList="Ready List", readyListDesc=" crystals selectable",
  huntSection="Pet Hunt (targeted)", huntTarget="Hunt Targets", huntTargetDesc="Select target pets",
  huntStatus="Hunt Status", huntStatusDesc="Idle",
  huntStart="Start Hunt", huntStarted="Hunt Started", huntStartedDesc="Opening crystals...",
  huntStop="Stop Hunt", huntStopped="Hunt Stopped",
  autoSellNonTarget="Auto-Sell Non-Targets", targetFound="TARGET FOUND!",
  huntFound=" found! attempts: ", sold2=" sold",
  hatchSection="Normal Hatch", autoHatch="Auto Hatch (no target)",
  notifyRare="Rare Pet Notification", hatchDelay="Hatch Delay",
  hatchOnce="Hatch Once", hatchResult="Hatch", hatchNoResult="Result not readable",
  hatch25="Hatch x25", hatch25Result=" rares found",
  hatchReport="Hatch Report", reportWritten="Written to F9",
  hatchStats="Hatch Statistics",
  petSource="Pet Source", petSourceDesc="Not scanned yet. Press 'Scan Inventory'.",
  crystalDB="Crystal Database", crystalDBDesc="Not scanned yet. Press 'Scan Crystals'.",
  crystalPets="Pets from this Crystal", crystalPetsDesc="Select targets - others auto-sold",
  huntTargetPH="Full pet name (e.g. Twin Element Birdies)",
  huntNoTarget="No target selected", huntToggleDesc="Opens until target found, sells the rest",
  huntSpeed="Hunt Speed (seconds)", huntStatsTitle="Hatch Statistics", huntStatsDesc="No hatches done yet.",
  mapSource="Map Source", mapSelect="Select Map",
  detectionLog="Detection Log", detectionLogDesc="Detector is off.",
  detectorDesc1="Catches TP-killers: teleport, kill farm, killing players, attacking you",
  autoHopDesc="Switches server when TP-kill farmer detected (45s cooldown)",
  sensitivity="Sensitivity", sensitivityDesc="1 = sensitive | 3 = balanced (recommended) | 5 = confirmed threats only",
  strictDesc="Keep OFF - everyone is fast in this game, causes false alarms",
  whitelistPH="Player name (your friend)",
  targetList="Target: ",
  sourcePet="Source: %s\nFound: %d unique pets",
  processing=" pets being processed, will repeat continuously",
  formatFoundShort="Format found", formatNotFoundShort="Not found",
  petRankingHeader="=== PET POWER RANKING ===",
  crystalContains="%s\n%d pets inside (source: %s)",
  seenCount=" (x%d seen)",
  learnedFromHistory="No database - learned from hatch history (%d pets)",
  hardcodedList="Hardcoded list: %d crystals\nDo some hatches, pets auto-fill",
  scanFirstBtn="Press 'Scan Crystals' first",
  huntTargetList="Target: ", huntNoTargetShort="No target selected",
  huntReport="Target: %s\nAttempts: %d | Sold: %d\nSpeed: %.0f hatch/min | Time: %ds",
  areaCirclesFallback="areaCircles not readable - using default list",
  detectorOff="Detector is off.",
  playerAnalysisHeader="=== PLAYER ANALYSIS ===",

  -- Teleports
  mapsSection="Maps", teleport="Teleport", tpNotFound="Not found: ",
  refreshMaps="Refresh Map List", refreshed="Refreshed", refreshedDesc=" maps found",
  notFoundArea="Not found", notFoundAreaDesc="areaCircles not readable",
  nextMap="Next Map", lastMap="Go to Last Map",
  playerTP="Player TP", tpNearest="TP to Nearest Player",
  -- Misc
  exploitDetector="Exploit Detector", detectorOn="Detector ON",
  detectorOnDesc="Monitoring other players...", autoHop="Server Hop on Threat",
  strictMode="Strict Mode (speed/fly counted)", strictModeOn="Strict Mode ON",
  strictModeOnDesc="Speed/fly/teleport also flagged",
  whitelistAdd="Add to Whitelist", whitelistAdded="Whitelist", whitelistAddedDesc=" no longer scanned",
  whitelistClear="Clear Whitelist", whitelistCleared="Whitelist cleared",
  hopNow="Switch Server Now", playerAnalysis="Print Player Analysis",
  analysisWritten="Written to F9", monitoring="Monitoring: ", players=" players",
  noThreat="No threats detected",
  codesSection="Codes", useCode="Use Code", useCodePH="Enter code",
  codeTried="Tried: ", tryAllCodes="Try All Known Codes",
  codesTried=" codes tried", otherSection="Other",
  fortuneWheel="Fortune Wheel Spin", wheelTried="Spin attempted",
  claimGift="Claim Free Gift", giftTried="Claim attempted",
  sellPowerUps="Sell All PowerUps", powerUpSold="Sale attempted",
  evolvePowerUps="Evolve All PowerUps", powerUpEvolved="Evolve attempted",
  ultimatesTrigger="Ultimates Trigger", ultimateTried="Attempted",
  -- Visual
  visualSection="Client-Side Visual Changes", visual="Visual ",
  visualDesc="Only changes on screen", applyNow="Apply Now", applied="Applied",
  appliedDesc="Applied", resetAll="Reset All", resetDesc="Reset", resetContent="Disabled",
  -- Settings
  system="System", antiAFK="Anti AFK", unload="Unload Script",
  credits="Credits", creditsDesc="nuggiez private\nUI: WindUI (Footagesus)",
  language="Language", langDesc="Select UI language (re-execute to apply)",
  langChanged="Language Changed", langChangedDesc="Re-execute the script to apply",
  -- Startup
  loaded="nuggiez private Loaded!", allReady="All systems ready",
  repNotifTitle="If rep doesn't work", repNotifBody="Using machineInteractRemote - ignore if working",
  -- Notify misc
  serverHopping="Switching Server", threat="Threat Detected", targetFound="Target Found!",
 },
 tr = {
  status="Durum", repSystem="Rep Sistemi", defense="Defense",
  repFound="muscleEvent bulundu", repMissing="muscleEvent YOK -> ",
  repUsingMachine="machineInteractRemote kullaniliyor", repNotFound="REP REMOTE BULUNAMADI",
  remoteStatus="Remote Durumu", remoteAll="Tum remoteler OK", remoteMissing="Eksik: ",
  antiAttack="Anti Attack (ForceField + NoClip)",
  movement="Hareket", speedMult="Speed Multiplier", speedMultDesc="WalkSpeed'i sabit tutar (oyun geri alamaz)",
  walkSpeed="Walk Speed", walkSpeedDesc="Normal = 16 | 100+ anticheat riski",
  speedMultVal="Speed Multiplier (x kat)", speedMultValDesc="16 tabanina carpan uygular",
  jumpPower="Jump Power", jumpPowerVal="Jump Power Degeri", jumpPowerValDesc="Normal = 50",
  infJump="Infinite Jump", infJumpDesc="Havada sinirsiz ziplama (Space / mobil jump)",
  fly="Fly", flyDesc="flyDesc",
  flySpeed="Fly Speed", flyUp="Yukari Cik (fly yonu)", flyDown="Asagi In (fly yonu)",
  noclip="NoClip (duvardan gec)", immortality="Olumsuzluk",
  godmode="GODMODE", godmodeDesc="ForceField + can kilidi + olum state engeli",
  blockDamage="Block Damage Packets", blockDamageDesc="guiDamageEvent/brawlEvent hasar paketlerini keser (en guclu)",
  notSupported="Desteklenmiyor", blockNotif="Executor hook desteklemiyor",
  antiVoid="Anti Void", antiVoidDesc="Haritadan dusersen otomatik yukari isinlar",
  healFull="Cani Full Yap", healed="Heal", healthRestored="Can dolduruldu",
  resetSection="Sifirla", resetPlayer="Tum Player Ayarlarini Sifirla",
  playerReset="Player ayarlari normale dondu",
  killAura="Kill Aura", autoKill="Auto Kill All (TP + Multi-Punch)",
  killSpeed="Kill Speed", repSection="Rep",
  fastRep="Very Fast Rep (animasyonlu)", fastRepDesc="Her frame'de 5x ates - animasyon hizlanir",
  repSpeed="Rep Speed (saniye)", repSpeedDesc="0.01 = maksimum hiz",
  exercises="Exercises", autoDumbbell="Auto Dumbbell", autoPushups="Auto Pushups",
  autoHandstand="Auto Handstand", autoSitups="Auto Situps", exerciseSpeed="Exercise Speed",
  autoRewards="Otomatik Oduller", autoQuests="Auto Quests Claim", autoFreeGift="Auto Free Gift",
  autoChest="Auto Chest",
  scanSection="1) Once Tara", scanInv="Scan Inventory",
  noPets="Pet yok", noPetsDesc="Once oyunda pet kazan, sonra Scan yap",
  scanned="Tarandi", scannedDesc=" pet bulundu (", petList="Pet Listesi", scanFirst="Once Scan yap",
  evolveSection="2) Evolve", autoEvolve="AUTO EVOLVE (TURBO)",
  autoEvolveDesc="Ne varsa hepsini evolve eder - bekleme yok, tam hiz",
  turboEvolveOn="Turbo Evolve Acik", turboEvolveOnDesc=" pet | Format #",
  evolveRate="Evolve Tekrar Hizi (saniye)", evolveRateDesc="0.1 = en hizli | lag olursa yukselt",
  evolveNow="Simdi Hepsini Evolve Et", turboEvolve="Turbo Evolve", petsProcessed=" pet islendi",
  learnFormat="Dogru Formatini Ogren (1 kez bas)", learnFormatDesc="Hangi arguman formatinin calistigini bulur 20x hizlanir",
  learning="Ogreniliyor...", fewSeconds="Birkac saniye...",
  formatFound="Format bulundu", formatNotFound="Bulunamadi",
  formatFoundDesc="Format #", formatSpeed=" - artik cok hizli",
  formatNotFoundDesc="Tum formatlar denenmeye devam edecek",
  equipBestSection="2b) Equip Best", autoEquipBest="AUTO EQUIP BEST",
  autoEquipBestDesc="En guclu petleri otomatik kuslanir (rarity'ye gore siralar)",
  error="Hata", equipBestOn="Equip Best Acik", equipBestOnDesc=" pet kusanildi (her 5sn yenilenir)",
  equipSlots="Kac Pet Kusanilacak?", equipSlotsDesc="Slot sayisi kadar en guclu petler secilir",
  equipNow="Simdi En Iyileri Kusan", equipNowDesc="Tek seferlik - en guclu petleri equip eder",
  equipped="Kusanildi", equippedDesc=" en iyi pet equip edildi",
  printRank="Pet Guc Siralamasini Yazdir", printRankDesc="F9'a tum petlerin guc puanini yazar",
  noPetsScan="Pet yok", noPetsScanDesc="Once Scan yap",
  ranking="Siralama", rankingDesc=" pet F9'a yazildi",
  unequipAll="Tum Petleri Unequip Et", unequipAllDesc="Kusanilan tum petleri cikarir",
  unequipped="Unequip", unequippedDesc=" pet cikarildi",
  sellSection="3) Sell", autoSell="Auto Sell (listedekiler)", addToSell="Secilenleri Sell Listesine Ekle",
  noSelection="Secim yok", noSelectionDesc="Once pet sec",
  added="Eklendi", addedDesc=" pet listede",
  manualAdd="Manuel Pet Ekle", petName="Pet adi",
  sellSelectedNow="Sell Selected Now", sold="Satildi", soldDesc=" pet denendi",
  clearSellList="Clear Sell List", cleared="Temizlendi", clearedDesc="Sell listesi bos",
  crystalSection="Crystal Secimi", crystalSelect="Crystal Sec",
  crystalDesc="Henuz taranmadi. 'Crystal'lari Tara' butonuna bas.",
  scanCrystals="Crystal'lari ve Petlerini Tara", scanning="Taraniyor", scanningDesc="Oyun verisi okunuyor...",
  found="Bulundu", foundDesc=" crystal (", partial="Kismi", partialDesc=" pet gecmisten alindi",
  notFound="Bulunamadi", notFoundDesc="Birkac hatch yap sonra tekrar tara",
  workspaceFound=" crystal bulundu", readyList="Hazir Liste", readyListDesc=" crystal secilebilir",
  huntSection="Pet Hunt (hedefli avlanma)", huntTarget="Hunt Hedefleri", huntTargetDesc="Hedef petleri sec",
  huntStatus="Hunt Durumu", huntStatusDesc="Beklemede",
  huntStart="Hunt Baslat", huntStarted="Hunt Basladi", huntStartedDesc="Crystal'lar aciliyor...",
  huntStop="Hunt Durdur", huntStopped="Hunt Durduruldu",
  autoSellNonTarget="Hedef Olmayani Otomatik Sat", targetFound="HEDEF BULUNDU!",
  huntFound=" bulundu! deneme: ", sold2=" satildi",
  hatchSection="Normal Hatch", autoHatch="Auto Hatch (hedefsiz)",
  notifyRare="Nadir Pet Bildirimi", hatchDelay="Hatch Delay",
  hatchOnce="Hatch Once", hatchResult="Hatch", hatchNoResult="Sonuc okunamadi",
  hatch25="Hatch x25", hatch25Result=" nadir cikti",
  hatchReport="Hatch Raporu", reportWritten="F9'a yazildi",
  hatchStats="Hatch Istatistigi",
  petSource="Pet Kaynagi", petSourceDesc="Henuz taranmadi. 'Scan Inventory' butonuna bas.",
  crystalDB="Crystal Veritabani", crystalDBDesc="Henuz taranmadi. 'Crystal'lari Tara' butonuna bas.",
  crystalPets="Bu Crystal'dan Cikan Petler", crystalPetsDesc="Hedeflerini sec - digerleri otomatik satilir",
  huntTargetPH="Tam pet adi (orn: Twin Element Birdies)",
  huntNoTarget="Hedef secilmedi", huntToggleDesc="Hedef cikana kadar acar, cikmayanlari satar",
  huntSpeed="Hunt Hizi (saniye)", huntStatsTitle="Hatch Istatistigi", huntStatsDesc="Henuz hatch yapilmadi.",
  mapSource="Harita Kaynagi", mapSelect="Harita Sec",
  detectionLog="Tespit Kaydi", detectionLogDesc="Detector kapali.",
  detectorDesc1="Isinlanip kill yapani yakalar: teleport, kill farm, oyuncu oldurme, sana saldiri",
  autoHopDesc="Isinlanip kill farm yapani gorunce server degistirir (45sn cooldown)",
  sensitivity="Hassasiyet", sensitivityDesc="1 = hassas | 3 = dengeli (onerilen) | 5 = sadece kesin tehdit",
  strictDesc="KAPALI tut - bu oyunda herkes hizli, yanlis alarm verir",
  whitelistPH="Oyuncu adi (arkadasin)",
  targetList="Hedef: ",
  sourcePet="Kaynak: %s\nBulunan: %d farkli pet",
  processing=" pet isleniyor, surekli tekrarlanacak",
  formatFoundShort="Format bulundu", formatNotFoundShort="Bulunamadi",
  petRankingHeader="=== PET GUC SIRALAMASI ===",
  crystalContains="%s\n%d pet iceriyor (kaynak: %s)",
  seenCount=" (x%d goruldu)",
  learnedFromHistory="Veritabani yok - hatch gecmisinden ogrenildi (%d pet)",
  hardcodedList="Hardcoded liste: %d crystal\nBirkac hatch yap, petler otomatik dolar",
  scanFirstBtn="Once 'Crystal'lari Tara' bas",
  huntTargetList="Hedef: ", huntNoTargetShort="Hedef secilmedi",
  huntReport="Hedef: %s\nDeneme: %d | Satilan: %d\nHiz: %.0f hatch/dk | Sure: %ds",
  areaCirclesFallback="areaCircles okunamadi - varsayilan liste kullaniliyor",
  detectorOff="Detector kapali.",
  playerAnalysisHeader="=== OYUNCU ANALIZI ===",

  mapsSection="Haritalar", teleport="Teleport", tpNotFound="Bulunamadi: ",
  refreshMaps="Harita Listesini Yenile", refreshed="Yenilendi", refreshedDesc=" harita bulundu",
  notFoundArea="Bulunamadi", notFoundAreaDesc="areaCircles okunamadi",
  nextMap="Siradaki Haritaya Gec", lastMap="En Son Haritaya Git",
  playerTP="Player TP", tpNearest="TP to Nearest Player",
  exploitDetector="Exploit Detector", detectorOn="Detector Acik",
  detectorOnDesc="Oyuncular izleniyor...", autoHop="Tehdit Gorunce Server Degistir",
  strictMode="Siki Mod (hiz/fly de sayilsin)", strictModeOn="Siki Mod Acik",
  strictModeOnDesc="Hiz/fly/teleport da isaretlenir",
  whitelistAdd="Whitelist'e Ekle", whitelistAdded="Whitelist", whitelistAddedDesc=" artik taranmayacak",
  whitelistClear="Whitelist'i Temizle", whitelistCleared="Whitelist bosaltilidi",
  hopNow="Simdi Server Degistir", playerAnalysis="Oyuncu Analizi Yazdir",
  analysisWritten="F9'a yazildi", monitoring="Izleniyor: ", players=" oyuncu",
  noThreat="Henuz tespit yok",
  codesSection="Kodlar", useCode="Kod Kullan", useCodePH="Kodu yaz",
  codeTried="Denendi: ", tryAllCodes="Bilinen Tum Kodlari Dene",
  codesTried=" kod denendi", otherSection="Diger",
  fortuneWheel="Fortune Wheel Spin", wheelTried="Spin denendi",
  claimGift="Claim Free Gift", giftTried="Claim denendi",
  sellPowerUps="Sell All PowerUps", powerUpSold="Satis denendi",
  evolvePowerUps="Evolve All PowerUps", powerUpEvolved="Evolve denendi",
  ultimatesTrigger="Ultimates Trigger", ultimateTried="Denendi",
  visualSection="Client-Side Gorsel Degisiklikler", visual="Visual ",
  visualDesc="Sadece ekranda degisir", applyNow="Apply Now", applied="Applied",
  appliedDesc="Uygulandi", resetAll="Reset All", resetDesc="Reset", resetContent="Kapatildi",
  system="System", antiAFK="Anti AFK", unload="Unload Script",
  credits="Credits", creditsDesc="nuggiez private\nUI: WindUI (Footagesus)",
  language="Language", langDesc="Dil sec (uygulamak icin yeniden calistir)",
  langChanged="Dil Degisti", langChangedDesc="Uygulamak icin scripti yeniden calistir",
  loaded="nuggiez private Yuklendi!", allReady="Tum sistemler hazir",
  repNotifTitle="Rep calismiyorsa", repNotifBody="machineInteractRemote ile rep gonderiliyor - sorun yoksa gormezden cik",
  serverHopping="Server Degistiriliyor", threat="Tehdit Tespit", targetFound="Hedef Bulundu!",
 },
 pt = {
  status="Status", repSystem="Sistema de Rep", defense="Defesa",
  repFound="muscleEvent encontrado", repMissing="muscleEvent NAO encontrado -> ",
  repUsingMachine="machineInteractRemote em uso", repNotFound="REP REMOTE NAO ENCONTRADO",
  remoteStatus="Status de Remote", remoteAll="Todos remotes OK", remoteMissing="Faltando: ",
  antiAttack="Anti Attack (ForceField + NoClip)",
  movement="Movimento", speedMult="Multiplicador de Velocidade", speedMultDesc="Trava WalkSpeed (jogo nao pode resetar)",
  walkSpeed="Walk Speed", walkSpeedDesc="Normal = 16 | 100+ risco de anticheat",
  speedMultVal="Multiplicador de Velocidade (x)", speedMultValDesc="Aplica multiplicador na base 16",
  jumpPower="Jump Power", jumpPowerVal="Valor de Jump Power", jumpPowerValDesc="Normal = 50",
  infJump="Pulo Infinito", infJumpDesc="Pulos infinitos no ar (Space / mobile jump)",
  fly="Voar", flyDesc="PC: WASD + Space/Shift | Mobile: joystick + botoes",
  flySpeed="Velocidade de Voo", flyUp="Subir (direcao do voo)", flyDown="Descer (direcao do voo)",
  noclip="NoClip (atravessar paredes)", immortality="Imortalidade",
  godmode="GODMODE", godmodeDesc="ForceField + trava de vida + bloqueio de morte",
  blockDamage="Bloquear Pacotes de Dano", blockDamageDesc="Bloqueia guiDamageEvent/brawlEvent (mais forte)",
  notSupported="Nao suportado", blockNotif="Executor nao suporta hook",
  antiVoid="Anti Void", antiVoidDesc="Teleporta para cima se cair do mapa",
  healFull="Curar Totalmente", healed="Curado", healthRestored="Vida restaurada",
  resetSection="Resetar", resetPlayer="Resetar Todas Configuracoes",
  playerReset="Configuracoes de player resetadas",
  killAura="Kill Aura", autoKill="Auto Kill All (TP + Multi-Punch)",
  killSpeed="Kill Speed", repSection="Rep",
  fastRep="Very Fast Rep (animado)", fastRepDesc="Dispara 5x por frame - acelera animacao",
  repSpeed="Rep Speed (segundos)", repSpeedDesc="0.01 = velocidade maxima",
  exercises="Exercicios", autoDumbbell="Auto Dumbbell", autoPushups="Auto Pushups",
  autoHandstand="Auto Handstand", autoSitups="Auto Situps", exerciseSpeed="Exercise Speed",
  autoRewards="Recompensas Auto", autoQuests="Auto Quests Claim", autoFreeGift="Auto Free Gift",
  autoChest="Auto Chest",
  scanSection="1) Escanear Primeiro", scanInv="Scan Inventory",
  noPets="Sem pets", noPetsDesc="Ganhe pets no jogo primeiro, depois Scan",
  scanned="Escaneado", scannedDesc=" pets encontrados (", petList="Lista de Pets", scanFirst="Escanear primeiro",
  evolveSection="2) Evoluir", autoEvolve="AUTO EVOLVE (TURBO)",
  autoEvolveDesc="Evolui tudo - sem delay, velocidade maxima",
  turboEvolveOn="Turbo Evolve LIGADO", turboEvolveOnDesc=" pets | Formato #",
  evolveRate="Taxa de Repeticao Evolve (seg)", evolveRateDesc="0.1 = mais rapido | aumente se lagar",
  evolveNow="Evoluir Todos Agora", turboEvolve="Turbo Evolve", petsProcessed=" pets processados",
  learnFormat="Aprender Formato Correto (pressione 1x)", learnFormatDesc="Encontra qual formato funciona 20x mais rapido",
  learning="Aprendendo...", fewSeconds="Alguns segundos...",
  formatFound="Formato encontrado", formatNotFound="Nao encontrado",
  formatFoundDesc="Formato #", formatSpeed=" - agora muito mais rapido",
  formatNotFoundDesc="Continuara tentando todos formatos",
  equipBestSection="2b) Equip Best", autoEquipBest="AUTO EQUIP BEST",
  autoEquipBestDesc="Equipa automaticamente os pets mais fortes por raridade",
  error="Erro", equipBestOn="Equip Best LIGADO", equipBestOnDesc=" pets equipados (atualiza a cada 5s)",
  equipSlots="Quantos pets equipar?", equipSlotsDesc="Top N pets mais fortes selecionados",
  equipNow="Equipar Melhores Agora", equipNowDesc="Unica vez - equipa os pets mais fortes",
  equipped="Equipado", equippedDesc=" melhores pets equipados",
  printRank="Imprimir Ranking de Pets", printRankDesc="Escreve scores de todos pets no console F9",
  noPetsScan="Sem pets", noPetsScanDesc="Escanear primeiro",
  ranking="Ranking", rankingDesc=" pets escritos no F9",
  unequipAll="Desequipar Todos os Pets", unequipAllDesc="Remove todos pets equipados",
  unequipped="Desequipado", unequippedDesc=" pets removidos",
  sellSection="3) Vender", autoSell="Auto Sell (listados)", addToSell="Adicionar Selecionados a Lista de Venda",
  noSelection="Sem selecao", noSelectionDesc="Selecione pets primeiro",
  added="Adicionado", addedDesc=" pets na lista",
  manualAdd="Adicionar Pet Manualmente", petName="Nome do pet",
  sellSelectedNow="Sell Selected Now", sold="Vendido", soldDesc=" pets tentados",
  clearSellList="Clear Sell List", cleared="Limpo", clearedDesc="Lista de venda vazia",
  crystalSection="Selecao de Crystal", crystalSelect="Selecionar Crystal",
  crystalDesc="Nao escaneado ainda. Pressione 'Escanear Crystals'.",
  scanCrystals="Escanear Crystals e Pets", scanning="Escaneando", scanningDesc="Lendo dados do jogo...",
  found="Encontrado", foundDesc=" crystals (", partial="Parcial", partialDesc=" pets do historico",
  notFound="Nao encontrado", notFoundDesc="Faca alguns hatches depois escaneie",
  workspaceFound=" crystals encontrados", readyList="Lista Pronta", readyListDesc=" crystals selecionaveis",
  huntSection="Pet Hunt (alvo)", huntTarget="Alvos de Hunt", huntTargetDesc="Selecione pets alvo",
  huntStatus="Status de Hunt", huntStatusDesc="Inativo",
  huntStart="Iniciar Hunt", huntStarted="Hunt Iniciado", huntStartedDesc="Abrindo crystals...",
  huntStop="Parar Hunt", huntStopped="Hunt Parado",
  autoSellNonTarget="Auto-Vender Nao-Alvos", targetFound="ALVO ENCONTRADO!",
  huntFound=" encontrado! tentativas: ", sold2=" vendidos",
  hatchSection="Hatch Normal", autoHatch="Auto Hatch (sem alvo)",
  notifyRare="Notificacao de Pet Raro", hatchDelay="Hatch Delay",
  hatchOnce="Hatch Once", hatchResult="Hatch", hatchNoResult="Resultado nao legivel",
  hatch25="Hatch x25", hatch25Result=" raros encontrados",
  hatchReport="Relatorio de Hatch", reportWritten="Escrito no F9",
  hatchStats="Estatisticas de Hatch",
  petSource="Fonte de Pets", petSourceDesc="Nao escaneado. Pressione 'Scan Inventory'.",
  crystalDB="Banco de Crystals", crystalDBDesc="Nao escaneado. Pressione 'Escanear Crystals'.",
  crystalPets="Pets deste Crystal", crystalPetsDesc="Selecione alvos - outros auto-vendidos",
  huntTargetPH="Nome completo do pet (ex: Twin Element Birdies)",
  huntNoTarget="Nenhum alvo selecionado", huntToggleDesc="Abre ate achar alvo, vende o resto",
  huntSpeed="Velocidade de Hunt (seg)", huntStatsTitle="Estatisticas de Hatch", huntStatsDesc="Nenhum hatch feito.",
  mapSource="Fonte de Mapas", mapSelect="Selecionar Mapa",
  detectionLog="Registro de Deteccao", detectionLogDesc="Detector desligado.",
  detectorDesc1="Pega TP-killers: teleport, kill farm, matar jogadores, te atacar",
  autoHopDesc="Troca de server ao detectar kill farmer (45s cooldown)",
  sensitivity="Sensibilidade", sensitivityDesc="1 = sensivel | 3 = equilibrado (recomendado) | 5 = ameacas confirmadas",
  strictDesc="Mantenha DESLIGADO - todos sao rapidos no jogo, causa falsos alarmes",
  whitelistPH="Nome do jogador (seu amigo)",
  targetList="Alvo: ",
  sourcePet="Fonte: %s\nEncontrados: %d pets unicos",
  processing=" pets sendo processados, repetira continuamente",
  formatFoundShort="Formato encontrado", formatNotFoundShort="Nao encontrado",
  petRankingHeader="=== RANKING DE PETS ===",
  crystalContains="%s\n%d pets dentro (fonte: %s)",
  seenCount=" (x%d visto)",
  learnedFromHistory="Sem banco - aprendido do historico de hatch (%d pets)",
  hardcodedList="Lista fixa: %d crystals\nFaca hatches, pets se preenchem",
  scanFirstBtn="Pressione 'Escanear Crystals' primeiro",
  huntTargetList="Alvo: ", huntNoTargetShort="Nenhum alvo selecionado",
  huntReport="Alvo: %s\nTentativas: %d | Vendidos: %d\nVelocidade: %.0f hatch/min | Tempo: %ds",
  areaCirclesFallback="areaCircles nao legivel - usando lista padrao",
  detectorOff="Detector desligado.",
  playerAnalysisHeader="=== ANALISE DE JOGADORES ===",

  mapsSection="Mapas", teleport="Teleport", tpNotFound="Nao encontrado: ",
  refreshMaps="Atualizar Lista de Mapas", refreshed="Atualizado", refreshedDesc=" mapas encontrados",
  notFoundArea="Nao encontrado", notFoundAreaDesc="areaCircles nao legivel",
  nextMap="Proximo Mapa", lastMap="Ir ao Ultimo Mapa",
  playerTP="Player TP", tpNearest="TP to Nearest Player",
  exploitDetector="Exploit Detector", detectorOn="Detector LIGADO",
  detectorOnDesc="Monitorando outros jogadores...", autoHop="Trocar Server em Ameaca",
  strictMode="Modo Estrito (velocidade/fly contam)", strictModeOn="Modo Estrito LIGADO",
  strictModeOnDesc="Velocidade/fly/teleport tambem marcados",
  whitelistAdd="Adicionar a Whitelist", whitelistAdded="Whitelist", whitelistAddedDesc=" nao sera mais escaneado",
  whitelistClear="Limpar Whitelist", whitelistCleared="Whitelist esvaziada",
  hopNow="Trocar Server Agora", playerAnalysis="Imprimir Analise de Jogadores",
  analysisWritten="Escrito no F9", monitoring="Monitorando: ", players=" jogadores",
  noThreat="Nenhuma ameaca detectada",
  codesSection="Codigos", useCode="Usar Codigo", useCodePH="Digite o codigo",
  codeTried="Tentado: ", tryAllCodes="Tentar Todos Codigos Conhecidos",
  codesTried=" codigos tentados", otherSection="Outros",
  fortuneWheel="Fortune Wheel Spin", wheelTried="Spin tentado",
  claimGift="Claim Free Gift", giftTried="Claim tentado",
  sellPowerUps="Sell All PowerUps", powerUpSold="Venda tentada",
  evolvePowerUps="Evolve All PowerUps", powerUpEvolved="Evolve tentado",
  ultimatesTrigger="Ultimates Trigger", ultimateTried="Tentado",
  visualSection="Alteracoes Visuais (Client-Side)", visual="Visual ",
  visualDesc="So muda na tela", applyNow="Apply Now", applied="Applied",
  appliedDesc="Aplicado", resetAll="Reset All", resetDesc="Reset", resetContent="Desativado",
  system="System", antiAFK="Anti AFK", unload="Unload Script",
  credits="Credits", creditsDesc="nuggiez private\nUI: WindUI (Footagesus)",
  language="Idioma", langDesc="Selecione o idioma (re-execute para aplicar)",
  langChanged="Idioma Alterado", langChangedDesc="Re-execute o script para aplicar",
  loaded="nuggiez private Carregado!", allReady="Todos sistemas prontos",
  repNotifTitle="Se o rep nao funcionar", repNotifBody="Usando machineInteractRemote - ignore se funcionar",
  serverHopping="Trocando de Server", threat="Ameaca Detectada", targetFound="Alvo Encontrado!",
 },
}

local function L(key)
 local lang = LANGS[LangCode] or LANGS.en
 return lang[key] or LANGS.en[key] or key
end

-- ════════════════════════════════════════════════════════════
-- REP SYSTEM (no muscleEvent -> machineInteract)
-- ════════════════════════════════════════════════════════════

local function doRep(target)
 if muscleEvent then
 if target then fire(muscleEvent,"rep",target) else fire(muscleEvent,"rep") end
 return
 end
 -- muscleEvent yok: machineInteractRemote dene
 if R.machineInteract then
 if target then
 send(R.machineInteract, target)
 send(R.machineInteract, "rep", target)
 send(R.machineInteract, "interact", target)
 else
 send(R.machineInteract, "rep")
 send(R.machineInteract)
 end
 end
end

local function doPunch(char, player)
 if muscleEvent then
 fire(muscleEvent,"punch",char); fire(muscleEvent,"attack",char); fire(muscleEvent,"hit",player)
 end
 if R.brawl then
 -- brawlEvent: try both player and char (different versions)
 send(R.brawl, player); send(R.brawl, "punch", player)
 send(R.brawl, "attack", player); send(R.brawl, char)
 send(R.brawl, "hit", player); send(R.brawl, "punch", char)
 end
 if R.guiDamage then
 -- guiDamageEvent: try player + char + damage amount
 send(R.guiDamage, player, 999999)
 send(R.guiDamage, char, 999999)
 send(R.guiDamage, player)
 send(R.guiDamage, char)
 end
end

-- ════════════════════════════════════════════════════════════
-- AUTO SYSTEMS
-- ════════════════════════════════════════════════════════════

local afkConn
local function toggleAntiAFK(e)
 if e then
 if not afkConn then
 afkConn = LocalPlayer.Idled:Connect(function()
 pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
 end)
 end
 elseif afkConn then afkConn:Disconnect(); afkConn=nil end
end

-- Very Fast Rep: fire multiple times per frame (speeds up the animation)
task.spawn(function() while true do
 if Config.VeryFastRep then
 for _ = 1, 5 do pcall(doRep) end
 end
 task.wait(math.max(Config.FastRepSpeed, 0.01))
end end)

-- Find exercise machines in workspace (NOT under the character)
-- In Muscle Legends machines sit on the map; the player walks over and interacts.
local exerciseCache = {} -- [name] = machine object (cache)
local function findExerciseMachine(name)
 -- if cached and still valid, use it
 if exerciseCache[name] and exerciseCache[name].Parent then
 return exerciseCache[name]
 end
 local found = nil
 pcall(function()
 for _, o in ipairs(workspace:GetDescendants()) do
 local n = o.Name:lower()
 local target = name:lower()
 -- exact match or contains words like "dumbbell", "pushup"
 if n:find(target, 1, true)
 and (o:IsA("Model") or o:IsA("Part") or o:IsA("BasePart")
 or o:IsA("MeshPart") or o:IsA("UnionOperation")) then
 found = o
 break
 end
 end
 end)
 if found then exerciseCache[name] = found end
 return found
end

local function doExercise(name)
 local char = LocalPlayer.Character
 if not char then return end
 -- 1) is it under the character? (some games equip it)
 local eq = char:FindFirstChild(name) or char:FindFirstChild(name.."s")
 if eq then
 doRep(eq)
 return
 end
 -- 2) search for the machine in workspace
 local machine = findExerciseMachine(name)
 if machine then
 -- if close to the machine interact directly, otherwise teleport
 local hrp = char:FindFirstChild("HumanoidRootPart")
 if hrp then
 local mPos = machine:IsA("Model") and machine:GetPivot().Position
 or machine.Position
 local dist = (mPos - hrp.Position).Magnitude
 if dist > 15 then
 -- if too far, teleport
 pcall(function() hrp.CFrame = CFrame.new(mPos + Vector3.new(0, 3, 5)) end)
 end
 end
 doRep(machine)
 else
 -- no machine found: send rep with no args
 doRep()
 end
end

local function exLoop(flag, name)
 task.spawn(function() while true do
 if Config[flag] then pcall(doExercise, name) end
 task.wait(math.max(Config.ExerciseSpeed, 0.05))
 end end)
end
exLoop("AutoDumbbell", "Dumbbell")
exLoop("AutoPushups", "Pushup")
exLoop("AutoHandstand", "Handstand")
exLoop("AutoSitups", "Situp")

-- ════════════════════════════════════════════════════════════
-- TURBO AUTO EVOLVE (v3.4) - no waiting, all pets
-- ════════════════════════════════════════════════════════════
-- The old version tried 6 formats x 2 actions per pet and waited with
-- task.wait -> it was very slow. Now:
-- 1) On the first run it LEARNS which format works
-- 2) Then uses only that format -> 10-20x faster
-- 3) No task.wait at all, whole inventory in a single frame

local EVOLVE_FMT = nil -- learned format index
local SELL_FMT = nil

local FORMATS = {
 function(rem,act,obj) send(rem, act, obj) end,
 function(rem,act,obj) send(rem, obj) end,
 function(rem,act,obj) send(rem, act, obj.Name) end,
 function(rem,act,obj) send(rem, obj.Name) end,
 function(rem,act,obj) send(rem, {obj}) end,
 function(rem,act,obj) send(rem, act, {obj}) end,
}

-- if format unknown try them all, if known single shot
local function fastSend(remote, action, obj, fmtVar)
 if not remote or not obj then return end
 local idx = (fmtVar == "evolve") and EVOLVE_FMT or SELL_FMT
 if idx then
 pcall(FORMATS[idx], remote, action, obj)
 else
 for i = 1, #FORMATS do pcall(FORMATS[i], remote, action, obj) end
 end
end

-- Checks if inventory count dropped / pet changed and learns the correct format
local function learnFormat(remote, action, kind)
 local objs = collectPetObjects()
 if #objs == 0 then return false end
 local before = #objs
 for i = 1, #FORMATS do
 pcall(FORMATS[i], remote, action, objs[1])
 task.wait(0.15)
 local after = #collectPetObjects()
 if after ~= before then
 if kind == "evolve" then EVOLVE_FMT = i else SELL_FMT = i end
 print(("[nuggiez] %s format learned: #%d"):format(kind, i))
 return true
 end
 end
 return false
end

-- TURBO: evolve the whole inventory in one pass (no waiting)
local function turboEvolveAll()
 if not R.petEvolve then return 0 end
 local objs = collectPetObjects()
 local n = 0
 for _, v in ipairs(objs) do
 fastSend(R.petEvolve, "evolvePet", v, "evolve")
 fastSend(R.petEvolve, "evolveTitan", v, "evolve")
 n = n + 1
 end
 return n
end

-- ════════════════════════════════════════════════════════════
-- AUTO EQUIP BEST (v3.5) - automatically equip the strongest pets
-- ════════════════════════════════════════════════════════════
-- Generates a power score from the rarity name for ranking pets.
-- If the pet object has a stat (Multiplier, Power, Strength) it uses that.

local RARITY_SCORE = {
 omega=1000, secret=900, exclusive=800, mythic=700,
 legendary=600, titan=500, ultimate=400, godly=350,
 divine=300, cosmic=250, epic=200, rare=100, uncommon=50,
 common=10, basic=5, normal=1,
}

local function petScore(obj)
 -- first look for stats inside the object
 local best = 0
 for _, c in ipairs(obj:GetDescendants()) do
 if c:IsA("NumberValue") or c:IsA("IntValue") then
 local n = c.Name:lower()
 if n:find("mult") or n:find("power") or n:find("strength")
 or n:find("damage") or n:find("boost") then
 best = math.max(best, tonumber(c.Value) or 0)
 end
 end
 end
 -- stat yoksa rarity'den tahmin et
 if best == 0 then
 local nm = obj.Name:lower()
 for word, sc in pairs(RARITY_SCORE) do
 if nm:find(word) then best = sc; break end
 end
 end
 -- still nothing -> give 1 for sorting (at least recent ones end up on top)
 if best == 0 then best = 1 end
 return best
end

local function equipPet(obj)
 if not R.equipPet then return false end
 local name = obj.Name
 -- try all possible equip formats
 send(R.equipPet, "equip", obj)
 send(R.equipPet, obj)
 send(R.equipPet, "equip", name)
 send(R.equipPet, name)
 send(R.equipPet, "equipPet", obj)
 send(R.equipPet, "equipPet", name)
 return true
end

local function unequipPet(obj)
 if not R.equipPet then return false end
 local name = obj.Name
 send(R.equipPet, "unequip", obj)
 send(R.equipPet, "unequip", name)
 send(R.equipPet, "remove", obj)
 send(R.equipPet, "remove", name)
 return true
end

-- Find the strongest N pets and equip them
local function equipBestPets(count)
 if not R.equipPet then return 0, "equipPetEvent not found" end
 local objs = collectPetObjects()
 if #objs == 0 then return 0, "No pets found - Scan first" end

 -- sort by power
 table.sort(objs, function(a, b) return petScore(a) > petScore(b) end)

 local n = math.min(count or Config.MaxEquipSlots or 6, #objs)
 for i = 1, n do
 pcall(equipPet, objs[i])
 task.wait(0.1)
 end
 return n, nil
end

-- auto equip loop (runs in the background)
task.spawn(function() while true do
 if Config.AutoEquipBest then
 pcall(equipBestPets, Config.MaxEquipSlots)
 end
 task.wait(5)
end end)

task.spawn(function() while true do
 if Config.AutoEvolvePets then
 pcall(function()
 -- also keep triggering the game's own auto-evolve if it has one
 if R.autoEvolve then
 send(R.autoEvolve, true)
 send(R.autoEvolve, "enable", true)
 send(R.autoEvolve)
 end
 -- + manuel turbo (filtresiz, ne varsa hepsi)
 turboEvolveAll()
 end)
 end
 task.wait(Config.EvolveTickRate)
end end)

-- Auto Sell
task.spawn(function() while true do
 if Config.AutoSellPets and #Config.SellPetList>0 then
 pcall(function()
 forEachPetObject(Config.SellPetList, function(v)
 tryAllFormats(R.sellPet, "sellPet", v)
 task.wait(0.05)
 end)
 end)
 end
 task.wait(1)
end end)

-- Auto Kill All
task.spawn(function() while true do
 if Config.AutoKillAll then
 local myChar = LocalPlayer.Character
 local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
 if myHRP then
 for _,player in ipairs(Players:GetPlayers()) do
 if not Config.AutoKillAll then break end
 if player ~= LocalPlayer and player.Character then
 local char = player.Character
 local hrp = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChildOfClass("Humanoid")
 -- check still alive + objects valid
 if hrp and hum and hum.Health > 0 and char.Parent and myHRP.Parent then
 -- teleport to the FRONT of the target, not behind + face it
 pcall(function()
 myHRP.CFrame = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
 * CFrame.new(0, 0, -3)
 end)
 task.wait(0.05)
 for _=1,8 do
 if not Config.AutoKillAll then break end
 -- check again: is the target still alive
 if not player.Character then break end
 local hc = player.Character
 local hh = hc and hc:FindFirstChildOfClass("Humanoid")
 if not hh or hh.Health <= 0 then break end
 pcall(doPunch, hc, player)
 pcall(doRep, hc)
 task.wait(0.03)
 end
 task.wait(math.max(Config.KillAuraSpeed, 0.05))
 end
 end
 end
 end
 end
 task.wait(0.1)
end end)

-- Anti Attack
RunService.Stepped:Connect(function()
 if not Config.AntiAttack then return end
 local char = LocalPlayer.Character
 if not char then return end
 for _,p in ipairs(char:GetDescendants()) do
 if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=false end
 end
 if not char:FindFirstChildOfClass("ForceField") then
 local ff=Instance.new("ForceField"); ff.Visible=false; ff.Parent=char
 end
end)

-- ════════════════════════════════════════════════════════════
-- PLAYER SYSTEMS (v3.3)
-- ════════════════════════════════════════════════════════════

local function getChar() return LocalPlayer.Character end
local function getHum()
 local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
 local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── Speed & Jump (keep forcing, so the game can't revert)
task.spawn(function()
 while true do
 local h = getHum()
 if h then
 if Config.SpeedEnabled and h.WalkSpeed ~= Config.WalkSpeed then
 pcall(function() h.WalkSpeed = Config.WalkSpeed end)
 end
 if Config.JumpEnabled then
 pcall(function()
 if h.UseJumpPower then h.JumpPower = Config.JumpPower
 else h.JumpHeight = Config.JumpPower / 10 end
 end)
 end
 end
 task.wait(0.25)
 end
end)

-- ── Infinite Jump
UserInputService.JumpRequest:Connect(function()
 if not Config.InfiniteJump then return end
 local h = getHum()
 if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

-- ── NoClip
RunService.Stepped:Connect(function()
 if not Config.NoClip then return end
 local c = getChar(); if not c then return end
 for _,p in ipairs(c:GetDescendants()) do
 if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
 end
end)

-- ── FLY (BodyVelocity based, mobile + PC)
local flyBV, flyBG, flyConn
local flyDir = Vector3.new()

local function stopFly()
 if flyConn then flyConn:Disconnect(); flyConn = nil end
 if flyBV then flyBV:Destroy(); flyBV = nil end
 if flyBG then flyBG:Destroy(); flyBG = nil end
 local h = getHum()
 if h then pcall(function() h.PlatformStand = false end) end
end

local function startFly()
 local hrp, h = getHRP(), getHum()
 if not hrp or not h then return end
 stopFly()

 flyBV = Instance.new("BodyVelocity")
 flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
 flyBV.Velocity = Vector3.new()
 flyBV.Parent = hrp

 flyBG = Instance.new("BodyGyro")
 flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
 flyBG.P = 9e4
 flyBG.CFrame = Camera.CFrame
 flyBG.Parent = hrp

 h.PlatformStand = true

 flyConn = RunService.RenderStepped:Connect(function()
 if not Config.FlyEnabled then return end
 local hrp2 = getHRP()
 if not hrp2 or not flyBV or not flyBV.Parent then return end

 local cam = Camera.CFrame
 local move = Vector3.new()

 -- Klavye
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
 if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end

 -- Mobil / joystick (Humanoid.MoveDirection)
 local h2 = getHum()
 if h2 and h2.MoveDirection.Magnitude > 0 then
 move = move + (cam.LookVector * h2.MoveDirection.Z * -1)
 + (cam.RightVector * h2.MoveDirection.X)
 end
 move = move + flyDir -- direction from GUI buttons

 if move.Magnitude > 0 then move = move.Unit * Config.FlySpeed end
 flyBV.Velocity = move
 if flyBG then flyBG.CFrame = cam end
 end)
end

local function setFly(on)
 Config.FlyEnabled = on
 if on then startFly() else stopFly() end
end

-- (CharacterAdded connection is set up below, after setGodmode is defined)

-- ════════════════════════════════════════════════════════════
-- GODMODE v2 (v3.5) - RESPAWN-PROOF, 6 LAYERS
-- ════════════════════════════════════════════════════════════
-- v3.4 issue: connections were only set up for the current character.
-- On death/respawn the ForceField + HealthChanged were lost -> godmode died.
-- Now it is AUTOMATICALLY re-applied on every new character.

local godConns = {}
local function clearGodConns()
 for _,c in ipairs(godConns) do pcall(function() c:Disconnect() end) end
 godConns = {}
end

-- Applies the godmode layers to a character
local function armGodmode(char)
 if not Config.Godmode or not char then return end
 local h = char:FindFirstChildOfClass("Humanoid")

 -- Katman 1: gizli ForceField
 if not char:FindFirstChild("nuggiezFF") then
 local ff = Instance.new("ForceField")
 ff.Name = "nuggiezFF"; ff.Visible = false; ff.Parent = char
 end

 if not h then return end

 -- Layer 2: completely disable the dead state
 pcall(function()
 h.BreakJointsOnDeath = false
 h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
 h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
 h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
 h.MaxHealth = math.huge
 h.Health = math.huge
 end)

 -- Layer 3: if health drops, refill instantly
 table.insert(godConns, h.HealthChanged:Connect(function(hp)
 if Config.Godmode and hp < h.MaxHealth then
 pcall(function() h.Health = h.MaxHealth end)
 end
 end))

 -- Layer 4: if it enters the dead state, revert it
 table.insert(godConns, h.StateChanged:Connect(function(_, new)
 if Config.Godmode and (new == Enum.HumanoidStateType.Dead
 or new == Enum.HumanoidStateType.Ragdoll) then
 pcall(function()
 h:ChangeState(Enum.HumanoidStateType.GettingUp)
 h.Health = h.MaxHealth
 end)
 end
 end))

 -- Katman 5: Died sinyali (son savunma)
 table.insert(godConns, h.Died:Connect(function()
 if Config.Godmode then
 pcall(function() h.Health = h.MaxHealth end)
 end
 end))

 -- Layer 6: if someone removes the ForceField, put it back
 table.insert(godConns, char.ChildRemoved:Connect(function(o)
 if Config.Godmode and o.Name == "nuggiezFF" then
 task.wait(0.1)
 if Config.Godmode and char.Parent and not char:FindFirstChild("nuggiezFF") then
 local ff = Instance.new("ForceField")
 ff.Name = "nuggiezFF"; ff.Visible = false; ff.Parent = char
 end
 end
 end))
end

local function setGodmode(on)
 Config.Godmode = on
 clearGodConns()
 local c = getChar()
 if not on then
 if c then
 local ff = c:FindFirstChild("nuggiezFF")
 if ff then ff:Destroy() end
 local h = c:FindFirstChildOfClass("Humanoid")
 if h then pcall(function()
 h:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
 h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
 h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
 if h.MaxHealth == math.huge then h.MaxHealth = 100; h.Health = 100 end
 end) end
 end
 return
 end
 armGodmode(c)
end

-- TEK CharacterAdded — godmode + speed + jump + fly hepsini geri uygular
LocalPlayer.CharacterAdded:Connect(function(char)
 char:WaitForChild("Humanoid", 10)
 task.wait(0.4)

 -- Godmode yeniden kur (v3.4'te eksik olan buydu)
 if Config.Godmode then
 clearGodConns()
 armGodmode(char)
 end

 -- Fly yeniden kur
 if Config.FlyEnabled then task.wait(0.3); startFly() end

 -- Speed / Jump geri uygula
 local h = char:FindFirstChildOfClass("Humanoid")
 if h then
 if Config.SpeedEnabled then pcall(function() h.WalkSpeed = Config.WalkSpeed end) end
 if Config.JumpEnabled then
 pcall(function()
 if h.UseJumpPower then h.JumpPower = Config.JumpPower
 else h.JumpHeight = Config.JumpPower/10 end
 end)
 end
 end
end)

-- Katman 7: hasar paketlerini kes (guiDamageEvent client'tan gidiyor)
if hookmetamethod and checkcaller and not getgenv().__nuggiezDmgHook then
 getgenv().__nuggiezDmgHook = true
 local oldNC
 oldNC = hookmetamethod(game, "__namecall", function(self, ...)
 local m = getnamecallmethod and getnamecallmethod() or ""
 if not checkcaller() and (m == "FireServer" or m == "InvokeServer")
 and typeof(self) == "Instance" then
 local n = self.Name
 if Config.BlockDamage and (n == "guiDamageEvent" or n == "brawlEvent") then
 return nil -- damage packet never reaches server
 end
 end
 return oldNC(self, ...)
 end)
end

-- Godmode keeper (sped up: 0.3 -> 0.1) + Anti Void
task.spawn(function()
 while true do
 if Config.Godmode then
 local c = getChar()
 if c then
 local h = c:FindFirstChildOfClass("Humanoid")
 if h and h.Health < h.MaxHealth then
 pcall(function() h.Health = h.MaxHealth end)
 end
 if not c:FindFirstChild("nuggiezFF") then
 local ff = Instance.new("ForceField")
 ff.Name="nuggiezFF"; ff.Visible=false; ff.Parent=c
 end
 end
 end
 if Config.AntiVoid then
 local hrp = getHRP()
 if hrp and hrp.Position.Y < -150 then
 pcall(function() hrp.CFrame = CFrame.new(0, 60, 0) end)
 end
 end
 task.wait(0.1)
 end
end)

-- ════════════════════════════════════════════════════════════
-- HATCH TRACKER (hatch result format learned from the leak)
-- openCrystalRemote:InvokeServer("openCrystal", <crystal>, <n>)
-- -> [1]=petName [2]=rarity [3]=imageUrl [4]=nil
-- ════════════════════════════════════════════════════════════

local HatchStats = { total=0, byRarity={}, byPet={}, last="-", lastRarity="-", session=os.time() }
local RARE_WORDS = { "omega","secret","exclusive","mythic","legendary","titan","ultimate","godly" }

local function isRare(rarity)
 local r = tostring(rarity):lower()
 for _,w in ipairs(RARE_WORDS) do if r:find(w,1,true) then return true end end
 return false
end

local function hatchOnce(crystal, amount)
 if not R.openCrystal then return nil end
 amount = amount or 1
 -- crystal may arrive as a string, find its object in workspace first
 local crystalObj = nil
 if type(crystal) == "string" then
 pcall(function()
 for _, o in ipairs(workspace:GetDescendants()) do
 if o.Name == crystal and (o:IsA("Model") or o:IsA("Part") or o:IsA("BasePart")) then
 crystalObj = o; break
 end
 end
 end)
 elseif typeof(crystal) == "Instance" then
 crystalObj = crystal
 crystal = crystal.Name
 end

 -- try both string and object (different versions expect different things)
 local res = table.pack(pcall(function()
 return R.openCrystal:InvokeServer("openCrystal", crystalObj or crystal, amount)
 end))
 if not res[1] then
 -- string ile tekrar dene
 res = table.pack(pcall(function()
 return R.openCrystal:InvokeServer("openCrystal", crystal, amount)
 end))
 if not res[1] then return nil end
 end
 -- res[2]=petName, res[3]=rarity, res[4]=image
 local petName, rarity, img = res[2], res[3], res[4]
 if petName and petName ~= "" then
 HatchStats.total = HatchStats.total + 1
 HatchStats.last = tostring(petName)
 HatchStats.lastRarity = tostring(rarity or "?")
 HatchStats.byPet[tostring(petName)] = (HatchStats.byPet[tostring(petName)] or 0) + 1
 local rk = tostring(rarity or "Unknown")
 HatchStats.byRarity[rk] = (HatchStats.byRarity[rk] or 0) + 1
 return { pet=tostring(petName), rarity=rk, image=tostring(img or "") }
 end
 return nil
end

-- Auto Hatch (now reads the result)
task.spawn(function() while true do
 if Config.AutoHatchCrystal and Config.SelectedCrystal~="" then
 local got = hatchOnce(Config.SelectedCrystal, 1)
 if got and Config.NotifyRare and isRare(got.rarity) then
 pcall(function()
 WindUI:Notify({ Title="-"..got.rarity.."!", Content=got.pet, Duration=5 })
 end)
 end
 end
 task.wait(math.max(Config.HatchDelay,0.05))
end end)

-- ════════════════════════════════════════════════════════════
-- CRYSTAL PET LIST FINDER (v3.4)
-- Which pets can come out of a crystal? -> read from the game
-- ════════════════════════════════════════════════════════════

local CrystalDB = {} -- [crystalName] = { {name=,rarity=,chance=}, ... }
local CrystalNames = {} -- all found crystal names
local DB_SOURCE = "not scanned"

-- Safely require a ModuleScript
local function tryRequire(m)
 local ok, res = pcall(require, m)
 if ok and type(res) == "table" then return res end
 return nil
end

-- Try to extract a pet list from the table (flexible: different schemas)
local function harvestPets(tbl, depth)
 depth = depth or 0
 if depth > 4 or type(tbl) ~= "table" then return nil end
 local pets = {}

 for k, v in pairs(tbl) do
 if type(v) == "table" then
 -- schema A: { Name="X", Rarity="Omega", Chance=0.1 }
 local nm = v.Name or v.name or v.petName or v.PetName
 or (type(k)=="string" and k or nil)
 local rar = v.Rarity or v.rarity or v.Tier or v.tier or v.class
 local chc = v.Chance or v.chance or v.Odds or v.odds
 or v.Weight or v.weight or v.Rate or v.rate
 if nm and (rar or chc) then
 table.insert(pets, {
 name = tostring(nm),
 rarity = tostring(rar or "?"),
 chance = tonumber(chc) or 0,
 })
 end
 elseif type(v) == "number" and type(k) == "string" and #k > 2 then
 -- schema B: { ["Pet Name"] = 12.5 } (name = chance)
 table.insert(pets, { name = k, rarity = "?", chance = v })
 end
 end

 if #pets > 0 then return pets end

 -- daha derine in
 for _, v in pairs(tbl) do
 if type(v) == "table" then
 local r = harvestPets(v, depth + 1)
 if r and #r > 0 then return r end
 end
 end
 return nil
end

-- Try to find the crystal database from 3 sources
local function buildCrystalDB()
 CrystalDB = {}; CrystalNames = {}; DB_SOURCE = "not found"

 -- KAYNAK 1: ReplicatedStorage'daki ModuleScript'ler
 local moduleHits = 0
 for _, m in ipairs(ReplicatedStorage:GetDescendants()) do
 if m:IsA("ModuleScript") then
 local n = m.Name:lower()
 if n:find("crystal") or n:find("egg") or n:find("pet")
 or n:find("hatch") or n:find("loot") or n:find("drop") then
 local data = tryRequire(m)
 if data then
 for key, val in pairs(data) do
 if type(key) == "string" and type(val) == "table" then
 local pets = harvestPets(val)
 if pets and #pets > 1 then
 CrystalDB[key] = pets
 table.insert(CrystalNames, key)
 moduleHits = moduleHits + 1
 end
 end
 end
 -- the module itself may be a single crystal
 if moduleHits == 0 then
 local pets = harvestPets(data)
 if pets and #pets > 1 then
 CrystalDB[m.Name] = pets
 table.insert(CrystalNames, m.Name)
 moduleHits = moduleHits + 1
 end
 end
 end
 end
 end
 end
 if moduleHits > 0 then DB_SOURCE = "ModuleScript ("..moduleHits.." crystal)" end

 -- SOURCE 2: pet lists under the crystal models in workspace/RS
 if moduleHits == 0 then
 local roots = { workspace, ReplicatedStorage }
 for _, root in ipairs(roots) do
 for _, o in ipairs(root:GetDescendants()) do
 if o.Name:lower():find("crystal") and (o:IsA("Model") or o:IsA("Folder")) then
 local pets = {}
 for _, c in ipairs(o:GetDescendants()) do
 if c:IsA("StringValue") or c:IsA("NumberValue") then
 if #c.Name > 2 then
 table.insert(pets, {
 name = c.Name, rarity = "?",
 chance = tonumber(c.Value) or 0,
 })
 end
 end
 end
 if #pets > 1 then
 CrystalDB[o.Name] = pets
 table.insert(CrystalNames, o.Name)
 DB_SOURCE = "workspace modelleri"
 end
 end
 end
 end
 end

 -- SOURCE 3: the hatch preview screen in PlayerGui
 if next(CrystalDB) == nil then
 local pg = LocalPlayer:FindFirstChild("PlayerGui")
 if pg then
 for _, o in ipairs(pg:GetDescendants()) do
 local n = o.Name:lower()
 if (n:find("crystal") or n:find("egg")) and (o:IsA("Frame") or o:IsA("ScrollingFrame")) then
 local pets, seen = {}, {}
 for _, lbl in ipairs(o:GetDescendants()) do
 if lbl:IsA("TextLabel") and lbl.Text and #lbl.Text > 3 and #lbl.Text < 50 then
 local t = lbl.Text
 if not t:find("^%d") and not seen[t] then
 seen[t] = true
 table.insert(pets, { name=t, rarity="?", chance=0 })
 end
 end
 end
 if #pets > 2 then
 CrystalDB[o.Name] = pets
 table.insert(CrystalNames, o.Name)
 DB_SOURCE = "PlayerGui preview"
 end
 end
 end
 end
 end

 table.sort(CrystalNames)
 return CrystalDB, DB_SOURCE
end

-- Pet list learned from hatch history (backup if DB not found)
local function learnedPetsFor(crystal)
 local out = {}
 for petName, cnt in pairs(HatchStats.byPet) do
 table.insert(out, { name=petName, rarity="?", chance=cnt })
 end
 table.sort(out, function(a,b) return a.chance > b.chance end)
 return out
end

-- ════════════════════════════════════════════════════════════
-- PET HUNT - keep opening until the target pet is hatched, sell the rest
-- ════════════════════════════════════════════════════════════

local HuntStats = { attempts=0, sold=0, found=false, foundPet="", startTime=0 }

local function isTarget(petName)
 for _, t in ipairs(Config.HuntTargets) do
 if tostring(t):lower() == tostring(petName):lower() then return true end
 end
 return false
end

-- Find and sell the most recently hatched pet (targets the newest object by name)
local function sellPetByName(name)
 if not R.sellPet then return false end
 local sold = false
 for _, v in ipairs(collectPetObjects()) do
 if v.Name == name then
 fastSend(R.sellPet, "sellPet", v, "sell")
 sold = true
 break -- only sells 1 (the new one)
 end
 end
 return sold
end

task.spawn(function()
 while true do
 if Config.HuntEnabled and #Config.HuntTargets > 0 and Config.SelectedCrystal ~= "" then
 local got = hatchOnce(Config.SelectedCrystal, 1)
 if got then
 HuntStats.attempts = HuntStats.attempts + 1
 if isTarget(got.pet) then
 -- HEDEF BULUNDU
 HuntStats.found = true
 HuntStats.foundPet = got.pet
 if Config.HuntStopOnFind then
 Config.HuntEnabled = false
 Config.AutoHatchCrystal = false
 end
 pcall(function()
 WindUI:Notify({
 Title = " HEDEF BULUNDU!",
 Content = got.pet.." ("..got.rarity..")\n"..HuntStats.attempts.." denemede",
 Duration = 10,
 })
 end)
 print(("[nuggiez HUNT] %s found! %d attempts, %d sold")
 :format(got.pet, HuntStats.attempts, HuntStats.sold))
 else
 -- not the target -> sell
 if Config.HuntAutoSell then
 if sellPetByName(got.pet) then
 HuntStats.sold = HuntStats.sold + 1
 end
 end
 end
 end
 task.wait(math.max(Config.HuntDelay, 0.05))
 else
 task.wait(0.3)
 end
 end
end)

-- ════════════════════════════════════════════════════════════
-- EXPLOIT DETECTOR - server hop if a suspicious player is seen
-- ════════════════════════════════════════════════════════════

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local DetectorLog = {} -- son tespitler
local playerTrack = {} -- [player] = { lastPos, lastCheck, score, ... }

local function logDetect(txt)
 table.insert(DetectorLog, 1, os.date("%H:%M:%S").." "..txt)
 while #DetectorLog > 12 do table.remove(DetectorLog) end
 print("[DETECTOR] "..txt)
end

local hopping = false
local function serverHop(reason)
 if hopping then return end
 hopping = true
 logDetect("SERVER HOP: "..reason)
 pcall(function()
 WindUI:Notify({ Title=L("serverHopping"), Content=reason, Duration=5 })
 end)
 task.wait(1)

 -- yeni server bul
 local placeId = game.PlaceId
 local ok = pcall(function()
 local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
 local res = HttpService:JSONDecode(game:HttpGet(url))
 local candidates = {}
 for _, s in ipairs(res.data or {}) do
 if s.playing and s.maxPlayers and s.playing < s.maxPlayers
 and s.id ~= game.JobId then
 table.insert(candidates, s.id)
 end
 end
 if #candidates > 0 then
 TeleportService:TeleportToPlaceInstance(placeId, candidates[math.random(#candidates)], LocalPlayer)
 else
 TeleportService:Teleport(placeId, LocalPlayer)
 end
 end)
 if not ok then
 pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
 end
 task.wait(5)
 hopping = false
end

-- ════════════════════════════════════════════════════════════
-- DETECTOR v2 (v3.5) - FALSE ALARM FIXED
-- ════════════════════════════════════════════════════════════
-- v3.4 problem: it flagged EVERYONE using speed/fly as a hacker and server hopped.
-- In this game speed already gets very high with rebirth + we use speed too.
--
-- Solution:
-- 1) Speed/fly no longer triggers on its own (only adds a "light suspicion" score)
-- 2) Only behavior that HURTS YOU triggers (kill farm, attacking)
-- 3) "Threat Only Mode" - ignores fast players, catches attackers
-- 4) Whitelist + hop cooldown + hop limiti

local HOP_COOLDOWN = 45 -- min seconds between hops
local lastHopTime = 0
local hopCount = 0

-- Weighted signature system: each behavior has a score
-- Only triggers when the total score crosses the threshold
-- WHO the attacker approached (last VICTIM_WINDOW seconds) - kill farm signature
local VICTIM_WINDOW = 15 -- victim listesi bu kadar saniye tutulur
local VICTIM_DIST = 14 -- within this distance counts as victim
local TP_THRESHOLD = 90 -- jump bigger than this = teleport
local ATTACK_DIST = 16 -- within this + hp drop = attack

local function trackVictim(tr, victimName, now)
 tr.victims = tr.victims or {}
 -- eski victim'leri temizle
 local alive = {}
 for name, t in pairs(tr.victims) do
 if now - t < VICTIM_WINDOW then alive[name] = t end
 end
 if victimName then alive[victimName] = now end
 tr.victims = alive
 -- unique victim count
 local n = 0; for _ in pairs(alive) do n = n + 1 end
 return n
end

local function analyzePlayer(p)
 if p == LocalPlayer then return end
 if Config.DetectorWhitelist[p.Name] then return end

 local char = p.Character
 if not char then return end
 local hrp = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChildOfClass("Humanoid")
 if not hrp then return end

 local myChar = LocalPlayer.Character
 local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
 local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

 local tr = playerTrack[p]
 if not tr then
 playerTrack[p] = { lastPos=hrp.Position, lastCheck=tick(), score=0,
 nearMeTime=0, myHealthDrop=0, victims={}, tpCount=0 }
 return
 end

 local now = tick()
 local dt = now - tr.lastCheck
 if dt < 0.4 then return end
 local dist = (hrp.Position - tr.lastPos).Magnitude
 local speed = dist / dt
 tr.lastPos = hrp.Position
 tr.lastCheck = now

 local flags = {}
 local score = 0
 local heavy = false -- heavy signature (enough to hop)

 -- ═══ HEAVY SIGNATURE 1: TELEPORT (big position jump) ═══
 -- TP-killer's core trait: suddenly teleports very far away.
 -- In this game normal speed can be very high but 90 stud/0.4s
 -- = 225 stud/s instant jump does not happen with normal walking.
 if dist > TP_THRESHOLD then
 tr.tpCount = (tr.tpCount or 0) + 1
 tr.lastTpTime = now
 -- a single teleport is light, but repeated teleport in a short time = certain
 if tr.tpCount >= 2 then
 score = score + 45
 table.insert(flags, "TELEPORT x"..tr.tpCount.." ("..math.floor(dist).." stud)")
 end
 else
 -- teleport counter slowly decays
 if now - (tr.lastTpTime or 0) > 3 then
 tr.tpCount = math.max(0, (tr.tpCount or 0) - 1)
 end
 end

 -- ═══ HEAVY SIGNATURE 2: APPROACHING MULTIPLE PEOPLE (kill farm) ═══
 -- TP-killer kills one by one: teleport to A, kill, teleport to B, kill.
 -- instead of nearCount>=2: count how many DIFFERENT people approached in last 15 s.
 local nearCount = 0
 local victimHit = nil -- nearby player losing hp
 for _, other in ipairs(Players:GetPlayers()) do
 if other ~= p and other ~= LocalPlayer and other.Character then
 local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
 if ohrp then
 local m = (ohrp.Position - hrp.Position).Magnitude
 if m < VICTIM_DIST then
 nearCount = nearCount + 1
 victimHit = other
 end
 end
 end
 end

 -- if currently near someone, add to the victim list
 if victimHit then
 local vc = trackVictim(tr, victimHit.Name, now)
 -- approached 2+ different people within 15 s = kill farm
 if vc >= 2 then
 score = score + 60
 table.insert(flags, "KILL FARM (TP'd to "..vc.." players)")
 heavy = true
 end
 else
 -- clean up the window (drop old victims)
 trackVictim(tr, nil, now)
 end

 -- ═══ HEAVY SIGNATURE 3: KILLING SOMEONE ELSE ═══
 -- A player near the attacker is losing health/dying.
 if victimHit then
 local vh = victimHit.Character and victimHit.Character:FindFirstChildOfClass("Humanoid")
 if vh then
 local vhp = vh.Health
 tr.victimHP = tr.victimHP or {}
 local prev = tr.victimHP[victimHit.Name]
 tr.victimHP[victimHit.Name] = vhp
 if prev and vhp < prev - 5 then
 -- health dropped noticeably and the attacker is nearby
 score = score + 55
 table.insert(flags, "KILLING PLAYERS ("..victimHit.Name.." -"..math.floor(prev-vhp).."hp)")
 heavy = true
 -- if killed, extra
 if vhp <= 0 then
 score = score + 25
 end
 end
 end
 end

 -- ═══ HEAVY SIGNATURE 4: ATTACKING ME ═══
 -- Even with godmode: if they stand next to me and attack, catch them.
 -- Even if my health is not dropping (godmode), an attack attempt = threat.
 local nearMe = myHRP and (hrp.Position - myHRP.Position).Magnitude < ATTACK_DIST
 if nearMe then
 tr.nearMeTime = tr.nearMeTime + dt
 -- is my health dropping? (if godmode is off)
 if myHum then
 local hp = myHum.Health
 if tr.lastMyHP and hp < tr.lastMyHP - 1 then
 tr.myHealthDrop = tr.myHealthDrop + (tr.lastMyHP - hp)
 end
 tr.lastMyHP = hp
 end
 -- if there is health loss, definite attack
 if tr.myHealthDrop > 15 then
 score = score + 90
 table.insert(flags, "BANA SALDIRIYOR (-"..math.floor(tr.myHealthDrop).." hp)")
 heavy = true
 -- if health isn't dropping but they're right next to me for a long time + I'm also a TP victim
 elseif tr.nearMeTime > 4 and (tr.tpCount or 0) > 0 then
 score = score + 50
 table.insert(flags, "ATTACKING ME ("..math.floor(tr.nearMeTime).."s)")
 heavy = true
 end
 else
 tr.nearMeTime = math.max(0, tr.nearMeTime - dt)
 tr.myHealthDrop = math.max(0, tr.myHealthDrop - dt*3)
 end

 -- ═══ LIGHT SIGNATURES (Strict Mode only) ═══
 if Config.DetectorStrictMode then
 if speed > 250 and dist > 120 then
 score = score + 25
 table.insert(flags, "extreme speed ("..math.floor(speed)..")")
 end
 if hum and hum.WalkSpeed > 200 then
 score = score + 20
 table.insert(flags, "walkspeed "..math.floor(hum.WalkSpeed))
 end
 for _, o in ipairs(hrp:GetChildren()) do
 if o:IsA("BodyVelocity") or o:IsA("BodyGyro") or o:IsA("LinearVelocity") then
 score = score + 15
 table.insert(flags, "fly objesi")
 break
 end
 end
 end

 -- ═══ KARAR ═══
 tr.score = math.max(0, (tr.score or 0) * 0.8 + score) -- decays slowly

 local THRESHOLD = 50 + (Config.DetectorSensitivity - 1) * 20
 -- hassasiyet 1 -> 50 (hassas) | 3 -> 90 | 5 -> 130

 if tr.score >= THRESHOLD and #flags > 0 then
 if not tr.reported or (now - (tr.reportTime or 0)) > 15 then
 tr.reported = true
 tr.reportTime = now
 local msg = p.Name.." "..table.concat(flags, ", ")
 logDetect(msg)
 pcall(function()
 WindUI:Notify({ Title=L("threat"), Content=msg, Duration=6 })
 end)
 -- server hop: if there is a heavy signature AND cooldown is over
 if Config.DetectorAutoHop and heavy and (now - lastHopTime) > HOP_COOLDOWN then
 lastHopTime = now
 hopCount = hopCount + 1
 task.spawn(serverHop, p.Name..": "..flags[1])
 end
 end
 end
end

Players.PlayerRemoving:Connect(function(p) playerTrack[p] = nil end)
Players.PlayerAdded:Connect(function(p)
 p.CharacterAdded:Connect(function()
 task.wait(0.5)
 if playerTrack[p] then playerTrack[p].spawnTime = tick() end
 end)
end)

task.spawn(function()
 while true do
 if Config.DetectorEnabled then
 for _, p in ipairs(Players:GetPlayers()) do
 pcall(analyzePlayer, p)
 end
 end
 task.wait(0.5)
 end
end)

-- Auto Quests / Gift / Chest
task.spawn(function() while true do
 if Config.AutoQuests then send(R.quests,"claimAll"); send(R.quests,"claim") end
 if Config.AutoFreeGift then send(R.freeGift,"claim"); send(R.freeGift) end
 if Config.AutoChest then send(R.checkChest,"claim"); send(R.checkChest) end
 task.wait(5)
end end)

-- Visual Edits
local function applyVisuals()
 pcall(function()
 local ls = LocalPlayer:FindFirstChild("leaderstats")
 if not ls then return end
 local function setv(flag,valKey,...)
 if not Config[flag] then return end
 for _,n in ipairs({...}) do
 local o = ls:FindFirstChild(n)
 if o then
 local num = tonumber(Config[valKey])
 if o:IsA("StringValue") then o.Value = tostring(Config[valKey])
 elseif num then o.Value = num end
 return
 end
 end
 end
 setv("VisualStrength","VisualStrengthVal","Strength","strength","")
 setv("VisualGems","VisualGemsVal","Gems","gems","")
 setv("VisualCoins","VisualCoinsVal","Coins","coins","")
 setv("VisualRebirths","VisualRebirthsVal","Rebirths","rebirths")
 setv("VisualLevel","VisualLevelVal","Level","level")
 setv("VisualWin","VisualWinVal","Wins","wins")
 end)
 pcall(function()
 local pg = LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return end
 for _,g in ipairs(pg:GetDescendants()) do
 if g:IsA("TextLabel") then
 local t = g.Text:lower()
 if Config.VisualStrength and t:find("strength") then g.Text="Strength: "..Config.VisualStrengthVal
 elseif Config.VisualGems and (t:find("gem") or t:find("")) then g.Text="Gems: "..Config.VisualGemsVal
 elseif Config.VisualCoins and (t:find("coin") or t:find("")) then g.Text="Coins: "..Config.VisualCoinsVal end
 end
 end
 end)
end
task.spawn(function() while true do applyVisuals(); task.wait(1) end end)

-- Gym TP
local function tpToGym(gymName)
 if not R.areaTravel then return false end
 local done=false
 pcall(function()
 local ac = workspace:FindFirstChild("areaCircles") or workspace:WaitForChild("areaCircles",5)
 if not ac then return end
 for _,circle in ipairs(ac:GetChildren()) do
 local an = circle:FindFirstChild("AreaName") or circle:FindFirstChild("areaName")
 or circle:FindFirstChild("Name") or circle:FindFirstChild("name")
 local val
 if an then
 val = (an:IsA("ValueBase") and tostring(an.Value))
 or (an:IsA("TextLabel") and an.Text) or tostring(an)
 else val = circle.Name end
 if val and val:lower():find(gymName:lower(),1,true) then
 invoke(R.areaTravel,"travelToArea",circle); done=true; break
 end
 end
 end)
 return done
end

-- ════════════════════════════════════════════════════════════
-- BUILD GUI
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.75,"Building GUI...")

local Window = WindUI:CreateWindow({
 Title="nuggiez private", Icon=LOGO_TEXTURE, Author="Muscle Legends 2",
 Folder="nuggiez_private", Size=UDim2.fromOffset(640,500),
 MinSize=Vector2.new(520,340), MaxSize=Vector2.new(880,620),
 Transparent=true, Theme="NuggiezBlue", Resizable=true,
 SideBarWidth=200, HideSearchBar=false,
 OpenButton={
 Title="nuggiez", Icon=LOGO_TEXTURE, StrokeThickness=2, Draggable=true,
 Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromHex("#000000")),
 ColorSequenceKeypoint.new(0.35,Color3.fromHex("#0088ff")),
 ColorSequenceKeypoint.new(0.7,Color3.fromHex("#004499")),
 ColorSequenceKeypoint.new(1,Color3.fromHex("#000000")),
 }),
 },
 User={ Enabled=true, Anonymous=false },
})

pcall(function()
 Window:Tag({ Title="private", Color=Color3.fromHex("#ffcc00") })
 Window:Tag({ Title="ML2", Color=Color3.fromHex("#2e8eff") })
end)

task.spawn(function() pcall(function()
 local bgPane = Window.UIElements and Window.UIElements.Main and Window.UIElements.Main.Background
 if not bgPane then return end
 local b=Instance.new("ImageLabel"); b.Name="NuggiezBG"; b.BackgroundTransparency=1
 b.Size=UDim2.fromScale(1,1); b.ImageTransparency=0.4
 b.ScaleType=Enum.ScaleType.Crop; b.Parent=bgPane
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
 b.Image = LOGO_TEXTURE
end) end)

task.spawn(function() pcall(function()
 local btn = Window.OpenButtonMain and Window.OpenButtonMain.Button; if not btn then return end
 local gs,ss={},{}
 for _,o in ipairs(btn:GetDescendants()) do
 if o:IsA("UIGradient") then table.insert(gs,o) end
 if o:IsA("UIStroke") then table.insert(ss,o) end
 end
 local r,t=0,0
 while btn.Parent do
 local dt=task.wait(); r=(r+dt*150)%360; t=t+dt
 for _,g in ipairs(gs) do g.Rotation=r end
 local p=0.1+0.25*(math.sin(t*3)*0.5+0.5)
 for _,s in ipairs(ss) do s.Transparency=p end
 end
end) end)

-- ════════════════════════════════════════════════════════════
-- TAB: MAIN
-- ════════════════════════════════════════════════════════════

local MainTab = Window:Tab({ Title="Main", Icon="solar:home-2-bold" })

MainTab:Section({ Title=L("status") })

MainTab:Paragraph({
 Title=L("repSystem"),
 Desc = muscleEvent
 and L("repFound")
 or (L("repMissing")..(R.machineInteract and L("repUsingMachine") or L("repNotFound"))),
})

MainTab:Paragraph({
 Title=L("remoteStatus"),
 Desc = (#MISSING>0) and (L("remoteMissing")..table.concat(MISSING,", ")) or L("remoteAll"),
})

MainTab:Section({ Title=L("defense") })
MainTab:Toggle({ Title=L("antiAttack"), Value=false,
 Callback=function(s) Config.AntiAttack=s end })

-- ════════════════════════════════════════════════════════════
-- TAB: PLAYER (v3.3)
-- ════════════════════════════════════════════════════════════

local PlayerTab = Window:Tab({ Title="Player", Icon="solar:user-bold" })

PlayerTab:Section({ Title=L("movement") })

PlayerTab:Toggle({
 Title=L("speedMult"),
 Desc=L("speedMultDesc"),
 Value=false,
 Callback=function(s)
 Config.SpeedEnabled = s
 local h = getHum()
 if h then pcall(function() h.WalkSpeed = s and Config.WalkSpeed or Config.DefaultSpeed end) end
 end,
})

PlayerTab:Slider({
 Title=L("walkSpeed"),
 Desc=L("walkSpeedDesc"),
 Value={ Min=16, Max=500, Default=16 }, Step=2,
 Callback=function(v)
 Config.WalkSpeed = tonumber(v) or 16
 if Config.SpeedEnabled then
 local h=getHum(); if h then pcall(function() h.WalkSpeed=Config.WalkSpeed end) end
 end
 end,
})

PlayerTab:Slider({
 Title=L("speedMultVal"),
 Desc=L("speedMultValDesc"),
 Value={ Min=1, Max=20, Default=1 }, Step=1,
 Callback=function(v)
 local mult = tonumber(v) or 1
 Config.WalkSpeed = 16 * mult
 Config.SpeedEnabled = true
 local h=getHum(); if h then pcall(function() h.WalkSpeed=Config.WalkSpeed end) end
 end,
})

PlayerTab:Toggle({
 Title=L("jumpPower"),
 Value=false,
 Callback=function(s)
 Config.JumpEnabled = s
 local h = getHum()
 if h then pcall(function()
 if h.UseJumpPower then h.JumpPower = s and Config.JumpPower or Config.DefaultJump
 else h.JumpHeight = (s and Config.JumpPower or Config.DefaultJump)/10 end
 end) end
 end,
})

PlayerTab:Slider({
 Title=L("jumpPowerVal"),
 Desc=L("jumpPowerValDesc"),
 Value={ Min=50, Max=500, Default=50 }, Step=10,
 Callback=function(v)
 Config.JumpPower = tonumber(v) or 50
 if Config.JumpEnabled then
 local h=getHum(); if h then pcall(function()
 if h.UseJumpPower then h.JumpPower=Config.JumpPower
 else h.JumpHeight=Config.JumpPower/10 end
 end) end
 end
 end,
})

PlayerTab:Toggle({
 Title=L("infJump"),
 Desc=L("infJumpDesc"),
 Value=false,
 Callback=function(s) Config.InfiniteJump = s end,
})

PlayerTab:Section({ Title=L("fly") })

PlayerTab:Toggle({
 Title=L("fly"),
 Desc=L("flyDesc"),
 Value=false,
 Callback=function(s) setFly(s) end,
})

PlayerTab:Slider({
 Title=L("flySpeed"),
 Value={ Min=10, Max=400, Default=60 }, Step=10,
 Callback=function(v) Config.FlySpeed = tonumber(v) or 60 end,
})

PlayerTab:Button({
 Title=L("flyUp"),
 Callback=function()
 flyDir = Vector3.new(0,1,0)
 task.delay(0.8, function() flyDir = Vector3.new() end)
 end,
})

PlayerTab:Button({
 Title=L("flyDown"),
 Callback=function()
 flyDir = Vector3.new(0,-1,0)
 task.delay(0.8, function() flyDir = Vector3.new() end)
 end,
})

PlayerTab:Toggle({
 Title=L("noclip"),
 Value=false,
 Callback=function(s) Config.NoClip = s end,
})

PlayerTab:Section({ Title=L("immortality") })

PlayerTab:Toggle({
 Title=L("godmode"),
 Desc=L("godmodeDesc"),
 Value=false,
 Callback=function(s)
 setGodmode(s)
 WindUI:Notify({
 Title = s and L("godmode") or L("godmode"),
 Content = s and L("godmodeDesc") or L("playerReset"),
 Duration = 3,
 })
 end,
})

PlayerTab:Toggle({
 Title=L("blockDamage"),
 Desc=L("blockDamageDesc"),
 Value=false,
 Callback=function(s)
 Config.BlockDamage = s
 if s and not (hookmetamethod and checkcaller) then
 WindUI:Notify({ Title=L("notSupported"), Content=L("blockNotif"), Duration=4 })
 end
 end,
})

PlayerTab:Toggle({
 Title=L("antiVoid"),
 Desc=L("antiVoidDesc"),
 Value=false,
 Callback=function(s) Config.AntiVoid = s end,
})

PlayerTab:Button({
 Title=L("healFull"),
 Callback=function()
 local h = getHum()
 if h then pcall(function() h.Health = h.MaxHealth end)
 WindUI:Notify({ Title=L("healed"), Content=L("healthRestored"), Duration=2 })
 end
 end,
})

PlayerTab:Section({ Title=L("resetSection") })

PlayerTab:Button({
 Title=L("resetPlayer"),
 Callback=function()
 Config.SpeedEnabled=false; Config.JumpEnabled=false
 Config.InfiniteJump=false; Config.NoClip=false
 Config.AntiVoid=false; Config.BlockDamage=false
 setFly(false); setGodmode(false)
 local h = getHum()
 if h then pcall(function()
 h.WalkSpeed = Config.DefaultSpeed
 if h.UseJumpPower then h.JumpPower = Config.DefaultJump else h.JumpHeight = 7.2 end
 end) end
 WindUI:Notify({ Title=L("resetSection"), Content=L("playerReset"), Duration=3 })
 end,
})

-- ════════════════════════════════════════════════════════════
-- TAB: AUTO FARMS
-- ════════════════════════════════════════════════════════════

local FarmTab = Window:Tab({ Title="Auto Farms", Icon="solar:chart-2-bold" })

FarmTab:Section({ Title=L("killAura") })
FarmTab:Toggle({ Title=L("autoKill"), Value=false,
 Callback=function(s) Config.AutoKillAll=s end })
FarmTab:Slider({ Title=L("killSpeed"), Value={Min=0.05,Max=2,Default=0.2}, Step=0.05,
 Callback=function(v) Config.KillAuraSpeed=tonumber(v) or 0.2 end })

FarmTab:Section({ Title=L("repSection") })
FarmTab:Toggle({ Title=L("fastRep"), Desc=L("fastRepDesc"), Value=false,
 Callback=function(s) Config.VeryFastRep=s end })
FarmTab:Slider({ Title=L("repSpeed"), Desc=L("repSpeedDesc"), Value={Min=0.01,Max=2,Default=0.05}, Step=0.01,
 Callback=function(v) Config.FastRepSpeed=tonumber(v) or 0.05 end })

FarmTab:Section({ Title=L("exercises") })
FarmTab:Toggle({ Title=L("autoDumbbell"), Value=false, Callback=function(s) Config.AutoDumbbell=s end })
FarmTab:Toggle({ Title=L("autoPushups"), Value=false, Callback=function(s) Config.AutoPushups=s end })
FarmTab:Toggle({ Title=L("autoHandstand"), Value=false, Callback=function(s) Config.AutoHandstand=s end })
FarmTab:Toggle({ Title=L("autoSitups"), Value=false, Callback=function(s) Config.AutoSitups=s end })
FarmTab:Slider({ Title=L("exerciseSpeed"), Value={Min=0.1,Max=2,Default=0.3}, Step=0.1,
 Callback=function(v) Config.ExerciseSpeed=tonumber(v) or 0.3 end })

FarmTab:Section({ Title=L("autoRewards") })
FarmTab:Toggle({ Title=L("autoQuests"), Value=false, Callback=function(s) Config.AutoQuests=s end })
FarmTab:Toggle({ Title=L("autoFreeGift"), Value=false, Callback=function(s) Config.AutoFreeGift=s end })
FarmTab:Toggle({ Title=L("autoChest"), Value=false, Callback=function(s) Config.AutoChest=s end })

-- ════════════════════════════════════════════════════════════
-- TAB: PETS
-- ════════════════════════════════════════════════════════════

local PetTab = Window:Tab({ Title="Pets", Icon="solar:heart-bold" })

local petDropdown, petStatus
local function cleanPetName(s)
 s = tostring(s); return s:match("^(.-)%s*%(%d+x%)$") or s
end

PetTab:Section({ Title=L("scanSection") })

petStatus = PetTab:Paragraph({
 Title=L("petSource"),
 Desc=L("petSourceDesc"),
})

PetTab:Button({
 Title=L("scanInv"),
 Callback=function()
 local pets, counts = scanPets()
 local values = {}
 for _,n in ipairs(pets) do table.insert(values, n.." ("..counts[n].."x)") end
 pcall(function() petStatus:SetDesc(
 (L("sourcePet")):format(PET_SOURCE, #pets)) end)
 if #values==0 then
 WindUI:Notify({ Title=L("noPets"), Content=L("noPetsDesc"), Duration=5 })
 return
 end
 if petDropdown then pcall(function() petDropdown:Refresh(values) end) end
 WindUI:Notify({ Title=L("scanned"), Content=#pets..L("scannedDesc")..PET_SOURCE..")", Duration=4 })
 print("\n=== PET INVENTORY ["..PET_SOURCE.."] ===")
 for _,n in ipairs(pets) do print(" "..n.." x"..counts[n]) end
 print("=== "..#pets.." unique ===\n")
 end,
})

petDropdown = PetTab:Dropdown({
 Title=L("petList"), Values={L("scanFirst")}, Multi=true, AllowNone=true,
 Callback=function(sel)
 local list={}
 if type(sel)=="table" then
 for k,v in pairs(sel) do
 if v==true then table.insert(list,cleanPetName(k))
 elseif type(v)=="string" then table.insert(list,cleanPetName(v)) end
 end
 elseif type(sel)=="string" then table.insert(list,cleanPetName(sel)) end
 Config.SelectedPets=list
 end,
})

PetTab:Section({ Title=L("evolveSection") })

PetTab:Toggle({
 Title=L("autoEvolve"),
 Desc=L("autoEvolveDesc"),
 Value=false,
 Callback=function(s)
 Config.AutoEvolvePets = s
 if s then
 -- also turn on the game's own auto-evolve
 send(R.autoEvolve, true); send(R.autoEvolve, "enable", true); send(R.autoEvolve)
 local n = turboEvolveAll()
 WindUI:Notify({ Title=L("turboEvolveOn"),
 Content=n..L("processing"), Duration=4 })
 end
 end,
})

PetTab:Slider({
 Title=L("evolveRate"),
 Desc=L("evolveRateDesc"),
 Value={ Min=0.05, Max=2, Default=0.1 }, Step=0.05,
 Callback=function(v) Config.EvolveTickRate = tonumber(v) or 0.1 end,
})

PetTab:Button({
 Title=L("evolveNow"),
 Callback=function()
 local n = turboEvolveAll()
 WindUI:Notify({ Title=L("turboEvolve"), Content=n..L("petsProcessed"), Duration=3 })
 end,
})

PetTab:Button({
 Title=L("learnFormat"),
 Desc=L("learnFormatDesc"),
 Callback=function()
 task.spawn(function()
 WindUI:Notify({ Title=L("learning"), Content=L("fewSeconds"), Duration=3 })
 local ok = learnFormat(R.petEvolve, "evolvePet", "evolve")
 WindUI:Notify({
 Title = ok and L("formatFoundShort") or L("formatNotFoundShort"),
 Content = ok and (L("formatFoundDesc")..tostring(EVOLVE_FMT)..L("formatSpeed"))
 or L("formatNotFoundDesc"),
 Duration = 5,
 })
 end)
 end,
})

PetTab:Section({ Title=L("equipBestSection") })

PetTab:Toggle({
 Title=L("autoEquipBest"),
 Desc=L("autoEquipBestDesc"),
 Value=false,
 Callback=function(s)
 Config.AutoEquipBest = s
 if s then
 local n, err = equipBestPets(Config.MaxEquipSlots)
 if err then
 WindUI:Notify({ Title=L("error"), Content=err, Duration=4 })
 else
 WindUI:Notify({ Title=L("equipBestOn"),
 Content=n..L("equipBestOnDesc"), Duration=4 })
 end
 end
 end,
})

PetTab:Slider({
 Title=L("equipSlots"),
 Desc=L("equipSlotsDesc"),
 Value={ Min=1, Max=10, Default=6 }, Step=1,
 Callback=function(v) Config.MaxEquipSlots = tonumber(v) or 6 end,
})

PetTab:Button({
 Title=L("equipNow"),
 Desc=L("equipNowDesc"),
 Callback=function()
 task.spawn(function()
 local n, err = equipBestPets(Config.MaxEquipSlots)
 if err then
 WindUI:Notify({ Title=L("error"), Content=err, Duration=4 })
 else
 WindUI:Notify({ Title=L("equipped"), Content=n..L("equippedDesc"), Duration=3 })
 -- write the ranking to the console
 local objs = collectPetObjects()
 table.sort(objs, function(a,b) return petScore(a) > petScore(b) end)
 print("\n=== EQUIP BEST ===")
 for i=1, math.min(#objs, 10) do
 print((" #%d %-30s score=%d"):format(i, objs[i].Name, petScore(objs[i])))
 end
 print("=== END ===\n")
 end
 end)
 end,
})

PetTab:Button({
 Title=L("printRank"),
 Desc=L("printRankDesc"),
 Callback=function()
 task.spawn(function()
 local objs = collectPetObjects()
 if #objs == 0 then
 WindUI:Notify({ Title=L("noPetsScan"), Content=L("noPetsScanDesc"), Duration=3 })
 return
 end
 table.sort(objs, function(a,b) return petScore(a) > petScore(b) end)
 print("\n"..L("petRankingHeader"))
 for i, v in ipairs(objs) do
 print((" #%d %-30s score=%d"):format(i, v.Name, petScore(v)))
 end
 print("Toplam "..#objs.." pet")
 print("=== END ===\n")
 WindUI:Notify({ Title=L("ranking"), Content=#objs..L("rankingDesc"), Duration=3 })
 end)
 end,
})

PetTab:Button({
 Title=L("unequipAll"),
 Desc=L("unequipAllDesc"),
 Callback=function()
 task.spawn(function()
 local objs = collectPetObjects()
 for _, v in ipairs(objs) do
 pcall(unequipPet, v)
 task.wait(0.05)
 end
 WindUI:Notify({ Title=L("unequipped"), Content=#objs..L("unequippedDesc"), Duration=3 })
 end)
 end,
})

PetTab:Section({ Title=L("sellSection") })

PetTab:Toggle({ Title=L("autoSell"), Value=false,
 Callback=function(s) Config.AutoSellPets=s end })

PetTab:Button({
 Title=L("addToSell"),
 Callback=function()
 if #Config.SelectedPets==0 then
 WindUI:Notify({ Title=L("noSelection"), Content=L("noSelectionDesc"), Duration=3 }); return
 end
 for _,n in ipairs(Config.SelectedPets) do table.insert(Config.SellPetList,n) end
 WindUI:Notify({ Title=L("added"), Content=#Config.SellPetList..L("addedDesc"), Duration=3 })
 end,
})

PetTab:Input({
 Title=L("manualAdd"), Placeholder=L("petName"),
 Callback=function(t)
 if t and t~="" then
 table.insert(Config.SellPetList,cleanPetName(t))
 WindUI:Notify({ Title=L("added"), Content=t, Duration=3 })
 end
 end,
})

PetTab:Button({
 Title=L("sellSelectedNow"),
 Callback=function()
 task.spawn(function()
 local n = forEachPetObject(Config.SelectedPets, function(v)
 tryAllFormats(R.sellPet,"sellPet",v); task.wait(0.05)
 end)
 WindUI:Notify({ Title=L("sold"), Content=n..L("soldDesc"), Duration=3 })
 end)
 end,
})

PetTab:Button({
 Title=L("clearSellList"),
 Callback=function() Config.SellPetList={}
 WindUI:Notify({ Title=L("cleared"), Content=L("clearedDesc"), Duration=3 }) end,
})

-- ════════════════════════════════════════════════════════════
-- CRYSTAL & HATCH (moved here from Teleports)
-- ════════════════════════════════════════════════════════════

PetTab:Section({ Title=L("crystalSection") })

local crystalDropdown, crystalStatus, petPoolDropdown, huntStatus

crystalStatus = PetTab:Paragraph({
 Title=L("crystalDB"),
 Desc=L("crystalDBDesc"),
})

-- ALL crystals in Muscle Legends 2 (hardcoded - backup if the game cannot be scanned)
local crystalListUI = {
 "Void Crystal",
 "Secret Void Crystal",
 "Ultra Shockwave Crystal",
 "Shockwave Crystal",
 "Jungle Crystal",
 "Inferno Crystal",
 "Frost Crystal",
 "Space Crystal",
 "Heaven Crystal",
 "Titan Crystal",
 "Mythical Crystal",
 "Legends Crystal",
 "Omega Crystal",
 "Divine Crystal",
 "Cosmic Crystal",
 "Starter Crystal",
 "Basic Crystal",
 "Common Crystal",
 "Rare Crystal",
 "Epic Crystal",
 "Legendary Crystal",
}

crystalDropdown = PetTab:Dropdown({
 Title = L("crystalSelect"),
 Values = crystalListUI,
 Value = crystalListUI[1],
 Callback = function(v)
 Config.SelectedCrystal = type(v)=="table" and tostring(v[1]) or tostring(v)
 -- push the pet pool of the selected crystal into the dropdown
 local pool = CrystalDB[Config.SelectedCrystal]
 if pool and #pool > 0 and petPoolDropdown then
 local vals = {}
 for _, p in ipairs(pool) do
 local s = p.name
 if p.rarity and p.rarity ~= "?" then s = s.." ["..p.rarity.."]" end
 if p.chance and p.chance > 0 then s = s.." "..string.format("%.2f%%", p.chance) end
 table.insert(vals, s)
 end
 pcall(function() petPoolDropdown:Refresh(vals) end)
 pcall(function() crystalStatus:SetDesc(
 (L("crystalContains")):format(Config.SelectedCrystal, #pool, DB_SOURCE)) end)
 end
 end,
})

PetTab:Button({
 Title = L("scanCrystals"),
 Callback = function()
 WindUI:Notify({ Title=L("scanning"), Content=L("scanningDesc"), Duration=3 })
 task.spawn(function()
 local db, src = buildCrystalDB()
 local names = {}
 for k in pairs(db) do table.insert(names, k) end
 table.sort(names)

 if #names > 0 then
 crystalListUI = names
 pcall(function() crystalDropdown:Refresh(names) end)
 pcall(function() crystalStatus:SetDesc(
 ("Kaynak: %s\n%d crystal bulundu"):format(src, #names)) end)
 WindUI:Notify({ Title=L("found"), Content=#names..L("foundDesc")..src..")", Duration=5 })
 print("\n=== CRYSTAL DB ["..src.."] ===")
 for _, n in ipairs(names) do
 print((" %s -> %d pet"):format(n, #db[n]))
 for i, p in ipairs(db[n]) do
 if i <= 12 then
 print((" %-32s %-12s %s"):format(p.name, p.rarity,
 p.chance>0 and string.format("%.3f",p.chance) or ""))
 end
 end
 end
 print("=== END ===\n")
 else
 -- DB not found -> learn from hatch history
 local learned = learnedPetsFor(Config.SelectedCrystal)
 if #learned > 0 then
 local vals = {}
 for _, p in ipairs(learned) do
 table.insert(vals, p.name..L("seenCount"):format(p.chance))
 end
 pcall(function() petPoolDropdown:Refresh(vals) end)
 pcall(function() crystalStatus:SetDesc(
 L("learnedFromHistory"):format(#learned)) end)
 WindUI:Notify({ Title=L("partial"), Content=#learned..L("partialDesc"), Duration=5 })
 else
 -- DB not found -> search the hardcoded list in workspace
 local foundNames = {}
 pcall(function()
 for _, o in ipairs(workspace:GetDescendants()) do
 local nm = o.Name
 if nm:lower():find("crystal") and (o:IsA("Model") or o:IsA("Part")) then
 local exists = false
 for _, f in ipairs(foundNames) do if f == nm then exists = true; break end end
 if not exists then table.insert(foundNames, nm) end
 end
 end
 end)
 if #foundNames > 0 then
 table.sort(foundNames)
 crystalListUI = foundNames
 pcall(function() crystalDropdown:Refresh(foundNames) end)
 pcall(function() crystalStatus:SetDesc(
 ("workspace'ten %d crystal bulundu"):format(#foundNames)) end)
 WindUI:Notify({ Title=L("found"), Content=#foundNames..L("workspaceFound"), Duration=5 })
 else
 -- hardcoded listeyi kullan
 pcall(function() crystalDropdown:Refresh(crystalListUI) end)
 pcall(function() crystalStatus:SetDesc(
 (L("hardcodedList")):format(#crystalListUI)) end)
 WindUI:Notify({ Title=L("readyList"), Content=#crystalListUI..L("readyListDesc"), Duration=5 })
 end
 end
 end
 end)
 end,
})

PetTab:Section({ Title=L("huntSection") })

petPoolDropdown = PetTab:Dropdown({
 Title=L("crystalPets"),
 Desc=L("crystalPetsDesc"),
 Values = { L("scanFirstBtn") },
 Multi = true,
 AllowNone = true,
 Callback = function(sel)
 local list = {}
 local function clean(s)
 s = tostring(s)
 s = s:gsub("%s*%[.-%]", "") -- [Omega] sil
 s = s:gsub("%s*%d+%.?%d*%%", "") -- 0.40% sil
 s = s:gsub("%s*%(x%d+%)", "") -- remove (x3)
 return (s:gsub("^%s+", ""):gsub("%s+$", ""))
 end
 if type(sel)=="table" then
 for k, v in pairs(sel) do
 if v == true then table.insert(list, clean(k))
 elseif type(v)=="string" then table.insert(list, clean(v)) end
 end
 elseif type(sel)=="string" then table.insert(list, clean(sel)) end
 Config.HuntTargets = list
 pcall(function() huntStatus:SetDesc(
 #list > 0 and (L("huntTargetList")..table.concat(list, ", ")) or L("huntNoTargetShort")) end)
 end,
})

PetTab:Input({
 Title = L("manualAdd"),
 Placeholder=L("huntTargetPH"),
 Callback = function(t)
 if t and t ~= "" then
 table.insert(Config.HuntTargets, t)
 pcall(function() huntStatus:SetDesc("Hedef: "..table.concat(Config.HuntTargets, ", ")) end)
 WindUI:Notify({ Title=L("added"), Content=t, Duration=3 })
 end
 end,
})

huntStatus = PetTab:Paragraph({
 Title = L("huntStatus"),
 Desc=L("huntNoTarget"),
})

PetTab:Toggle({
 Title = L("huntStart"),
 Desc=L("huntToggleDesc"),
 Value = false,
 Callback = function(s)
 if s and #Config.HuntTargets == 0 then
 WindUI:Notify({ Title=L("noSelection"), Content=L("noSelectionDesc"), Duration=4 })
 return
 end
 Config.HuntEnabled = s
 if s then
 HuntStats = { attempts=0, sold=0, found=false, foundPet="", startTime=tick() }
 WindUI:Notify({ Title=L("huntStarted"),
 Content=L("targetList")..table.concat(Config.HuntTargets, ", "), Duration=4 })
 end
 end,
})

PetTab:Toggle({
 Title = L("autoSellNonTarget"),
 Value = true,
 Callback = function(s) Config.HuntAutoSell = s end,
})

PetTab:Toggle({
 Title = L("huntStop"),
 Value = true,
 Callback = function(s) Config.HuntStopOnFind = s end,
})

PetTab:Slider({
 Title=L("huntSpeed"),
 Value = { Min=0.05, Max=1, Default=0.08 }, Step=0.01,
 Callback = function(v) Config.HuntDelay = tonumber(v) or 0.08 end,
})

-- live hunt statistics
task.spawn(function()
 while true do
 if Config.HuntEnabled or HuntStats.attempts > 0 then
 local el = HuntStats.startTime > 0 and (tick()-HuntStats.startTime) or 0
 local rate = el > 0 and (HuntStats.attempts/el*60) or 0
 local txt = L("huntReport")
 :format(#Config.HuntTargets>0 and table.concat(Config.HuntTargets,", ") or "-",
 HuntStats.attempts, HuntStats.sold, rate, math.floor(el))
 if HuntStats.found then
 txt = " BULUNDU: "..HuntStats.foundPet.."\n"..txt
 end
 pcall(function() huntStatus:SetDesc(txt) end)
 end
 task.wait(1)
 end
end)

PetTab:Section({ Title=L("hatchSection") })

PetTab:Toggle({ Title=L("autoHatch"), Value=false,
 Callback=function(s) Config.AutoHatchCrystal=s end })

PetTab:Toggle({ Title=L("notifyRare"), Value=true,
 Callback=function(s) Config.NotifyRare=s end })

PetTab:Slider({ Title=L("hatchDelay"), Value={Min=0.05,Max=2,Default=0.1}, Step=0.05,
 Callback=function(v) Config.HatchDelay=tonumber(v) or 0.1 end })

local hatchLabel = PetTab:Paragraph({
 Title=L("huntStatsTitle"),
 Desc=L("huntStatsDesc"),
})

local function refreshHatchLabel()
 local lines = { ("Toplam: %d | Son: %s (%s)"):format(
 HatchStats.total, HatchStats.last, HatchStats.lastRarity) }
 local rar = {}
 for k,v in pairs(HatchStats.byRarity) do table.insert(rar,{k,v}) end
 table.sort(rar, function(a,b) return a[2] > b[2] end)
 for i=1, math.min(#rar,6) do
 local pct = HatchStats.total>0 and (rar[i][2]/HatchStats.total*100) or 0
 table.insert(lines, (" %s: %d (%.1f%%)"):format(rar[i][1], rar[i][2], pct))
 end
 pcall(function() hatchLabel:SetDesc(table.concat(lines,"\n")) end)
end

task.spawn(function()
 while true do
 if HatchStats.total > 0 then pcall(refreshHatchLabel) end
 task.wait(2)
 end
end)

PetTab:Button({ Title=L("hatchOnce"), Callback=function()
 local got = hatchOnce(Config.SelectedCrystal, 1)
 if got then
 refreshHatchLabel()
 WindUI:Notify({
 Title = isRare(got.rarity) and (" "..got.rarity.."!") or ("Hatch: "..got.rarity),
 Content = got.pet, Duration = 4,
 })
 else
 WindUI:Notify({ Title=L("hatchResult"), Content=L("hatchNoResult"), Duration=3 })
 end
end })

PetTab:Button({ Title=L("hatch25"), Callback=function()
 task.spawn(function()
 local rares = 0
 for i=1,25 do
 local g = hatchOnce(Config.SelectedCrystal,1)
 if g and isRare(g.rarity) then rares = rares + 1 end
 task.wait(0.1)
 end
 refreshHatchLabel()
 WindUI:Notify({ Title=L("hatch25"), Content=rares..L("hatch25Result"), Duration=4 })
 end)
end })

PetTab:Button({ Title=L("hatchReport"), Callback=function()
 print("\n=== HATCH RAPORU ===")
 print("Toplam: "..HatchStats.total)
 for k,v in pairs(HatchStats.byRarity) do
 print((" %-22s %d (%.1f%%)"):format(k,v,HatchStats.total>0 and v/HatchStats.total*100 or 0))
 end
 local arr={} for k,v in pairs(HatchStats.byPet) do table.insert(arr,{k,v}) end
 table.sort(arr,function(a,b) return a[2]>b[2] end)
 for _,e in ipairs(arr) do print((" %-30s x%d"):format(e[1],e[2])) end
 print("=== END ===\n")
 WindUI:Notify({ Title=L("hatchReport"), Content=L("reportWritten"), Duration=3 })
end })

-- ════════════════════════════════════════════════════════════
-- TAB: TELEPORTS
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.85,"Adding teleports...")
local TPTab = Window:Tab({ Title="Teleports", Icon="solar:map-point-bold" })

TPTab:Section({ Title=L("mapsSection") })

-- Reads the game's real areas from workspace
local mapList = {}
local mapCircles = {} -- [display name] = circle object

local function refreshMaps()
 mapList = {}; mapCircles = {}
 local ac = workspace:FindFirstChild("areaCircles")
 if ac then
 for _, c in ipairs(ac:GetChildren()) do
 local an = c:FindFirstChild("AreaName") or c:FindFirstChild("areaName")
 or c:FindFirstChild("Name") or c:FindFirstChild("name")
 local nm
 if an then
 nm = (an:IsA("ValueBase") and tostring(an.Value))
 or (an:IsA("TextLabel") and an.Text) or nil
 end
 nm = nm or c.Name
 if nm and nm ~= "" and not mapCircles[nm] then
 mapCircles[nm] = c
 table.insert(mapList, nm)
 end
 end
 end
 table.sort(mapList)
 return mapList
end

refreshMaps()

-- known list if it could not be read from the game
if #mapList == 0 then
 mapList = {
 "Starter Gym","Muscle King Gym","Mythical Gym","External Gym",
 "Frost Gym","Legends Gym","Jungle Gym","Volcano Gym",
 "Space Gym","Void Gym","Heaven Gym","Titan Gym",
 }
end

local mapStatus = TPTab:Paragraph({
 Title=L("mapSource"),
 Desc = (next(mapCircles) and ("Oyundan okundu: "..#mapList.." harita"))
 or L("areaCirclesFallback"),
})

local mapDropdown
mapDropdown = TPTab:Dropdown({
 Title=L("mapSelect"),
 Values = mapList,
 Value = mapList[1],
 Callback = function(v)
 local n = type(v)=="table" and tostring(v[1]) or tostring(v)
 local circle = mapCircles[n]
 local ok
 if circle and R.areaTravel then
 ok = invoke(R.areaTravel, "travelToArea", circle) ~= nil
 else
 ok = tpToGym(n)
 end
 WindUI:Notify({ Title=L("teleport"), Content=(ok and n or L("tpNotFound")..n), Duration=2 })
 end,
})

TPTab:Button({
 Title=L("refreshMaps"),
 Callback=function()
 local l = refreshMaps()
 if #l > 0 and mapDropdown then
 pcall(function() mapDropdown:Refresh(l) end)
 pcall(function() mapStatus:SetDesc("Oyundan okundu: "..#l.." harita") end)
 WindUI:Notify({ Title=L("refreshed"), Content=#l..L("refreshedDesc"), Duration=3 })
 else
 WindUI:Notify({ Title=L("notFoundArea"), Content=L("notFoundAreaDesc"), Duration=3 })
 end
 end,
})

TPTab:Button({
 Title=L("nextMap"),
 Callback=function()
 if #mapList == 0 then return end
 Config._mapIdx = ((Config._mapIdx or 0) % #mapList) + 1
 local n = mapList[Config._mapIdx]
 local c = mapCircles[n]
 if c and R.areaTravel then invoke(R.areaTravel,"travelToArea",c) else tpToGym(n) end
 WindUI:Notify({ Title=L("teleport"), Content=n, Duration=2 })
 end,
})

TPTab:Button({
 Title=L("lastMap"),
 Callback=function()
 if #mapList == 0 then return end
 local n = mapList[#mapList]
 local c = mapCircles[n]
 if c and R.areaTravel then invoke(R.areaTravel,"travelToArea",c) else tpToGym(n) end
 WindUI:Notify({ Title=L("teleport"), Content=n, Duration=2 })
 end,
})

TPTab:Section({ Title=L("playerTP") })
TPTab:Button({ Title=L("tpNearest"), Callback=function()
 local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not h then return end
 local near,d = nil,math.huge
 for _,p in ipairs(Players:GetPlayers()) do
 if p~=LocalPlayer and p.Character then
 local o = p.Character:FindFirstChild("HumanoidRootPart")
 if o then local m=(o.Position-h.Position).Magnitude; if m<d then near,d=o,m end end
 end
 end
 if near then h.CFrame = near.CFrame*CFrame.new(0,0,3) end
end })

-- ════════════════════════════════════════════════════════════
-- TAB: MISC (yeni remoteler)
-- ════════════════════════════════════════════════════════════

local MiscTab = Window:Tab({ Title="Misc", Icon="solar:star-bold" })

-- ════════════════════════════════════════════════════════════
-- EXPLOIT DETECTOR
-- ════════════════════════════════════════════════════════════

MiscTab:Section({ Title=L("exploitDetector") })

local detStatus = MiscTab:Paragraph({
 Title=L("detectionLog"),
 Desc=L("detectionLogDesc"),
})

MiscTab:Toggle({
 Title = L("exploitDetector"),
 Desc=L("detectorDesc1"),
 Value = false,
 Callback = function(s)
 Config.DetectorEnabled = s
 if s then
 DetectorLog = {}
 playerTrack = {}
 WindUI:Notify({ Title=L("detectorOn"),
 Content=#Players:GetPlayers().." oyuncu izleniyor", Duration=4 })
 else
 pcall(function() detStatus:SetDesc(L("detectorOff")) end)
 end
 end,
})

MiscTab:Toggle({
 Title = L("autoHop"),
 Desc=L("autoHopDesc"),
 Value = true,
 Callback = function(s) Config.DetectorAutoHop = s end,
})

MiscTab:Slider({
 Title = L("sensitivity"),
 Desc=L("sensitivityDesc"),
 Value = { Min=1, Max=5, Default=3 }, Step=1,
 Callback = function(v) Config.DetectorSensitivity = tonumber(v) or 3 end,
})

MiscTab:Toggle({
 Title = L("strictMode"),
 Desc=L("strictDesc"),
 Value = false,
 Callback = function(s)
 Config.DetectorStrictMode = s
 if s then
 WindUI:Notify({ Title=L("strictModeOn"),
 Content=L("strictModeOnDesc"), Duration=5 })
 end
 end,
})

MiscTab:Input({
 Title = L("whitelistAdd"),
 Placeholder=L("whitelistPH"),
 Callback = function(t)
 if t and t ~= "" then
 Config.DetectorWhitelist[t] = true
 WindUI:Notify({ Title=L("whitelistAdded"), Content=t..L("whitelistAddedDesc")..".", Duration=3 })
 end
 end,
})

MiscTab:Button({
 Title = L("whitelistClear"),
 Callback = function()
 Config.DetectorWhitelist = {}
 WindUI:Notify({ Title=L("whitelistCleared"), Content=L("whitelistCleared")..".", Duration=2 })
 end,
})

MiscTab:Button({
 Title = L("hopNow"),
 Callback = function() task.spawn(serverHop, "manuel") end,
})

MiscTab:Button({
 Title = L("playerAnalysis"),
 Callback = function()
 print("\n"..L("playerAnalysisHeader"))
 for _, p in ipairs(Players:GetPlayers()) do
 if p ~= LocalPlayer then
 local tr = playerTrack[p]
 local ch = p.Character
 local hum = ch and ch:FindFirstChildOfClass("Humanoid")
 print((" %-20s score=%d ws=%s ff=%s"):format(
 p.Name,
 tr and math.floor(tr.score or 0) or 0,
 hum and math.floor(hum.WalkSpeed) or "?",
 (ch and ch:FindFirstChildOfClass("ForceField")) and "VAR" or "yok"))
 end
 end
 print("=== END ===\n")
 WindUI:Notify({ Title=L("playerAnalysis"), Content=L("analysisWritten"), Duration=3 })
 end,
})

-- detector log live update
task.spawn(function()
 while true do
 if Config.DetectorEnabled then
 local txt
 if #DetectorLog == 0 then
 txt = (L("monitoring").."%d"..L("players").."\n"..L("noThreat")):format(#Players:GetPlayers()-1)
 else
 txt = "Son tespitler:\n"..table.concat(DetectorLog, "\n", 1, math.min(#DetectorLog,6))
 end
 pcall(function() detStatus:SetDesc(txt) end)
 end
 task.wait(2)
 end
end)

MiscTab:Section({ Title=L("codesSection") })
MiscTab:Input({
 Title=L("useCode"), Placeholder=L("useCodePH"),
 Callback=function(t)
 if t and t~="" then
 send(R.code,t); send(R.code,"redeem",t)
 WindUI:Notify({ Title=L("useCode"), Content=L("codeTried")..t, Duration=3 })
 end
 end,
})
MiscTab:Button({
 Title=L("tryAllCodes"),
 Callback=function()
 local codes = {"release","muscle","update","gym","strength","legends","free","launch","2025","pets"}
 task.spawn(function()
 for _,c in ipairs(codes) do send(R.code,c); send(R.code,"redeem",c); task.wait(0.4) end
 WindUI:Notify({ Title=L("codesSection"), Content=#codes.." kod denendi", Duration=3 })
 end)
 end,
})

MiscTab:Section({ Title=L("otherSection") })
MiscTab:Button({ Title=L("fortuneWheel"), Callback=function()
 send(R.fortuneWheel,"spin"); send(R.fortuneWheel)
 WindUI:Notify({ Title=L("fortuneWheel"), Content=L("wheelTried"), Duration=2 }) end })
MiscTab:Button({ Title=L("claimGift"), Callback=function()
 send(R.freeGift,"claim"); send(R.freeGift)
 WindUI:Notify({ Title=L("claimGift"), Content=L("giftTried"), Duration=2 }) end })
MiscTab:Button({ Title=L("sellPowerUps"), Callback=function()
 send(R.sellPowerUp,"sellAll"); send(R.sellPowerUp)
 WindUI:Notify({ Title=L("sellPowerUps"), Content=L("powerUpSold"), Duration=2 }) end })
MiscTab:Button({ Title=L("evolvePowerUps"), Callback=function()
 send(R.evolvePowerUp,"evolveAll"); send(R.evolvePowerUp)
 WindUI:Notify({ Title=L("evolvePowerUps"), Content=L("powerUpEvolved"), Duration=2 }) end })
MiscTab:Button({ Title=L("ultimatesTrigger"), Callback=function()
 send(R.ultimates,"use"); send(R.ultimates)
 WindUI:Notify({ Title=L("ultimatesTrigger"), Content=L("ultimateTried"), Duration=2 }) end })

-- ════════════════════════════════════════════════════════════
-- TAB: VISUAL
-- ════════════════════════════════════════════════════════════

local VisualTab = Window:Tab({ Title="Visual", Icon="solar:eye-bold" })
VisualTab:Section({ Title=L("visualSection") })
local function vpair(title,flag,val)
 VisualTab:Toggle({ Title=L("visual")..title, Desc=L("visualDesc"), Value=false,
 Callback=function(s) Config[flag]=s end })
 VisualTab:Input({ Title=title.." Value", Placeholder="999999999", Value="999999999",
 Callback=function(t) Config[val]=(t~="" and t) or "999999999" end })
end
vpair("Strength","VisualStrength","VisualStrengthVal")
vpair("Gems","VisualGems","VisualGemsVal")
vpair("Coins","VisualCoins","VisualCoinsVal")
vpair("Rebirths","VisualRebirths","VisualRebirthsVal")
vpair("Level","VisualLevel","VisualLevelVal")
vpair("Wins","VisualWin","VisualWinVal")
VisualTab:Button({ Title=L("applyNow"), Callback=function() applyVisuals()
 WindUI:Notify({ Title=L("applied"), Content=L("appliedDesc"), Duration=3 }) end })
VisualTab:Button({ Title=L("resetAll"), Callback=function()
 Config.VisualStrength,Config.VisualGems=false,false
 Config.VisualCoins,Config.VisualRebirths=false,false
 Config.VisualLevel,Config.VisualWin=false,false
 WindUI:Notify({ Title=L("resetDesc"), Content=L("resetContent"), Duration=3 }) end })

-- ════════════════════════════════════════════════════════════
-- TAB: SETTINGS
-- ════════════════════════════════════════════════════════════

local SettingsTab = Window:Tab({ Title="Settings", Icon="solar:settings-bold" })
SettingsTab:Section({ Title=L("system") })
SettingsTab:Toggle({ Title=L("antiAFK"), Value=true,
 Callback=function(s) Config.AntiAFK=s; toggleAntiAFK(s) end })

SettingsTab:Section({ Title=L("language") })
SettingsTab:Dropdown({
 Title=L("language"), Desc=L("langDesc"),
 Values={ "English", "Portugues", "Turkce" },
 Value = (LangCode=="en" and "English") or (LangCode=="pt" and "Portugues") or "Turkce",
 Callback=function(v)
  local s = type(v)=="table" and tostring(v[1]) or tostring(v)
  local code = "en"
  if s == "Portugues" then code = "pt"
  elseif s == "Turkce" then code = "tr" end
  getgenv().__nuggiezLang = code
  pcall(function()
   if not isfolder("nuggiez_private") then makefolder("nuggiez_private") end
   writefile("nuggiez_private/lang.txt", code)
  end)
  WindUI:Notify({ Title=L("langChanged"), Content=L("langChangedDesc"), Duration=5 })
 end,
})

SettingsTab:Button({ Title=L("unload"), Callback=function()
 toggleAntiAFK(false)
 for k,v in pairs(Config) do if type(v)=="boolean" then Config[k]=false end end
 pcall(function() WindUI:Destroy() end)
end })
SettingsTab:Section({ Title=L("credits") })
SettingsTab:Paragraph({ Title="nuggiez private",
 Desc=L("creditsDesc") })

-- ════════════════════════════════════════════════════════════
-- START
-- ════════════════════════════════════════════════════════════

toggleAntiAFK(true)
Loading:SetProgress(1,"Ready!")
task.wait(0.4)
Loading:Close()
pcall(function() Window:SelectTab(1) end)

WindUI:Notify({
 Title = L("loaded"),
 Content = muscleEvent and L("allReady")
 or L("repMissing")..L("repUsingMachine"),
 Duration = 6, Icon = "solar:bell-bold",
})

if not muscleEvent then
 task.delay(2, function()
 WindUI:Notify({
 Title = L("repNotifTitle"),
 Content = L("repNotifBody"),
 Duration = 8, Icon = "solar:info-circle-bold",
 })
 end)
end
