-- ══════════════════════════════════════════════════════════════
--   ShHub  •  Muscle Legends 2  •  v3.5
--   Made by molokoz/yatzukix   •   Private for nuggiez6244
--
--   v3.5 DÜZELTMELERİ:
--    • DETECTOR FIX — TP-killer artık yakalanıyor:
--      teleport tespiti, unique victim takibi (tek tek öldüren),
--      başkasını öldürme, godmode olsa bile sana yapışan saldırgan
--    • GODMODE FIX — respawn'da ölüyordu, artık CharacterAdded'da
--      otomatik yeniden kuruluyor (7 katman)
--    • AUTO EQUIP BEST — en güçlü petleri rarity/stat'a göre kuşanır
--    • AUTO KILL FIX — hedef kontrolü, doğru TP yönü, stale reference
--    • AUTO EXERCISE FIX — makineleri workspace'te bul + ışınlan
--    • VERY FAST REP — animasyonlu 5x hızlı rep
--    • REBIRTH KALDIRILDI — artık yok
--    • DEBUG TAB KALDIRILDI
--    • 17 YENİ REMOTE — trading, gift, cPetShop, countdownReward vb
--    • BUG FIX: teleport bildirimi her zaman "başarılı" diyordu
--    • BUG FIX: strikes değişkeni ölü koddu, artık score gösteriliyor
--
--   v3.4:
--    • TURBO AUTO EVOLVE — beklemesiz, tüm envanter, format öğrenmeli
--    • PET HUNT — hedef pet seç, çıkana kadar aç, çıkmayanı otomatik sat
--    • CRYSTAL DB — crystal'daki tüm petleri oyundan okur (3 kaynak)
--    • EXPLOIT DETECTOR — oyuncuları izler, şüpheli görünce server hop
--    • Teleports sadeleşti: gerçek harita listesi (areaCircles'tan)
--    • Hatch sistemi Pets sekmesine taşındı
--
--   v3.3:
--    • PLAYER TAB: WalkSpeed, JumpPower, Infinite Jump, Fly,
--      NoClip, Godmode (3 katmanlı ölümsüzlük)
--    • Hatch Tracker: openCrystalRemote dönüş değeri okunuyor
-- ══════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
--  EXECUTOR UYUMLULUK
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
--  LOADING SCREEN
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
    gui.Name="ShHubLoading"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
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
    title.Text="ShHub"; title.TextTransparency=1; title.Parent=ct
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
    sub.Text="Muscle Legends 2  •  WindUI  •  v3.5"
    sub.TextTransparency=1; sub.Parent=ct

    local cr=Instance.new("TextLabel")
    cr.Position=UDim2.new(0,0,0,170); cr.Size=UDim2.new(1,0,0,14)
    cr.BackgroundTransparency=1; cr.Font=Enum.Font.Gotham; cr.TextSize=11
    cr.TextColor3=Color3.fromHex(CLR.sari)
    cr.Text="Made by molokoz/yatzukix  •  For nuggiez6244"
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
    tip.Text="💪 Tip: Very Fast Rep aç, petlerini evolve et!"
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
        pc.TextColor3=Color3.fromHex(CLR.hata); warn("[ShHub] "..tostring(m))
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
    for _,n in ipairs({"ShHubLoading","ShHub","WindUI"}) do
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
--  LOAD WINDUI
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
--  THEME
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.30,"Preparing theme...")
pcall(function()
WindUI:AddTheme({
    Name="ShHubBlue",
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
--  REMOTES  (senin verdiğin GERÇEK listeye göre)
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.42,"Connecting remotes...")

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 15)
local R = {}   -- tüm remoteler burada
local MISSING = {}

local function grab(key, parent, name, timeout)
    if not parent then table.insert(MISSING, name); return nil end
    local o = parent:WaitForChild(name, timeout or 5)
    if o then R[key] = o else table.insert(MISSING, name) end
    return o
end

if rEvents then
    -- ana kullanılanlar
    grab("areaTravel",      rEvents, "areaTravelRemote")
    grab("petEvolve",       rEvents, "petEvolveEvent")
    grab("autoEvolve",      rEvents, "autoEvolveRemote")      -- ★ YENİ
    grab("sellPet",         rEvents, "sellPetEvent")
    grab("equipPet",        rEvents, "equipPetEvent")         -- ★ YENİ
    grab("showPets",        rEvents, "showPetsEvent")         -- ★ YENİ
    grab("openCrystal",     rEvents, "openCrystalRemote")
    grab("machineInteract", rEvents, "machineInteractRemote") -- ★ REP İÇİN
    grab("brawl",           rEvents, "brawlEvent")            -- ★ DÖVÜŞ İÇİN
    grab("purchase",        rEvents, "purchaseEvent")
    grab("code",            rEvents, "codeRemote")            -- ★ YENİ
    grab("freeGift",        rEvents, "freeGiftClaimRemote")   -- ★ YENİ
    grab("fortuneWheel",    rEvents, "openFortuneWheelRemote")-- ★ YENİ
    grab("quests",          rEvents, "questsEvent")           -- ★ YENİ
    grab("checkChest",      rEvents, "checkChestRemote")      -- ★ YENİ
    grab("ultimates",       rEvents, "ultimatesRemote")       -- ★ YENİ
    grab("sellPowerUp",     rEvents, "sellPowerUpEvent")      -- ★ YENİ
    grab("evolvePowerUp",   rEvents, "evolvePowerUpEvent")    -- ★ YENİ
    grab("changeSpeedSize", rEvents, "changeSpeedSizeRemote") -- ★ YENİ
    grab("savePlayerSize",  rEvents, "savePlayerSizeEvent")
    grab("guiDamage",       rEvents, "guiDamageEvent")
    grab("unlockChar",      rEvents, "unlockCharacterEvent")
    grab("trading",         rEvents, "tradingEvent")           -- ★ YENİ
    grab("gifted",          rEvents, "giftedEvent")            -- ★ YENİ
    grab("serverChat",      rEvents, "serverChatEvent")        -- ★ YENİ
    grab("petGenNotif",     rEvents, "petGeneratorNotificationEvent") -- ★ YENİ
    grab("getServerTime",   rEvents, "getServerTimeRemote")    -- ★ YENİ
    grab("rename",          rEvents, "renameRemote")          -- ★ YENİ
    grab("group",           rEvents, "groupRemote")            -- ★ YENİ
    grab("gift",            rEvents, "giftRemote")             -- ★ YENİ
    grab("playerNamePack",  rEvents, "playerNamePackRemote")  -- ★ YENİ
    grab("nameGiftSpin",    rEvents, "playerNameGiftSpinRemote")-- ★ YENİ
    grab("nameGiftOffer",   rEvents, "playerNameGiftSpecialOfferRemote") -- ★ YENİ
    grab("nameGiftJungle",  rEvents, "playerNameGiftJungleCaptainRemote")-- ★ YENİ
    -- crossServerUpdateFolder altındaki remote
    grab("countdownReward", ReplicatedStorage:WaitForChild("crossServerUpdateFolder", 5), "giveCountdownRewardEvent")
    -- ReplicatedStorage kökündeki remoteler
    grab("getDecision",     ReplicatedStorage, "GetDecision")
    grab("cPetShop",        ReplicatedStorage, "cPetShopRemote")
else
    table.insert(MISSING, "rEvents")
end

-- muscleEvent oyunda YOK -> otomatik tespit
local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
    or ReplicatedStorage:FindFirstChild("muscleEvent")
local REP_MODE = muscleEvent and "muscleEvent" or "machineInteract"

-- güvenli çağrı wrapper'ları
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
-- RemoteEvent mi RemoteFunction mı bilmiyorsak ikisini de dene
local function send(remote, ...)
    if not remote then return end
    if remote:IsA("RemoteFunction") then return invoke(remote, ...) end
    return fire(remote, ...)
end

-- ════════════════════════════════════════════════════════════
--  PET BULUCU  (6 farklı kaynak)
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.52,"Scanning pets...")

local PET_SOURCE = "?"      -- petlerin nerede bulunduğu

-- Bir objenin "pet" olup olmadığını tahmin et
local function looksLikePet(o)
    local cls = o.ClassName
    if cls ~= "StringValue" and cls ~= "Folder" and cls ~= "Configuration"
       and cls ~= "Model" and cls ~= "ObjectValue" then return false end
    if o.Name == "" then return false end
    return true
end

