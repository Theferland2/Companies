# Configuración Automatizada de DATABASE_URL con GitHub Actions

## 🎯 Objetivo
Configurar el SECRET `DATABASE_URL` en DigitalOcean App Platform de forma automatizada usando GitHub Actions.

---

## 📋 Archivos Creados

### 1. `.github/workflows/setup-supabase-secret.yml` (PRINCIPAL)
Workflow manual para configurar `DATABASE_URL` por primera vez.

**Características:**
- ✅ Ejecutable manualmente desde GitHub UI
- ✅ Valida formato de connection string
- ✅ Actualiza el app spec con el SECRET
- ✅ Dispara deployment automático
- ✅ Espera hasta que el deployment esté activo
- ✅ Verifica logs de conexión DB

### 2. `.github/workflows/configure-database.yml` (ALTERNATIVO)
Workflow simplificado para actualizar la URL más adelante.

### 3. `.do/app.yaml` (ACTUALIZADO)
Cambié la configuración de `DATABASE_URL` para usar secrets de forma dinámica:
```yaml
- key: DATABASE_URL
  scope: RUN_AND_BUILD_TIME
  type: SECRET
  value: "${DATABASE_URL}"
```

---

## 🚀 Cómo Usar (Paso a Paso)

### **Paso 1: Verificar GitHub Secrets**

Los siguientes secrets **ya deben estar configurados** en tu repositorio:
- `DIGITALOCEAN_ACCESS_TOKEN` - Token API de DigitalOcean
- `DO_APP_NAME` - Nombre de tu app (probablemente `companies-app`)

Verificar en: `https://github.com/ferangarita01/Companies/settings/secrets/actions`

---

### **Paso 2: Obtener Connection String de Supabase**

1. Ve a: https://supabase.com/dashboard/project/[TU_PROJECT]
2. Click en **Settings** → **Database**
3. Busca la sección **Connection String**
4. Selecciona: **Transaction Pooler** (puerto 6543)
5. Copia la URL completa que se ve así:
   ```
   postgresql://postgres.[PROJECT_ID]:[YOUR_PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres
   ```

**⚠️ IMPORTANTE:** Si tu password tiene caracteres especiales (`#`, `@`, `:`, etc.), debes URL-encodearlos:

```bash
# Opción 1: En terminal de Linux/Mac
echo -n "TuPassword#123" | jq -sRr @uri

# Opción 2: En Node.js
node -e "console.log(encodeURIComponent('TuPassword#123'))"

# Resultado: TuPassword%23123
```

---

### **Paso 3: Ejecutar el Workflow**

1. Ve a: https://github.com/ferangarita01/Companies/actions/workflows/setup-supabase-secret.yml

2. Click en **Run workflow** (botón azul a la derecha)

3. Pega la connection string de Supabase en el input:
   ```
   postgresql://postgres.abcdefgh:MyPass%23word@aws-0-us-west-2.pooler.supabase.com:6543/postgres
   ```

4. Click en **Run workflow** (verde)

5. Espera 5-10 minutos mientras:
   - ✅ Valida el formato
   - ✅ Actualiza el app spec
   - ✅ Dispara el deployment
   - ✅ Espera que esté ACTIVE
   - ✅ Verifica logs de DB

---

## 📊 Qué Hace el Workflow

### Fase 1: Validación
```bash
✅ Busca la app en DigitalOcean por nombre
✅ Valida que la connection string sea válida
✅ Verifica formato postgresql:// y puerto 6543
```

### Fase 2: Configuración
```bash
✅ Descarga el app spec actual
✅ Actualiza DATABASE_URL con scope SECRET
✅ Aplica la nueva configuración
```

### Fase 3: Deployment
```bash
✅ Dispara deployment automático
✅ Monitorea el estado cada 15 segundos
✅ Espera hasta que esté ACTIVE (max 10 min)
```

### Fase 4: Verificación
```bash
✅ Revisa logs buscando "Using external PostgreSQL"
✅ Genera resumen con links directos
```

---

## 📝 Output Esperado

### En GitHub Actions Log:
```
🔍 Searching for app: companies-app
✅ Found App ID: abc123def-456-789
✅ Connection string format validated
📄 Updated app spec:
  key: DATABASE_URL
  scope: RUN_AND_BUILD_TIME
  type: SECRET
  value: postgresql://postgres...
🚀 Applying updated configuration...
🔄 Triggering new deployment...
✅ Deployment ID: xyz789
⏳ Waiting for deployment to complete...
[0 s] Deployment status: PENDING_BUILD
[15 s] Deployment status: BUILDING
[30 s] Deployment status: DEPLOYING
[45 s] Deployment status: ACTIVE
✅ Deployment successful!
```

### En DigitalOcean App Logs:
```
Using external PostgreSQL via DATABASE_URL/config
Running migrations...
✅ All migrations applied successfully
Paperclip server started successfully
Listening on port 3100
```

---

## 🔧 Troubleshooting

### Si falla con "App not found":
```bash
# El nombre en DO_APP_NAME debe coincidir exactamente
# Verifica en: https://cloud.digitalocean.com/apps
# O ejecuta localmente:
doctl apps list
```

### Si falla con "Invalid connection string":
```bash
# Verifica el formato:
postgresql://postgres.[PROJECT]:[PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres

# Asegúrate de URL-encodear caracteres especiales
```

### Si el deployment se queda en PENDING_BUILD:
```bash
# Es normal, puede tomar 5-10 minutos
# El workflow espera automáticamente
# Si excede 10 min, revisa manualmente en:
https://cloud.digitalocean.com/apps/[APP_ID]
```

### Si persiste "Tenant or user not found":
```bash
# Verifica en Supabase:
# Settings → Database → Connection Pooling
# Asegura que:
# - Pooler esté habilitado
# - Password sea el correcto
# - Proyecto esté activo (no pausado)
```

---

## 🔄 Actualizaciones Futuras

Si necesitas cambiar la URL más adelante (ej: cambio de password):

### Opción 1: Re-ejecutar el mismo workflow
1. Ve a Actions → Setup Supabase Secret
2. Run workflow con la nueva URL

### Opción 2: Usar el workflow alternativo
1. Ve a Actions → Configure Database URL
2. Run workflow (es más simple pero hace lo mismo)

---

## ✅ Checklist de Validación Post-Deploy

Después de ejecutar el workflow:

- [ ] Workflow completó con status verde
- [ ] Deployment summary muestra `Status: ACTIVE`
- [ ] Logs de la app muestran "Using external PostgreSQL"
- [ ] No hay errores "Tenant or user not found"
- [ ] Endpoint de salud responde: `curl https://your-app.ondigitalocean.app/api/health`

---

## 🔗 Links Útiles

- **GitHub Actions**: https://github.com/ferangarita01/Companies/actions
- **Workflow Principal**: https://github.com/ferangarita01/Companies/actions/workflows/setup-supabase-secret.yml
- **DigitalOcean Apps**: https://cloud.digitalocean.com/apps
- **Supabase Dashboard**: https://supabase.com/dashboard

---

## ⚡ Comandos Rápidos (para debugging local)

```bash
# Ver estado de la app
doctl apps get <APP_ID>

# Ver logs en vivo
doctl apps logs <APP_ID> --type run --follow

# Ver spec actual
doctl apps spec get <APP_ID>

# Listar deployments
doctl apps list-deployments <APP_ID>
```

---

**¿Todo listo?** Ejecuta el workflow desde GitHub Actions ahora! 🚀
