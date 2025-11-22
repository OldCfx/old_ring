ESX = exports['es_extended']:getSharedObject()

local doorbells = {}
local appointments = {}
local doorbellIdCounter = 0
local appointmentIdCounter = 0

local function sendDiscordLog(title, description, color)
    if not Config.LogWebhook or Config.LogWebhook == '' then return end

    local embed = {
        {
            ["color"] = color or 56108,
            ["title"] = title,
            ["description"] = description,
            ["footer"] = {
                ["text"] = os.date('%d/%m/%Y %H:%M:%S')
            }
        }
    }

    PerformHttpRequest(Config.LogWebhook, function(err, text, headers) end, 'POST',
        json.encode({ username = 'OldXBlunt', embeds = embed, avatar_url = 'https://i.goopics.net/sek245.png' }),
        { ['Content-Type'] = 'application/json' })
end


function FormatDate(timestamp)
    if not timestamp or timestamp == '' then
        return 'Non spécifié'
    end


    if type(timestamp) == 'string' and string.match(timestamp, '%d%d/%d%d/%d%d%d%d') then
        return timestamp
    end


    if type(timestamp) == 'number' then
        if timestamp > 9999999999 then
            timestamp = timestamp / 1000
        end

        local date = os.date("*t", timestamp)
        return string.format("%02d/%02d/%04d", date.day, date.month, date.year)
    end

    return 'Non spécifié'
end

function FormatTime(timestamp)
    if not timestamp or timestamp == '' then
        return 'Non spécifié'
    end


    if type(timestamp) == 'string' and string.match(timestamp, '%d%d:%d%d') then
        return timestamp
    end


    if type(timestamp) == 'number' then
        if timestamp > 9999999999 then
            timestamp = timestamp / 1000
        end

        local date = os.date("*t", timestamp)
        return string.format("%02d:%02d", date.hour, date.min)
    end

    return 'Non spécifié'
end

function loadJSON(file)
    local filepath = GetResourcePath(GetCurrentResourceName()) .. '/data/' .. file
    local f = io.open(filepath, 'r')
    if f then
        local content = f:read('*a')
        f:close()
        local decoded = json.decode(content)
        return decoded or (file == "appointments.json" and {} or {})
    end
    return (file == "appointments.json" and {} or {})
end

function saveJSON(file, data)
    local filepath = GetResourcePath(GetCurrentResourceName()) .. '/data/' .. file
    local f = io.open(filepath, 'w')
    if f then
        f:write(json.encode(data, { indent = true }))
        f:close()
        return true
    end
    return false
end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

CreateThread(function()
    doorbells = loadJSON('doorbells.json')
    appointments = loadJSON('appointments.json')


    for id, _ in pairs(doorbells) do
        local numId = tonumber(id)
        if numId and numId > doorbellIdCounter then
            doorbellIdCounter = numId
        end
    end


    for _, appointment in ipairs(appointments) do
        if appointment.id and appointment.id > appointmentIdCounter then
            appointmentIdCounter = appointment.id
        end
    end


    sendDiscordLog(
        'Sonnettes chargées',
        GetTableLength(doorbells) .. ' sonnettes et ' .. #appointments .. ' rendez-vous',
        65280
    )
end)


RegisterNetEvent('old_ring:requestData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer then
        TriggerClientEvent('old_ring:loadDoorbells', src, doorbells)
        TriggerClientEvent('old_ring:loadAppointments', src, appointments)


        local isAdmin = false
        for _, group in ipairs(Config.AdminGroups) do
            if xPlayer.getGroup() == group then
                isAdmin = true
                break
            end
        end

        TriggerClientEvent('old_ring:setAdmin', src, isAdmin)
    end
end)


ESX.RegisterServerCallback('old_ring:checkAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(false)
        return
    end

    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            cb(true)
            return
        end
    end

    cb(false)
end)

ESX.RegisterCommand('ringsManager', Config.AdminGroups, function(xPlayer, args, showError)
    TriggerClientEvent('old_ring:openStaff', xPlayer.source)
end, false, { help = 'Gestion des sonnettes' })


RegisterNetEvent('old_ring:createDoorbell', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local isAdmin = false
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            isAdmin = true
            break
        end
    end

    if not isAdmin then
        xPlayer.showNotification(Config.Notifications.no_permission)
        return
    end

    doorbellIdCounter = doorbellIdCounter + 1
    doorbells[tostring(doorbellIdCounter)] = {
        label = data.label,
        job = data.job,
        coords = data.coords
    }

    saveJSON('doorbells.json', doorbells)


    TriggerClientEvent('old_ring:loadDoorbells', -1, doorbells)

    xPlayer.showNotification(Config.Notifications.doorbell_created)

    local playerName = GetPlayerName(src)
    sendDiscordLog(
        'créé une sonnette',
        ('%s a créé une sonnette: %s (Job: %s)')
        :format(playerName, data.label, data.job),
        65280
    )
end)