-- Tüm olası kaynaklardan pet objelerini topla
local function collectPetObjects()
    local out = {}
    local seen = {}
    local src  = nil

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

    -- 2) LocalPlayer altındaki pet klasörleri
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

    -- 4) workspace altındaki oyuncu klasörü
    pcall(function()
        local wf = workspace:FindFirstChild(LocalPlayer.Name)
        if wf then
            local pf = wf:FindFirstChild("Pets") or wf:FindFirstChild("pets")
            if pf then for _,c in ipairs(pf:GetDescendants()) do if looksLikePet(c) then add(c,"workspace") end end end
        end
    end)

    -- 5) PlayerGui envanter frame'lerinden isim çıkarma (obje yok, sadece isim)
    -- (bu objeler remote'a gönderilemez ama listeyi doldurur)

    PET_SOURCE = src or "bulunamadı"
    return out
end

-- Sadece PlayerGui'den pet İSİMLERİ (obje bulunamazsa)
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
    -- obje yoksa GUI'den isim çek
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

-- ★ ARGÜMAN FORMATI BİLİNMİYOR -> hepsini dene
local function tryAllFormats(remote, action, petObj)
    if not remote then return end
    local name = petObj and petObj.Name or tostring(petObj)
    send(remote, action, petObj)      -- 1: ("sellPet", obj)
    send(remote, petObj)              -- 2: (obj)
    send(remote, action, name)        -- 3: ("sellPet", "Name")
    send(remote, name)                -- 4: ("Name")
    send(remote, {petObj})            -- 5: ({obj})
    send(remote, action, {petObj})    -- 6: ("sellPet", {obj})
end

-- ════════════════════════════════════════════════════════════
--  CONFIG
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
    -- Evolve hız
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
--  REP SİSTEMİ (muscleEvent yok -> machineInteract)
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
        -- brawlEvent: hem player hem char dene (farklı sürümler)
        send(R.brawl, player); send(R.brawl, "punch", player)
        send(R.brawl, "attack", player); send(R.brawl, char)
        send(R.brawl, "hit", player); send(R.brawl, "punch", char)
    end
    if R.guiDamage then
        -- guiDamageEvent: player + char + hasar miktarı dene
        send(R.guiDamage, player, 999999)
        send(R.guiDamage, char, 999999)
        send(R.guiDamage, player)
        send(R.guiDamage, char)
    end
end

-- ════════════════════════════════════════════════════════════
--  AUTO SYSTEMS
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

-- Very Fast Rep: her frame'de birden çok kez ateş et (animasyon hızlanır)
task.spawn(function() while true do
    if Config.VeryFastRep then
        for _ = 1, 5 do pcall(doRep) end
    end
    task.wait(math.max(Config.FastRepSpeed, 0.01))
end end)

-- ★ Egzersiz makinelerini workspace'te bul (karakterin altında DEĞİL)
-- Muscle Legends'te makineler haritada durur, oyuncu yürür ve etkileşir.
local exerciseCache = {}   -- [name] = machine objesi (cache)
local function findExerciseMachine(name)
    -- cache'de varsa ve hala geçerliyse onu kullan
    if exerciseCache[name] and exerciseCache[name].Parent then
        return exerciseCache[name]
    end
    local found = nil
    pcall(function()
        for _, o in ipairs(workspace:GetDescendants()) do
            local n = o.Name:lower()
            local target = name:lower()
            -- tam eşleşme veya "dumbbell", "pushup" gibi kelimeleri içeren
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
    -- 1) karakterin altında var mı? (bazı oyunlarda equipment takılı)
    local eq = char:FindFirstChild(name) or char:FindFirstChild(name.."s")
    if eq then
        doRep(eq)
        return
    end
    -- 2) workspace'te makine ara
    local machine = findExerciseMachine(name)
    if machine then
        -- makineye yakınsa direkt interact, değilse ışınlan
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local mPos = machine:IsA("Model") and machine:GetPivot().Position
                           or machine.Position
            local dist = (mPos - hrp.Position).Magnitude
            if dist > 15 then
                -- çok uzaktaysa ışınlan
                pcall(function() hrp.CFrame = CFrame.new(mPos + Vector3.new(0, 3, 5)) end)
            end
        end
        doRep(machine)
    else
        -- makine bulunamadı: parametresiz rep gönder
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
--  ★ TURBO AUTO EVOLVE (v3.4) — beklemesiz, tüm petler
-- ════════════════════════════════════════════════════════════
-- Eski hali her pet için 6 format x 2 aksiyon deneyip task.wait ile
-- bekliyordu -> çok yavaştı. Artık:
--   1) İlk çalışmada hangi formatın işe yaradığını ÖĞRENİR
--   2) Sonra sadece o formatı kullanır -> 10-20x hızlı
--   3) Hiç task.wait yok, tek karede tüm envanter

local EVOLVE_FMT = nil    -- öğrenilen format indexi
local SELL_FMT   = nil

local FORMATS = {
    function(rem,act,obj) send(rem, act, obj) end,
    function(rem,act,obj) send(rem, obj) end,
    function(rem,act,obj) send(rem, act, obj.Name) end,
    function(rem,act,obj) send(rem, obj.Name) end,
    function(rem,act,obj) send(rem, {obj}) end,
    function(rem,act,obj) send(rem, act, {obj}) end,
}

-- format bilinmiyorsa hepsini dene, biliniyorsa tek atış
local function fastSend(remote, action, obj, fmtVar)
    if not remote or not obj then return end
    local idx = (fmtVar == "evolve") and EVOLVE_FMT or SELL_FMT
    if idx then
        pcall(FORMATS[idx], remote, action, obj)
    else
        for i = 1, #FORMATS do pcall(FORMATS[i], remote, action, obj) end
    end
end

-- Envanter sayısı düştü/pet değişti mi diye bakıp doğru formatı öğrenir
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
            print(("[ShHub] %s format öğrenildi: #%d"):format(kind, i))
            return true
        end
    end
    return false
end

-- ★ TURBO: tek seferde tüm envanteri evolve et (bekleme yok)
local function turboEvolveAll()
    if not R.petEvolve then return 0 end
    local objs = collectPetObjects()
    local n = 0
    for _, v in ipairs(objs) do
        fastSend(R.petEvolve, "evolvePet",   v, "evolve")
        fastSend(R.petEvolve, "evolveTitan", v, "evolve")
        n = n + 1
    end
    return n
end

-- ════════════════════════════════════════════════════════════
--  ★ AUTO EQUIP BEST  (v3.5) — en güçlü petleri otomatik kuşan
-- ════════════════════════════════════════════════════════════
-- Petlerin "güç" sıralaması için rarity isminden puan üretir.
-- Eğer pet objesinde stat varsa (Multiplier, Power, Strength) onu kullanır.

local RARITY_SCORE = {
    omega=1000, secret=900, exclusive=800, mythic=700,
    legendary=600, titan=500, ultimate=400, godly=350,
    divine=300, cosmic=250, epic=200, rare=100, uncommon=50,
    common=10, basic=5, normal=1,
}

local function petScore(obj)
    -- önce obje içindeki stat'leri ara
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
    -- hala yoksa sıralama için 1 ver (en azından ilk çıkanlar üstte)
    if best == 0 then best = 1 end
    return best
end

local function equipPet(obj)
    if not R.equipPet then return false end
    local name = obj.Name
    -- tüm olası equip formatlarını dene
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

