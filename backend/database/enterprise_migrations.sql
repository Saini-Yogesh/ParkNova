-- Enterprise Dashboard Migrations

-- 1. Materialized View for Daily Revenue
DROP MATERIALIZED VIEW IF EXISTS mv_daily_revenue CASCADE;
CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT 
    DATE(exit_time) as revenue_date,
    parking_location_id,
    vehicle_categories.name as category_name,
    SUM(total_amount) as total_revenue,
    COUNT(parking_sessions.id) as total_transactions
FROM parking_sessions
JOIN vehicle_categories ON parking_sessions.vehicle_category_id = vehicle_categories.id
WHERE status = 'COMPLETED'
GROUP BY DATE(exit_time), parking_location_id, vehicle_categories.name;

-- Create index for fast querying
CREATE UNIQUE INDEX idx_mv_daily_revenue ON mv_daily_revenue(revenue_date, parking_location_id, category_name);

-- 2. Function to refresh Materialized Views (Can be triggered via cron or API)
CREATE OR REPLACE FUNCTION refresh_enterprise_mvs()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue;
END;
$$ LANGUAGE plpgsql;

-- 3. RPC for Executive Summary
CREATE OR REPLACE FUNCTION fn_get_executive_summary()
RETURNS json AS $$
DECLARE
    total_locs int;
    total_emps int;
    total_trans int;
    rev_today numeric;
    rev_week numeric;
    rev_month numeric;
BEGIN
    SELECT COUNT(*) INTO total_locs FROM parking_locations;
    SELECT COUNT(*) INTO total_emps FROM users WHERE role = 'WORKER';
    SELECT COUNT(*) INTO total_trans FROM parking_sessions WHERE status = 'COMPLETED';
    
    SELECT COALESCE(SUM(total_amount), 0) INTO rev_today FROM parking_sessions 
    WHERE status = 'COMPLETED' AND DATE(exit_time) = CURRENT_DATE;

    SELECT COALESCE(SUM(total_amount), 0) INTO rev_week FROM parking_sessions 
    WHERE status = 'COMPLETED' AND exit_time >= date_trunc('week', CURRENT_DATE);

    SELECT COALESCE(SUM(total_amount), 0) INTO rev_month FROM parking_sessions 
    WHERE status = 'COMPLETED' AND exit_time >= date_trunc('month', CURRENT_DATE);

    RETURN json_build_object(
        'totalLocations', total_locs,
        'totalEmployees', total_emps,
        'totalTransactions', total_trans,
        'revenueToday', rev_today,
        'revenueThisWeek', rev_week,
        'revenueThisMonth', rev_month
    );
END;
$$ LANGUAGE plpgsql;

-- 4. RPC for Peak Heatmap
CREATE OR REPLACE FUNCTION fn_get_peak_heatmap()
RETURNS json AS $$
DECLARE
    result json;
BEGIN
    SELECT json_agg(row_to_json(t)) INTO result
    FROM (
        SELECT 
            EXTRACT(DOW FROM entry_time) as day_of_week,
            EXTRACT(HOUR FROM entry_time) as hour_of_day,
            COUNT(*) as activity_count
        FROM parking_sessions
        GROUP BY 1, 2
        ORDER BY 1, 2
    ) t;
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql;

-- 5. RPC for Employee Performance
CREATE OR REPLACE FUNCTION fn_get_employee_performance()
RETURNS json AS $$
DECLARE
    result json;
BEGIN
    SELECT json_agg(row_to_json(t)) INTO result
    FROM (
        SELECT 
            u.name as employee_name,
            COUNT(s.id) as tasks_processed,
            COALESCE(SUM(s.total_amount), 0) as revenue_generated
        FROM users u
        LEFT JOIN parking_sessions s ON u.id = s.created_by AND s.status = 'COMPLETED'
        WHERE u.role = 'WORKER'
        GROUP BY u.id, u.name
        ORDER BY revenue_generated DESC
    ) t;
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql;
