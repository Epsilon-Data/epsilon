-- Epsilon Demo Database Seed Script
-- Creates 5 relational tables with ~1000 rows of synthetic health data
-- Usage: psql -h localhost -U postgres -d epsilon_demo -f seed-demo-db.sql

-- Drop existing tables if they exist
DROP TABLE IF EXISTS observations CASCADE;
DROP TABLE IF EXISTS encounters CASCADE;
DROP TABLE IF EXISTS medications CASCADE;
DROP TABLE IF EXISTS conditions CASCADE;
DROP TABLE IF EXISTS patients CASCADE;

-- Table 1: patients (200 rows)
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    blood_type VARCHAR(5),
    region VARCHAR(20) NOT NULL,
    education_level VARCHAR(20),
    smoking_status VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table 2: encounters (400 rows, ~2 per patient)
CREATE TABLE encounters (
    encounter_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    encounter_date DATE NOT NULL,
    encounter_type VARCHAR(30) NOT NULL,
    facility VARCHAR(50) NOT NULL,
    duration_minutes INTEGER,
    notes TEXT
);

-- Table 3: observations (600 rows, vitals per encounter)
CREATE TABLE observations (
    observation_id SERIAL PRIMARY KEY,
    encounter_id INTEGER REFERENCES encounters(encounter_id),
    patient_id INTEGER REFERENCES patients(patient_id),
    observation_type VARCHAR(30) NOT NULL,
    value_numeric DECIMAL(10,2),
    value_text VARCHAR(100),
    unit VARCHAR(20),
    observed_at TIMESTAMP NOT NULL
);

-- Table 4: conditions (300 rows, diagnoses)
CREATE TABLE conditions (
    condition_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    encounter_id INTEGER REFERENCES encounters(encounter_id),
    condition_code VARCHAR(10) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    severity VARCHAR(15),
    onset_date DATE,
    resolved_date DATE
);

-- Table 5: medications (200 rows)
CREATE TABLE medications (
    medication_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id),
    condition_id INTEGER REFERENCES conditions(condition_id),
    medication_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(50),
    frequency VARCHAR(30),
    start_date DATE NOT NULL,
    end_date DATE,
    active BOOLEAN DEFAULT true
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Seed patients (200 rows)
INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_type, region, education_level, smoking_status)
SELECT
    'Patient' || n,
    'Family' || (n % 50 + 1),
    DATE '1940-01-01' + (random() * 30000)::int,
    CASE WHEN random() < 0.5 THEN 'Male' ELSE 'Female' END,
    (ARRAY['A+','A-','B+','B-','AB+','AB-','O+','O-'])[floor(random()*8+1)],
    (ARRAY['North','South','East','West','Central'])[floor(random()*5+1)],
    (ARRAY['None','Primary','Secondary','Tertiary'])[floor(random()*4+1)],
    (ARRAY['never','former','current'])[floor(random()*3+1)]
FROM generate_series(1, 200) AS n;

-- Seed encounters (400 rows)
INSERT INTO encounters (patient_id, encounter_date, encounter_type, facility, duration_minutes, notes)
SELECT
    (n % 200) + 1,
    DATE '2020-01-01' + (random() * 2000)::int,
    (ARRAY['Outpatient','Inpatient','Emergency','Telehealth'])[floor(random()*4+1)],
    'Facility ' || (n % 10 + 1),
    15 + floor(random() * 120),
    'Routine visit notes for encounter ' || n
FROM generate_series(1, 400) AS n;

-- Seed observations (600 rows)
INSERT INTO observations (encounter_id, patient_id, observation_type, value_numeric, value_text, unit, observed_at)
SELECT
    (n % 400) + 1,
    ((n % 400) % 200) + 1,
    obs_type,
    CASE obs_type
        WHEN 'heart_rate' THEN 60 + floor(random() * 40)
        WHEN 'blood_pressure_sys' THEN 100 + floor(random() * 60)
        WHEN 'blood_pressure_dia' THEN 60 + floor(random() * 40)
        WHEN 'temperature' THEN 36.0 + (random() * 2.5)::numeric(4,1)
        WHEN 'bmi' THEN 18.0 + (random() * 20)::numeric(4,1)
        WHEN 'glucose' THEN 70 + floor(random() * 80)
    END,
    NULL,
    CASE obs_type
        WHEN 'heart_rate' THEN 'bpm'
        WHEN 'blood_pressure_sys' THEN 'mmHg'
        WHEN 'blood_pressure_dia' THEN 'mmHg'
        WHEN 'temperature' THEN '°C'
        WHEN 'bmi' THEN 'kg/m²'
        WHEN 'glucose' THEN 'mg/dL'
    END,
    NOW() - (random() * 730)::int * INTERVAL '1 day'
FROM generate_series(1, 100) AS n,
     unnest(ARRAY['heart_rate','blood_pressure_sys','blood_pressure_dia','temperature','bmi','glucose']) AS obs_type;

-- Seed conditions (300 rows)
INSERT INTO conditions (patient_id, encounter_id, condition_code, condition_name, severity, onset_date, resolved_date)
SELECT
    (n % 200) + 1,
    (n % 400) + 1,
    (ARRAY['E11','I10','J06','M54','F32','E78','J45','K21','G43','N39'])[floor(random()*10+1)],
    (ARRAY['Type 2 Diabetes','Hypertension','Upper Respiratory Infection','Low Back Pain','Depression','Hyperlipidemia','Asthma','GERD','Migraine','UTI'])[floor(random()*10+1)],
    (ARRAY['Mild','Moderate','Severe'])[floor(random()*3+1)],
    DATE '2018-01-01' + (random() * 2500)::int,
    CASE WHEN random() < 0.4 THEN DATE '2024-01-01' + (random() * 500)::int ELSE NULL END
FROM generate_series(1, 300) AS n;

-- Seed medications (200 rows)
INSERT INTO medications (patient_id, condition_id, medication_name, dosage, frequency, start_date, end_date, active)
SELECT
    (n % 200) + 1,
    (n % 300) + 1,
    (ARRAY['Metformin','Lisinopril','Amoxicillin','Ibuprofen','Sertraline','Atorvastatin','Albuterol','Omeprazole','Sumatriptan','Ciprofloxacin'])[floor(random()*10+1)],
    (ARRAY['5mg','10mg','20mg','50mg','100mg','250mg','500mg'])[floor(random()*7+1)],
    (ARRAY['Once daily','Twice daily','Three times daily','As needed'])[floor(random()*4+1)],
    DATE '2022-01-01' + (random() * 1000)::int,
    CASE WHEN random() < 0.3 THEN DATE '2025-01-01' + (random() * 365)::int ELSE NULL END,
    random() > 0.3
FROM generate_series(1, 200) AS n;

-- Summary
SELECT 'patients' AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL SELECT 'observations', COUNT(*) FROM observations
UNION ALL SELECT 'conditions', COUNT(*) FROM conditions
UNION ALL SELECT 'medications', COUNT(*) FROM medications
ORDER BY table_name;
