-- Database initialization script
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    major VARCHAR(100) NOT NULL,
    gpa DECIMAL(3,2) CHECK (gpa >= 0.0 AND gpa <= 4.0),
    enrollment_date DATE,
    graduation_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data if table is empty
INSERT INTO students (first_name, last_name, email, major, gpa, enrollment_date, graduation_year)
SELECT 'John', 'Doe', 'john.doe@stanford.edu', 'Computer Science', 3.8, '2021-09-01', 2025
WHERE NOT EXISTS (SELECT 1 FROM students LIMIT 1);