# DC Motorshop Inventory & POS

An offline-first, cloud-synced inventory and Point-of-Sale (POS) management system tailored for DC Motorshop. Built with Flutter, Isar, and Supabase.

## Features
- **Offline-First Capabilities:** Works seamlessly without an internet connection using an embedded Isar NoSQL database.
- **Cloud Synchronization:** Deeply integrated with Supabase for realtime conflict-free data syncing across multiple devices.
- **Point of Sale (POS):** Fast and robust checkout process with cart management, barcodes, and receipt generation.
- **Inventory Management:** Easy tracking of products, stock levels, and pricing. Features bulk-add support via barcode scanning.
- **Expense Tracking:** Monitor day-to-day business expenses directly within the app.
- **Dashboards & Reporting:** Visual financial calendars and business calendars to monitor sales and performance.
- **Secure Cloud Backup:** All data, including settings and logos, are securely backed up to the cloud.

## Tech Stack
- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Local Database:** [Isar](https://isar.dev/) (Fast NoSQL database)
- **Backend & Cloud Sync:** [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage, Edge Functions)
- **State Management:** Riverpod

## Getting Started

### Prerequisites
- Flutter SDK (v3.22.0 or higher)
- Supabase Project (configured with required tables, RLS, and storage buckets)

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/Zalweb/Dc-Motorshop-Accessories.git
   cd "Dc-Motorshop-Accessories"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create a `.env` file in the root directory (make sure it stays ignored) and add your Supabase credentials:
   ```env
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Sync Architecture
The app implements a robust two-way sync engine (`SupabaseSyncService`). It uses Isar as the single source of truth for the UI while continuously pushing changes (upserts) to Supabase and pulling remote changes down. It safely handles `Map<String, dynamic>` type parsing from Supabase's PostgREST API to ensure stability.

## Security
- Enforced Row Level Security (RLS) on all Supabase tables ensuring users can only manage their own shop's data.
- Secure environment configuration.
- Secure token storage for authentication.

## License
Proprietary software. Created for DC Motorshop.
