Config = {}

-- Groupes autorisés à créer des sonnettes
Config.AdminGroups = {
    'admin',
    'superadmin',
    'owner'
}

-- Commande pour ouvrir le menu admin
Config.AdminCommand = 'sonnettes'

-- Distance d'interaction
Config.DrawDistance = 10.0
Config.InteractDistance = 2.0

-- Cooldown sonnette (en secondes)
Config.DoorbellCooldown = 30

-- Marker settings
Config.Marker = {
    type = 27,
    color = { r = 0, g = 255, b = 255, a = 150 },
    size = { x = 1.0, y = 1.0, z = 1.0 },
    bobUpAndDown = false,
    rotate = true
}

-- Notifications
Config.Notifications = {
    doorbell_rang = "Quelqu'un a sonné à la porte !",
    appointment_created = "Rendez-vous créé avec succès",
    appointment_deleted = "Rendez-vous supprimé",
    no_permission = "Vous n'avez pas la permission",
    doorbell_created = "Sonnette créée avec succès",
    doorbell_deleted = "Sonnette supprimée",
    doorbell_cooldown = "Veuillez attendre avant de sonner à nouveau (%s secondes)",
    already_has_appointment = "Vous avez déjà un rendez-vous en cours pour ce service"
}


Config.LogWebhook = "" --Logs discord
