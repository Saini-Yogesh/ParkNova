# ParkFlow Backend ⚙️

The backend for ParkFlow is a robust, highly-scalable Express.js REST API. It handles authentication, data validation, business logic, and real-time operations, backed by a powerful PostgreSQL database managed via Supabase.

## 🛠️ Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL (via Supabase Client)
- **Authentication**: JWT (JSON Web Tokens) & bcryptjs
- **Real-Time WebSockets**: Socket.io
- **CORS & Security**: cors, dotenv

## 📂 Directory Structure

```text
/backend
  /controllers   # Business logic (auth, analytics, sessions, pricing)
  /database      # SQL schema files, migrations, and dummy data generators
  /middleware    # Express middleware (auth protection, error handling)
  /routes        # Express route definitions
  app.js         # Application entry point and server configuration
  createAdmin.js # Utility script to bootstrap the first Super Admin
```

## 🚀 Development Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Environment Configuration**:
   Create a `.env` file in the `backend` root directory:
   ```env
   PORT=5000
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   JWT_SECRET=your_super_secret_jwt_string
   JWT_EXPIRES_IN=30d
   ```

3. **Database Initialization**:
   You must set up your PostgreSQL database schema before running the server. 
   - Open your Supabase SQL Editor.
   - Run the contents of `database/schema.sql`.
   - Run the contents of `database/enterprise_migrations.sql`.
   - *(Optional)* Run `database/dummy_data.sql` to populate the database with realistic test data.

4. **Bootstrap Admin Account**:
   Run the setup script to create your initial `SUPER_ADMIN` account:
   ```bash
   node createAdmin.js
   ```

5. **Start the Server**:
   ```bash
   npm run dev
   ```
   The API will be available at `http://localhost:5000`.

## 📡 API Endpoints

The API is structured around several core domains:
- `/api/auth` - Login and registration.
- `/api/enterprise` - Cross-location aggregate statistics and materialized views.
- `/api/dashboard` - Real-time location-specific statistics.
- `/api/locations` - Management of parking facilities.
- `/api/pricing` - Dynamic pricing rules and category assignments.
- `/api/sessions` - Core business logic: vehicle entry, exit, and payment processing.
- `/api/users` - Worker and admin account management.

## 🔐 Authentication Flow
All protected routes require an `Authorization: Bearer <token>` header. The `protect` middleware verifies the token, while the `authorize(...roles)` middleware ensures the authenticated user has the correct permission level.
