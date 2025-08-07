package db

import (
	"database/sql"
	"log"

	_ "github.com/lib/pq"
	"stanford-uni-students-api/config"
)

// InitDB initializes the database connection
func InitDB(cfg *config.Config) (*sql.DB, error) {
	connStr := cfg.GetDBConnectionString()
	log.Printf("Attempting to connect to database with connection string: %s", connStr)
	
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Printf("Failed to open database connection: %v", err)
		return nil, err
	}

	log.Println("Database connection opened, testing with ping...")
	if err = db.Ping(); err != nil {
		log.Printf("Database ping failed: %v", err)
		return nil, err
	}

	log.Println("Database connection established successfully")
	return db, nil
}

// RunMigrations runs database migrations
func RunMigrations(db *sql.DB) error {
	log.Println("Running migrations...")
	
	// Create students table if it doesn't exist
	_, err := db.Exec(`
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
		)
	`)
	
	if err != nil {
		return err
	}
	
	log.Println("Migrations completed successfully")
	return nil
}