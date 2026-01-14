-- Brainrot Control System
-- Salve como: brainrot_system.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Variáveis do sistema
local guiEnabled = false
local currentGui = nil
local selectedModelName = nil
local brainrotFolder = nil
local modelCache = {}
local activeConnections = {}

-- Encontrar a pasta ActiveBrainrots
local function findBrainrotFolder()
    brainrotFolder = Workspace:FindFirstChild("ActiveBrainrots")
    
    if not brainrotFolder then
        warn("Pasta 'ActiveBrainrots' não encontrada no Workspace!")
        return nil
    end
    
    -- Coletar todos os modelos
    modelCache = {}
    for _, subFolder in ipairs(brainrotFolder:GetChildren()) do
        if subFolder:IsA("Folder") then
            for _, model in ipairs(subFolder:GetChildren()) do
                if model:IsA("Model") then
                    table.insert(modelCache, {
                        Name = model.Name,
                        Model = model,
                        FolderName = subFolder.Name
                    })
                end
            end
        end
    end
    
    -- Ordenar alfabeticamente
    table.sort(modelCache, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    
    return brainrotFolder
end

-- Criar círculo arrastável
local function createDragCircle()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrainrotControl"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local circle = Instance.new("Frame")
    circle.Name = "DragCircle"
    circle.Size = UDim2.new(0, 60, 0, 60)
    circle.Position = UDim2.new(0.8, 0, 0.8, 0)
    circle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    circle.BackgroundTransparency = 0.3
    circle.BorderSizePixel = 0
    circle.ZIndex = 100
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "☺"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = circle
    
    -- Tornar arrastável
    local dragging = false
    local dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        circle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    circle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = circle.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    circle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput) then
            update(input)
        end
    end)
    
    -- Função de clique para abrir/fechar GUI
    local clickCount = 0
    local lastClickTime = 0
    
    circle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local currentTime = tick()
            if currentTime - lastClickTime < 0.3 then
                clickCount = clickCount + 1
            else
                clickCount = 1
            end
            lastClickTime = currentTime
            
            if clickCount == 2 then
                clickCount = 0
                guiEnabled = not guiEnabled
                
                if guiEnabled then
                    -- Criar título
                    title.Text = "Shift Lock\nMobile and PC"
                    
                    -- Criar GUI principal
                    createMainGUI()
                else
                    -- Fechar GUI
                    title.Text = "☺"
                    if currentGui then
                        currentGui:Destroy()
                        currentGui = nil
                    end
                end
            end
        end
    end)
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    return screenGui
end

