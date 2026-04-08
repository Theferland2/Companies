# Fix: Database Connection Error en DigitalOcean App Platform

## Problema Diagnosticado
```
PostgresError: Tenant or user not found
code: XX000
```

El error ocurre en `packages/db/src/client.ts:605` dentro de `inspectMigrations()` al ejecutar la primera query contra Supabase.

## Análisis del Código

### 1. Flujo de Conexión (server/src/index.ts)
```typescript
// Línea 237: Lee DATABASE_URL de process.env
databaseUrl: process.env.DATABASE_URL ?? fileDbUrl

// Línea 266: Si existe DATABASE_URL, usa Postgres externo
if (config.databaseUrl) {
  db = createDb(config.databaseUrl); // Usa la URL directamente
}
```

### 2. Configuración Actual (.do/app.yaml)
```yaml
envs:
  - key: DATABASE_URL
    value: ""  # ❌ VACÍO - Por eso NO se conecta a Supabase
```

### 3. Función de Conexión (packages/db/src/client.ts)
```typescript
function createUtilitySql(url: string) {
  return postgres(url, { max: 1, onnotice: () => {} });
}
```
**No hay validación de URL** - Si está vacía o malformada, falla en runtime.

---

## Solución: Configurar DATABASE_URL en DigitalOcean

### Opción 1: Vía CLI (doctl) - RECOMENDADO

```bash
# 1. Listar apps para obtener el ID
doctl apps list

# 2. Crear el SECRET con la URL correcta de Supabase
doctl apps create-env \
  --app <APP_ID> \
  --env DATABASE_URL="postgresql://postgres.XXXXX:[PASSWORD_ENCODED]@aws-0-us-west-2.pooler.supabase.com:6543/postgres"

# 3. Triggear redeploy
doctl apps create-deployment <APP_ID>
```

### Opción 2: Vía Control Panel (Web UI)

1. Ve a: https://cloud.digitalocean.com/apps
2. Selecciona tu app "companies-app"
3. Settings → Environment Variables
4. Edita `DATABASE_URL` y pega la URL completa
5. Save → Re-deploy

---

## Formato Correcto de DATABASE_URL para Supabase

### Obtener Credenciales de Supabase:
1. Ve a: https://supabase.com/dashboard/project/companies
2. Settings → Database → Connection String
3. Selecciona: **Transaction Pooler (Recommended for App Platform)**

### Formato Esperado:
```
postgresql://postgres.PROJECT_ID:[PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres
```

### ⚠️ URL Encoding de Caracteres Especiales:
Si tu password tiene caracteres como `#`, `@`, `:`, `%`, `/`, etc., debes escaparlos:

```bash
# Ejemplo: Si password es "Pass#Word@123"
# Escapa: Pass%23Word%40123

# Tabla de conversión:
# ! → %21    # → %23    $ → %24    % → %25
# & → %26    ' → %27    ( → %28    ) → %29
# * → %2A    + → %2B    , → %2C    / → %2F
# : → %3A    ; → %3B    = → %3D    ? → %3F
# @ → %40    [ → %5B    ] → %5D
```

### Script para URL Encoding (si es necesario):
```bash
# En Bash/Linux:
echo -n "TuPasswordAqui" | jq -sRr @uri

# En Node.js:
node -e "console.log(encodeURIComponent('TuPasswordAqui'))"
```

---

## Validación Pre-Deploy

Antes de configurar en DigitalOcean, valida localmente:

```bash
# 1. Exporta la URL
export DATABASE_URL="postgresql://postgres.XXX:YYY@aws-0-us-west-2.pooler.supabase.com:6543/postgres"

# 2. Prueba conexión con psql
psql "$DATABASE_URL" -c "SELECT version();"

# 3. Prueba con el código (local)
cd packages/db
pnpm build
node -e "import('./dist/client.js').then(m => m.inspectMigrations(process.env.DATABASE_URL).then(console.log))"
```

---

## Checklist de Implementación

- [ ] Obtener credenciales de Supabase (Pooler en puerto 6543)
- [ ] Verificar password y aplicar URL encoding si tiene caracteres especiales
- [ ] Validar conexión local con `psql` o script Node
- [ ] Configurar SECRET en DigitalOcean App Platform
- [ ] Triggear redeploy manualmente
- [ ] Monitorear logs: `doctl apps logs <app-id> --type run`
- [ ] Verificar startup exitoso: debe mostrar "Using external PostgreSQL via DATABASE_URL/config"

---

## Monitoreo Post-Deploy

```bash
# Ver logs en vivo
doctl apps logs <app-id> --type run --follow

# Buscar mensajes de éxito:
# ✅ "Using external PostgreSQL via DATABASE_URL/config"
# ✅ "Paperclip server started successfully"
# ✅ "Listening on port 3100"

# Errores a evitar:
# ❌ "Tenant or user not found"
# ❌ "FATAL: password authentication failed"
# ❌ "connection refused"
```

---

## Troubleshooting Adicional

### Si persiste el error después de configurar:

1. **Verificar que el SECRET se aplicó:**
   ```bash
   doctl apps spec get <app-id> | grep -A 2 DATABASE_URL
   ```

2. **Revisar firewall de Supabase:**
   - Settings → Database → Connection Pooling
   - Asegurar que permite conexiones desde DigitalOcean IPs

3. **Probar con conexión directa (puerto 5432) temporalmente:**
   ```
   postgresql://postgres.XXX:YYY@aws-0-us-west-2.pooler.supabase.com:5432/postgres
   ```
   **Nota:** Esto NO es recomendado para producción, solo para diagnóstico.

4. **Validar roles de Supabase:**
   ```sql
   -- Conectarse a Supabase y verificar:
   SELECT rolname, rolsuper FROM pg_roles WHERE rolname = 'postgres';
   ```

---

## Referencia: Por qué falló antes

El archivo `.do/app.yaml` tenía:
```yaml
- key: DATABASE_URL
  value: ""  # String vacío
```

Esto hace que `process.env.DATABASE_URL` sea `""` (string vacío, no `undefined`), entonces:
1. El código detecta que existe `config.databaseUrl` (línea 265 de server/src/index.ts)
2. Intenta `createDb("")` con URL vacía
3. El cliente `postgres` construye una conexión inválida
4. Al ejecutar `inspectMigrations()`, Supabase rechaza con "Tenant or user not found"

**Fix:** Configurar el valor real del SECRET en DigitalOcean, no en el YAML.

<!-- Fix applied: 2026-04-08 01:38:35 -->
