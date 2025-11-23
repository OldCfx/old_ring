# 🔔 old_ring Doorbell & Appointment System for ESX

A complete and modern **doorbell & appointment management system** for ESX jobs, featuring a sleek **React interface**, admin tools, and ox_lib forms.

---

## 📦 Dependencies

This resource requires the following:

* **es_extended**
* **ox_lib**

---

## 🔔 Doorbell System

* Interactive doorbells for ESX jobs
* Customizable anti-spam cooldown (30s by default)
* Real-time notifications for employees on duty
* Doorbells assigned per job
* Creation/deletion via admin menu

---

## 📅 Appointment Management

* Appointment request form powered by **ox_lib**
* Only **one active appointment per player and per job**
* Employees can delete completed appointments

---

## 🧑‍💼 Administrator Panel

* Full **RageUI** management menu
* List of all ESX jobs
* Create doorbells at your current location
* Teleport directly to doorbells
* Delete doorbells

---

## 🎨 Modern React Interface

* Realistic administrative-paper style UI
* Smooth animations
* Scrollable when a long message/motif is provided
* Close with **ESC**

---

## 🔐 Security

* Cooldown-based anti-spam protection
* Discord logging system
* `/ringsManager` command restricted to permissions defined in `shared/config.lua`

## 🧳 ox_inventory
* add item :
```lua
['rdv'] = {
		label = 'Rendez-vous',
		weight = 20,
		stack = false,
		consume = 0,
		close = true,
		client = {
			export = 'old_ring.rdv'
		}
	}
```