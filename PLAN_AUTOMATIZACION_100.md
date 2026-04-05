# Plan de Automatización 100% - DATABASE_URL

**Fecha:** 2026-04-05  
**Estado Actual:** ❌ Requiere intervención manual  
**Estado Objetivo:** ✅ Totalmente automatizado  

---

## 📊 Análisis del Problema Actual

### ❌ Estado Actual (Requiere Acción Manual)

**Workflow:** `.github/workflows/setup-supabase-secret.yml`
```yaml
on:
  workflow_dispatch:  # ❌ Ejecución manual desde UI
    inputs:
      supabase_connection_string:  # ❌ Usuario debe pegar manualmente
```

**Flujo Actual:**
1. Usuario hace push → Deploy falla con "Tenant or user not found"
2. Usuario va a GitHub Actions UI manualmente
3. Usuario selecciona workflow
4. Usuario pega connection string
5. Usuario hace click en "Run workflow"
6. Espera 10 minutos
7. ✅ Funciona

**Problemas:**
- ❌ No es automático
- ❌ Requiere 6 pasos manuales
- ❌ Propenso a errores humanos
- ❌ Connection string expuesta en logs de GitHub
- ❌ No funciona en primer deployment

---

## ✅ Solución Propuesta: Automatización Total

### Estrategia: GitHub Secrets + Workflow Integrado

**Concepto:**
- Guardar `DATABASE_URL` como **GitHub Secret** (encriptado)
- Modificar `do-deploy.yml` para configurar automáticamente
- Todo sucede en un solo push, sin intervención manual

---

## 🎯 Plan de Implementación

### Fase 1: Configurar GitHub Secret (Una sola vez, manual)

**Acción requerida del usuario:**

1. Ve a: https://github.com/Theferland2/Companies/settings/secrets/actions

2. Click en **"New repository secret"**

3. Configurar:
   - **Name:** `DATABASE_URL`
   - **Value:** `postgresql://postgres.[PROJECT_ID]:[PASSWORD_URL_ENCODED]@aws-0-us-west-2.pooler.supabase.com:6543/postgres`
   
   (Reemplaza `[PROJECT_ID]` y `[PASSWORD_URL_ENCODED]` con tus valores reales de Supabase)

4. Click **"Add secret"**

**Esto se hace una sola vez.** Después de esto, todo es automático.

---

### Fase 2: Modificar Workflow do-deploy.yml (Automatizado)

**Cambios a implementar:**

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches:
      - master
      - main