-- Criar GUI principal
local function createMainGUI()
    if currentGui then
        currentGui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "BrainrotMainGUI"
    gui.Parent = player:WaitForChild("PlayerGui")
    currentGui = gui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    title.Text = "BRAINROT CONTROL SYSTEM"
    title.TextColor3 = Color3.white
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Barra de pesquisa
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.9, 0, 0, 35)
    searchBox.Position = UDim2.new(0.05, 0, 0, 60)
    searchBox.PlaceholderText = "Pesquisar modelos..."
    searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    searchBox.TextColor3 = Color3.white
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 14
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 4)
    searchCorner.Parent = searchBox
    
    -- Frame de scroll para a lista
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.9, 0, 0, 250)
    scrollFrame.Position = UDim2.new(0.05, 0, 0, 110)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 4)
    scrollCorner.Parent = scrollFrame
    
    -- Frame para os botões de função
    local functionFrame = Instance.new("Frame")
    functionFrame.Size = UDim2.new(0.9, 0, 0, 120)
    functionFrame.Position = UDim2.new(0.05, 0, 0, 370)
    functionFrame.BackgroundTransparency = 1
    
    -- Botão 1: Escolher modelo
    local chooseBtn = Instance.new("TextButton")
    chooseBtn.Size = UDim2.new(1, 0, 0, 35)
    chooseBtn.Position = UDim2.new(0, 0, 0, 0)
    chooseBtn.Text = "1. ESCOLHER MODELO"
    chooseBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    chooseBtn.TextColor3 = Color3.white
    chooseBtn.Font = Enum.Font.GothamBold
    chooseBtn.TextSize = 14
    
    local chooseCorner = Instance.new("UICorner")
    chooseCorner.CornerRadius = UDim.new(0, 4)
    chooseCorner.Parent = chooseBtn
    
    -- Botão 2: Trazer brainrot
    local catchBtn = Instance.new("TextButton")
    catchBtn.Size = UDim2.new(1, 0, 0, 35)
    catchBtn.Position = UDim2.new(0, 0, 0, 45)
    catchBtn.Text = "2. CATCH BRAINROT"
    catchBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    catchBtn.TextColor3 = Color3.white
    catchBtn.Font = Enum.Font.GothamBold
    catchBtn.TextSize = 14
    
    local catchCorner = Instance.new("UICorner")
    catchCorner.CornerRadius = UDim.new(0, 4)
    catchCorner.Parent = catchBtn
    
    -- Botão 3: Teleport automático
    local autoTpBtn = Instance.new("TextButton")
    autoTpBtn.Size = UDim2.new(0.48, 0, 0, 35)
    autoTpBtn.Position = UDim2.new(0, 0, 0, 85)
    autoTpBtn.Text = "3. AUTO TP"
    autoTpBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    autoTpBtn.TextColor3 = Color3.white
    autoTpBtn.Font = Enum.Font.GothamBold
    autoTpBtn.TextSize = 12
    
    local autoTpCorner = Instance.new("UICorner")
    autoTpCorner.CornerRadius = UDim.new(0, 4)
    autoTpCorner.Parent = autoTpBtn
    
    -- Botão 4: Teleport manual
    local manualTpBtn = Instance.new("TextButton")
    manualTpBtn.Size = UDim2.new(0.48, 0, 0, 35)
    manualTpBtn.Position = UDim2.new(0.52, 0, 0, 85)
    manualTpBtn.Text = "4. MANUAL TP"
    manualTpBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 0)
    manualTpBtn.TextColor3 = Color3.white
    manualTpBtn.Font = Enum.Font.GothamBold
    manualTpBtn.TextSize = 12
    
    local manualTpCorner = Instance.new("UICorner")
    manualTpCorner.CornerRadius = UDim.new(0, 4)
    manualTpCorner.Parent = manualTpBtn
    
    -- Texto do modelo selecionado
    local selectedText = Instance.new("TextLabel")
    selectedText.Size = UDim2.new(1, 0, 0, 20)
    selectedText.Position = UDim2.new(0, 0, 0, 325)
    selectedText.BackgroundTransparency = 1
    selectedText.Text = "Nenhum modelo selecionado"
    selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
    selectedText.Font = Enum.Font.Gotham
    selectedText.TextSize = 12
    selectedText.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Adicionar elementos à hierarquia
    title.Parent = mainFrame
    searchBox.Parent = mainFrame
    scrollFrame.Parent = mainFrame
    selectedText.Parent = mainFrame
    
    chooseBtn.Parent = functionFrame
    catchBtn.Parent = functionFrame
    autoTpBtn.Parent = functionFrame
    manualTpBtn.Parent = functionFrame
    functionFrame.Parent = mainFrame
    
    mainFrame.Parent = gui
    
    -- Variáveis para a lista
    local listItems = {}
    local selectedItem = nil
    
    -- Função para atualizar a lista
    local function updateList(filter)
        -- Limpar lista atual
        for _, item in ipairs(listItems) do
            item:Destroy()
        end
        listItems = {}
        
        -- Filtrar modelos
        local filteredModels = {}
        if filter and filter ~= "" then
            local lowerFilter = filter:lower()
            for _, modelData in ipairs(modelCache) do
                if modelData.Name:lower():find(lowerFilter, 1, true) then
                    table.insert(filteredModels, modelData)
                end
            end
        else
            filteredModels = modelCache
        end
        
        -- Criar novos itens
        local yOffset = 0
        local itemHeight = 30
        
        for i, modelData in ipairs(filteredModels) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -10, 0, itemHeight)
            itemFrame.Position = UDim2.new(0, 5, 0, yOffset)
            itemFrame.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(50, 50, 60) 
                                                     or Color3.fromRGB(45, 45, 55)
            itemFrame.BorderSizePixel = 0
            
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 4)
            itemCorner.Parent = itemFrame
            
            local itemText = Instance.new("TextLabel")
            itemText.Size = UDim2.new(1, 0, 1, 0)
            itemText.BackgroundTransparency = 1
            itemText.Text = modelData.Name
            itemText.TextColor3 = Color3.white
            itemText.Font = Enum.Font.Gotham
            itemText.TextSize = 12
            itemText.TextXAlignment = Enum.TextXAlignment.Left
            itemText.PaddingLeft = UDim.new(0, 10)
            itemText.Parent = itemFrame
            
            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(0, 80, 0, 20)
            selectBtn.Position = UDim2.new(1, -85, 0.5, -10)
            selectBtn.Text = "SELECIONAR"
            selectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            selectBtn.TextColor3 = Color3.white
            selectBtn.Font = Enum.Font.GothamBold
            selectBtn.TextSize = 10
            selectBtn.Parent = itemFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = selectBtn
            
            -- Função de seleção
            selectBtn.MouseButton1Click:Connect(function()
                if selectedItem then
                    selectedItem.BackgroundColor3 = selectedItem.Name:find("Selected") and 
                                                    Color3.fromRGB(60, 60, 70) or
                                                    (tonumber(selectedItem.Name:match("%d+")) % 2 == 0 and 
                                                     Color3.fromRGB(50, 50, 60) or 
                                                     Color3.fromRGB(45, 45, 55))
                end
                
                selectedItem = itemFrame
                selectedModelName = modelData.Name
                selectedText.Text = "Selecionado: " .. modelData.Name
                itemFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
                
                -- Fechar GUI após seleção
                task.wait(0.3)
                guiEnabled = false
                gui:Destroy()
                currentGui = nil
                
                -- Atualizar título do círculo
                local playerGui = player:WaitForChild("PlayerGui")
                local brainrotControl = playerGui:FindFirstChild("BrainrotControl")
                if brainrotControl then
                    local circle = brainrotControl:FindFirstChild("DragCircle")
                    if circle then
                        circle.Title.Text = "☺"
                    end
                end
            end)
            
            itemFrame.Parent = scrollFrame
            table.insert(listItems, itemFrame)
            
            yOffset = yOffset + itemHeight + 2
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end
    
    -- Configurar barra de pesquisa
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        updateList(searchBox.Text)
    end)
    
    -- Inicializar lista
    updateList("")
    
    -- FUNÇÃO 1: Sistema de escolha (já implementado acima)
    
    -- FUNÇÃO 2: Catch brainrot
    catchBtn.MouseButton1Click:Connect(function()
        if not selectedModelName then
            selectedText.Text = "Selecione um modelo primeiro!"
            selectedText.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(1)
            selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
            return
        end
        
        -- Encontrar o modelo
        local targetModel = nil
        for _, modelData in ipairs(modelCache) do
            if modelData.Name == selectedModelName then
                targetModel = modelData.Model
                break
            end
        end
        
        if targetModel then
            -- Teleportar modelo para a posição do jogador
            local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                targetModel:PivotTo(humanoidRootPart.CFrame + Vector3.new(0, 0, -10))
                selectedText.Text = "Modelo trazido: " .. selectedModelName
                selectedText.TextColor3 = Color3.fromRGB(50, 255, 50)
                task.wait(1)
                selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
    
    -- FUNÇÃO 3: Teleport automático
    autoTpBtn.MouseButton1Click:Connect(function()
        if not selectedModelName then
            selectedText.Text = "Selecione um modelo primeiro!"
            selectedText.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(1)
            selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
            return
        end
        
        -- Encontrar o modelo
        local targetModel = nil
        for _, modelData in ipairs(modelCache) do
            if modelData.Name == selectedModelName then
                targetModel = modelData.Model
                break
            end
        end
        
        if targetModel then
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local spawnLocation = nil
            
            -- Encontrar spawn point
            for _, spawn in ipairs(Workspace:GetChildren()) do
                if spawn.Name == "SpawnLocation" or spawn:IsA("SpawnLocation") then
                    spawnLocation = spawn
                    break
                end
            end
            
            if humanoidRootPart and spawnLocation then
                -- Salvar posição original
                local originalPosition = humanoidRootPart.CFrame
                
                -- Teleportar para o modelo
                humanoidRootPart.CFrame = targetModel:GetPivot() + Vector3.new(0, 5, 0)
                selectedText.Text = "Teleportado para: " .. selectedModelName
                
                -- Sistema de detecção de atualização do modelo
                local connection
                connection = targetModel.Changed:Connect(function()
                    -- Quando o modelo for atualizado, teleportar de volta
                    humanoidRootPart.CFrame = spawnLocation.CFrame
                    selectedText.Text = "Retornado ao spawn (atualização detectada)"
                    
                    -- Esperar e teleportar novamente (método alternativo)
                    task.wait(5)
                    humanoidRootPart.CFrame = spawnLocation.CFrame
                    
                    -- Limpar conexão
                    if connection then
                        connection:Disconnect()
                    end
                end)
                
                -- Também usar método alternativo
                task.wait(5)
                humanoidRootPart.CFrame = spawnLocation.CFrame
                
                task.wait(1)
                selectedText.Text = "Teleport automático completo"
            end
        end
    end)
    
    -- FUNÇÃO 4: Teleport manual
    manualTpBtn.MouseButton1Click:Connect(function()
        if not selectedModelName then
            selectedText.Text = "Selecione um modelo primeiro!"
            selectedText.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(1)
            selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
            return
        end
        
        -- Encontrar o modelo
        local targetModel = nil
        for _, modelData in ipairs(modelCache) do
            if modelData.Name == selectedModelName then
                targetModel = modelData.Model
                break
            end
        end
        
        if targetModel then
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                -- Método 1: Verificar atualização
                local updateDetected = false
                local connection = targetModel.Changed:Connect(function()
                    updateDetected = true
                end)
                
                -- Teleportar para o modelo
                humanoidRootPart.CFrame = targetModel:GetPivot() + Vector3.new(0, 5, 0)
                selectedText.Text = "Teleport manual para: " .. selectedModelName
                
                -- Método 2: Clique manual para retornar
                manualTpBtn.Text = "CLIQUE PARA RETORNAR"
                manualTpBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                
                local clickConnection
                clickConnection = manualTpBtn.MouseButton1Click:Connect(function()
                    -- Encontrar spawn
                    local spawnLocation = nil
                    for _, spawn in ipairs(Workspace:GetChildren()) do
                        if spawn.Name == "SpawnLocation" or spawn:IsA("SpawnLocation") then
                            spawnLocation = spawn
                            break
                        end
                    end
                    
                    if spawnLocation then
                        humanoidRootPart.CFrame = spawnLocation.CFrame
                        selectedText.Text = "Retornado manualmente ao spawn"
                        
                        -- Resetar botão
                        task.wait(0.5)
                        manualTpBtn.Text = "4. MANUAL TP"
                        manualTpBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 0)
                        
                        -- Limpar conexões
                        if connection then connection:Disconnect() end
                        if clickConnection then clickConnection:Disconnect() end
                    end
                end)
                
                -- Se detectar atualização, retornar automaticamente
                if updateDetected then
                    local spawnLocation = nil
                    for _, spawn in ipairs(Workspace:GetChildren()) do
                        if spawn.Name == "SpawnLocation" or spawn:IsA("SpawnLocation") then
                            spawnLocation = spawn
                            break
                        end
                    end
                    
                    if spawnLocation then
                        humanoidRootPart.CFrame = spawnLocation.CFrame
                        selectedText.Text = "Retornado (atualização detectada)"
                        
                        -- Resetar botão
                        manualTpBtn.Text = "4. MANUAL TP"
                        manualTpBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 0)
                        
                        if connection then connection:Disconnect() end
                        if clickConnection then clickConnection:Disconnect() end
                    end
                end
            end
        end
    end)
end

-- Inicializar sistema
local function initialize()
    -- Encontrar pasta ActiveBrainrots
    findBrainrotFolder()
    
    if brainrotFolder then
        print("Sistema Brainrot inicializado!")
        print("Modelos encontrados: " .. #modelCache)
        
        for _, modelData in ipairs(modelCache) do
            print("  - " .. modelData.Name .. " (Pasta: " .. modelData.FolderName .. ")")
        end
    else
        print("Pasta ActiveBrainrots não encontrada. Sistema em modo limitado.")
    end
    
    -- Criar círculo arrastável
    createDragCircle()
    
    print("\nInstruções:")
    print("1. Clique duplo no círculo azul para abrir/fechar o menu")
    print("2. Use a barra de pesquisa para filtrar modelos")
    print("3. Selecione um modelo clicando em 'SELECIONAR'")
    print("4. Use os 4 botões de função para controlar os modelos")
end

-- Executar inicialização
task.spawn(initialize)

return {
    RefreshModels = findBrainrotFolder,
    GetSelectedModel = function() return selectedModelName end,
    GetModelCache = function() return modelCache end
}