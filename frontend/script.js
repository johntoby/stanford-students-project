const API_BASE_URL = 'http://localhost:8080/api/v1';

// Tab functionality
function showTab(tabName) {
    const tabs = document.querySelectorAll('.tab-content');
    const buttons = document.querySelectorAll('.tab-button');
    
    tabs.forEach(tab => tab.classList.remove('active'));
    buttons.forEach(button => button.classList.remove('active'));
    
    document.getElementById(tabName).classList.add('active');
    event.target.classList.add('active');
    
    if (tabName === 'students-list') {
        loadStudents();
    }
}

// Load all students
async function loadStudents() {
    const container = document.getElementById('students-container');
    container.innerHTML = '<div class="loading">Loading students...</div>';
    
    try {
        const response = await fetch(`${API_BASE_URL}/students`);
        const students = await response.json();
        
        if (students.length === 0) {
            container.innerHTML = '<p>No students found. Add some students to get started!</p>';
            return;
        }
        
        container.innerHTML = students.map(student => `
            <div class="student-card">
                <div class="student-info">
                    <div><strong>Name:</strong> ${student.first_name} ${student.last_name}</div>
                    <div><strong>Email:</strong> ${student.email}</div>
                    <div><strong>Major:</strong> ${student.major}</div>
                    <div><strong>GPA:</strong> ${student.gpa || 'N/A'}</div>
                    <div><strong>Enrollment:</strong> ${student.enrollment_date ? new Date(student.enrollment_date).toLocaleDateString() : 'N/A'}</div>
                    <div><strong>Graduation:</strong> ${student.graduation_year || 'N/A'}</div>
                </div>
                <div class="student-actions">
                    <button class="btn btn-edit" onclick="editStudent(${student.id})">Edit</button>
                    <button class="btn btn-danger" onclick="deleteStudent(${student.id})">Delete</button>
                </div>
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = '<div class="error">Error loading students. Please make sure the API is running.</div>';
        console.error('Error loading students:', error);
    }
}

// Add new student
document.getElementById('student-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
        first_name: document.getElementById('firstName').value,
        last_name: document.getElementById('lastName').value,
        email: document.getElementById('email').value,
        major: document.getElementById('major').value,
        gpa: parseFloat(document.getElementById('gpa').value) || 0,
        enrollment_date: document.getElementById('enrollmentDate').value ? new Date(document.getElementById('enrollmentDate').value).toISOString() : null,
        graduation_year: parseInt(document.getElementById('graduationYear').value) || null
    };
    
    console.log('Sending student data:', formData);
    
    try {
        const response = await fetch(`${API_BASE_URL}/students`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });
        
        console.log('Response status:', response.status);
        console.log('Response headers:', response.headers);
        
        if (response.ok) {
            const result = await response.json();
            console.log('Student created:', result);
            document.getElementById('student-form').reset();
            showMessage('Student added successfully!', 'success');
            showTab('students-list');
        } else {
            const errorText = await response.text();
            console.error('Error response:', errorText);
            try {
                const error = JSON.parse(errorText);
                showMessage(`Error: ${error.error}`, 'error');
            } catch {
                showMessage(`Error: ${response.status} - ${errorText}`, 'error');
            }
        }
    } catch (error) {
        console.error('Network error:', error);
        showMessage('Error adding student. Please make sure the API is running.', 'error');
    }
});

// Edit student
async function editStudent(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/students/${id}`);
        const student = await response.json();
        
        document.getElementById('editId').value = student.id;
        document.getElementById('editFirstName').value = student.first_name;
        document.getElementById('editLastName').value = student.last_name;
        document.getElementById('editEmail').value = student.email;
        document.getElementById('editMajor').value = student.major;
        document.getElementById('editGpa').value = student.gpa || '';
        document.getElementById('editEnrollmentDate').value = student.enrollment_date ? student.enrollment_date.split('T')[0] : '';
        document.getElementById('editGraduationYear').value = student.graduation_year || '';
        
        document.getElementById('edit-modal').style.display = 'block';
    } catch (error) {
        showMessage('Error loading student data.', 'error');
        console.error('Error loading student:', error);
    }
}

// Update student
document.getElementById('edit-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const id = document.getElementById('editId').value;
    const formData = {
        first_name: document.getElementById('editFirstName').value,
        last_name: document.getElementById('editLastName').value,
        email: document.getElementById('editEmail').value,
        major: document.getElementById('editMajor').value,
        gpa: parseFloat(document.getElementById('editGpa').value) || 0,
        enrollment_date: document.getElementById('editEnrollmentDate').value ? new Date(document.getElementById('editEnrollmentDate').value).toISOString() : null,
        graduation_year: parseInt(document.getElementById('editGraduationYear').value) || null
    };
    
    try {
        const response = await fetch(`${API_BASE_URL}/students/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });
        
        if (response.ok) {
            closeEditModal();
            showMessage('Student updated successfully!', 'success');
            loadStudents();
        } else {
            const error = await response.json();
            showMessage(`Error: ${error.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error updating student.', 'error');
        console.error('Error updating student:', error);
    }
});

// Delete student
async function deleteStudent(id) {
    if (!confirm('Are you sure you want to delete this student?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/students/${id}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showMessage('Student deleted successfully!', 'success');
            loadStudents();
        } else {
            const error = await response.json();
            showMessage(`Error: ${error.error}`, 'error');
        }
    } catch (error) {
        showMessage('Error deleting student.', 'error');
        console.error('Error deleting student:', error);
    }
}

// Close edit modal
function closeEditModal() {
    document.getElementById('edit-modal').style.display = 'none';
}

// Show message
function showMessage(message, type) {
    const existingMessage = document.querySelector('.message');
    if (existingMessage) {
        existingMessage.remove();
    }
    
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.textContent = message;
    
    document.querySelector('.container').insertBefore(messageDiv, document.querySelector('.tabs'));
    
    setTimeout(() => {
        messageDiv.remove();
    }, 5000);
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('edit-modal');
    if (event.target === modal) {
        closeEditModal();
    }
}

// Load students on page load
document.addEventListener('DOMContentLoaded', () => {
    loadStudents();
});