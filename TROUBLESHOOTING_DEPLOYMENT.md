# Guía de Troubleshooting: GitHub Actions Deployment Failure

**Fecha:** 2026-04-05 17:29 UTC  
**Workflow:** Deploy to DigitalOcean  
**Estado:** ❌ Failed

---

## 🔍 Pasos para Diagnosticar el Error

### 1. Acceder a los Logs de GitHub Actions

1. Ve a: https://github.com/Theferland2/Companies/actions
2. Click en el workflow **"Deploy to DigitalOcean"** más reciente (con ❌)
3. Click en el job **"Build, Test & Deploy"**
4. Identifica el step con ❌ rojo
5. Expande el step y copia el error completo

---

## 🎯 Posibles Errores y Soluciones

### Error 1: "App not found" (MÁS PROBABLE)

**Aparece en:** Step "Update App Spec with DATABASE_URL"

**Síntoma:**
```
❌ Error: App 'companies-app' not found
```

**Causa:** El nombre en `DO_APP_NAME` no coincide con el nombre real en DigitalOcean

**Solución:**
```bash
# Verificar nombre real de la app en DigitalOcean
# Ve a: https://cloud.digitalocean.com/apps
# Copia el nombre exacto de tu app

# Actualizar secret DO_APP_NAME:
# 1. Ve a: https://github.com/Theferland2/Companies/settings/secrets/actions
# 2. Click en DO_APP_NAME
# 3. Update value con el nombre exacto
# 4. Re-run workflow
```

---

### Error 2: "Authentication failed"

**Aparece en:** Step "Configure Database Secret"

**Síntoma:**
```
Error: Unable to authenticate you
401 Unauthorized
```

**Causa:** Token de DigitalOcean expirado o inválido

**Solución:**
```bash
# Generar nuevo token:
# 1. Ve a: https://cloud.digitalocean.com/account/api/tokens
# 2. Click "Generate New Token"
# 3. Name: GitHub Actions
# 4. Scopes: Read & Write
# 5. Generate Token
# 6. Copia el token

# Actualizar secret:
# 1. Ve a: https://github.com/Theferland2/Companies/settings/secrets/actions
# 2. Click en DIGITALOCEAN_ACCESS_TOKEN
# 3. Update value con el nuevo token
# 4. Re-run workflow
```

---

### Error 3: "Invalid app spec" o "Validation failed"

**Aparece en:** Step "Update App Spec with DATABASE_URL"

**Síntoma:**
```
Error: app spec validation failed
Invalid format for services[0].envs
```

**Causa:** El yq eval está modificando el YAML de forma incorrecta

**Solución A - Fix del Script:**
```yaml
# Modificar el yq eval para ser más específico
yq eval '
  .services[0].envs |= map(
    if .key == "DATABASE_URL" then
      {"key": "DATABASE_URL", "value": "${{ secrets.DATABASE_URL }}", "scope": "RUN_AND_BUILD_TIME", "type": "SECRET"}
    else . end
  )
' -i app-spec.yaml
```

**Solución B - Simplificar (Sin modificar spec):**
```yaml
# Opción: Configurar DATABASE_URL manualmente UNA VEZ
# Luego el workflow solo hace deploy sin modificar spec
```

---

### Error 4: "Test suite failed"

**Aparece en:** Step "Run tests"

**Síntoma:**
```
FAIL packages/*/tests/*.test.ts
Test suite failed to run
```

**Causa:** Tests fallando en el código

**Solución:**
```bash
# Correr tests localmente para ver el error específico
pnpm test:run

# Fix los tests que fallan
# Commit y push
```

---

### Error 5: "Compilation failed"

**Aparece en:** Step "Build" o "Typecheck"

**Síntoma:**
```
error TS2322: Type 'X' is not assignable to type 'Y'
```

**Causa:** Errores de TypeScript en el código

**Solución:**
```bash
# Correr typecheck localmente
pnpm -r typecheck

# Fix los errores de tipos
# Commit y push
```

---

### Error 6: "Module not found" o "Cannot find package"

