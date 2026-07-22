# Norm

> Aplicación de notas multimedia local-first con sincronización en la nube y asistencia de IA.

**Estado del proyecto:** Beta activo. Las funcionalidades principales están estables en escritorio.

## Plataformas soportadas

| Plataforma | Estado |
|-----------|--------|
| Windows   | ✅ Listo |
| Linux     | ✅ Listo |
| Android   | 🚧 En desarrollo |
| macOS     | 🚧 En desarrollo |

## Características Clave

- **Arquitectura Local-First:** Almacenamiento y procesamiento inmediato en el dispositivo mediante Isar Database. Operatividad total sin conexión.
- **Sincronización Bidireccional:** Respaldo automático en la nube con Firebase y aislamiento por usuario.
- **Editor de Bloques Modular:** Lienzo interactivo para texto estructurado, listas, pizarrones y marcadores multimedia.
- **Asistente de IA con Consentimiento:** Integración con motores de IA (Local/Ollama o APIs externas).
- **Interfaz Premium:** Diseño glassmorphic con soporte nativo para tema oscuro.

## Tecnologías

- **Framework:** Flutter 3.x
- **Base de Datos Local:** Isar
- **Backend & Sync:** Firebase
- **Editor:** AppFlowyEditor

## Cómo contribuir

1. Haz fork del repositorio.
2. Crea una rama (`git checkout -b feature/mi-mejora`).
3. Haz commit de tus cambios (`git commit -m 'feat: agregar mi mejora'`).
4. Haz push a la rama (`git push origin feature/mi-mejora`).
5. Abre un Pull Request.

## Changelog

### v1.4.0 (actual)
- IA: integración con Google Gemini (modelo ligero flash) y caché de respuestas.
- Web: página profesional con paleta corporativa y descargas dinámicas.
- Tablas: widget de tabla editable con inserción de filas/columnas.
- Importación: pantalla base para migración desde Notion.
- Banner Beta con persistencia en SharedPreferences.
- Correcciones en compilación Android (plugin isar_flutter_libs) y macOS (empaquetado).

### v1.3.0
- Correcciones Android (lStar, Kotlin/AGP) y macOS (zip).
- GitHub Pages con despliegue automático.
- Página web profesional docs/index.html.

### v1.2.0
- UI: botón de login centrado y con tamaño controlado.
- Logo: iconos regenerados para Windows y Linux.
- Banner de bienvenida Beta.
- Documentación expandida.
- Estructura preparada para auto‑actualización y empaquetado MSIX.

### v1.1.0
- Builds automatizados con GitHub Actions (Windows y Linux).
- Release con instaladores de Windows y Linux.
- Correcciones en Gradle para Android.

## Compilación

```powershell
.\scripts\build.ps1 -Target logo      # Generar iconos
.\scripts\build.ps1 -Target windows   # Compilar para Windows
.\scripts\build.ps1 -Target linux     # Compilar para Linux
```

## Licencia

Apache 2.0. Consulta el archivo `LICENSE`.

---

**Web:** https://ferreirahector731-gif.github.io/Norm
