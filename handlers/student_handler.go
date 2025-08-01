package handlers

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"stanford-uni-students-api/models"
)

// StudentHandler handles HTTP requests for students
type StudentHandler struct {
	repo models.StudentRepository
}

// NewStudentHandler creates a new StudentHandler
func NewStudentHandler(db *sql.DB) *StudentHandler {
	return &StudentHandler{
		repo: models.NewPostgresStudentRepository(db),
	}
}

// CreateStudent handles POST requests to create a new student
func (h *StudentHandler) CreateStudent(c *gin.Context) {
	log.Printf("Received POST request to create student")
	
	var student models.Student
	if err := c.ShouldBindJSON(&student); err != nil {
		log.Printf("Error binding JSON: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	log.Printf("Parsed student data: %+v", student)

	if err := h.repo.Create(&student); err != nil {
		log.Printf("Error creating student in database: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create student"})
		return
	}
	
	log.Printf("Student created successfully with ID: %d", student.ID)
	c.JSON(http.StatusCreated, student)
}

// GetAllStudents handles GET requests to retrieve all students
func (h *StudentHandler) GetAllStudents(c *gin.Context) {
	students, err := h.repo.GetAll()
	if err != nil {
		log.Printf("Error getting all students: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve students"})
		return
	}

	c.JSON(http.StatusOK, students)
}

// GetStudentByID handles GET requests to retrieve a student by ID
func (h *StudentHandler) GetStudentByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid student ID"})
		return
	}

	student, err := h.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Student not found"})
			return
		}
		log.Printf("Error getting student by ID: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve student"})
		return
	}

	c.JSON(http.StatusOK, student)
}

// UpdateStudent handles PUT requests to update a student
func (h *StudentHandler) UpdateStudent(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid student ID"})
		return
	}

	// Check if student exists
	_, err = h.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Student not found"})
			return
		}
		log.Printf("Error checking student existence: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve student"})
		return
	}

	var student models.Student
	if err := c.ShouldBindJSON(&student); err != nil {
		log.Printf("Error binding JSON: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	student.ID = id
	if err := h.repo.Update(&student); err != nil {
		log.Printf("Error updating student: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update student"})
		return
	}

	c.JSON(http.StatusOK, student)
}

// DeleteStudent handles DELETE requests to remove a student
func (h *StudentHandler) DeleteStudent(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid student ID"})
		return
	}

	// Check if student exists
	_, err = h.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Student not found"})
			return
		}
		log.Printf("Error checking student existence: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve student"})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		log.Printf("Error deleting student: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete student"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Student deleted successfully"})
}

// HealthCheck handles GET requests to check API health
func (h *StudentHandler) HealthCheck(c *gin.Context) {
	// Test database connection
	var dbStatus string
	var count int
	err := h.repo.(*models.PostgresStudentRepository).DB.QueryRow("SELECT COUNT(*) FROM students").Scan(&count)
	if err != nil {
		dbStatus = "disconnected"
		log.Printf("Database health check failed: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status": "error",
			"message": "API is running but database is not accessible",
			"database": dbStatus,
		})
		return
	}
	
	dbStatus = "connected"
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"message": "API is running",
		"database": dbStatus,
		"total_students": count,
	})
}