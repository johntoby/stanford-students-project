package router

import (
	"database/sql"
	"net/http"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"stanford-uni-students-api/handlers"
	"stanford-uni-students-api/middleware"
)

// SetupRouter configures the API routes
func SetupRouter(db *sql.DB) *gin.Engine {
	r := gin.New()
	
	// Use middleware
	r.Use(gin.Recovery())
	r.Use(middleware.Logger())
	
	// CORS middleware
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"*"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))
	
	// Serve static files
	r.Static("/static", "./frontend")
	r.StaticFile("/", "./frontend/index.html")
	
	// Create handlers
	studentHandler := handlers.NewStudentHandler(db)
	
	// Health check endpoint
	r.GET("/healthcheck", studentHandler.HealthCheck)
	
	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		students := v1.Group("/students")
		{
			students.POST("", studentHandler.CreateStudent)
			students.GET("", studentHandler.GetAllStudents)
			students.GET("/:id", studentHandler.GetStudentByID)
			students.PUT("/:id", studentHandler.UpdateStudent)
			students.DELETE("/:id", studentHandler.DeleteStudent)
		}
	}
	
	return r
}