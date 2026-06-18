-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'PARKING_ADMIN', 'WORKER')),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED')),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parking Locations Table
CREATE TABLE parking_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vehicle Categories Table
CREATE TABLE vehicle_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parking Workers Table
CREATE TABLE parking_workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parking_location_id UUID REFERENCES parking_locations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parking_location_id, user_id)
);

-- Parking Slots Table
CREATE TABLE parking_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parking_location_id UUID REFERENCES parking_locations(id) ON DELETE CASCADE,
    slot_number VARCHAR(50) NOT NULL,
    vehicle_category_id UUID REFERENCES vehicle_categories(id) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parking_location_id, slot_number)
);

-- Pricing Rules Table
CREATE TABLE pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parking_location_id UUID REFERENCES parking_locations(id) ON DELETE CASCADE,
    vehicle_category_id UUID REFERENCES vehicle_categories(id) ON DELETE CASCADE,
    base_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    hourly_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    daily_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parking_location_id, vehicle_category_id)
);

-- Parking Sessions Table
CREATE TABLE parking_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(100) UNIQUE NOT NULL,
    parking_location_id UUID REFERENCES parking_locations(id) ON DELETE RESTRICT,
    slot_id UUID REFERENCES parking_slots(id) ON DELETE RESTRICT,
    vehicle_number VARCHAR(50) NOT NULL,
    vehicle_category_id UUID REFERENCES vehicle_categories(id) ON DELETE RESTRICT,
    entry_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    exit_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50) CHECK (payment_method IN ('CASH', 'CARD', 'UPI', 'ONLINE', NULL)),
    payment_status VARCHAR(50) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    closed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments Table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES parking_sessions(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('CASH', 'CARD', 'UPI', 'ONLINE')),
    reference_number VARCHAR(255),
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit Logs Table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_parking_locations_admin ON parking_locations(admin_id);

CREATE INDEX idx_parking_slots_location ON parking_slots(parking_location_id);
CREATE INDEX idx_parking_slots_status ON parking_slots(status);

CREATE INDEX idx_parking_sessions_location ON parking_sessions(parking_location_id);
CREATE INDEX idx_parking_sessions_ticket ON parking_sessions(ticket_number);
CREATE INDEX idx_parking_sessions_vehicle ON parking_sessions(vehicle_number);
CREATE INDEX idx_parking_sessions_status ON parking_sessions(status);
CREATE INDEX idx_parking_sessions_entry_time ON parking_sessions(entry_time);

CREATE INDEX idx_payments_session ON payments(session_id);

CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- Initial Seed Data
INSERT INTO vehicle_categories (name, code, description) VALUES
('Bike', 'LIGHT', 'Two wheelers'),
('Car', 'MEDIUM', 'Four wheelers, SUVs'),
('Truck/Lorry', 'HEAVY', 'Heavy commercial vehicles');

-- Create a trigger function to update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_parking_locations_updated_at BEFORE UPDATE ON parking_locations FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_parking_slots_updated_at BEFORE UPDATE ON parking_slots FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_pricing_rules_updated_at BEFORE UPDATE ON pricing_rules FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_parking_sessions_updated_at BEFORE UPDATE ON parking_sessions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
