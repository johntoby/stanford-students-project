package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"stanford-uni-students-api/models"
)

// MockStudentRepository is a mock implementation of StudentRepository
type MockStudentRepository struct {
	mock.Mock
}

func (m *MockStudentRepository) Create(student *models.Student) error {
	args := m.Called(student)
	student.ID = 1 // Simulate ID assignment
	return args.Error(0)
}

func (m *MockStudentRepository) GetAll() ([]models.Student, error) {
	args := m.Called()
	return args.Get(0).([]models.Student), args.Error(1)
}

func (m *MockStudentRepository) GetByID(id int) (*models.Student, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Student), args.Error(1)
}

func (m *MockStudentRepository) Update(student *models.Student) error {
	args := m.Called(student)
	return args.Error(0)
}

func (m *MockStudentRepository) Delete(id int) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockStudentRepository) HealthCheck() (int, error) {
	args := m.Called()
	return args.Int(0), args.Error(1)
}

func setupTestRouter() (*gin.Engine, *MockStudentRepository) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockRepo := new(MockStudentRepository)
	
	handler := &StudentHandler{repo: mockRepo}
	
	r.POST("/api/v1/students", handler.CreateStudent)
	r.GET("/api/v1/students", handler.GetAllStudents)
	r.GET("/api/v1/students/:id", handler.GetStudentByID)
	r.PUT("/api/v1/students/:id", handler.UpdateStudent)
	r.DELETE("/api/v1/students/:id", handler.DeleteStudent)
	r.GET("/healthcheck", handler.HealthCheck)
	
	return r, mockRepo
}

func TestCreateStudent(t *testing.T) {
	r, mockRepo := setupTestRouter()
	
	// Setup mock
	mockRepo.On("Create", mock.AnythingOfType("*models.Student")).Return(nil)
	
	// Create test request
	student := models.Student{
		FirstName: "John",
		LastName:  "Doe",
		Email:     "john.doe@stanford.edu",
		Major:     "Computer Science",
		GPA:       3.8,
	}
	
	jsonValue, _ := json.Marshal(student)
	req, _ := http.NewRequest("POST", "/api/v1/students", bytes.NewBuffer(jsonValue))
	w := httptest.NewRecorder()
	
	// Perform request
	r.ServeHTTP(w, req)
	
	// Assert
	assert.Equal(t, http.StatusCreated, w.Code)
	mockRepo.AssertExpectations(t)
	
	// Verify response
	var response models.Student
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, 1, response.ID)
	assert.Equal(t, student.FirstName, response.FirstName)
	assert.Equal(t, student.LastName, response.LastName)
}

func TestGetAllStudents(t *testing.T) {
	r, mockRepo := setupTestRouter()
	
	// Setup mock
	students := []models.Student{
		{ID: 1, FirstName: "John", LastName: "Doe", Email: "john.doe@stanford.edu", Major: "Computer Science"},
		{ID: 2, FirstName: "Jane", LastName: "Smith", Email: "jane.smith@stanford.edu", Major: "Computer Science"},
	}
	mockRepo.On("GetAll").Return(students, nil)
	
	// Create test request
	req, _ := http.NewRequest("GET", "/api/v1/students", nil)
	w := httptest.NewRecorder()
	
	// Perform request
	r.ServeHTTP(w, req)
	
	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	mockRepo.AssertExpectations(t)
	
	// Verify response
	var response []models.Student
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Len(t, response, 2)
	assert.Equal(t, students[0].ID, response[0].ID)
	assert.Equal(t, students[1].ID, response[1].ID)
}

func TestGetStudentByID(t *testing.T) {
	r, mockRepo := setupTestRouter()
	
	// Setup mock
	student := &models.Student{ID: 1, FirstName: "John", LastName: "Doe", Email: "john.doe@stanford.edu", Major: "Computer Science"}
	mockRepo.On("GetByID", 1).Return(student, nil)
	
	// Create test request
	req, _ := http.NewRequest("GET", "/api/v1/students/1", nil)
	w := httptest.NewRecorder()
	
	// Perform request
	r.ServeHTTP(w, req)
	
	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	mockRepo.AssertExpectations(t)
	
	// Verify response
	var response models.Student
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, student.ID, response.ID)
	assert.Equal(t, student.FirstName, response.FirstName)
}

func TestHealthCheck(t *testing.T) {
	r, mockRepo := setupTestRouter()
	
	// Setup mock
	mockRepo.On("HealthCheck").Return(5, nil)
	
	// Create test request
	req, _ := http.NewRequest("GET", "/healthcheck", nil)
	w := httptest.NewRecorder()
	
	// Perform request
	r.ServeHTTP(w, req)
	
	// Assert
	assert.Equal(t, http.StatusOK, w.Code)
	mockRepo.AssertExpectations(t)
	
	// Verify response
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "ok", response["status"])
	assert.Equal(t, "API is running", response["message"])
	assert.Equal(t, "connected", response["database"])
	assert.Equal(t, float64(5), response["total_students"])
}