**Aparece en:** Step "Install dependencies"

**Síntoma:**
```
ERR_PNPM_NO_MATCHING_VERSION
No matching version found for package@version
```

**Causa:** Lockfile desincronizado o dependencia no disponible

**Solución:**
```bash
# Regenerar lockfile
rm pnpm-lock.yaml
pnpm install
git add pnpm-lock.yaml
git commit -m "fix: regenerate lockfile"
git push
```

---

## 🛠️ Diagnóstico Paso a Paso

### Checklist de Verificación:

#### 1. GitHub Secrets
- [ ] `DATABASE_URL` configurado correctamente
- [ ] `DIGITALOCEAN_ACCESS_TOKEN` válido (no expirado)
- [ ] `DO_APP_NAME` coincide exactamente con el nombre en DO

#### 2. Verificar en DigitalOcean
- [ ] App existe y está activa
- [ ] Token tiene permisos Read & Write
- [ ] App name es exactamente el mismo (case-sensitive)

#### 3. Workflow Syntax
- [ ] YAML válido (no tabs, solo espacios)
- [ ] Secrets referenciados correctamente: `${{ secrets.NAME }}`
- [ ] Scripts bash no tienen errores de sintaxis

#### 4. Código Local
- [ ] `pnpm -r typecheck` pasa localmente
- [ ] `pnpm build` pasa localmente
- [ ] `pnpm test:run` pasa localmente

---

## 🔧 Soluciones Rápidas por Tipo de Error

### Si el error es en steps 1-7 (antes de DB config):
→ Es un problema de código/build
→ Correr localmente y fix

### Si el error es en step 8-9 (DB config):
→ Es un problema de secrets o permisos
→ Verificar DO_APP_NAME y DIGITALOCEAN_ACCESS_TOKEN

### Si el error es en step 10 (deploy):
→ Es un problema de spec o deployment
→ Revisar app-spec.yaml generado

---

## 📊 Comandos Útiles para Debug

### Verificar localmente antes de push:
```bash
# Full CI/CD local
pnpm install --frozen-lockfile
pnpm -r typecheck
pnpm build
pnpm test:run
```

### Verificar secrets (sin exponer valores):
```bash
# En GitHub Actions, agregar step temporal:
- name: Debug Secrets
  run: |
    echo "DO_APP_NAME length: ${#DO_APP_NAME}"
    echo "DATABASE_URL starts with: $(echo $DATABASE_URL | cut -c1-15)"
  env:
    DO_APP_NAME: ${{ secrets.DO_APP_NAME }}
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Verificar doctl funcionando:
```bash
# Agregar step temporal después de "Configure Database Secret":
- name: Debug doctl
  run: |
    doctl auth list
    doctl apps list
```

---

## 🚨 Si Nada Funciona: Rollback Temporal

### Opción 1: Volver a workflow básico
```yaml
# Comentar temporalmente steps 8-9 (DB config)
# Solo hacer deploy básico
```

### Opción 2: Configurar DATABASE_URL manualmente
```bash
# Una sola vez, manualmente en DigitalOcean:
# 1. Ve a tu app en DO
# 2. Settings → Environment Variables
# 3. Edita DATABASE_URL
# 4. Pega: postgresql://postgres.[PROJECT_ID]:[PASSWORD_URL_ENCODED]@aws-0-us-west-2.pooler.supabase.com:6543/postgres
# 5. Save

# Luego comentar steps 8-9 del workflow
```

---

## 📞 Información Necesaria para Ayuda

Si compartes el error, incluye:

1. **Nombre del step que falló**
2. **Error completo (copiar/pegar)**
3. **Commit SHA o mensaje**
4. **Hora aproximada del fallo**

---

## ✅ Una Vez Resuelto

1. Re-run workflow
2. Verificar que pasa todos los steps
3. Verificar en DigitalOcean que app está ACTIVE
4. Probar endpoint: `curl https://tu-app.ondigitalocean.app/api/health`

---

**Última actualización:** 2026-04-05 17:29 UTC
