# Claude Configuration

RPG ILE test project for IBM i V7R5.

## Architecture

**IMPORTANT: All database access MUST go through RPG service programs.**

```
React UI → Node.js API → iToolkit/XMLSERVICE → RPG Service Programs → DB2
```

- **Node.js controllers**: HTTP handling, validation, call rpgConnector only
- **rpgConnector.js**: Calls RPG via iToolkit XMLSERVICE
- **RPG Service Programs**: ALL SQL/database operations (BROKRSRV, CONTSRV, CUSTSRV, etc.)
- **DB2**: Tables in library MRS1

**NO direct SQL queries from Node.js to DB2.** All data access goes through RPG.

### RPG Wrapper Pattern (RPGWRAP.sqlrpgle → DASSRV)

All iToolkit calls go through RPGWRAP which provides WRAP_* procedures:
- `WRAP_CreateBroker`, `WRAP_ListBrokers`, `WRAP_GetBrokerById`, `WRAP_DeleteBroker`
- `WRAP_CreateCustomer`, `WRAP_ListCustomers`, `WRAP_GetCustomerByEmail`
- `WRAP_CreateContract`, `WRAP_ListContracts`, `WRAP_GetContractById`
- `WRAP_CreateClaim`, `WRAP_ListClaims`
- `WRAP_ListProducts`, `WRAP_GetProductById`, `WRAP_GetProductGuarantees`
- `WRAP_GetDashboardStats`

**IMPORTANT: RPGWRAP = ZERO SQL**

RPGWRAP is a **thin wrapper only**. It must contain **NO `exec sql` statements** (except `SET OPTION`).

Its only responsibilities:
1. Convert iToolkit scalar parameters to RPG data structures
2. Call the appropriate business service procedure (CUSTSRV, BROKRSRV, CONTSRV, PRODSRV, CLAIMSRV)
3. Convert RPG data structures back to scalar OUTPUT parameters

```
iToolkit → RPGWRAP (conversion only) → *SRV (SQL here) → DB2
```

All SQL operations (SELECT, INSERT, UPDATE, cursors) belong in the service programs, NOT in RPGWRAP.

**Correct pattern (WRAP_ListBrokers):**
```rpgle
oCount = BROKRSRV_ListBrokersJson(pStatus: oJsonData);
```

**Wrong pattern (to refactor):**
```rpgle
exec sql DECLARE C_CUSTOMERS CURSOR FOR SELECT...  // NO! Move to CUSTSRV
```

### iToolkit VARCHAR Output Fix

When RPG returns VARCHAR data, strip leading control bytes before JSON.parse:
```javascript
const firstBracket = jsonData.indexOf('[');
if (firstBracket > 0) jsonData = jsonData.substring(firstBracket);
```

## Project Structure

- `src/qrpglesrc/` - RPG source files (service programs)
- `api/` - Node.js Express API (calls RPG only)
- `ui/` - React frontend
- `sql/` - SQL DDL scripts (tables, views)
- `docs/` - Program documentation

## Skills

This project uses the following Claude skills:

- **rpg-generator** - Generate modern RPG ILE code following project standards
- **document-rpg-program** - Generate documentation for RPG programs
- **knowledge-capture** - Capture decisions and patterns during development
- **layer-alignment-check** - Verify alignment between all architecture layers

### Post-Fix Verification (MANDATORY)

**After EVERY code fix or modification**, use the `layer-alignment-check` skill to verify:
1. The fix didn't break alignment between layers
2. All parameters match across UI -> API -> Connector -> RPGWRAP -> Service
3. No missing procedures or functions
4. Date types use `'10a'` not `'date'` in iToolkit
5. All OUT parameters have initial `value`

## Coding Standards

See `/skills/rpg-generator/SKILL.md` for naming conventions and code structure requirements.

## Error Handling

Use ERRUTIL for all error handling:
- `/copy qrpglesrc/ERRUTIL`
- `ERRUTIL_addErrorCode('CODE')` for known errors
- `ERRUTIL_addExecutionError()` in ON-ERROR blocks

## SQLCODE 8013 - PUB400 Licensing Warning

**SQLCODE 8013 = Warning de licence DB2 Connect (limite de connexions concurrentes)**

Sur PUB400 (serveur IBM i gratuit/partagé), ce warning est **normal et doit être ignoré**.

- Ce n'est PAS une erreur, c'est un avertissement
- L'opération SQL a généralement réussi malgré le warning
- Le code doit traiter 8013 comme un succès

**Dans le code RPG :**
```rpgle
if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
    // Succès
endif;
```

**Dans rpgConnector.js :**
```javascript
if (error.message && error.message.includes('8013')) {
    console.warn('[RPG] SQLCODE 8013 (PUB400 licensing) - ignoring');
    return []; // ou continuer normalement
}
```

Source: [IBM DB2 Messages SQL8000-SQL8015](https://www.columbia.edu/sec/acis/db2/db2m0/sql8000.htm)

## Operations - IMPORTANT

**API Node.js sur IBM i :**
- L'utilisateur lance/arrête l'API lui-même via commande QSYS (SBMJOB)
- **#IMPORTANT: TOUJOURS lancer l'API via SBMJOB, JAMAIS via commande QSH directe**
- NE JAMAIS utiliser nohup ou commande shell directe pour lancer l'API
- Port actuel : **8090**
- Commande pour lancer via SBMJOB :
```
system "SBMJOB CMD(QSH CMD('/home/MRS/DAS/start-api.sh')) JOB(DASAPI90) USER(MRS)"
```
- Le script `/home/MRS/DAS/start-api.sh` contient : `cd /home/MRS/DAS && PORT=8090 node api/src/app.js`

**Tunnel SSH :**
- Claude crée le tunnel SSH via plink (run_in_background) pour tester les APIs
- Port local = Port distant (ex: 8090:localhost:8090)
- **Si SSH est down** : Claude ne teste pas lui-même, l'utilisateur teste et donne les résultats

**UI React (Vite) :**
- Claude peut redémarrer si demandé
- Config API dans `ui/.env.local` : `VITE_API_BASE_URL=http://localhost:8090/api`

**Déploiement RPG :**
- Upload fichiers via FTP (scripts ftp-*.txt)
- Compilation via FTP RCMD (quote RCMD CRTSQLRPGI...)
- Service program DASSRV dans MRS1

**Headers (copybooks) :**
Les `/copy MRS1/QRPGLESRC,xxx_H` référencent le source physical file, pas l'IFS.
Après upload d'un header modifié, il faut le copier vers QRPGLESRC :
```
quote RCMD CPYFRMSTMF FROMSTMF('/home/MRS/DAS/src/qrpglesrc/CUSTSRV_H.rpgle') TOMBR('/QSYS.LIB/MRS1.LIB/QRPGLESRC.FILE/CUSTSRV_H.MBR') MBROPT(*REPLACE)
```

## Windows Command Gotchas

**NEVER use `start /B`** - It redirects to Windows drive B: instead of running in background.

For background SSH tunnels, use PowerShell or run manually:
```powershell
# Use PowerShell Start-Process instead
Start-Process -NoNewWindow -FilePath "plink.exe" -ArgumentList "-P 2222 ..."
```

For IBM i remote commands, prefer **FTP RCMD** over SSH:
```
quote RCMD CRTSQLRPGI OBJ(MRS1/RPGWRAP) SRCSTMF('/path/file') ...
```
