# SyncTogether

PWA para coordinar disponibilidad entre personas con Google Calendar y Outlook. UI inicial en español, timeline, estados manuales y base para notificaciones push.

## Stack
- Next.js 15 + React + TypeScript
- Supabase Auth + PostgreSQL + RLS (persistencia multiusuario)
- Web Push + Service Worker
- Integración Google Calendar FreeBusy y Microsoft Graph (OAuth por completar)

## Ejecutar localmente
```bash
npm install
cp .env.example .env.local
npm run dev
```
Abre http://localhost:3000.

## Configuración
1. Crea un proyecto en Supabase y ejecuta `supabase/schema.sql` en SQL Editor.
2. Configura URL, anon key, service role key y VAPID en `.env.local` usando `.env.example` como guía.
3. Habilita OAuth de Google/Microsoft en Supabase y configura sus redirect URI.
4. Ejecuta `npm run dev`.

## Alcance MVP
- [x] UI responsive, timeline y estados manuales
- [x] Manifest y service worker PWA
- [x] Esquema Supabase para usuarios, espacios, disponibilidad y suscripciones push
- [x] Endpoints iniciales de estado y push
- [ ] Integración productiva OAuth/FreeBusy/Graph, sincronización de calendarios e invitaciones

**Nota:** Esta es una base inicial. La integración real de calendarios, push y persistencia requiere configurar credenciales y completar los flujos señalados. No publiques secretos OAuth, service role o VAPID private key.