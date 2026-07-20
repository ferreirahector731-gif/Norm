-- Migration: create notes table for cloud sync
-- Tabla espejo del modelo NoteModel local para sync bidireccional

-- Extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE notes (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL DEFAULT '',
  content_json TEXT       NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices para consultas del SyncManager
CREATE INDEX idx_notes_user_id ON notes (user_id);
CREATE INDEX idx_notes_updated_at ON notes (updated_at);

-- Row Level Security: aislamiento por usuario
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS: cada usuario solo ve sus propias notas
CREATE POLICY "Users can view own notes"
  ON notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own notes"
  ON notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes"
  ON notes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes"
  ON notes FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
