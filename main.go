package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"stanford-uni-students-api/config"
	"stanford-uni-students-api/db"
	"stanford-uni-students-api/router"
)

func main() {
	// Load environment variables from .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Initialize configuration
	cfg := config.LoadConfig()

	// Initialize database
	database, err := db.InitDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// Run migrations
	if err := db.RunMigrations(database); err != nil {
		log.Printf("Failed to run migrations: %v", err)
		return
	}

	// Setup router
	r := router.SetupRouter(database)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}