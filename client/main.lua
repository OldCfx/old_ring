ESX = exports['es_extended']:getSharedObject()

local doorbells = {}
local appointments = {}
local isAdmin = false
local playerJob = nil
local selectedDoorbell = nil
local selectedAppointment = nil
local currentDoorbellId = nil

local doorbellCooldowns = {}

RegisterNetEvent('old_ring:loadDoorbells', function(data)
    doorbells = data
end)

RegisterNetEvent('old_ring:loadAppointments', function(data)
    appointments = data
end)

RegisterNetEvent('old_ring:setAdmin', function(admin)
    isAdmin = admin
end)

RegisterNetEvent('esx:setJob', function(job)
    playerJob = job.name
end)


RegisterNetEvent('old_ring:openStaff', function(message)
    OpenAdminMenu()
end)


CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for id, doorbell in pairs(doorbells) do
            local distance = #(playerCoords - vector3(doorbell.coords.x, doorbell.coords.y, doorbell.coords.z))

            if distance < Config.DrawDistance then
                sleep = 0

                DrawMarker(
                    Config.Marker.type,
                    doorbell.coords.x, doorbell.coords.y, doorbell.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                    Config.Marker.bobUpAndDown,
                    false,
                    2,
                    Config.Marker.rotate,
                    nil,
                    nil,
                    false
                )

                if distance < Config.InteractDistance then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour utiliser la sonnette")

                    if IsControlJustReleased(0, 38) then
                        OpenDoorbellMenu(id, doorbell)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function CanRingDoorbell(doorbellId)
    if not doorbellCooldowns[doorbellId] then
        return true
    end

    local currentTime = GetGameTimer()
    local timeElapsed = (currentTime - doorbellCooldowns[doorbellId]) / 1000

    if timeElapsed >= Config.DoorbellCooldown then
        return true
    end

    return false, math.ceil(Config.DoorbellCooldown - timeElapsed)
end

function OpenDoorbellMenu(id, doorbell)
    currentDoorbellId = id
    local DoorbellMenu = RageUI.CreateMenu("Sonnette", doorbell.label)
    local AppointmentsMenu = RageUI.CreateSubMenu(DoorbellMenu, "Rendez-vous", "Gestion des RDV")
    local DetailMenu = RageUI.CreateSubMenu(AppointmentsMenu, "Détails", "Détails du rendez-vous")

    local rdvList = {}
    local rdvLoaded = false

    RageUI.Visible(DoorbellMenu, not RageUI.Visible(DoorbellMenu))

    while DoorbellMenu do
        Wait(0)

        RageUI.IsVisible(DoorbellMenu, function()
            local canRing, remainingTime = CanRingDoorbell(id)
            local ringDesc = "Appuyer sur la sonnette"

            if not canRing then
                ringDesc = ("Cooldown: %s secondes"):format(remainingTime)
            end

            RageUI.Button("🔔 Sonner", ringDesc, {}, canRing, {
                onSelected = function()
                    local canRingNow, remaining = CanRingDoorbell(id)
                    if canRingNow then
                        TriggerServerEvent('old_ring:ring', doorbell.job, doorbell.label)
                        doorbellCooldowns[id] = GetGameTimer()
                        ESX.ShowNotification("~g~Vous avez sonné !")
                    else
                        ESX.ShowNotification(Config.Notifications.doorbell_cooldown:format(remaining))
                    end
                end
            })

            RageUI.Button("📅 Prendre un rendez-vous", "Demander un rendez-vous", {}, true, {
                onSelected = function()
                    ESX.TriggerServerCallback('old_ring:hasAppointment', function(hasAppointment)
                        if hasAppointment then
                            ESX.ShowNotification(Config.Notifications.already_has_appointment)
                        else
                            OpenAppointmentForm(doorbell.job)
                        end
                    end, doorbell.job)
                end
            })

            if playerJob == doorbell.job then
                RageUI.Separator("~b~↓ Gestion (Employé) ↓")

                RageUI.Button("📋 Gérer les rendez-vous", "Voir et gérer les RDV", { RightLabel = "→" }, true, {
                    onSelected = function()
                        rdvLoaded = false
                        ESX.TriggerServerCallback('old_ring:getAppointments', function(data)
                            rdvList = data
                            rdvLoaded = true
                        end, doorbell.job)
                    end
                }, AppointmentsMenu)
            end
        end)

        RageUI.IsVisible(AppointmentsMenu, function()
            if not rdvLoaded then
                RageUI.Separator("~o~Chargement...")
            else
                RageUI.Separator(("~b~Total: ~g~%s rendez-vous"):format(#rdvList))

                if #rdvList == 0 then
                    RageUI.Separator("~r~Aucun rendez-vous")
                else
                    for _, appointment in ipairs(rdvList) do
                        local desc = ("Tel: %s\nDate: %s à %s"):format(
                            appointment.phone,
                            appointment.date,
                            appointment.time
                        )

                        RageUI.Button(appointment.name, desc, { RightLabel = "→" }, true, {
                            onSelected = function()
                                selectedAppointment = appointment
                            end
                        }, DetailMenu)
                    end
                end
            end
        end)

        RageUI.IsVisible(DetailMenu, function()
            if not selectedAppointment then
                RageUI.Separator("~r~Erreur")
                return
            end

            RageUI.Separator(("~b~Client: ~s~%s"):format(selectedAppointment.name))

            local reason = selectedAppointment.reason

            RageUI.Button("~y~Consulter le rdv", "Afficher le document", {}, true, {
                onSelected = function()
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openAppointmentPaper',
                        appointment = selectedAppointment
                    })
                end
            })

            RageUI.Button("~p~Récupérer le rdv", "Imprimer le rdv sur un papier", {}, true, {
                onSelected = function()
                    ESX.TriggerServerCallback('old_ring:giveRdv', function(try)
                        if try then
                            ESX.ShowNotification("~g~RDV récupéré")
                        end
                    end, selectedAppointment)
                end
            })

            RageUI.Button("~r~Supprimer ce RDV", "Supprimer définitivement", { RightBadge = RageUI.BadgeStyle.Alert },
                true, {
                    onSelected = function()
                        local alert = lib.alertDialog({
                            header = 'Supprimer le rendez-vous',
                            content = ('Supprimer le RDV de %s ?'):format(selectedAppointment.name),
                            centered = true,
                            cancel = true,
                            labels = { confirm = 'Supprimer', cancel = 'Annuler' }
                        })

                        if alert == 'confirm' then
                            TriggerServerEvent('old_ring:deleteAppointment', selectedAppointment.id)

                            for i, rdv in ipairs(rdvList) do
                                if rdv.id == selectedAppointment.id then
                                    table.remove(rdvList, i)
                                    break
                                end
                            end

                            selectedAppointment = nil
                            ESX.ShowNotification("~g~RDV supprimé")
                            RageUI.GoBack()
                        end
                    end
                })
        end)

        if not RageUI.Visible(DoorbellMenu) and not RageUI.Visible(AppointmentsMenu) and not RageUI.Visible(DetailMenu) then
            DoorbellMenu = RMenu:DeleteType('DoorbellMenu', true)
            selectedAppointment = nil
            rdvList = {}
            rdvLoaded = false
            break
        end
    end
