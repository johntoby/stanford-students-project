package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	// Test connection parameters
	host := "localhost"
	port := "5432"
	user := "stanley"
	password := "123456789"
	dbname := "postgres" // First try connecting to default postgres db

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	fmt.Printf("Testing connection with: %s\n", connStr)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to open connection: %v", err)
	}
	defer db.Close()

	if err = db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("✅ Successfully connected to PostgreSQL!")

	// Test if stanford_students database exists
	var exists bool
	err = db.QueryRow("SELECT EXISTS(SELECT datname FROM pg_catalog.pg_database WHERE datname = 'stanford_students')").Scan(&exists)
	if err != nil {
		log.Printf("Error checking if database exists: %v", err)
	} else if exists {
		fmt.Println("✅ stanford_students database exists")
		
		// Try connecting to stanford_students database
		connStr2 := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			host, port, user, password, "stanford_students")
		
		db2, err := sql.Open("postgres", connStr2)
		if err != nil {
			log.Printf("Failed to connect to stanford_students: %v", err)
		} else {
			defer db2.Close()
			if err = db2.Ping(); err != nil {
				log.Printf("Failed to ping stanford_students database: %v", err)
			} else {
				fmt.Println("✅ Successfully connected to stanford_students database!")
			}
		}
	} else {
		fmt.Println("❌ stanford_students database does not exist")
		fmt.Println("Creating stanford_students database...")
		
		_, err = db.Exec("CREATE DATABASE stanford_students")
		if err != nil {
			log.Printf("Failed to create database: %v", err)
		} else {
			fmt.Println("✅ stanford_students database created successfully!")
		}
	}
}