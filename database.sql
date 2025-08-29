-- Users Table (Profile Setup)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_type VARCHAR(20) NOT NULL DEFAULT 'renter' CHECK (user_type IN ('renter', 'landlord')),
    name VARCHAR(255) NOT NULL,
    passport_number VARCHAR(100),
    phone_number VARCHAR(50) NOT NULL,
    email_address VARCHAR(255) UNIQUE NOT NULL,
    suburb_city VARCHAR(255) NOT NULL,
    configuration_of_enrollment TEXT,
    profile_status VARCHAR(20) DEFAULT 'offline' CHECK (profile_status IN ('online', 'offline'))
);

-- User Preferences Table
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    language VARCHAR(50) DEFAULT 'English',
    max_distance_km INTEGER DEFAULT 10,
    utilities_included BOOLEAN DEFAULT false,
    special_considerations TEXT,
    allergies TEXT,
    accessibility_needs TEXT
);

-- Rental Listings Table (Established/Listed)
-- 3. Rental Listings Table (Established/Listed)
CREATE TABLE rental_listings (
    id SERIAL PRIMARY KEY,
    landlord_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- User with type 'landlord'
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    suburb_city VARCHAR(255) NOT NULL,
    
    -- Pricing and Availability
    price DECIMAL(10,2) NOT NULL,
    price_currency VARCHAR(3) DEFAULT 'USD',
    availability_date DATE, -- General availability date
    available_immediately BOOLEAN DEFAULT FALSE, -- TRUE if ready to move in now
    urgent_until TIMESTAMP, -- How long should this listing be shown in the "Urgent" section? (e.g., for next 48 hours)
    
    accessibility_features TEXT,
    special_considerations TEXT,
    
    -- Status and Management
    astetus VARCHAR(50) DEFAULT 'active' CHECK (astetus IN ('active', 'inactive', 'pending', 'rented')),
    point_reality_system_rating DECIMAL(3,2),
    technology_deadline DATE,
    chairman_approval_required BOOLEAN,
    vehicle_parking_available BOOLEAN,
    
    -- Media
    photo_urls TEXT[],
    video_url TEXT
);

-- Rental Types Table
CREATE TABLE rental_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- Rental Listing Types Junction Table
CREATE TABLE rental_listing_types (
    rental_listing_id INTEGER NOT NULL REFERENCES rental_listings(id) ON DELETE CASCADE,
    rental_type_id INTEGER NOT NULL REFERENCES rental_types(id) ON DELETE CASCADE,
    PRIMARY KEY (rental_listing_id, rental_type_id)
);


-- ###############################################
-- IMPORTANT: VIEW FOR URGENT LISTINGS
-- This view easily finds all listings that are currently marked as urgent and available.
-- ###############################################
CREATE VIEW vw_urgent_listings AS
SELECT 
    rl.*,
    u.name as landlord_name,
    u.phone_number as landlord_phone,
    u.profile_status as landlord_status
FROM rental_listings rl
JOIN users u ON rl.landlord_id = u.id
WHERE 
    rl.available_immediately = TRUE -- Must be available now
    AND rl.astetus = 'active' -- Listing must be active
    AND (rl.urgent_until IS NULL OR rl.urgent_until > CURRENT_TIMESTAMP) -- Urgency period hasn't expired
ORDER BY rl.created_at DESC;


-- Favorites Table
CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    renter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rental_listing_id INTEGER NOT NULL REFERENCES rental_listings(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(renter_id, rental_listing_id)
);


-- Indexes for better performance
CREATE INDEX idx_users_email ON users(email_address);
CREATE INDEX idx_users_city ON users(suburb_city);
CREATE INDEX idx_users_type ON users(user_type);

CREATE INDEX idx_rental_listings_city ON rental_listings(suburb_city);
CREATE INDEX idx_rental_listings_price ON rental_listings(price);
CREATE INDEX idx_rental_listings_status ON rental_listings(astetus);
CREATE INDEX idx_rental_listings_immediate ON rental_listings(available_immediately) WHERE available_immediately = TRUE;
CREATE INDEX idx_rental_listings_urgent_time ON rental_listings(urgent_until) WHERE available_immediately = TRUE;

CREATE INDEX idx_urgent_applications_status ON urgent_applications(status);
CREATE INDEX idx_favorites_renter ON favorites(renter_id);
