package models

import (
	"database/sql"
	"time"
)

// Student represents a student entity
type Student struct {
	ID             int       `json:"id"`
	FirstName      string    `json:"first_name" binding:"required"`
	LastName       string    `json:"last_name" binding:"required"`
	Email          string    `json:"email" binding:"required,email"`
	Major          string    `json:"major" binding:"required"`
	GPA            float64   `json:"gpa" binding:"omitempty,min=0,max=4"`
	EnrollmentDate time.Time `json:"enrollment_date,omitempty"`
	GraduationYear int       `json:"graduation_year,omitempty"`
	CreatedAt      time.Time `json:"created_at,omitempty"`
	UpdatedAt      time.Time `json:"updated_at,omitempty"`
}

// StudentRepository defines the interface for student data operations
type StudentRepository interface {
	Create(student *Student) error
	GetAll() ([]Student, error)
	GetByID(id int) (*Student, error)
	Update(student *Student) error
	Delete(id int) error
}

// PostgresStudentRepository implements StudentRepository for PostgreSQL
type PostgresStudentRepository struct {
	DB *sql.DB
}

// NewPostgresStudentRepository creates a new PostgresStudentRepository
func NewPostgresStudentRepository(db *sql.DB) *PostgresStudentRepository {
	return &PostgresStudentRepository{DB: db}
}

// Create adds a new student to the database
func (r *PostgresStudentRepository) Create(student *Student) error {
	query := `
		INSERT INTO students (first_name, last_name, email, major, gpa, enrollment_date, graduation_year)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`
	
	return r.DB.QueryRow(
		query,
		student.FirstName,
		student.LastName,
		student.Email,
		student.Major,
		student.GPA,
		student.EnrollmentDate,
		student.GraduationYear,
	).Scan(&student.ID, &student.CreatedAt, &student.UpdatedAt)
}

// GetAll retrieves all students from the database
func (r *PostgresStudentRepository) GetAll() ([]Student, error) {
	query := `
		SELECT id, first_name, last_name, email, major, gpa, enrollment_date, graduation_year, created_at, updated_at
		FROM students
		ORDER BY id
	`
	
	rows, err := r.DB.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	var students []Student
	for rows.Next() {
		var s Student
		var enrollmentDate, createdAt, updatedAt sql.NullTime
		var gpa sql.NullFloat64
		var graduationYear sql.NullInt32
		
		if err := rows.Scan(
			&s.ID,
			&s.FirstName,
			&s.LastName,
			&s.Email,
			&s.Major,
			&gpa,
			&enrollmentDate,
			&graduationYear,
			&createdAt,
			&updatedAt,
		); err != nil {
			return nil, err
		}
		
		if gpa.Valid {
			s.GPA = gpa.Float64
		}
		if enrollmentDate.Valid {
			s.EnrollmentDate = enrollmentDate.Time
		}
		if graduationYear.Valid {
			s.GraduationYear = int(graduationYear.Int32)
		}
		if createdAt.Valid {
			s.CreatedAt = createdAt.Time
		}
		if updatedAt.Valid {
			s.UpdatedAt = updatedAt.Time
		}
		
		students = append(students, s)
	}
	
	return students, nil
}

// GetByID retrieves a student by ID from the database
func (r *PostgresStudentRepository) GetByID(id int) (*Student, error) {
	query := `
		SELECT id, first_name, last_name, email, major, gpa, enrollment_date, graduation_year, created_at, updated_at
		FROM students
		WHERE id = $1
	`
	
	var s Student
	var enrollmentDate, createdAt, updatedAt sql.NullTime
	var gpa sql.NullFloat64
	var graduationYear sql.NullInt32
	
	err := r.DB.QueryRow(query, id).Scan(
		&s.ID,
		&s.FirstName,
		&s.LastName,
		&s.Email,
		&s.Major,
		&gpa,
		&enrollmentDate,
		&graduationYear,
		&createdAt,
		&updatedAt,
	)
	
	if err != nil {
		return nil, err
	}
	
	if gpa.Valid {
		s.GPA = gpa.Float64
	}
	if enrollmentDate.Valid {
		s.EnrollmentDate = enrollmentDate.Time
	}
	if graduationYear.Valid {
		s.GraduationYear = int(graduationYear.Int32)
	}
	if createdAt.Valid {
		s.CreatedAt = createdAt.Time
	}
	if updatedAt.Valid {
		s.UpdatedAt = updatedAt.Time
	}
	
	return &s, nil
}

// Update updates an existing student in the database
func (r *PostgresStudentRepository) Update(student *Student) error {
	query := `
		UPDATE students
		SET first_name = $1, last_name = $2, email = $3, major = $4, gpa = $5, 
			enrollment_date = $6, graduation_year = $7, updated_at = CURRENT_TIMESTAMP
		WHERE id = $8
		RETURNING updated_at
	`
	
	return r.DB.QueryRow(
		query,
		student.FirstName,
		student.LastName,
		student.Email,
		student.Major,
		student.GPA,
		student.EnrollmentDate,
		student.GraduationYear,
		student.ID,
	).Scan(&student.UpdatedAt)
}

// Delete removes a student from the database
func (r *PostgresStudentRepository) Delete(id int) error {
	query := `DELETE FROM students WHERE id = $1`
	_, err := r.DB.Exec(query, id)
	return err
}