jobs:
  build-test-deploy:
    name: Build, Test & Deploy
    runs-on: ubuntu-latest
    timeout-minutes: 20
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9.15.4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Typecheck
        run: pnpm -r typecheck

      - name: Build
        run: pnpm build

      - name: Run tests
        run: pnpm test:run

      # ✅ NUEVO: Configurar DATABASE_URL automáticamente
      - name: Configure Database Secret
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
      
      - name: Update App Spec with DATABASE_URL
        run: |
          # Obtener App ID
          APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "${{ secrets.DO_APP_NAME }}" | awk '{print $1}')
          
          # Descargar spec actual
          doctl apps spec get "$APP_ID" > app-spec.yaml
          
          # Instalar yq
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq
          
          # Actualizar DATABASE_URL en el spec
          yq eval '
            .services[0].envs = (
              .services[0].envs | 
              map(
                if .key == "DATABASE_URL" then
                  .value = "${{ secrets.DATABASE_URL }}" |
                  .scope = "RUN_AND_BUILD_TIME" |
                  .type = "SECRET"
                else . end
              )
            )
          ' -i app-spec.yaml
          
          # Aplicar spec actualizado
          doctl apps update "$APP_ID" --spec app-spec.yaml

      # Deployment normal
      - name: Trigger App Platform Deployment
        uses: digitalocean/app_action@v2
        with:
          app_name: ${{ secrets.DO_APP_NAME }}
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
```

**Ventajas:**
- ✅ Automático en cada push
- ✅ Sin intervención manual
- ✅ DATABASE_URL encriptada en GitHub Secrets
- ✅ No expuesta en logs
- ✅ Configuración antes de deployment

---

### Fase 3: Limpiar Workflows Obsoletos (Opcional)

**Eliminar archivos que ya no son necesarios:**
- `.github/workflows/setup-supabase-secret.yml` (manual, ya no se usa)
- `.github/workflows/configure-database.yml` (manual, ya no se usa)

**Mantener:**
- `DO_DATABASE_FIX.md` (documentación útil)
- `SETUP_DATABASE_AUTOMATED.md` (referencia)

---

## 🔄 Flujo Automatizado Final

### Usuario hace:
```bash
git add .
git commit -m "feat: nueva funcionalidad"
git push origin master
```

### GitHub Actions hace automáticamente:
1. ✅ Checkout código
2. ✅ Install dependencies
3. ✅ Typecheck
4. ✅ Build
5. ✅ Run tests
6. ✅ **Configura DATABASE_URL en DigitalOcean** ← NUEVO
7. ✅ Deploy a DigitalOcean
8. ✅ Espera hasta ACTIVE
9. ✅ Server se conecta a Supabase exitosamente

**Total:** 0 pasos manuales después del setup inicial.

---

## ⚠️ Consideraciones de Seguridad

### ✅ Seguro:
- DATABASE_URL guardada como GitHub Secret (encriptada)
- No aparece en logs de GitHub Actions
- No está en código fuente
- Solo accesible por workflows autorizados

### ❌ NO Seguro (evitado):
- ❌ Hardcodear en .env (expuesto en repo)
- ❌ Poner en app.yaml directo (expuesto en repo)
- ❌ Usar workflow_dispatch con input (aparece en logs)

---

## 📋 Checklist de Implementación

### Paso 1: Usuario configura GitHub Secret (Manual, una vez)
- [ ] Ir a: https://github.com/Theferland2/Companies/settings/secrets/actions
- [ ] Crear secret: `DATABASE_URL`
- [ ] Pegar: `postgresql://postgres.[PROJECT_ID]:[PASSWORD_URL_ENCODED]@aws-0-us-west-2.pooler.supabase.com:6543/postgres`
- [ ] Guardar

### Paso 2: Implementar nuevo workflow (Automático)
- [ ] Modificar `.github/workflows/do-deploy.yml`
- [ ] Agregar step "Configure Database Secret"
- [ ] Agregar step "Update App Spec with DATABASE_URL"
- [ ] Commit y push

### Paso 3: Validar (Automático)
- [ ] Push trigger workflow automáticamente
- [ ] Verificar que configura DATABASE_URL
- [ ] Verificar que deployment sea exitoso
- [ ] Verificar logs: "Using external PostgreSQL"

### Paso 4: Cleanup (Opcional)
- [ ] Eliminar `setup-supabase-secret.yml`
- [ ] Eliminar `configure-database.yml`
- [ ] Actualizar documentación

---

## 🎯 Resultado Final

### Antes (Manual):
```
Push → Falla → UI manual → Pegar string → Run → Espera → Funciona
6 pasos manuales, 15+ minutos
```

### Después (Automático):
```
Push → Funciona
0 pasos manuales, 10 minutos
```

---

## 🚀 Siguiente Acción Inmediata

**El usuario debe:**

1. **Configurar GitHub Secret** (2 minutos):
   - Ir a: https://github.com/ferangarita01/Companies/settings/secrets/actions
   - New secret: `DATABASE_URL`
   - Value: `postgresql://postgres.[PROJECT_ID]:[PASSWORD_URL_ENCODED]@aws-0-us-west-2.pooler.supabase.com:6543/postgres`
   
   (Reemplaza con tus valores reales de Supabase)

2. **Confirmar que está listo para que yo modifique el workflow**

**Yo haré:**
1. Modificar `do-deploy.yml` para automatización total
2. Commit y push de los cambios
3. Validar que funciona en el próximo deployment

---

## ⏱️ Timeline Estimado

| Paso | Duración | Responsable |
|------|----------|-------------|
| Configurar GitHub Secret | 2 min | Usuario |
| Modificar workflow | 5 min | AI |
| Commit y push | 1 min | AI |
| Trigger deployment | 10 min | Automático |
| Validación | 2 min | Usuario |
| **TOTAL** | **20 min** | - |

---

**Estado:** ⏸️ Esperando que usuario configure GitHub Secret  
**Próximo paso:** Usuario crea secret `DATABASE_URL` en GitHub
