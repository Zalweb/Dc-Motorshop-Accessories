# Supabase Setup Guide — DC Motorshop Inventory

This guide walks you through connecting the app to your Supabase project.
The whole process takes about 10 minutes.

---

## 1. Create a Supabase Project

1. Go to https://supabase.com and sign up (free)
2. Click **New Project**
3. Give it a name (e.g. `dc-motorshop`)
4. Set a **Database Password** (save this!)
5. Choose a region close to the Philippines (e.g. Singapore)
6. Click **Create new project** and wait ~2 minutes for provisioning

---

## 2. Run the SQL Migrations

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Copy and paste the contents of `supabase/migrations/001_initial_schema.sql`
4. Click **Run** (bottom right) — you should see "Success. No rows returned"
5. Create another new query
6. Copy and paste `supabase/migrations/002_storage_bucket.sql`
7. Click **Run**

---

## 3. Get Your API Keys

In your Supabase project dashboard:
1. Click **Settings** (gear icon, bottom left)
2. Click **API**
3. Copy:
   - **Project URL** (looks like `https://xxxxxxxxxxxx.supabase.co`)
   - **anon / public** key (the long JWT string)

---

## 4. Configure the Flutter App

Open `lib/core/supabase/supabase_config.dart` and replace the placeholder values:

```dart
const String kSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

**Alternatively**, pass them as build-time defines (recommended for production):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 5. Enable Email Auth (important!)

In your Supabase dashboard:
1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled
3. Under **Email** settings:
   - Turn **OFF** "Confirm email" for development (optional — turn ON for production)
   - This lets you register and log in immediately without checking your inbox

---

## 6. Run the App

```bash
cd "DC Motorshop Inventory"
flutter pub get
flutter run
```

The app will:
- Work **fully offline** (Isar local database) if Supabase is unreachable
- Automatically **sync to the cloud** when the device goes online
- Store auth tokens **securely** (flutter_secure_storage under the hood)

---

## 7. Add Cloud Sync to Your More Screen

The new `CloudSyncScreen` widget (`lib/features/more/cloud_sync_screen.dart`)
provides a UI for manual sync and cloud restore. Add it to your More tab:

```dart
// In your More screen, add a navigation tile:
ListTile(
  leading: const Icon(Icons.cloud_sync_rounded),
  title: const Text('Cloud Backup & Sync'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/more/cloud-sync'),
),
```

And register the route in your router.

---

## How Sync Works

```
User creates/edits data
  └─ Isar (local) updated immediately ✅
       └─ isDirty = true (marked for sync)
          └─ On reconnect (or manual sync)
               └─ Dirty rows pushed to Supabase
                    └─ New/updated rows pulled from Supabase
                         └─ isDirty = false ✅
```

### Conflict Resolution
- **Products, categories, expenses**: Last-write-wins by `updated_at`
- **Sales**: Append-only (never overwritten — push only)
- **Offline edits**: Preserved until the device reconnects and pushes

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Failed host lookup" | Device is offline — this is expected; app still works locally |
| "invalid api key" | Check `supabase_config.dart` for typos |
| "row violates RLS policy" | Make sure you ran both migration SQL files |
| "Email not confirmed" | Disable email confirmation in Supabase Auth settings |
| Images not uploading | Check the storage bucket was created via `002_storage_bucket.sql` |

---

## Security Notes

- The **anon key** is safe to embed in the app — it only allows access per the RLS policies
- All data is protected by **Row-Level Security**: users can only see their own shop data
- Auth tokens are stored in **Keychain (iOS) / Keystore (Android)** automatically
- All traffic is over **HTTPS/TLS**
