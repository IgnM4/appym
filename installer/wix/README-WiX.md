# Instalador WiX para AplicacionPyme

Este directorio contiene un esqueleto de proyecto [WiX Toolset](https://wixtoolset.org/) para generar un MSI básico de **AplicacionPyme**.

## Requisitos
- [WiX Toolset 3.x](https://wixtoolset.org/releases/)
- Windows con las herramientas `candle.exe` y `light.exe` en el `PATH`.

## Compilación
1. Abrir una consola de comandos de Windows.
2. Navegar a este directorio: `installer\wix`.
3. Ejecutar:
   ```bat
   build_msi.bat
   ```
   Se generará el archivo `AplicacionPyme.msi`.

Si faltan archivos como `third_party\nssm\nssm.exe`, puede comentar temporalmente el componente correspondiente en `Files.wxs` para que el proyecto compile.

### Harvest con Heat
WiX no admite comodines de forma nativa. Utilice [heat.exe](https://wixtoolset.org/documentation/manual/v3/overview/heat.html) para generar fragmentos `.wxs` a partir de directorios reales. Ejemplos:

```bat
heat dir ..\third_party\node -nologo -cg CG.Api -dr INSTALLDIR -var var.SourceDir -out files_node.wxs
heat dir ..\server\dist -nologo -cg CG.Api -dr INSTALLDIR -var var.SourceDir -out files_server_dist.wxs
heat dir ..\desktop\AplicacionPyme -nologo -cg CG.Desktop -dr INSTALLDIR -var var.SourceDir -out files_desktop.wxs
heat dir ..\third_party\oracle\instantclient -nologo -cg CG.OracleClient -dr INSTALLDIR -var var.SourceDir -out files_oracle.wxs
```

Los archivos generados (`files_*.wxs`) se incluyen automáticamente por `build_msi.bat` si están presentes.

## Propiedades de base de datos y API
El MSI expone las siguientes propiedades con valores por defecto:

| Propiedad | Valor por defecto |
|-----------|------------------|
| `DB_USER` | `app_user` |
| `DB_PASSWORD` | `change_me` |
| `DB_CONNECT_STRING` | `localhost:1521/XEPDB1` |
| `API_PORT` | `4000` |

Puede sobreescribirlas al momento de instalar:

```powershell
msiexec /i AplicacionPyme.msi DB_USER="otro_usuario" DB_PASSWORD="secreto" API_PORT=8080
```

Para instalaciones silenciosas se puede agregar `/qn` al comando:

```powershell
msiexec /i AplicacionPyme.msi DB_USER=usuario DB_PASSWORD=clave API_PORT=8080 /qn
```

La interfaz `WixUI_InstallDir` permite elegir la carpeta de instalación mediante la opción `INSTALLDIR`.

## Características opcionales
El MSI define las features `Desktop`, `ApiService` y `OracleClient`. Puede controlar cuáles instalar usando `ADDLOCAL`.

Incluir el cliente de Oracle:
```powershell
msiexec /i AplicacionPyme.msi ADDLOCAL=Desktop,ApiService,OracleClient
```

Omitir el cliente de Oracle:
```powershell
msiexec /i AplicacionPyme.msi ADDLOCAL=Desktop,ApiService
```


## Archivos de configuración en ProgramData
Durante la instalación se copian dos archivos de ejemplo en `C:\ProgramData\AplicacionPyme\config\`:

- `app.properties`: parámetros de la aplicación de escritorio.
- `.env`: variables para el servicio de la API.

Los archivos provienen del directorio `config_templates` y se instalan con `NeverOverwrite="yes"`, por lo que las modificaciones del usuario se conservarán en reinstalaciones o upgrades.

## Servicio Windows de la API
La instalación registra la API como un servicio de Windows llamado `AplicacionPymeAPI` utilizando `nssm.exe`. El servicio se inicia automáticamente al final de la instalación y se elimina al desinstalar el MSI.

### Verificación
Para comprobar el estado del servicio:

```powershell
sc query AplicacionPymeAPI
```

Los logs del servicio se escriben en `INSTALLDIR\logs` y se rotan automáticamente.

Si `node\node.exe` o `server\dist\app.js` no están presentes durante la instalación, el MSI mostrará un error claro indicando el archivo faltante.

### Propiedades de entorno
Las propiedades `DB_USER`, `DB_PASSWORD`, `DB_CONNECT_STRING` y `API_PORT` se pasan al servicio como variables de entorno junto con `APP_CONFIG_DIR`, que apunta a la carpeta `CONFIGDIR`. Puede sobreescribirlas usando `msiexec` como se mostró anteriormente:

```powershell
msiexec /i AplicacionPyme.msi DB_USER=usuario DB_PASSWORD=clave DB_CONNECT_STRING="servidor:puerto/servicio" API_PORT=8080
```

## Pruebas

1. Instalar el MSI pasando las propiedades necesarias.
2. Verificar que el servicio `AplicacionPymeAPI` esté en ejecución.
3. Confirmar que se creó `INSTALLDIR\\logs` y la carpeta `ProgramData\\AplicacionPyme` con los archivos de configuración.
4. Si se incluye la aplicación de escritorio, comprobar los accesos directos en el menú Inicio y el escritorio.
5. Desinstalar y validar que el servicio y los archivos en `ProgramFiles` y `ProgramData` se eliminaron.
