# Procédures de Communication avec PUB400

## Connexion à PUB400

### 1. SSH (Prioritaire)
```bash
plink -P 2222 -pw CLAUDE1234 -hostkey "SHA256:NcBw63NS/aa3kLgyEzg7TMDqp3H4D1q6CLjJfS/FyaE" -batch MRS@pub400.com "commande"
```

### 2. FTP (Si SSH non disponible)
```
open pub400.com
user MRS CLAUDE1234
quote RCMD <commande CL>
quit
```

**Note:** FTP RCMD ne retourne pas la sortie des commandes, juste le statut.

## Tunnel SSH pour API

Créer manuellement (ne pas utiliser `start /B` sous Windows) :
```bash
plink -P 2222 -pw CLAUDE1234 -hostkey "SHA256:NcBw63NS/aa3kLgyEzg7TMDqp3H4D1q6CLjJfS/FyaE" -N -L 8087:localhost:8087 MRS@pub400.com
```

## Lancer l'API Node.js

**IMPORTANT:** Toujours utiliser `SBMJOB` avec `USER(MRS)` pour pouvoir contrôler le job.

### Via SSH :
```bash
plink ... MRS@pub400.com "system 'SBMJOB CMD(QSH CMD(cd /home/MRS/DAS && PORT=8087 node api/src/app.js)) JOB(DASAPI) USER(MRS)'"
```

### Via FTP RCMD :
```
quote RCMD SBMJOB CMD(QSH CMD('cd /home/MRS/DAS && PORT=8087 node api/src/app.js')) JOB(DASAPI) USER(MRS)
```

**Ne JAMAIS utiliser `nohup ... &`** - Le job ne sera pas visible et impossible à arrêter.

## Arrêter l'API Node.js

### Option 1 : Demander à l'utilisateur
Si Claude ne peut pas arrêter le job, **demander à l'utilisateur** de le faire manuellement.

### Option 2 : Via SSH
```bash
plink ... MRS@pub400.com "system 'ENDJOB JOB(DASAPI) OPTION(*IMMED)'"
```

### Option 3 : Via FTP RCMD
```
quote RCMD ENDJOB JOB(DASAPI) OPTION(*IMMED)
```

## Compilation RPG

### Compiler un module :
```
quote RCMD CRTSQLRPGI OBJ(MRS1/RPGWRAP) SRCSTMF('/home/MRS/DAS/src/qrpglesrc/RPGWRAP.sqlrpgle') OBJTYPE(*MODULE) COMMIT(*NONE) OPTION(*EVENTF) DBGVIEW(*SOURCE) RPGPPOPT(*LVL2)
```

### Mettre à jour le service program :
```
quote RCMD UPDSRVPGM SRVPGM(MRS1/DASSRV) MODULE(MRS1/RPGWRAP MRS1/BROKRSRV MRS1/CUSTSRV MRS1/PRODSRV MRS1/CONTSRV MRS1/CLAIMSRV MRS1/ERRUTIL) EXPORT(*ALL)
```

## Upload de fichiers

```
open pub400.com
user MRS CLAUDE1234
ascii
cd /home/MRS/DAS/src/qrpglesrc
delete FICHIER.sqlrpgle
put "chemin\local\FICHIER.sqlrpgle" FICHIER.sqlrpgle
quit
```

## Ports utilisés

| Port | Usage |
|------|-------|
| 8086 | API (ancienne instance) |
| 8087 | API (nouvelle instance après recompilation) |
| 5173/5174 | UI React (Vite dev server) |

## Checklist Redémarrage API

1. ☐ Arrêter le job API existant (`ENDJOB` ou demander à l'utilisateur)
2. ☐ Upload des fichiers modifiés via FTP
3. ☐ Compiler les modules RPG (`CRTSQLRPGI`)
4. ☐ Mettre à jour le service program (`UPDSRVPGM`)
5. ☐ Démarrer l'API avec `SBMJOB ... USER(MRS)`
6. ☐ Créer le tunnel SSH si nécessaire
7. ☐ Mettre à jour `ui/.env.local` si le port a changé
8. ☐ Tester `/health` endpoint