-- En güçlü N peti bul, kuşan
local function equipBestPets(count)
    if not R.equipPet then return 0, "equipPetEvent bulunamadı" end
    local objs = collectPetObjects()
    if #objs == 0 then return 0, "Pet bulunamadı — önce Scan yap" end

    -- güce göre sırala
    table.sort(objs, function(a, b) return petScore(a) > petScore(b) end)

    local n = math.min(count or Config.MaxEquipSlots or 6, #objs)
    for i = 1, n do
        pcall(equipPet, objs[i])
        task.wait(0.1)
    end
    return n, nil
end

-- auto equip loop (arka planda çalışır)
task.spawn(function() while true do
    if Config.AutoEquipBest then
        pcall(equipBestPets, Config.MaxEquipSlots)
    end
    task.wait(5)
end end)

task.spawn(function() while true do
    if Config.AutoEvolvePets then
        pcall(function()
            -- oyunun kendi auto-evolve'u varsa onu da sürekli tetikle
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
                    -- hala canlı mı + objeler geçerli mi kontrol et
                    if hrp and hum and hum.Health > 0 and char.Parent and myHRP.Parent then
                        -- hedefin arkasına değil ÖNÜNE ışınlan + ona bak
                        pcall(function()
                            myHRP.CFrame = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
                                * CFrame.new(0, 0, -3)
                        end)
                        task.wait(0.05)
                        for _=1,8 do
                            if not Config.AutoKillAll then break end
                            -- tekrar kontrol: hedef hala canlı mı
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
--  ★ PLAYER SİSTEMLERİ (v3.3)
-- ════════════════════════════════════════════════════════════

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── Speed & Jump (sürekli zorla, oyun geri almasın)
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

-- ── FLY (BodyVelocity tabanlı, mobil + PC)
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
        move = move + flyDir   -- GUI butonlarından gelen yön

        if move.Magnitude > 0 then move = move.Unit * Config.FlySpeed end
        flyBV.Velocity = move
        if flyBG then flyBG.CFrame = cam end
    end)
end

local function setFly(on)
    Config.FlyEnabled = on
    if on then startFly() else stopFly() end
end

-- (CharacterAdded bağlantısı aşağıda, setGodmode tanımlandıktan sonra kuruluyor)

-- ════════════════════════════════════════════════════════════
--  ★ GODMODE v2 (v3.5) — RESPAWN DAYANIKLI, 6 KATMAN
-- ════════════════════════════════════════════════════════════
-- v3.4'teki sorun: bağlantılar sadece o anki karaktere kuruluyordu.
-- Ölüp respawn olunca ForceField + HealthChanged gidiyordu -> godmode ölüyordu.
-- Artık her yeni karakterde OTOMATİK yeniden kuruluyor.

local godConns = {}
local function clearGodConns()
    for _,c in ipairs(godConns) do pcall(function() c:Disconnect() end) end
    godConns = {}
end

-- Bir karaktere godmode katmanlarını uygular
local function armGodmode(char)
    if not Config.Godmode or not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")

    -- Katman 1: gizli ForceField
    if not char:FindFirstChild("ShHubFF") then
        local ff = Instance.new("ForceField")
        ff.Name = "ShHubFF"; ff.Visible = false; ff.Parent = char
    end

    if not h then return end

    -- Katman 2: ölüm state'ini tamamen kapat
    pcall(function()
        h.BreakJointsOnDeath = false
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h.MaxHealth = math.huge
        h.Health = math.huge
    end)

    -- Katman 3: can düşerse anında geri doldur
    table.insert(godConns, h.HealthChanged:Connect(function(hp)
        if Config.Godmode and hp < h.MaxHealth then
            pcall(function() h.Health = h.MaxHealth end)
        end
    end))

    -- Katman 4: ölüm state'ine geçerse geri çevir
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

    -- Katman 6: birisi ForceField'ı silerse geri koy
    table.insert(godConns, char.ChildRemoved:Connect(function(o)
        if Config.Godmode and o.Name == "ShHubFF" then
            task.wait(0.1)
            if Config.Godmode and char.Parent and not char:FindFirstChild("ShHubFF") then
                local ff = Instance.new("ForceField")
                ff.Name = "ShHubFF"; ff.Visible = false; ff.Parent = char
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
            local ff = c:FindFirstChild("ShHubFF")
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

-- ★ TEK CharacterAdded — godmode + speed + jump + fly hepsini geri uygular
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
if hookmetamethod and checkcaller and not getgenv().__ShHubDmgHook then
    getgenv().__ShHubDmgHook = true
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod and getnamecallmethod() or ""
        if not checkcaller() and (m == "FireServer" or m == "InvokeServer")
           and typeof(self) == "Instance" then
            local n = self.Name
            if Config.BlockDamage and (n == "guiDamageEvent" or n == "brawlEvent") then
                return nil   -- hasar paketi sunucuya hiç gitmez
            end
        end
        return oldNC(self, ...)
    end)
end

-- Godmode canlı tutucu (hızlandırıldı: 0.3 -> 0.1) + Anti Void
task.spawn(function()
    while true do
        if Config.Godmode then
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health < h.MaxHealth then
                    pcall(function() h.Health = h.MaxHealth end)
                end
                if not c:FindFirstChild("ShHubFF") then
                    local ff = Instance.new("ForceField")
                    ff.Name="ShHubFF"; ff.Visible=false; ff.Parent=c
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
--  ★ HATCH TRACKER (leak'ten öğrenilen dönüş formatı)
--    openCrystalRemote:InvokeServer("openCrystal", <crystal>, <n>)
--      -> [1]=petName  [2]=rarity  [3]=imageUrl  [4]=nil
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
    -- crystal string olarak gelebilir, önce workspace'te objesini bul
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

    -- hem string hem obje ile dene (farklı sürümler farklı bekler)
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

-- Auto Hatch (artık sonucu okuyor)
task.spawn(function() while true do
    if Config.AutoHatchCrystal and Config.SelectedCrystal~="" then
        local got = hatchOnce(Config.SelectedCrystal, 1)
        if got and Config.NotifyRare and isRare(got.rarity) then
            pcall(function()
                WindUI:Notify({ Title="🌟 "..got.rarity.."!", Content=got.pet, Duration=5 })
            end)
        end
    end
    task.wait(math.max(Config.HatchDelay,0.05))
end end)

-- ════════════════════════════════════════════════════════════
--  ★ CRYSTAL PET LİSTESİ BULUCU (v3.4)
--  Bir crystal'dan hangi petler çıkabiliyor? -> oyundan okur
-- ════════════════════════════════════════════════════════════

local CrystalDB = {}       -- [crystalName] = { {name=,rarity=,chance=}, ... }
local CrystalNames = {}    -- bulunan tüm crystal isimleri
local DB_SOURCE = "taranmadı"

-- Bir ModuleScript'i güvenli require et
local function tryRequire(m)
    local ok, res = pcall(require, m)
    if ok and type(res) == "table" then return res end
    return nil
end

-- Tablodan pet listesi çıkarmaya çalış (esnek: farklı şemalar)
local function harvestPets(tbl, depth)
    depth = depth or 0
    if depth > 4 or type(tbl) ~= "table" then return nil end
    local pets = {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            -- şema A: { Name="X", Rarity="Omega", Chance=0.1 }
            local nm  = v.Name or v.name or v.petName or v.PetName
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
            -- şema B: { ["Pet Adı"] = 12.5 }  (isim = şans)
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

-- Crystal veritabanını 3 kaynaktan bulmaya çalış
local function buildCrystalDB()
    CrystalDB = {}; CrystalNames = {}; DB_SOURCE = "bulunamadı"

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
                    -- modülün kendisi tek bir crystal olabilir
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

    -- KAYNAK 2: workspace/RS'teki crystal modelleri altındaki pet listeleri
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

    -- KAYNAK 3: PlayerGui'deki hatch önizleme ekranı
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
                        DB_SOURCE = "PlayerGui önizleme"
                    end
                end
            end
        end
    end

    table.sort(CrystalNames)
    return CrystalDB, DB_SOURCE
end

-- Hatch geçmişinden öğrenilen pet listesi (DB bulunamazsa yedek)
local function learnedPetsFor(crystal)
    local out = {}
    for petName, cnt in pairs(HatchStats.byPet) do
        table.insert(out, { name=petName, rarity="?", chance=cnt })
    end
    table.sort(out, function(a,b) return a.chance > b.chance end)
    return out
end

-- ════════════════════════════════════════════════════════════
--  ★ PET HUNT — hedef pet çıkana kadar aç, çıkmayanı sat
-- ════════════════════════════════════════════════════════════

local HuntStats = { attempts=0, sold=0, found=false, foundPet="", startTime=0 }

local function isTarget(petName)
    for _, t in ipairs(Config.HuntTargets) do
        if tostring(t):lower() == tostring(petName):lower() then return true end
    end
    return false
end

-- Az önce çıkan peti bul ve sat (isme göre en yeni objeyi hedefler)
local function sellPetByName(name)
    if not R.sellPet then return false end
    local sold = false
    for _, v in ipairs(collectPetObjects()) do
        if v.Name == name then
            fastSend(R.sellPet, "sellPet", v, "sell")
            sold = true
            break   -- sadece 1 tane sat (yeni çıkanı)
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
                    -- ★ HEDEF BULUNDU
                    HuntStats.found = true
                    HuntStats.foundPet = got.pet
                    if Config.HuntStopOnFind then
                        Config.HuntEnabled = false
                        Config.AutoHatchCrystal = false
                    end
                    pcall(function()
                        WindUI:Notify({
                            Title = "🎯 HEDEF BULUNDU!",
                            Content = got.pet.." ("..got.rarity..")\n"..HuntStats.attempts.." denemede",
                            Duration = 10,
                        })
                    end)
                    print(("[ShHub HUNT] ★ %s bulundu! %d deneme, %d satıldı")
                        :format(got.pet, HuntStats.attempts, HuntStats.sold))
                else
                    -- hedef değil -> sat
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
--  ★ EXPLOIT DETECTOR — şüpheli oyuncu görürse server hop
-- ════════════════════════════════════════════════════════════

local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local DetectorLog = {}          -- son tespitler
local playerTrack = {}          -- [player] = { lastPos, lastCheck, score, ... }

local function logDetect(txt)
    table.insert(DetectorLog, 1, os.date("%H:%M:%S").."  "..txt)
    while #DetectorLog > 12 do table.remove(DetectorLog) end
    print("[DETECTOR] "..txt)
end

local hopping = false
local function serverHop(reason)
    if hopping then return end
    hopping = true
    logDetect("SERVER HOP: "..reason)
    pcall(function()
        WindUI:Notify({ Title="⚠️ Server Değişiyor", Content=reason, Duration=5 })
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
--  ★ DETECTOR v2 (v3.5) — YANLIŞ ALARM DÜZELTİLDİ
-- ════════════════════════════════════════════════════════════
-- v3.4 sorunu: hız/fly kullanan HERKESİ hile sayıp server hop yapıyordu.
-- Bu oyunda rebirth ile hız normalde de çok yükseliyor + biz de hız kullanıyoruz.
--
-- Çözüm:
--  1) Hız/fly artık TEK BAŞINA tetiklemiyor (sadece "hafif şüphe" puanı)
--  2) Sadece SANA ZARAR VEREN davranış tetikliyor (kill farm, saldırı)
--  3) "Sadece Tehdit Modu" — hızlı oyuncuyu takmaz, saldıranı yakalar
--  4) Whitelist + hop cooldown + hop limiti

local HOP_COOLDOWN = 45      -- iki hop arası minimum saniye
local lastHopTime  = 0
local hopCount     = 0

-- Ağırlıklı imza sistemi: her davranışın bir puanı var
-- Sadece toplam puan eşiği geçerse tetiklenir
-- saldırganın yakınlaştığı KİMLER (son VICTIM_WINDOW saniye) — kill farm imzası
local VICTIM_WINDOW = 15     -- victim listesi bu kadar saniye tutulur
local VICTIM_DIST   = 14     -- bu mesafeye giren "victim" sayılır
local TP_THRESHOLD  = 90     -- bu stud'tan büyük sıçrama = teleport
local ATTACK_DIST   = 16     -- bu mesafede + can düşerse saldırı sayılır

local function trackVictim(tr, victimName, now)
    tr.victims = tr.victims or {}
    -- eski victim'leri temizle
    local alive = {}
    for name, t in pairs(tr.victims) do
        if now - t < VICTIM_WINDOW then alive[name] = t end
    end
    if victimName then alive[victimName] = now end
    tr.victims = alive
    -- unique victim sayısı
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
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")

    local tr = playerTrack[p]
    if not tr then
        playerTrack[p] = { lastPos=hrp.Position, lastCheck=tick(), score=0,
                           nearMeTime=0, myHealthDrop=0, victims={}, tpCount=0 }
        return
    end

    local now = tick()
    local dt  = now - tr.lastCheck
    if dt < 0.4 then return end
    local dist  = (hrp.Position - tr.lastPos).Magnitude
    local speed = dist / dt
    tr.lastPos   = hrp.Position
    tr.lastCheck = now

    local flags  = {}
    local score  = 0
    local heavy  = false   -- ağır imza var mı (hop'a yetecek)

    -- ═══ AĞIR İMZA 1: TELEPORT (büyük konum sıçraması) ═══
    -- TP-killer'ın temel özelliği: aniden çok uzaga ışınlanır.
    -- Bu oyunda normal hız çok yüksek olabilir ama 90 stud/0.4sn
    -- = 225 stud/sn anlık sıçrama normal yürüyüşle olmaz.
    if dist > TP_THRESHOLD then
        tr.tpCount = (tr.tpCount or 0) + 1
        tr.lastTpTime = now
        -- tek teleport hafif, ama kısa sürede tekrarlanan teleport = kesin
        if tr.tpCount >= 2 then
            score = score + 45
            table.insert(flags, "IŞINLANMA x"..tr.tpCount.." ("..math.floor(dist).." stud)")
        end
    else
        -- teleport sayacı yavaşça söner
        if now - (tr.lastTpTime or 0) > 3 then
            tr.tpCount = math.max(0, (tr.tpCount or 0) - 1)
        end
    end

    -- ═══ AĞIR İMZA 2: BİRDEN FAZLA KİŞİYE YAKLAŞMA (kill farm) ═══
    -- TP-killer tek tek öldürür: A'ya ışınlan, öldür, B'ye ışınlan, öldür.
    -- nearCount>=2 yerine: son 15 sn'de kaç FARKLI kişiye yaklaştığını say.
    local nearCount = 0
    local victimHit = nil   -- şu an yakınındaki canı düşen oyuncu
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

    -- şu an birine yakınsa victim listesine ekle
    if victimHit then
        local vc = trackVictim(tr, victimHit.Name, now)
        -- 2+ farklı kişiye 15 sn içinde yaklaştıysa kill farm
        if vc >= 2 then
            score = score + 60
            table.insert(flags, "KILL FARM ("..vc.." kişiye ışınlandı)")
            heavy = true
        end
    else
        -- pencereyi temizle (eski victim'leri düşür)
        trackVictim(tr, nil, now)
    end

    -- ═══ AĞIR İMZA 3: BAŞKASINI ÖLDÜRÜYOR ═══
    -- Saldıranın yakınındaki bir oyuncunun canı düşüyorsa/ölüyorsa.
    if victimHit then
        local vh = victimHit.Character and victimHit.Character:FindFirstChildOfClass("Humanoid")
        if vh then
            local vhp = vh.Health
            tr.victimHP = tr.victimHP or {}
            local prev = tr.victimHP[victimHit.Name]
            tr.victimHP[victimHit.Name] = vhp
            if prev and vhp < prev - 5 then
                -- can belirgin düştü ve saldıran yanında
                score = score + 55
                table.insert(flags, "OYUNCU ÖLDÜRÜYOR ("..victimHit.Name.." -"..math.floor(prev-vhp).."hp)")
                heavy = true
                -- öldüyse ekstra
                if vhp <= 0 then
                    score = score + 25
                end
            end
        end
    end

    -- ═══ AĞIR İMZA 4: BANA SALDIRIYOR ═══
    -- Godmode olsa bile: yanımda dikilip saldırıyorsa yakala.
    -- Canım düşmüyorsa (godmode) bile saldırı girişimi = tehdit.
    local nearMe = myHRP and (hrp.Position - myHRP.Position).Magnitude < ATTACK_DIST
    if nearMe then
        tr.nearMeTime = tr.nearMeTime + dt
        -- canım düşüyor mu? (godmode kapalıysa)
        if myHum then
            local hp = myHum.Health
            if tr.lastMyHP and hp < tr.lastMyHP - 1 then
                tr.myHealthDrop = tr.myHealthDrop + (tr.lastMyHP - hp)
            end
            tr.lastMyHP = hp
        end
        -- can kaybı varsa kesin saldırı
        if tr.myHealthDrop > 15 then
            score = score + 90
            table.insert(flags, "BANA SALDIRIYOR (-"..math.floor(tr.myHealthDrop).." hp)")
            heavy = true
        -- can düşmüyorsa ama uzun süre dibimde + ben de TP kurbanıyorsam
        elseif tr.nearMeTime > 4 and (tr.tpCount or 0) > 0 then
            score = score + 50
            table.insert(flags, "BANA YAPIŞTI ("..math.floor(tr.nearMeTime).."sn)")
            heavy = true
        end
    else
        tr.nearMeTime = math.max(0, tr.nearMeTime - dt)
        tr.myHealthDrop = math.max(0, tr.myHealthDrop - dt*3)
    end

    -- ═══ HAFİF İMZALAR (sadece Sıkı Mod) ═══
    if Config.DetectorStrictMode then
        if speed > 250 and dist > 120 then
            score = score + 25
            table.insert(flags, "aşırı hız ("..math.floor(speed)..")")
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
    tr.score = math.max(0, (tr.score or 0) * 0.8 + score)   -- yavaş söner

    local THRESHOLD = 50 + (Config.DetectorSensitivity - 1) * 20
    -- hassasiyet 1 -> 50 (hassas) | 3 -> 90 | 5 -> 130

    if tr.score >= THRESHOLD and #flags > 0 then
        if not tr.reported or (now - (tr.reportTime or 0)) > 15 then
            tr.reported = true
            tr.reportTime = now
            local msg = p.Name.." → "..table.concat(flags, ", ")
            logDetect(msg)
            pcall(function()
                WindUI:Notify({ Title="🚨 Tehdit Tespit", Content=msg, Duration=6 })
            end)
            -- server hop: ağır imza varsa VE cooldown dolduysa
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
    if Config.AutoQuests  then send(R.quests,"claimAll"); send(R.quests,"claim") end
    if Config.AutoFreeGift then send(R.freeGift,"claim"); send(R.freeGift) end
    if Config.AutoChest   then send(R.checkChest,"claim"); send(R.checkChest) end
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
        setv("VisualStrength","VisualStrengthVal","Strength","strength","💪")
        setv("VisualGems","VisualGemsVal","Gems","gems","💎")
        setv("VisualCoins","VisualCoinsVal","Coins","coins","💰")
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
                elseif Config.VisualGems and (t:find("gem") or t:find("💎")) then g.Text="Gems: "..Config.VisualGemsVal
                elseif Config.VisualCoins and (t:find("coin") or t:find("💰")) then g.Text="Coins: "..Config.VisualCoinsVal end
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
--  BUILD GUI
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.75,"Building GUI...")

local Window = WindUI:CreateWindow({
    Title="ShHub", Icon=LOGO_TEXTURE, Author="Muscle Legends 2",
    Folder="ShHub_ML2", Size=UDim2.fromOffset(640,500),
    MinSize=Vector2.new(520,340), MaxSize=Vector2.new(880,620),
    Transparent=true, Theme="ShHubBlue", Resizable=true,
    SideBarWidth=200, HideSearchBar=false,
    OpenButton={
        Title="ShHub", Icon=LOGO_TEXTURE, StrokeThickness=2, Draggable=true,
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
    Window:Tag({ Title="v3.5 💪", Color=Color3.fromHex("#ffcc00") })
    Window:Tag({ Title="Private", Color=Color3.fromHex("#2e8eff") })
end)

task.spawn(function() pcall(function()
    local bgPane = Window.UIElements and Window.UIElements.Main and Window.UIElements.Main.Background
    if not bgPane then return end
    local b=Instance.new("ImageLabel"); b.Name="ShHubBG"; b.BackgroundTransparency=1
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
--  TAB: MAIN
-- ════════════════════════════════════════════════════════════

local MainTab = Window:Tab({ Title="Main", Icon="solar:home-2-bold" })

MainTab:Section({ Title="Durum" })

MainTab:Paragraph({
    Title = "Rep Sistemi",
    Desc  = muscleEvent
        and "✅ muscleEvent bulundu"
        or  ("⚠️ muscleEvent YOK -> "..(R.machineInteract and "machineInteractRemote kullanılıyor" or "REP REMOTE BULUNAMADI")),
})

MainTab:Paragraph({
    Title = "Remote Durumu",
    Desc  = (#MISSING>0) and ("Eksik: "..table.concat(MISSING,", ")) or "Tüm remoteler ✅",
})

MainTab:Section({ Title="Defense" })
MainTab:Toggle({ Title="Anti Attack (ForceField + NoClip)", Value=false,
    Callback=function(s) Config.AntiAttack=s end })

-- ════════════════════════════════════════════════════════════
--  ★ TAB: PLAYER  (v3.3)
-- ════════════════════════════════════════════════════════════

local PlayerTab = Window:Tab({ Title="Player", Icon="solar:user-bold" })

PlayerTab:Section({ Title="Hareket" })

PlayerTab:Toggle({
    Title="Speed Multiplier",
    Desc="WalkSpeed'i sabit tutar (oyun geri alamaz)",
    Value=false,
    Callback=function(s)
        Config.SpeedEnabled = s
        local h = getHum()
        if h then pcall(function() h.WalkSpeed = s and Config.WalkSpeed or Config.DefaultSpeed end) end
    end,
})

PlayerTab:Slider({
    Title="Walk Speed",
    Desc="Normal = 16 | 100+ anticheat riski",
    Value={ Min=16, Max=500, Default=16 }, Step=2,
    Callback=function(v)
        Config.WalkSpeed = tonumber(v) or 16
        if Config.SpeedEnabled then
            local h=getHum(); if h then pcall(function() h.WalkSpeed=Config.WalkSpeed end) end
        end
    end,
})

PlayerTab:Slider({
    Title="Speed Multiplier (x kat)",
    Desc="16 tabanına çarpan uygular",
    Value={ Min=1, Max=20, Default=1 }, Step=1,
    Callback=function(v)
        local mult = tonumber(v) or 1
        Config.WalkSpeed = 16 * mult
        Config.SpeedEnabled = true
        local h=getHum(); if h then pcall(function() h.WalkSpeed=Config.WalkSpeed end) end
    end,
})

PlayerTab:Toggle({
    Title="Jump Power",
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
    Title="Jump Power Değeri",
    Desc="Normal = 50",
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
    Title="♾️ Infinite Jump",
    Desc="Havada sınırsız zıplama (Space / mobil jump)",
    Value=false,
    Callback=function(s) Config.InfiniteJump = s end,
})

PlayerTab:Section({ Title="Fly" })

PlayerTab:Toggle({
    Title="🕊️ Fly",
    Desc="PC: WASD + Space/Shift | Mobil: joystick + butonlar",
    Value=false,
    Callback=function(s) setFly(s) end,
})

PlayerTab:Slider({
    Title="Fly Speed",
    Value={ Min=10, Max=400, Default=60 }, Step=10,
    Callback=function(v) Config.FlySpeed = tonumber(v) or 60 end,
})

PlayerTab:Button({
    Title="⬆️ Yukarı Çık (fly yönü)",
    Callback=function()
        flyDir = Vector3.new(0,1,0)
        task.delay(0.8, function() flyDir = Vector3.new() end)
    end,
})

PlayerTab:Button({
    Title="⬇️ Aşağı İn (fly yönü)",
    Callback=function()
        flyDir = Vector3.new(0,-1,0)
        task.delay(0.8, function() flyDir = Vector3.new() end)
    end,
})

PlayerTab:Toggle({
    Title="👻 NoClip (duvardan geç)",
    Value=false,
    Callback=function(s) Config.NoClip = s end,
})

PlayerTab:Section({ Title="⚡ Ölümsüzlük" })

PlayerTab:Toggle({
    Title="🛡️ GODMODE",
    Desc="ForceField + can kilidi + ölüm state engeli",
    Value=false,
    Callback=function(s)
        setGodmode(s)
        WindUI:Notify({
            Title = s and "Godmode AÇIK" or "Godmode KAPALI",
            Content = s and "Ölümsüzsün 🛡️" or "Normal moda dönüldü",
            Duration = 3,
        })
    end,
})

PlayerTab:Toggle({
    Title="🚫 Block Damage Packets",
    Desc="guiDamageEvent/brawlEvent hasar paketlerini keser (en güçlü)",
    Value=false,
    Callback=function(s)
        Config.BlockDamage = s
        if s and not (hookmetamethod and checkcaller) then
            WindUI:Notify({ Title="Desteklenmiyor", Content="Executor hook desteklemiyor", Duration=4 })
        end
    end,
})

PlayerTab:Toggle({
    Title="🕳️ Anti Void",
    Desc="Haritadan düşersen otomatik yukarı ışınlar",
    Value=false,
    Callback=function(s) Config.AntiVoid = s end,
})

PlayerTab:Button({
    Title="❤️ Canı Full Yap",
    Callback=function()
        local h = getHum()
        if h then pcall(function() h.Health = h.MaxHealth end)
            WindUI:Notify({ Title="Heal", Content="Can dolduruldu", Duration=2 })
        end
    end,
})

PlayerTab:Section({ Title="Sıfırla" })

PlayerTab:Button({
    Title="🔄 Tüm Player Ayarlarını Sıfırla",
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
        WindUI:Notify({ Title="Sıfırlandı", Content="Player ayarları normale döndü", Duration=3 })
    end,
})

-- ════════════════════════════════════════════════════════════
--  TAB: AUTO FARMS
-- ════════════════════════════════════════════════════════════

local FarmTab = Window:Tab({ Title="Auto Farms", Icon="solar:chart-2-bold" })

FarmTab:Section({ Title="Kill Aura" })
FarmTab:Toggle({ Title="Auto Kill All (TP + Multi-Punch)", Value=false,
    Callback=function(s) Config.AutoKillAll=s end })
FarmTab:Slider({ Title="Kill Speed", Value={Min=0.05,Max=2,Default=0.2}, Step=0.05,
    Callback=function(v) Config.KillAuraSpeed=tonumber(v) or 0.2 end })

FarmTab:Section({ Title="Rep" })
FarmTab:Toggle({ Title="Very Fast Rep (animasyonlu)", Desc="Her frame'de 5x ateş — animasyon hızlanır", Value=false,
    Callback=function(s) Config.VeryFastRep=s end })
FarmTab:Slider({ Title="Rep Speed (saniye)", Desc="0.01 = maksimum hız", Value={Min=0.01,Max=2,Default=0.05}, Step=0.01,
    Callback=function(v) Config.FastRepSpeed=tonumber(v) or 0.05 end })

FarmTab:Section({ Title="Exercises" })
FarmTab:Toggle({ Title="Auto Dumbbell",  Value=false, Callback=function(s) Config.AutoDumbbell=s end })
FarmTab:Toggle({ Title="Auto Pushups",   Value=false, Callback=function(s) Config.AutoPushups=s end })
FarmTab:Toggle({ Title="Auto Handstand", Value=false, Callback=function(s) Config.AutoHandstand=s end })
FarmTab:Toggle({ Title="Auto Situps",    Value=false, Callback=function(s) Config.AutoSitups=s end })
FarmTab:Slider({ Title="Exercise Speed", Value={Min=0.1,Max=2,Default=0.3}, Step=0.1,
    Callback=function(v) Config.ExerciseSpeed=tonumber(v) or 0.3 end })

FarmTab:Section({ Title="Otomatik Ödüller" })
FarmTab:Toggle({ Title="Auto Quests Claim", Value=false, Callback=function(s) Config.AutoQuests=s end })
FarmTab:Toggle({ Title="Auto Free Gift",    Value=false, Callback=function(s) Config.AutoFreeGift=s end })
FarmTab:Toggle({ Title="Auto Chest",        Value=false, Callback=function(s) Config.AutoChest=s end })

-- ════════════════════════════════════════════════════════════
--  TAB: PETS
-- ════════════════════════════════════════════════════════════

local PetTab = Window:Tab({ Title="Pets", Icon="solar:heart-bold" })

local petDropdown, petStatus
local function cleanPetName(s)
    s = tostring(s); return s:match("^(.-)%s*%(%d+x%)$") or s
end

PetTab:Section({ Title="1) Önce Tara" })

petStatus = PetTab:Paragraph({
    Title = "Pet Kaynağı",
    Desc  = "Henüz taranmadı. 'Scan Inventory' butonuna bas.",
})

PetTab:Button({
    Title="🔍 Scan Inventory",
    Callback=function()
        local pets, counts = scanPets()
        local values = {}
        for _,n in ipairs(pets) do table.insert(values, n.." ("..counts[n].."x)") end
        pcall(function() petStatus:SetDesc(
            ("Kaynak: %s\nBulunan: %d farklı pet"):format(PET_SOURCE, #pets)) end)
        if #values==0 then
            WindUI:Notify({ Title="Pet yok", Content="Önce oyunda pet kazan, sonra Scan yap", Duration=5 })
            return
        end
        if petDropdown then pcall(function() petDropdown:Refresh(values) end) end
        WindUI:Notify({ Title="Tarandı", Content=#pets.." pet bulundu ("..PET_SOURCE..")", Duration=4 })
        print("\n=== PET INVENTORY ["..PET_SOURCE.."] ===")
        for _,n in ipairs(pets) do print("  "..n.." x"..counts[n]) end
        print("=== "..#pets.." unique ===\n")
    end,
})

petDropdown = PetTab:Dropdown({
    Title="Pet Listesi", Values={"Önce Scan yap"}, Multi=true, AllowNone=true,
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

PetTab:Section({ Title="2) Evolve" })

PetTab:Toggle({
    Title="⚡ AUTO EVOLVE (TURBO)",
    Desc="Ne varsa hepsini evolve eder — beklemesiz, tam hız",
    Value=false,
    Callback=function(s)
        Config.AutoEvolvePets = s
        if s then
            -- oyunun kendi auto-evolve'unu da aç
            send(R.autoEvolve, true); send(R.autoEvolve, "enable", true); send(R.autoEvolve)
            local n = turboEvolveAll()
            WindUI:Notify({ Title="⚡ Turbo Evolve AÇIK",
                Content=n.." pet işleniyor, sürekli tekrarlanacak", Duration=4 })
        end
    end,
})

PetTab:Slider({
    Title="Evolve Tekrar Hızı (saniye)",
    Desc="0.1 = en hızlı | lag olursa yükselt",
    Value={ Min=0.05, Max=2, Default=0.1 }, Step=0.05,
    Callback=function(v) Config.EvolveTickRate = tonumber(v) or 0.1 end,
})

PetTab:Button({
    Title="⚡ Şimdi Hepsini Evolve Et",
    Callback=function()
        local n = turboEvolveAll()
        WindUI:Notify({ Title="Turbo Evolve", Content=n.." pet işlendi", Duration=3 })
    end,
})

PetTab:Button({
    Title="🧠 Doğru Formatı Öğren (1 kez bas)",
    Desc="Hangi argüman formatının çalıştığını bulur → 20x hızlanır",
    Callback=function()
        task.spawn(function()
            WindUI:Notify({ Title="Öğreniliyor", Content="Birkaç saniye...", Duration=3 })
            local ok = learnFormat(R.petEvolve, "evolvePet", "evolve")
            WindUI:Notify({
                Title = ok and "✅ Format bulundu" or "⚠️ Bulunamadı",
                Content = ok and ("Format #"..tostring(EVOLVE_FMT).." — artık çok hızlı")
                             or "Tüm formatlar denenmeye devam edecek",
                Duration = 5,
            })
        end)
    end,
})

PetTab:Section({ Title="2b) Equip Best" })

PetTab:Toggle({
    Title="🏆 AUTO EQUIP BEST",
    Desc="En güçlü petleri otomatik kuşanır (rarity'ye göre sıralar)",
    Value=false,
    Callback=function(s)
        Config.AutoEquipBest = s
        if s then
            local n, err = equipBestPets(Config.MaxEquipSlots)
            if err then
                WindUI:Notify({ Title="⚠️ Hata", Content=err, Duration=4 })
            else
                WindUI:Notify({ Title="🏆 Equip Best AÇIK",
                    Content=n.." pet kuşanıldı (her 5sn yenilenir)", Duration=4 })
            end
        end
    end,
})

PetTab:Slider({
    Title="Kaç Pet Kuşanılacak?",
    Desc="Slot sayısı kadar en güçlü petler seçilir",
    Value={ Min=1, Max=10, Default=6 }, Step=1,
    Callback=function(v) Config.MaxEquipSlots = tonumber(v) or 6 end,
})

PetTab:Button({
    Title="🏆 Şimdi En İyileri Kuşan",
    Desc="Tek seferlik — en güçlü petleri equip eder",
    Callback=function()
        task.spawn(function()
            local n, err = equipBestPets(Config.MaxEquipSlots)
            if err then
                WindUI:Notify({ Title="⚠️ Hata", Content=err, Duration=4 })
            else
                WindUI:Notify({ Title="🏆 Kuşanıldı", Content=n.." en iyi pet equip edildi", Duration=3 })
                -- konsola sıralamayı yaz
                local objs = collectPetObjects()
                table.sort(objs, function(a,b) return petScore(a) > petScore(b) end)
                print("\n=== EQUIP BEST ===")
                for i=1, math.min(#objs, 10) do
                    print(("  #%d  %-30s  score=%d"):format(i, objs[i].Name, petScore(objs[i])))
                end
                print("=== END ===\n")
            end
        end)
    end,
})

PetTab:Button({
    Title="📋 Pet Güç Sıralamasını Yazdır",
    Desc="F9'a tüm petlerin güç puanını yazar",
    Callback=function()
        task.spawn(function()
            local objs = collectPetObjects()
            if #objs == 0 then
                WindUI:Notify({ Title="Pet yok", Content="Önce Scan yap", Duration=3 })
                return
            end
            table.sort(objs, function(a,b) return petScore(a) > petScore(b) end)
            print("\n=== PET GÜÇ SIRALAMASI ===")
            for i, v in ipairs(objs) do
                print(("  #%d  %-30s  score=%d"):format(i, v.Name, petScore(v)))
            end
            print("Toplam "..#objs.." pet")
            print("=== END ===\n")
            WindUI:Notify({ Title="Sıralama", Content=#objs.." pet F9'a yazıldı", Duration=3 })
        end)
    end,
})

PetTab:Button({
    Title="❌ Tüm Petleri Unequip Et",
    Desc="Kuşanılan tüm petleri çıkarır",
    Callback=function()
        task.spawn(function()
            local objs = collectPetObjects()
            for _, v in ipairs(objs) do
                pcall(unequipPet, v)
                task.wait(0.05)
            end
            WindUI:Notify({ Title="Unequip", Content=#objs.." pet çıkarıldı", Duration=3 })
        end)
    end,
})

PetTab:Section({ Title="3) Sell" })

PetTab:Toggle({ Title="Auto Sell (listedekiler)", Value=false,
    Callback=function(s) Config.AutoSellPets=s end })

PetTab:Button({
    Title="Seçilenleri Sell Listesine Ekle",
    Callback=function()
        if #Config.SelectedPets==0 then
            WindUI:Notify({ Title="Seçim yok", Content="Önce pet seç", Duration=3 }); return
        end
        for _,n in ipairs(Config.SelectedPets) do table.insert(Config.SellPetList,n) end
        WindUI:Notify({ Title="Eklendi", Content=#Config.SellPetList.." pet listede", Duration=3 })
    end,
})

PetTab:Input({
    Title="Manuel Pet Ekle", Placeholder="Pet adı",
    Callback=function(t)
        if t and t~="" then
            table.insert(Config.SellPetList,cleanPetName(t))
            WindUI:Notify({ Title="Eklendi", Content=t, Duration=3 })
        end
    end,
})

PetTab:Button({
    Title="Sell Selected Now",
    Callback=function()
        task.spawn(function()
            local n = forEachPetObject(Config.SelectedPets, function(v)
                tryAllFormats(R.sellPet,"sellPet",v); task.wait(0.05)
            end)
            WindUI:Notify({ Title="Satıldı", Content=n.." pet denendi", Duration=3 })
        end)
    end,
})

PetTab:Button({
    Title="Clear Sell List",
    Callback=function() Config.SellPetList={}
        WindUI:Notify({ Title="Temizlendi", Content="Sell listesi boş", Duration=3 }) end,
})

-- ════════════════════════════════════════════════════════════
--  ★ CRYSTAL & HATCH  (Teleports'tan buraya taşındı)
-- ════════════════════════════════════════════════════════════

PetTab:Section({ Title="🔮 Crystal Seçimi" })

local crystalDropdown, crystalStatus, petPoolDropdown, huntStatus

crystalStatus = PetTab:Paragraph({
    Title = "Crystal Veritabanı",
    Desc  = "Henüz taranmadı. 'Crystal'ları Tara' butonuna bas.",
})

-- Muscle Legends 2'deki TÜM kristaller (hardcoded — oyun tarayamazsa yedek)
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
    Title = "Crystal Seç",
    Values = crystalListUI,
    Value = crystalListUI[1],
    Callback = function(v)
        Config.SelectedCrystal = type(v)=="table" and tostring(v[1]) or tostring(v)
        -- seçilen crystal'ın pet havuzunu dropdown'a bas
        local pool = CrystalDB[Config.SelectedCrystal]
        if pool and #pool > 0 and petPoolDropdown then
            local vals = {}
            for _, p in ipairs(pool) do
                local s = p.name
                if p.rarity and p.rarity ~= "?" then s = s.."  ["..p.rarity.."]" end
                if p.chance and p.chance > 0 then s = s.."  "..string.format("%.2f%%", p.chance) end
                table.insert(vals, s)
            end
            pcall(function() petPoolDropdown:Refresh(vals) end)
            pcall(function() crystalStatus:SetDesc(
                ("%s\n%d pet içeriyor (kaynak: %s)"):format(Config.SelectedCrystal, #pool, DB_SOURCE)) end)
        end
    end,
})

PetTab:Button({
    Title = "🔍 Crystal'ları ve Petlerini Tara",
    Callback = function()
        WindUI:Notify({ Title="Taranıyor", Content="Oyun verisi okunuyor...", Duration=3 })
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
                WindUI:Notify({ Title="Bulundu", Content=#names.." crystal ("..src..")", Duration=5 })
                print("\n=== CRYSTAL DB ["..src.."] ===")
                for _, n in ipairs(names) do
                    print(("  %s -> %d pet"):format(n, #db[n]))
                    for i, p in ipairs(db[n]) do
                        if i <= 12 then
                            print(("      %-32s %-12s %s"):format(p.name, p.rarity,
                                p.chance>0 and string.format("%.3f",p.chance) or ""))
                        end
                    end
                end
                print("=== END ===\n")
            else
                -- DB bulunamadı -> hatch geçmişinden öğren
                local learned = learnedPetsFor(Config.SelectedCrystal)
                if #learned > 0 then
                    local vals = {}
                    for _, p in ipairs(learned) do
                        table.insert(vals, p.name.."  (x"..p.chance.." görüldü)")
                    end
                    pcall(function() petPoolDropdown:Refresh(vals) end)
                    pcall(function() crystalStatus:SetDesc(
                        "Veritabanı yok — hatch geçmişinden öğrenildi ("..#learned.." pet)") end)
                    WindUI:Notify({ Title="Kısmi", Content=#learned.." pet geçmişten alındı", Duration=5 })
                else
                    -- DB bulunamadı -> hardcoded listeyi workspace'te ara
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
                        WindUI:Notify({ Title="Bulundu", Content=#foundNames.." crystal (workspace)", Duration=5 })
                    else
                        -- hardcoded listeyi kullan
                        pcall(function() crystalDropdown:Refresh(crystalListUI) end)
                        pcall(function() crystalStatus:SetDesc(
                            ("Hardcoded liste: %d crystal\nBirkaç hatch yap, petler otomatik dolar"):format(#crystalListUI)) end)
                        WindUI:Notify({ Title="Hazır Liste", Content=#crystalListUI.." crystal seçilebilir", Duration=5 })
                    end
                end
            end
        end)
    end,
})

PetTab:Section({ Title="🎯 Pet Hunt (hedefli avlanma)" })

petPoolDropdown = PetTab:Dropdown({
    Title = "Bu Crystal'dan Çıkan Petler",
    Desc = "Hedeflerini seç — diğerleri otomatik satılır",
    Values = { "Önce 'Crystal'ları Tara' bas" },
    Multi = true,
    AllowNone = true,
    Callback = function(sel)
        local list = {}
        local function clean(s)
            s = tostring(s)
            s = s:gsub("%s*%[.-%]", "")          -- [Omega] sil
            s = s:gsub("%s*%d+%.?%d*%%", "")     -- 0.40% sil
            s = s:gsub("%s*%(x%d+ görüldü%)", "")-- (x3 görüldü) sil
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
            #list > 0 and ("Hedef: "..table.concat(list, ", ")) or "Hedef seçilmedi") end)
    end,
})

PetTab:Input({
    Title = "Manuel Hedef Ekle",
    Placeholder = "Tam pet adı (örn: Twin Element Birdies)",
    Callback = function(t)
        if t and t ~= "" then
            table.insert(Config.HuntTargets, t)
            pcall(function() huntStatus:SetDesc("Hedef: "..table.concat(Config.HuntTargets, ", ")) end)
            WindUI:Notify({ Title="Hedef eklendi", Content=t, Duration=3 })
        end
    end,
})

huntStatus = PetTab:Paragraph({
    Title = "🎯 Hunt Durumu",
    Desc  = "Hedef seçilmedi",
})

PetTab:Toggle({
    Title = "▶️ HUNT BAŞLAT",
    Desc  = "Hedef çıkana kadar açar, çıkmayanları satar",
    Value = false,
    Callback = function(s)
        if s and #Config.HuntTargets == 0 then
            WindUI:Notify({ Title="Hedef yok", Content="Önce hedef pet seç", Duration=4 })
            return
        end
        Config.HuntEnabled = s
        if s then
            HuntStats = { attempts=0, sold=0, found=false, foundPet="", startTime=tick() }
            WindUI:Notify({ Title="🎯 Hunt Başladı",
                Content="Hedef: "..table.concat(Config.HuntTargets, ", "), Duration=4 })
        end
    end,
})

PetTab:Toggle({
    Title = "🗑️ Hedef Olmayanı Otomatik Sat",
    Value = true,
    Callback = function(s) Config.HuntAutoSell = s end,
})

PetTab:Toggle({
    Title = "⏹️ Hedef Bulununca Dur",
    Value = true,
    Callback = function(s) Config.HuntStopOnFind = s end,
})

PetTab:Slider({
    Title = "Hunt Hızı (saniye)",
    Value = { Min=0.05, Max=1, Default=0.08 }, Step=0.01,
    Callback = function(v) Config.HuntDelay = tonumber(v) or 0.08 end,
})

-- canlı hunt istatistiği
task.spawn(function()
    while true do
        if Config.HuntEnabled or HuntStats.attempts > 0 then
            local el = HuntStats.startTime > 0 and (tick()-HuntStats.startTime) or 0
            local rate = el > 0 and (HuntStats.attempts/el*60) or 0
            local txt = ("Hedef: %s\nDeneme: %d  |  Satılan: %d\nHız: %.0f hatch/dk  |  Süre: %ds")
                :format(#Config.HuntTargets>0 and table.concat(Config.HuntTargets,", ") or "-",
                        HuntStats.attempts, HuntStats.sold, rate, math.floor(el))
            if HuntStats.found then
                txt = "✅ BULUNDU: "..HuntStats.foundPet.."\n"..txt
            end
            pcall(function() huntStatus:SetDesc(txt) end)
        end
        task.wait(1)
    end
end)

PetTab:Section({ Title="🥚 Normal Hatch" })

PetTab:Toggle({ Title="Auto Hatch (hedefsiz)", Value=false,
    Callback=function(s) Config.AutoHatchCrystal=s end })

PetTab:Toggle({ Title="🌟 Nadir Pet Bildirimi", Value=true,
    Callback=function(s) Config.NotifyRare=s end })

PetTab:Slider({ Title="Hatch Delay", Value={Min=0.05,Max=2,Default=0.1}, Step=0.05,
    Callback=function(v) Config.HatchDelay=tonumber(v) or 0.1 end })

local hatchLabel = PetTab:Paragraph({
    Title = "📊 Hatch İstatistiği",
    Desc  = "Henüz hatch yapılmadı.",
})

local function refreshHatchLabel()
    local lines = { ("Toplam: %d  |  Son: %s (%s)"):format(
        HatchStats.total, HatchStats.last, HatchStats.lastRarity) }
    local rar = {}
    for k,v in pairs(HatchStats.byRarity) do table.insert(rar,{k,v}) end
    table.sort(rar, function(a,b) return a[2] > b[2] end)
    for i=1, math.min(#rar,6) do
        local pct = HatchStats.total>0 and (rar[i][2]/HatchStats.total*100) or 0
        table.insert(lines, ("  %s: %d (%.1f%%)"):format(rar[i][1], rar[i][2], pct))
    end
    pcall(function() hatchLabel:SetDesc(table.concat(lines,"\n")) end)
end

task.spawn(function()
    while true do
        if HatchStats.total > 0 then pcall(refreshHatchLabel) end
        task.wait(2)
    end
end)

PetTab:Button({ Title="🥚 Hatch Once", Callback=function()
    local got = hatchOnce(Config.SelectedCrystal, 1)
    if got then
        refreshHatchLabel()
        WindUI:Notify({
            Title = isRare(got.rarity) and ("🌟 "..got.rarity.."!") or ("Hatch: "..got.rarity),
            Content = got.pet, Duration = 4,
        })
    else
        WindUI:Notify({ Title="Hatch", Content="Sonuç okunamadı", Duration=3 })
    end
end })

PetTab:Button({ Title="🥚 Hatch x25", Callback=function()
    task.spawn(function()
        local rares = 0
        for i=1,25 do
            local g = hatchOnce(Config.SelectedCrystal,1)
            if g and isRare(g.rarity) then rares = rares + 1 end
            task.wait(0.1)
        end
        refreshHatchLabel()
        WindUI:Notify({ Title="25 Hatch", Content=rares.." nadir çıktı", Duration=4 })
    end)
end })

PetTab:Button({ Title="📋 Hatch Raporu", Callback=function()
    print("\n=== HATCH RAPORU ===")
    print("Toplam: "..HatchStats.total)
    for k,v in pairs(HatchStats.byRarity) do
        print(("  %-22s %d (%.1f%%)"):format(k,v,HatchStats.total>0 and v/HatchStats.total*100 or 0))
    end
    local arr={} for k,v in pairs(HatchStats.byPet) do table.insert(arr,{k,v}) end
    table.sort(arr,function(a,b) return a[2]>b[2] end)
    for _,e in ipairs(arr) do print(("  %-30s x%d"):format(e[1],e[2])) end
    print("=== END ===\n")
    WindUI:Notify({ Title="Rapor", Content="F9'a yazıldı", Duration=3 })
end })

-- ════════════════════════════════════════════════════════════
--  TAB: TELEPORTS
-- ════════════════════════════════════════════════════════════

Loading:SetProgress(0.85,"Adding teleports...")
local TPTab = Window:Tab({ Title="Teleports", Icon="solar:map-point-bold" })

TPTab:Section({ Title="🗺️ Haritalar" })

-- Oyundaki gerçek area'ları workspace'ten okur
local mapList = {}
local mapCircles = {}   -- [görünen isim] = circle objesi

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

-- oyundan okunamadıysa bilinen liste
if #mapList == 0 then
    mapList = {
        "Starter Gym","Muscle King Gym","Mythical Gym","External Gym",
        "Frost Gym","Legends Gym","Jungle Gym","Volcano Gym",
        "Space Gym","Void Gym","Heaven Gym","Titan Gym",
    }
end

local mapStatus = TPTab:Paragraph({
    Title = "Harita Kaynağı",
    Desc  = (next(mapCircles) and ("Oyundan okundu: "..#mapList.." harita"))
            or "areaCircles okunamadı — varsayılan liste kullanılıyor",
})

local mapDropdown
mapDropdown = TPTab:Dropdown({
    Title = "Harita Seç",
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
        WindUI:Notify({ Title="Teleport", Content=(ok and "→ " or "Bulunamadı: ")..n, Duration=2 })
    end,
})

TPTab:Button({
    Title="🔄 Harita Listesini Yenile",
    Callback=function()
        local l = refreshMaps()
        if #l > 0 and mapDropdown then
            pcall(function() mapDropdown:Refresh(l) end)
            pcall(function() mapStatus:SetDesc("Oyundan okundu: "..#l.." harita") end)
            WindUI:Notify({ Title="Yenilendi", Content=#l.." harita bulundu", Duration=3 })
        else
            WindUI:Notify({ Title="Bulunamadı", Content="areaCircles okunamadı", Duration=3 })
        end
    end,
})

TPTab:Button({
    Title="⏭️ Sıradaki Haritaya Geç",
    Callback=function()
        if #mapList == 0 then return end
        Config._mapIdx = ((Config._mapIdx or 0) % #mapList) + 1
        local n = mapList[Config._mapIdx]
        local c = mapCircles[n]
        if c and R.areaTravel then invoke(R.areaTravel,"travelToArea",c) else tpToGym(n) end
        WindUI:Notify({ Title="Teleport", Content="→ "..n, Duration=2 })
    end,
})

TPTab:Button({
    Title="🏆 En Son Haritaya Git",
    Callback=function()
        if #mapList == 0 then return end
        local n = mapList[#mapList]
        local c = mapCircles[n]
        if c and R.areaTravel then invoke(R.areaTravel,"travelToArea",c) else tpToGym(n) end
        WindUI:Notify({ Title="Teleport", Content="→ "..n, Duration=2 })
    end,
})

TPTab:Section({ Title="Player TP" })
TPTab:Button({ Title="TP to Nearest Player", Callback=function()
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
--  TAB: MISC (yeni remoteler)
-- ════════════════════════════════════════════════════════════

local MiscTab = Window:Tab({ Title="Misc", Icon="solar:star-bold" })

-- ════════════════════════════════════════════════════════════
--  ★ EXPLOIT DETECTOR
-- ════════════════════════════════════════════════════════════

MiscTab:Section({ Title="🚨 Exploit Detector" })

local detStatus = MiscTab:Paragraph({
    Title = "Tespit Kaydı",
    Desc  = "Detector kapalı.",
})

MiscTab:Toggle({
    Title = "🚨 Exploit Detector",
    Desc  = "Işınlanıp kill yapanı yakalar: teleport, kill farm, oyuncu öldürme, sana saldırı",
    Value = false,
    Callback = function(s)
        Config.DetectorEnabled = s
        if s then
            DetectorLog = {}
            playerTrack = {}
            WindUI:Notify({ Title="Detector AÇIK",
                Content=#Players:GetPlayers().." oyuncu izleniyor", Duration=4 })
        else
            pcall(function() detStatus:SetDesc("Detector kapalı.") end)
        end
    end,
})

MiscTab:Toggle({
    Title = "🔄 Tehdit Görünce Server Değiştir",
    Desc  = "Işınlanıp kill farm yapanı görünca server değiştirir (45sn cooldown)",
    Value = true,
    Callback = function(s) Config.DetectorAutoHop = s end,
})

MiscTab:Slider({
    Title = "Hassasiyet",
    Desc  = "1 = hassas | 3 = dengeli (önerilen) | 5 = sadece kesin tehdit",
    Value = { Min=1, Max=5, Default=3 }, Step=1,
    Callback = function(v) Config.DetectorSensitivity = tonumber(v) or 3 end,
})

MiscTab:Toggle({
    Title = "⚠️ Sıkı Mod (hız/fly de sayılsın)",
    Desc  = "KAPALI tut — bu oyunda herkes hızlı, yanlış alarm verir",
    Value = false,
    Callback = function(s)
        Config.DetectorStrictMode = s
        if s then
            WindUI:Notify({ Title="Sıkı Mod AÇIK",
                Content="Hız/fly kullananlar da şüpheli sayılacak", Duration=5 })
        end
    end,
})

MiscTab:Input({
    Title = "🤍 Whitelist'e Ekle",
    Placeholder = "Oyuncu adı (arkadaşın)",
    Callback = function(t)
        if t and t ~= "" then
            Config.DetectorWhitelist[t] = true
            WindUI:Notify({ Title="Whitelist", Content=t.." artık taranmayacak", Duration=3 })
        end
    end,
})

MiscTab:Button({
    Title = "🤍 Whitelist'i Temizle",
    Callback = function()
        Config.DetectorWhitelist = {}
        WindUI:Notify({ Title="Temizlendi", Content="Whitelist boşaltıldı", Duration=2 })
    end,
})

MiscTab:Button({
    Title = "🔄 Şimdi Server Değiştir",
    Callback = function() task.spawn(serverHop, "manuel") end,
})

MiscTab:Button({
    Title = "👥 Oyuncu Analizi Yazdır",
    Callback = function()
        print("\n=== OYUNCU ANALİZİ ===")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local tr = playerTrack[p]
                local ch = p.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                print(("  %-20s score=%d  ws=%s  ff=%s"):format(
                    p.Name,
                    tr and math.floor(tr.score or 0) or 0,
                    hum and math.floor(hum.WalkSpeed) or "?",
                    (ch and ch:FindFirstChildOfClass("ForceField")) and "VAR" or "yok"))
            end
        end
        print("=== END ===\n")
        WindUI:Notify({ Title="Analiz", Content="F9'a yazıldı", Duration=3 })
    end,
})

-- detector log canlı güncelleme
task.spawn(function()
    while true do
        if Config.DetectorEnabled then
            local txt
            if #DetectorLog == 0 then
                txt = ("İzleniyor: %d oyuncu\nHenüz tespit yok ✅"):format(#Players:GetPlayers()-1)
            else
                txt = "Son tespitler:\n"..table.concat(DetectorLog, "\n", 1, math.min(#DetectorLog,6))
            end
            pcall(function() detStatus:SetDesc(txt) end)
        end
        task.wait(2)
    end
end)

MiscTab:Section({ Title="Kodlar" })
MiscTab:Input({
    Title="Kod Kullan", Placeholder="Kodu yaz",
    Callback=function(t)
        if t and t~="" then
            send(R.code,t); send(R.code,"redeem",t)
            WindUI:Notify({ Title="Kod", Content="Denendi: "..t, Duration=3 })
        end
    end,
})
MiscTab:Button({
    Title="Bilinen Tüm Kodları Dene",
    Callback=function()
        local codes = {"release","muscle","update","gym","strength","legends","free","launch","2025","pets"}
        task.spawn(function()
            for _,c in ipairs(codes) do send(R.code,c); send(R.code,"redeem",c); task.wait(0.4) end
            WindUI:Notify({ Title="Kodlar", Content=#codes.." kod denendi", Duration=3 })
        end)
    end,
})

MiscTab:Section({ Title="Diğer" })
MiscTab:Button({ Title="Fortune Wheel Spin", Callback=function()
    send(R.fortuneWheel,"spin"); send(R.fortuneWheel)
    WindUI:Notify({ Title="Wheel", Content="Spin denendi", Duration=2 }) end })
MiscTab:Button({ Title="Claim Free Gift", Callback=function()
    send(R.freeGift,"claim"); send(R.freeGift)
    WindUI:Notify({ Title="Gift", Content="Claim denendi", Duration=2 }) end })
MiscTab:Button({ Title="Sell All PowerUps", Callback=function()
    send(R.sellPowerUp,"sellAll"); send(R.sellPowerUp)
    WindUI:Notify({ Title="PowerUp", Content="Satış denendi", Duration=2 }) end })
MiscTab:Button({ Title="Evolve All PowerUps", Callback=function()
    send(R.evolvePowerUp,"evolveAll"); send(R.evolvePowerUp)
    WindUI:Notify({ Title="PowerUp", Content="Evolve denendi", Duration=2 }) end })
MiscTab:Button({ Title="Ultimates Trigger", Callback=function()
    send(R.ultimates,"use"); send(R.ultimates)
    WindUI:Notify({ Title="Ultimate", Content="Denendi", Duration=2 }) end })

-- ════════════════════════════════════════════════════════════
--  TAB: VISUAL
-- ════════════════════════════════════════════════════════════

local VisualTab = Window:Tab({ Title="Visual", Icon="solar:eye-bold" })
VisualTab:Section({ Title="Client-Side Görsel Değişiklikler" })
local function vpair(title,flag,val)
    VisualTab:Toggle({ Title="Visual "..title, Desc="Sadece ekranda değişir", Value=false,
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
VisualTab:Button({ Title="Apply Now", Callback=function() applyVisuals()
    WindUI:Notify({ Title="Applied", Content="Uygulandı", Duration=3 }) end })
VisualTab:Button({ Title="Reset All", Callback=function()
    Config.VisualStrength,Config.VisualGems=false,false
    Config.VisualCoins,Config.VisualRebirths=false,false
    Config.VisualLevel,Config.VisualWin=false,false
    WindUI:Notify({ Title="Reset", Content="Kapatıldı", Duration=3 }) end })

-- ════════════════════════════════════════════════════════════
--  TAB: SETTINGS
-- ════════════════════════════════════════════════════════════

local SettingsTab = Window:Tab({ Title="Settings", Icon="solar:settings-bold" })
SettingsTab:Section({ Title="System" })
SettingsTab:Toggle({ Title="Anti AFK", Value=true,
    Callback=function(s) Config.AntiAFK=s; toggleAntiAFK(s) end })
SettingsTab:Button({ Title="Unload Script", Callback=function()
    toggleAntiAFK(false)
    for k,v in pairs(Config) do if type(v)=="boolean" then Config[k]=false end end
    pcall(function() WindUI:Destroy() end)
end })
SettingsTab:Section({ Title="Credits" })
SettingsTab:Paragraph({ Title="ShHub v3.5",
    Desc="Made by molokoz/yatzukix\nPrivate for nuggiez6244\nUI: WindUI (Footagesus)" })

-- ════════════════════════════════════════════════════════════
--  START
-- ════════════════════════════════════════════════════════════

toggleAntiAFK(true)
Loading:SetProgress(1,"Ready!")
task.wait(0.4)
Loading:Close()
pcall(function() Window:SelectTab(1) end)

WindUI:Notify({
    Title = "ShHub v3.5 Loaded!",
    Content = muscleEvent and "Tüm sistemler hazır"
        or "⚠️ muscleEvent yok — machineInteract kullanılıyor",
    Duration = 6, Icon = "solar:bell-bold",
})

if not muscleEvent then
    task.delay(2, function()
        WindUI:Notify({
            Title = "Rep çalışmıyorsa",
            Content = "machineInteractRemote ile rep gönderiliyor — sorun yoksa görmezden çık",
            Duration = 8, Icon = "solar:info-circle-bold",
        })
    end)
end
