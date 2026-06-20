# Lab 2 — Bash Monitoring Script

> Script Bash de monitoring serveur Linux avec alertes, rapport JSON et exécution automatique via cron.
> Deuxième lab du parcours **Cloud Infrastructure Engineer** (Phase 0 — Socle Technique).

[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?logo=ubuntu&logoColor=white)]()
[![Bash](https://img.shields.io/badge/Bash-Script-4EAA25?logo=gnubash&logoColor=white)]()
[![Status](https://img.shields.io/badge/Status-Validated-3FB950)]()
[![Lab](https://img.shields.io/badge/Lab-Phase_0-58A6FF)]()

---

## 🎯 Objectif

Créer un script de monitoring complet qui surveille un serveur Linux en continu et alerte automatiquement quand les seuils sont dépassés.

## 🛠️ Ce que le script surveille

| Vérification | Seuil WARNING | Seuil CRITICAL |
|--------------|--------------|----------------|
| **Espace disque** | ≥ 80% | ≥ 90% |
| **RAM** | ≥ 85% | — |
| **Services systemd** | — | Service inactif |
| **HTTP localhost** | Réponse > 500ms | Injoignable |

## 📋 Prérequis

- Ubuntu Server 22.04 avec les services du Lab 1 configurés (SSH, UFW, Fail2Ban, systemd audit)
- curl installé (`sudo apt install curl -y`)

## 🚀 Déploiement

La procédure complète est disponible dans les PDFs :

📄 **[Lab2_Bash_Monitoring_Complet.pdf](./Lab2_Bash_Monitoring_Complet.pdf)** — Procédure étape par étape


## 🚀 Installation

```bash
# Créer le fichier log avec les bons droits
sudo touch /var/log/monitor.log
sudo chown $USER:$USER /var/log/monitor.log

# Rendre le script exécutable
chmod +x monitor.sh

# Lancer manuellement
bash monitor.sh

# Vérifier le rapport JSON généré
cat /tmp/health_report.json
```

## ⏰ Exécution automatique (Cron)

```bash
# Ouvrir crontab
crontab -e

# Ajouter cette ligne pour exécuter toutes les 5 minutes
*/5 * * * * /bin/bash /home/user/lab2-bash-monitoring/monitor.sh
```

## 📁 Structure du repo

```
lab2-bash-monitoring/
├── README.md
├── Lab2_Bash_Monitoring_Complet.pdf
└── monitor.sh
```

## 📊 Exemple de sortie

```
[2026-06-20 15:22:59] [INFO] === Début monitoring Serveur-Linux ===
[2026-06-20 15:22:59] [INFO] Disque OK : 46%
[OK] Disque : 46%
[2026-06-20 15:22:59] [INFO] RAM OK : 6%
[OK] RAM : 6%
[2026-06-20 15:22:59] [INFO] Service ssh : actif
[OK] Service : ssh
[2026-06-20 15:22:59] [INFO] Service ufw : actif
[OK] Service : ufw
[2026-06-20 15:22:59] [INFO] Service fail2ban : actif
[OK] Service : fail2ban
[2026-06-20 15:22:59] [INFO] Service log-python : actif
[OK] Service : log-python
[2026-06-20 15:22:59] [CRITICAL] HTTP http://localhost : injoignable
[CRIT] HTTP http://localhost : injoignable
[2026-06-20 15:23:00] [INFO] Rapport JSON généré : /tmp/health_report.json
[2026-06-20 15:23:00] [INFO] === Fin monitoring ===
```

## 📄 Exemple de rapport JSON

```json
{
  "date": "2026-06-20 15:23:00",
  "hostname": "Serveur-Linux",
  "disque_pct": 46,
  "ram_pct": 6,
  "services": {
    "ssh": "active",
    "ufw": "active",
    "fail2ban": "active",
    "log-python": "active"
  }
}
```

## ✅ Validation

- [x] Script s'exécute sans erreur avec `set -euo pipefail`
- [x] Disque, RAM, services et HTTP sont vérifiés
- [x] Couleurs OK/WARN/CRIT affichées dans le terminal
- [x] Logs écrits dans `/var/log/monitor.log`
- [x] Rapport JSON généré dans `/tmp/health_report.json`
- [x] Cron configuré toutes les 5 minutes

## 🔍 Erreurs rencontrées

| Erreur | Solution |
|--------|----------|
| `tee: /var/log/monitor.log: Permission denied` | `sudo touch` + `sudo chown user:user` le fichier log |
| RAM et services non affichés | Oubli de l'appel de fonction après sa définition |
| Script s'arrête si un service est down | Ajouter `|| true` après `check_service` |

## 🎓 Compétences mises en pratique

- Bash scripting (fonctions, variables, conditions, boucles, arrays)
- Commandes système Linux (df, free, systemctl, curl, awk, tr)
- Pipelines et substitution de commandes
- Gestion d'erreurs (set -euo pipefail, return codes)
- Génération de rapports JSON via here-document
- Automatisation avec cron

## 🔜 Prochaine étape

**Lab 3 — Script Python d'analyse de logs** : analyser les logs nginx, détecter les tentatives d'attaque et générer un rapport de sécurité.

---

**Parcours :** BTS SIO SISR → Bachelor ESGI Cloud/Réseaux → Mastère
**Objectif :** Cloud Infrastructure / Platform Engineer