end

function FormatDate(timestamp)
    if not timestamp or timestamp == '' or timestamp == 'Non spécifié' then
        return 'Non spécifié'
    end


    if type(timestamp) == 'string' and string.match(timestamp, '%d%d/%d%d/%d%d%d%d') then
        return timestamp
    end


    return tostring(timestamp)
end

function FormatTime(timestamp)
    if not timestamp or timestamp == '' or timestamp == 'Non spécifié' then
        return 'Non spécifié'
    end


    if type(timestamp) == 'string' and string.match(timestamp, '%d%d:%d%d') then
        return timestamp
    end


    return tostring(timestamp)
end

function OpenAppointmentForm(job)
    local playerData = ESX.GetPlayerData()
    local playerName = ('%s %s'):format(playerData.firstName or 'Prénom', playerData.lastName or 'Nom')

    local input = lib.inputDialog('Prendre un rendez-vous', {
        {
            type = 'input',
            label = 'Votre nom',
            default = playerName,
            disabled = true
        },
        {
            type = 'number',
            label = 'Numéro de téléphone',
            required = true,
            description = 'Ex: 5554545'
        },
        {
            type = 'textarea',
            label = 'Motif du rendez-vous',
            required = true,
            min = 10,
            max = 500
        },
        {
            type = 'date',
            label = 'Date du rendez-vous',
            icon = 'calendar',
            format = "DD/MM/YYYY",
            required = true
        },
        {
            type = 'time',
            label = 'Heure du rendez-vous',
            icon = 'clock',
            format = '24',
            required = true
        }
    })

    if input then
        TriggerServerEvent('old_ring:createAppointment', {
            job = job,
            name = playerName,
            phone = input[2],
            reason = input[3],
            dateTimestamp = input[4],
            timeTimestamp = input[5]
        })
    end
end

