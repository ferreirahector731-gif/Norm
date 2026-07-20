# Norm

Aplicación de notas multimedia local-first con sincronización en la nube y asistencia de IA.

## 🚀 Características Clave

* **Arquitectura Local-First:** Almacenamiento y procesamiento inmediato en el dispositivo mediante la base de datos indexada Isar. Operatividad total sin conexión a internet.
* **Sincronización Bidireccional:** Respaldo automático en la nube a través de Supabase con aislamiento total por usuario mediante políticas RLS (Row Level Security).
* **Editor de Bloques Modular:** Lienzo interactivo basado en componentes para texto estructurado, listas, pizarrones y marcadores multimedia.
* **Asistente de IA con Consentimiento:** Integración con motores de IA (Local/Ollama o APIs externas) mediante captura de estado (snapshot) previa a la consolidación del texto.
* **Interfaz Premium:** Interfaz de usuario responsiva con estética glassmorphic y soporte nativo para tema oscuro.

## 🛠️ Tecnologías Utilizadas

* **Framework:** Flutter 3.x
* **Base de Datos Local:** Isar Database
* **Backend & Sync:** Supabase
* **Editor Core:** AppFlowyEditor

## 📦 Compilación y Despliegue

El proyecto cuenta con un script automatizado en PowerShell para simplificar el pipeline de desarrollo:

```powershell
# Generar iconos y pantallas de carga desde C:\Src\logo\logo.png
.\scripts\build.ps1 -Target logo

# Compilar instalador ejecutable para Windows
.\scripts\build.ps1 -Target windows

# Generar APKs optimizados por arquitectura para Android
.\scripts\build.ps1 -Target apk
```

### Pasos individuales

```powershell
.\scripts\build.ps1 -Target clean    # Limpiar artefactos de compilación
.\scripts\build.ps1 -Target icons    # Regenerar iconos de la aplicación
.\scripts\build.ps1 -Target splash   # Regenerar pantalla de carga
.\scripts\build.ps1 -Target all      # Ejecutar todos los pasos en orden
```

## 📄 Licencia

Distribuido bajo la Licencia Apache 2.0. Consulta el archivo `LICENSE` para más información.