RegisterNetEvent('old_ring:deleteDoorbell', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local isAdmin = false
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            isAdmin = true
            break
        end
    end

    if not isAdmin then
        xPlayer.showNotification(Config.Notifications.no_permission)
        return
    end

    if doorbells[id] then
        local label = doorbells[id].label
        doorbells[id] = nil
        saveJSON('doorbells.json', doorbells)

        TriggerClientEvent('old_ring:loadDoorbells', -1, doorbells)

        xPlayer.showNotification(Config.Notifications.doorbell_deleted)



        local playerName = GetPlayerName(src)
        sendDiscordLog(
            'supprimé une sonnette',
            ('%s a supprimé une sonnette: %s')
            :format(playerName, label),
            16711680
        )
    end
end)


RegisterNetEvent('old_ring:ring', function(job, label)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end


    local xPlayers = ESX.GetExtendedPlayers('job', job)

    if #xPlayers == 0 then
        xPlayer.showNotification('~o~Personne n\'est disponible actuellement')
        return
    end

    for _, player in ipairs(xPlayers) do
        player.showNotification(('🔔 Quelqu\'un sonne à: ~b~%s'):format(label))
    end


    local playerName = GetPlayerName(src)
    sendDiscordLog(
        'sonne',
        ('%s a sonné: %s')
        :format(playerName, label),
        16711680
    )
end)


RegisterNetEvent('old_ring:createAppointment', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    appointmentIdCounter = appointmentIdCounter + 1


    local formattedDate = data.date or FormatDate(data.dateTimestamp)
    local formattedTime = data.time or FormatTime(data.timeTimestamp)

    table.insert(appointments, {
        id = appointmentIdCounter,
        job = data.job,
        name = data.name,
        phone = data.phone,
        reason = data.reason,
        date = formattedDate,
        time = formattedTime,
        created_at = os.date('%Y-%m-%d %H:%M:%S')
    })

    saveJSON('appointments.json', appointments)


    xPlayer.showNotification(Config.Notifications.appointment_created)
    TriggerClientEvent('old_ring:loadAppointments', -1, appointments)


    local xPlayers = ESX.GetExtendedPlayers('job', data.job)
    for _, player in ipairs(xPlayers) do
        player.showNotification(('Nouveau RDV de: ~b~%s~s~ (%s à %s)'):format(data.name, formattedDate, formattedTime))
    end



    local playerName = GetPlayerName(src)
    sendDiscordLog(
        'créé un rendez-vous',
        ('%s a créé un rendez-vous: %s (%s à %s)')
        :format(playerName, data.name, formattedDate, formattedTime),
        65280
    )
end)


ESX.RegisterServerCallback('old_ring:getAppointments', function(source, cb, job)
    local jobAppointments = {}

    for _, appointment in ipairs(appointments) do
        if appointment.job == job then
            table.insert(jobAppointments, appointment)
        end
    end


    table.sort(jobAppointments, function(a, b)
        return a.id > b.id
    end)

    cb(jobAppointments)
end)


RegisterNetEvent('old_ring:deleteAppointment', function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    for i, appointment in ipairs(appointments) do
        if appointment.id == id then
            if xPlayer.job.name == appointment.job then
                local name = appointment.name
                table.remove(appointments, i)
                saveJSON('appointments.json', appointments)

                xPlayer.showNotification(Config.Notifications.appointment_deleted)
                TriggerClientEvent('old_ring:loadAppointments', -1, appointments)

                local playerName = GetPlayerName(src)
                sendDiscordLog(
                    'supprimé un rendez-vous',
                    ('%s a supprimé un rendez-vous: %s (ID: %s)')
                    :format(playerName, name, id),
                    16711680
                )
                return
            else
                xPlayer.showNotification(Config.Notifications.no_permission)
                return
            end
        end
    end
end)


ESX.RegisterServerCallback('old_ring:hasAppointment', function(source, cb, job)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(false)
        return
    end

    local playerName = ('%s %s'):format(xPlayer.get('firstName'), xPlayer.get('lastName'))

    for _, appointment in ipairs(appointments) do
        if appointment.job == job and appointment.name == playerName then
            cb(true)
            return
        end
    end

    cb(false)
end)

ESX.RegisterServerCallback('old_ring:getJobs', function(source, cb)
    local jobs = {}
    local ESXJobs = ESX.GetJobs()

    for jobName, jobData in pairs(ESXJobs) do
        table.insert(jobs, {
            name = jobName,
            label = jobData.label or jobName
        })
    end


    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)

    cb(jobs)
end)