function OpenAdminMenu()
    local MainMenu = RageUI.CreateMenu("Sonnettes", "Administration")
    local DoorbellOptionsMenu = RageUI.CreateSubMenu(MainMenu, "Options", "Actions sur la sonnette")

    local selectedDoorbellId = nil

    RageUI.Visible(MainMenu, not RageUI.Visible(MainMenu))

    while MainMenu do
        Wait(0)

        RageUI.IsVisible(MainMenu, function()
            RageUI.Button("Créer une sonnette", "Créer une nouvelle sonnette à votre position", { RightLabel = "→" },
                true, {
                    onSelected = function()
                        CreateDoorbellForm()
                    end
                })

            RageUI.Separator("~b~↓↓↓ Liste des sonnettes ↓↓↓")

            if GetTableLength(doorbells) == 0 then
                RageUI.Separator("~r~Aucune sonnette créée")
            else
                for id, doorbell in pairs(doorbells) do
                    local desc = ("Job: ~b~%s~s~\nCoords: %.2f, %.2f, %.2f"):format(
                        doorbell.job,
                        doorbell.coords.x,
                        doorbell.coords.y,
                        doorbell.coords.z
                    )

                    RageUI.Button(doorbell.label, desc, { RightLabel = "→" }, true, {
                        onSelected = function()
                            selectedDoorbellId = id
                        end
                    }, DoorbellOptionsMenu)
                end
            end
        end)

        RageUI.IsVisible(DoorbellOptionsMenu, function()
            if not selectedDoorbellId or not doorbells[selectedDoorbellId] then
                RageUI.Separator("~r~Erreur")
                return
            end

            local doorbell = doorbells[selectedDoorbellId]

            RageUI.Separator(("~b~Sonnette: ~s~%s"):format(doorbell.label))
            RageUI.Separator(("~b~Job: ~s~%s"):format(doorbell.job))


            RageUI.Button("Téléporter", "Se téléporter à cette sonnette", {}, true, {
                onSelected = function()
                    SetEntityCoords(PlayerPedId(), doorbell.coords.x, doorbell.coords.y, doorbell.coords.z)
                    ESX.ShowNotification("~g~Téléporté à la sonnette")
                end
            })

            RageUI.Button("~r~Supprimer", "Supprimer définitivement cette sonnette",
                { RightBadge = RageUI.BadgeStyle.Alert }, true, {
                    onSelected = function()
                        local alert = lib.alertDialog({
                            header = 'Supprimer la sonnette',
                            content = ('Voulez-vous vraiment supprimer "%s" ?'):format(doorbell.label),
                            centered = true,
                            cancel = true,
                            labels = { confirm = 'Supprimer', cancel = 'Annuler' }
                        })

                        if alert == 'confirm' then
                            TriggerServerEvent('old_ring:deleteDoorbell', selectedDoorbellId)
                            ESX.ShowNotification("~r~Sonnette supprimée")
                            Wait(100)
                            selectedDoorbellId = nil
                            RageUI.GoBack()
                        end
                    end
                })
        end)

        if not RageUI.Visible(MainMenu) and not RageUI.Visible(DoorbellOptionsMenu) then
            MainMenu = RMenu:DeleteType('MainMenu', true)
            selectedDoorbellId = nil
            break
        end
    end
end

function CreateDoorbellForm()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local coords = {
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z - 1.0
    }


    ESX.TriggerServerCallback('old_ring:getJobs', function(jobs)
        if not jobs or #jobs == 0 then
            ESX.ShowNotification("~r~Impossible de récupérer la liste des jobs")
            return
        end


        local jobOptions = {}
        for _, job in ipairs(jobs) do
            table.insert(jobOptions, {
                label = job.label .. ' (' .. job.name .. ')',
                value = job.name
            })
        end

        local input = lib.inputDialog('Créer une sonnette', {
            {
                type = 'input',
                label = 'Position',
                description = 'Coordonnées actuelles',
                default = ('%.2f, %.2f, %.2f'):format(coords.x, coords.y, coords.z),
                disabled = true
            },
            {
                type = 'input',
                label = 'Nom de la sonnette',
                description = 'Ex: LSPD, Hopital, Entreprise',
                required = true,
                placeholder = 'Nom affiché sur la sonnette'
            },
            {
                type = 'select',
                label = 'Job associé',
                description = 'Sélectionnez le job',
                required = true,
                searchable = true,
                options = jobOptions
            }
        })

        if input then
            TriggerServerEvent('old_ring:createDoorbell', {
                label = input[2],
                job = input[3],
                coords = coords
            })

            ESX.ShowNotification("~g~Sonnette créée avec succès !")
        end
    end)
end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end

    playerJob = ESX.GetPlayerData().job.name
    TriggerServerEvent('old_ring:requestData')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


exports('rdv', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAppointmentPaper',
            appointment = data.metadata
        })
    end)
end)
