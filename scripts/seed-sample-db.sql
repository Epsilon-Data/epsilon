
-- Drop existing tables
DROP TABLE IF EXISTS student_subject CASCADE;
DROP TABLE IF EXISTS subject CASCADE;
DROP TABLE IF EXISTS student CASCADE;
DROP TABLE IF EXISTS university CASCADE;

-- Universities
CREATE TABLE university (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(255) NOT NULL,
    country      VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    founded_year INTEGER,
    website      VARCHAR(255),
    created_at   TIMESTAMP DEFAULT NOW()
);

-- Students
CREATE TABLE student (
    id              SERIAL PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    date_of_birth   DATE,
    enrollment_year INTEGER NOT NULL,
    university_id   INTEGER NOT NULL REFERENCES university ON DELETE CASCADE,
    created_at      TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_student_university ON student(university_id);

-- Subjects
CREATE TABLE subject (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    code          VARCHAR(20) NOT NULL UNIQUE,
    credits       INTEGER DEFAULT 3 NOT NULL,
    department    VARCHAR(100),
    university_id INTEGER NOT NULL REFERENCES university ON DELETE CASCADE,
    created_at    TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_subject_university ON subject(university_id);

-- Student-Subject enrollment
CREATE TABLE student_subject (
    student_id INTEGER NOT NULL REFERENCES student ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES subject ON DELETE CASCADE,
    grade      VARCHAR(2),
    semester   VARCHAR(20) NOT NULL,
    PRIMARY KEY (student_id, subject_id, semester)
);
CREATE INDEX idx_student_subject_student ON student_subject(student_id);
CREATE INDEX idx_student_subject_subject ON student_subject(subject_id);



-- Universities
INSERT INTO university (name, country, city, founded_year, website) VALUES
('Monash University', 'Australia', 'Melbourne', 1958, 'https://www.monash.edu'),
('ETH Zurich', 'Switzerland', 'Zurich', 1855, 'https://ethz.ch'),
('MIT', 'United States', 'Cambridge', 1861, 'https://www.mit.edu'),
('University of Edinburgh', 'United Kingdom', 'Edinburgh', 1583, 'https://www.ed.ac.uk'),
('National University of Singapore', 'Singapore', 'Singapore', 1905, 'https://www.nus.edu.sg');

-- Students (50 students across 5 universities)
INSERT INTO student (first_name, last_name, email, date_of_birth, enrollment_year, university_id) VALUES
('Alice', 'Chen', 'alice.chen@monash.edu', '2000-03-15', 2022, 1),
('Bob', 'Smith', 'bob.smith@monash.edu', '2001-07-22', 2023, 1),
('Carol', 'Wang', 'carol.wang@monash.edu', '1999-11-08', 2021, 1),
('David', 'Kumar', 'david.kumar@monash.edu', '2000-05-30', 2022, 1),
('Emma', 'Liu', 'emma.liu@monash.edu', '2001-01-14', 2023, 1),
('Frank', 'Taylor', 'frank.taylor@monash.edu', '1998-09-25', 2020, 1),
('Grace', 'Nguyen', 'grace.nguyen@monash.edu', '2000-12-03', 2022, 1),
('Henry', 'Brown', 'henry.brown@monash.edu', '2001-04-17', 2023, 1),
('Isabel', 'Garcia', 'isabel.garcia@monash.edu', '1999-08-21', 2021, 1),
('James', 'Wilson', 'james.wilson@monash.edu', '2000-06-09', 2022, 1),
('Klaus', 'Mueller', 'klaus.mueller@ethz.ch', '2000-02-11', 2022, 2),
('Laura', 'Schmidt', 'laura.schmidt@ethz.ch', '2001-10-05', 2023, 2),
('Marco', 'Rossi', 'marco.rossi@ethz.ch', '1999-04-28', 2021, 2),
('Nina', 'Weber', 'nina.weber@ethz.ch', '2000-08-16', 2022, 2),
('Oliver', 'Fischer', 'oliver.fischer@ethz.ch', '2001-03-07', 2023, 2),
('Petra', 'Keller', 'petra.keller@ethz.ch', '1998-12-20', 2020, 2),
('Ralf', 'Braun', 'ralf.braun@ethz.ch', '2000-07-13', 2022, 2),
('Sophie', 'Huber', 'sophie.huber@ethz.ch', '2001-06-01', 2023, 2),
('Thomas', 'Meier', 'thomas.meier@ethz.ch', '1999-01-25', 2021, 2),
('Ursula', 'Wolf', 'ursula.wolf@ethz.ch', '2000-11-18', 2022, 2),
('Alex', 'Johnson', 'alex.johnson@mit.edu', '2000-05-03', 2022, 3),
('Beth', 'Davis', 'beth.davis@mit.edu', '2001-09-14', 2023, 3),
('Chris', 'Martinez', 'chris.martinez@mit.edu', '1999-02-27', 2021, 3),
('Diana', 'Anderson', 'diana.anderson@mit.edu', '2000-10-09', 2022, 3),
('Eric', 'Thompson', 'eric.thompson@mit.edu', '2001-01-30', 2023, 3),
('Fiona', 'White', 'fiona.white@mit.edu', '1998-06-22', 2020, 3),
('George', 'Harris', 'george.harris@mit.edu', '2000-04-05', 2022, 3),
('Hannah', 'Clark', 'hannah.clark@mit.edu', '2001-08-19', 2023, 3),
('Ian', 'Lewis', 'ian.lewis@mit.edu', '1999-12-11', 2021, 3),
('Julia', 'Lee', 'julia.lee@mit.edu', '2000-03-24', 2022, 3),
('Kyle', 'MacLeod', 'kyle.macleod@ed.ac.uk', '2000-07-08', 2022, 4),
('Lucy', 'Campbell', 'lucy.campbell@ed.ac.uk', '2001-11-20', 2023, 4),
('Mark', 'Stewart', 'mark.stewart@ed.ac.uk', '1999-05-15', 2021, 4),
('Nora', 'Robertson', 'nora.robertson@ed.ac.uk', '2000-09-02', 2022, 4),
('Owen', 'Murray', 'owen.murray@ed.ac.uk', '2001-02-18', 2023, 4),
('Pam', 'Watson', 'pam.watson@ed.ac.uk', '1998-10-30', 2020, 4),
('Quinn', 'Fraser', 'quinn.fraser@ed.ac.uk', '2000-01-07', 2022, 4),
('Rachel', 'Douglas', 'rachel.douglas@ed.ac.uk', '2001-07-25', 2023, 4),
('Sean', 'Hamilton', 'sean.hamilton@ed.ac.uk', '1999-06-13', 2021, 4),
('Tara', 'Gordon', 'tara.gordon@ed.ac.uk', '2000-12-28', 2022, 4),
('Wei', 'Tan', 'wei.tan@nus.edu.sg', '2000-04-19', 2022, 5),
('Xin', 'Lim', 'xin.lim@nus.edu.sg', '2001-08-06', 2023, 5),
('Yuki', 'Sato', 'yuki.sato@nus.edu.sg', '1999-03-11', 2021, 5),
('Zara', 'Ahmad', 'zara.ahmad@nus.edu.sg', '2000-10-23', 2022, 5),
('Amir', 'Hassan', 'amir.hassan@nus.edu.sg', '2001-05-17', 2023, 5),
('Bao', 'Tran', 'bao.tran@nus.edu.sg', '1998-11-09', 2020, 5),
('Chandra', 'Patel', 'chandra.patel@nus.edu.sg', '2000-02-26', 2022, 5),
('Devi', 'Singh', 'devi.singh@nus.edu.sg', '2001-06-14', 2023, 5),
('Eko', 'Wijaya', 'eko.wijaya@nus.edu.sg', '1999-09-30', 2021, 5),
('Fatima', 'Ali', 'fatima.ali@nus.edu.sg', '2000-01-20', 2022, 5);

-- Subjects (across universities)
INSERT INTO subject (name, code, credits, department, university_id) VALUES
('Data Science', 'FIT5201', 6, 'Information Technology', 1),
('Cybersecurity', 'FIT5163', 6, 'Information Technology', 1),
('Machine Learning', 'FIT5202', 6, 'Information Technology', 1),
('Software Engineering', 'FIT5136', 6, 'Information Technology', 1),
('Computer Networks', 'FIT5047', 6, 'Information Technology', 1),
('Algorithms', 'CS401', 8, 'Computer Science', 2),
('Cryptography', 'CS407', 8, 'Computer Science', 2),
('Distributed Systems', 'CS455', 8, 'Computer Science', 2),
('Machine Learning', 'CS450', 8, 'Computer Science', 2),
('Data Structures', 'CS201', 8, 'Computer Science', 2),
('Introduction to CS', '6.100A', 12, 'EECS', 3),
('Algorithms', '6.1210', 12, 'EECS', 3),
('Machine Learning', '6.3900', 12, 'EECS', 3),
('Computer Security', '6.5660', 12, 'EECS', 3),
('Distributed Systems', '6.5840', 12, 'EECS', 3),
('Informatics', 'INF1A', 20, 'Informatics', 4),
('Computer Security', 'INF3C', 20, 'Informatics', 4),
('Machine Learning', 'INF4M', 20, 'Informatics', 4),
('Databases', 'INF3D', 20, 'Informatics', 4),
('Data Science', 'CS5228', 4, 'Computing', 5),
('Cybersecurity', 'CS5231', 4, 'Computing', 5),
('Distributed Systems', 'CS5223', 4, 'Computing', 5),
('Machine Learning', 'CS5242', 4, 'Computing', 5);

-- Enrollments (each student takes 3-4 subjects)
INSERT INTO student_subject (student_id, subject_id, grade, semester) VALUES
(1, 1, 'HD', '2022-S1'), (1, 2, 'D', '2022-S1'), (1, 3, 'HD', '2022-S2'),
(2, 1, 'C', '2023-S1'), (2, 4, 'D', '2023-S1'), (2, 5, 'C', '2023-S2'),
(3, 2, 'HD', '2021-S1'), (3, 3, 'D', '2021-S2'), (3, 1, 'HD', '2021-S2'),
(4, 1, 'D', '2022-S1'), (4, 3, 'C', '2022-S2'), (4, 5, 'D', '2022-S2'),
(5, 2, 'P', '2023-S1'), (5, 4, 'C', '2023-S1'), (5, 1, 'D', '2023-S2'),
(6, 3, 'HD', '2020-S1'), (6, 5, 'HD', '2020-S2'),
(7, 1, 'D', '2022-S1'), (7, 2, 'D', '2022-S2'),
(8, 4, 'C', '2023-S1'), (8, 5, 'P', '2023-S2'),
(9, 1, 'HD', '2021-S1'), (9, 3, 'HD', '2021-S2'),
(10, 2, 'D', '2022-S1'), (10, 4, 'C', '2022-S2'),
(11, 6, 'A', '2022-HS'), (11, 7, 'B', '2022-HS'), (11, 8, 'A', '2022-FS'),
(12, 6, 'B', '2023-HS'), (12, 9, 'A', '2023-HS'),
(13, 7, 'A', '2021-HS'), (13, 10, 'B', '2021-FS'),
(14, 8, 'C', '2022-HS'), (14, 9, 'B', '2022-FS'),
(15, 6, 'A', '2023-HS'), (15, 10, 'A', '2023-FS'),
(21, 11, 'A', '2022-Fall'), (21, 12, 'B', '2022-Fall'), (21, 13, 'A', '2023-Spring'),
(22, 11, 'B', '2023-Fall'), (22, 14, 'A', '2023-Fall'),
(23, 12, 'A', '2021-Fall'), (23, 15, 'B', '2021-Spring'),
(24, 13, 'B', '2022-Fall'), (24, 14, 'A', '2022-Spring'),
(25, 11, 'A', '2023-Fall'), (25, 15, 'B', '2023-Spring'),
(31, 16, 'A', '2022-S1'), (31, 17, 'B', '2022-S1'),
(32, 16, 'B', '2023-S1'), (32, 18, 'A', '2023-S2'),
(33, 17, 'A', '2021-S1'), (33, 19, 'B', '2021-S2'),
(41, 20, 'A', '2022-S1'), (41, 21, 'B', '2022-S1'), (41, 22, 'A', '2022-S2'),
(42, 20, 'B', '2023-S1'), (42, 23, 'A', '2023-S1'),
(43, 21, 'A', '2021-S1'), (43, 22, 'B', '2021-S2'),
(44, 20, 'A', '2022-S1'), (44, 23, 'B', '2022-S2'),
(45, 21, 'B', '2023-S1'), (45, 22, 'A', '2023-S2');


