-- Run this in your Supabase SQL Editor to populate dummy data!
-- If you don't have any locations, workers, or categories, this will create them for you automatically!

DO $$
DECLARE
    loc_id UUID;
    cat_id UUID;
    wrk_id UUID;
    i INT;
    sim_date TIMESTAMP;
    sim_exit TIMESTAMP;
    rand_hour INT;
    rand_duration INT;
    amount NUMERIC;
BEGIN
    -- 1. Create a Location if none exist
    SELECT id INTO loc_id FROM parking_locations LIMIT 1;
    IF loc_id IS NULL THEN
        INSERT INTO parking_locations (name, code, address, city, country, total_slots, created_at, updated_at) 
        VALUES ('Downtown Main Garage', 'DTM-001', '123 Enterprise Way', 'New York', 'USA', 500, NOW(), NOW())
        RETURNING id INTO loc_id;
    END IF;

    -- 2. Create Vehicle Categories if none exist
    SELECT id INTO cat_id FROM vehicle_categories LIMIT 1;
    IF cat_id IS NULL THEN
        INSERT INTO vehicle_categories (name, base_rate, hourly_rate, description) 
        VALUES ('Car (Four Wheeler)', 10, 5, 'Standard car parking'),
               ('Bike (Two Wheeler)', 5, 2, 'Motorcycle parking')
        RETURNING id INTO cat_id;
    END IF;

    -- 3. Create a Worker if none exist
    SELECT id INTO wrk_id FROM users WHERE role = 'WORKER' LIMIT 1;
    IF wrk_id IS NULL THEN
        INSERT INTO users (name, email, password_hash, role, status)
        VALUES ('John Worker', 'john@parknova.com', 'dummy_hash_not_used', 'WORKER', 'ACTIVE')
        RETURNING id INTO wrk_id;
    END IF;

    -- 4. Generate 150 dummy parking sessions distributed over the last 30 days
    FOR i IN 1..150 LOOP
        -- Random day between 0 and 30 days ago
        sim_date := CURRENT_DATE - (floor(random() * 30)::INT);
        
        -- Random hour of the day (heavily weighted towards 9AM-11AM and 5PM-8PM for realistic heatmaps)
        IF random() < 0.4 THEN
            rand_hour := floor(random() * 3) + 8; -- 8 AM to 10 AM
        ELSIF random() < 0.8 THEN
            rand_hour := floor(random() * 4) + 16; -- 4 PM to 7 PM
        ELSE
            rand_hour := floor(random() * 24); -- Any other time
        END IF;

        -- Set exact entry time
        sim_date := sim_date + (rand_hour || ' hours')::INTERVAL + (floor(random() * 60) || ' minutes')::INTERVAL;

        -- Random duration between 1 to 5 hours
        rand_duration := floor(random() * 5) + 1;
        sim_exit := sim_date + (rand_duration || ' hours')::INTERVAL;

        -- Random amount between $15 and $60
        amount := floor(random() * 45) + 15;

        -- Insert the completed session
        INSERT INTO parking_sessions (
            ticket_number,
            parking_location_id,
            vehicle_category_id,
            created_by,
            closed_by,
            vehicle_number,
            entry_time,
            exit_time,
            status,
            total_amount,
            payment_status,
            created_at,
            updated_at
        ) VALUES (
            'TKT-' || floor(random() * 999999)::text || '-' || i::text,
            loc_id,
            cat_id,
            wrk_id,
            wrk_id,
            'SIM-' || lpad(floor(random() * 9999)::text, 4, '0'),
            sim_date,
            sim_exit,
            'COMPLETED',
            amount,
            'PAID',
            sim_date,
            sim_exit
        );
    END LOOP;

    -- 5. Important: We must refresh the materialized view so the Revenue Trend graph updates!
    REFRESH MATERIALIZED VIEW mv_daily_revenue;

END $$;
