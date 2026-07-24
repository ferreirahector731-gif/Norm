# Norm.

[![CI](https://github.com/ferreirahector731-gif/Norm/actions/workflows/build.yml/badge.svg)](https://github.com/ferreirahector731-gif/Norm/actions/workflows/build.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPLv3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platform-Windows%20|%20Linux%20|%20macOS%20|%20Android%20|%20iOS-blue)](#)
[![Local-First](https://img.shields.io/badge/Architecture-Local--First-success)](#)

> **Your space. Your rules.**  
> *Your mind has no limits. Your tool shouldn't either.*

---

## Overview

**Norm.** is a multimodal, local-first productivity suite that unifies your knowledge on a single infinite canvas at 120 FPS. Built on the principle that **no one decides for you — not even the app**, it eliminates the need for multiple subscriptions by integrating 7 native modules into a single fluid workspace:

| Module | Purpose |
|---|---|
| **Note** | High-speed Markdown editor for rapid idea capture |
| **Doc** | Structured documentation with flexible rich-text blocks |
| **Canvas** | Infinite whiteboard to interconnect concepts, notes, and visual objects |
| **Sheet** | Liquid databases and tables that project instantly onto the canvas |
| **Chart** | Dynamic, interactive graphs live-synced to your data |
| **Task** | Full project management with NLP-powered task entry |
| **Link** | Knowledge graphs with automatic bidirectional linking and backlink discovery |

---

## Architecture & Philosophy

### 🔒 Absolute Data Sovereignty (Local-First)

- **Zero-trust privacy**: All data lives locally on your device via the **Isar** embedded database engine — no cloud gateways, no telemetry, no surveillance.
- **Vendor lock-in impossible**: Your information is stored in open, accessible formats. Export to Markdown, JSON, CSV, or compressed archives with a single click.
- **Offline by default**: Fully functional with zero network dependencies. Optional Supabase sync for cross-device workflows when you choose.

### ⚡ Liquid Data — Cross-Module Polymorphism

Every piece of content can be referenced, embedded, or projected into any other module in real time:

- A **Sheet row** instantiates as an interactive **Chart** series or a **Task** item
- A **Canvas node** embeds a live **Doc** fragment or **Note**
- A **Link** automatically discovers backlinks across all 7 modules
- All mutations propagate atomically at **120 FPS** through the `LiquidDataSync` engine

### 🔄 Universal Import / Export (Zero-Friction Migration)

| Source | Format | Preservation |
|---|---|---|
| **Obsidian** | `.md` vault | YAML frontmatter, `[[wikilinks]]`, `#tags` |
| **Notion** | Markdown + CSV export | Databases → Sheet, pages → Doc/Note |
| **Office** | CSV, JSON, OPML | Raw import with automatic type detection |
| **Export** | Markdown, JSON (flat/gzip), CSV | Full metadata + frontmatter |

---

## Official Releases

The only certified, signed, and official versions of **Norm.** are distributed exclusively through the project's GitHub Releases page. Binaries downloaded from any other source are not verified and may pose security or integrity risks.

> **Download safely**: https://github.com/ferreirahector731-gif/Norm/releases

See [`TRADEMARK.md`](./TRADEMARK.md) for brand usage guidelines.

---

## Licensing (AGPLv3 / Dual-Licensing)

To protect development effort and guarantee ecosystem freedom, **Norm.** is distributed under a dual-licensing model:

- **AGPLv3 (Community)**: If you modify, extend, or improve the codebase, the license legally requires that those contributions be shared transparently with the community. Innovations flow back to the main project by law.
- **Commercial / Fair-Use (Enterprise)**: Proprietary or closed-source use cases. Strictly prohibits monopolistic practices, opaque repackaging, or unfair competition against the original project.

See [`LICENSE`](./LICENSE) for the full AGPLv3 terms.
