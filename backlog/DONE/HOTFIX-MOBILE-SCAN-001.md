---
id: HOTFIX-MOBILE-SCAN-001
title: Correction du système de scan employé
status: IN_PROGRESS
priority: HIGH
---

# 📱 Correction du système de scan employé (Mobile - système existant)

## 🎯 Objectif

Corriger et stabiliser le comportement du scan facial des employés dans une application mobile déjà existante, sans refonte complète du système.

## ⚙️ Contexte

Le système de scan est déjà en production. L’objectif est uniquement de corriger les problèmes de flux, notamment :

- double scan
- double appel API
- mauvais comportement UI pendant le traitement

## 📸 1. Pendant le scan (caméra active)

Lors du lancement du scan :

- 🔄 afficher un **loading global (overlay plein écran)**
- 📷 **désactiver temporairement la caméra** pendant le traitement backend
- 🚫 bloquer toute nouvelle capture ou scan
- ⛔ empêcher les appels API multiples

## ✅ 2. Cas de succès (SUCCESS uniquement)

Si le backend retourne un résultat positif :

### 🎉 UI à afficher

- afficher un **modal de succès uniquement**
- remplacer le feedback actuel de succès par ce modal
- afficher les données retournées :
  - nom de l’employé
  - type de pointage (check-in / check-out)
  - score ou information disponible

### 🔘 Action utilisateur

- bouton **OK obligatoire**

### 👉 Comportement du bouton OK

- fermer le modal
- réactiver la caméra
- permettre un nouveau scan

## ❌ 3. Cas d’échec (FAILURE)

Si le backend retourne une erreur :

- ❌ ne PAS afficher de modal
- ⚠️ conserver le système d’erreur actuel existant
- 📢 afficher uniquement le message d’erreur standard déjà utilisé

## 🔁 4. Problème critique à corriger

- empêcher les doubles check-in
- empêcher les double scans rapides
- garantir un seul traitement actif à la fois
- éviter les appels API simultanés
