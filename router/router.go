package router

import (
	"database/sql"

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