-- المعهد الأول - Database Schema Design
-- Comprehensive database structure for educational platform

-- Users base table (for authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teachers table
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    experience_years INTEGER,
    bio TEXT,
    profile_image_url VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    age INTEGER,
    educational_level VARCHAR(50),
    target_level VARCHAR(50),
    parent_phone VARCHAR(20),
    profile_image_url VARCHAR(255),
    is_new_student BOOLEAN DEFAULT true,
    final_grade DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Classes table
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    teacher_id UUID REFERENCES teachers(id) ON DELETE SET NULL,
    description TEXT,
    subject VARCHAR(100),
    max_students INTEGER DEFAULT 50,
    duration_minutes INTEGER DEFAULT 60,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Class enrollments (students in classes)
CREATE TABLE class_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(class_id, student_id)
);

-- Class sessions (individual lecture instances)
CREATE TABLE class_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    duration_minutes INTEGER,
    topic VARCHAR(200),
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'paused', 'completed', 'cancelled')),
    recording_url VARCHAR(255),
    recording_size_mb DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance tracking
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    join_time TIMESTAMP,
    leave_time TIMESTAMP,
    total_minutes INTEGER,
    is_present BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, student_id)
);

-- Grade management system
CREATE TABLE grade_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    max_marks DECIMAL(5,2) NOT NULL,
    weight_percentage DECIMAL(5,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Student grades
CREATE TABLE student_grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    component_id UUID REFERENCES grade_components(id) ON DELETE CASCADE,
    marks_obtained DECIMAL(5,2),
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    comments TEXT,
    date_assessed DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chat messages
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'file', 'system')),
    content TEXT NOT NULL,
    file_url VARCHAR(255),
    file_name VARCHAR(255),
    file_size_mb DECIMAL(10,2),
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session recordings metadata
CREATE TABLE recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    file_size_mb DECIMAL(10,2),
    duration_minutes INTEGER,
    quality VARCHAR(20) DEFAULT '720p',
    storage_provider VARCHAR(50) DEFAULT 'local',
    is_processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Permissions and audio controls
CREATE TABLE session_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    can_speak BOOLEAN DEFAULT false,
    request_to_speak BOOLEAN DEFAULT false,
    request_time TIMESTAMP,
    granted_by UUID REFERENCES users(id) ON DELETE SET NULL,
    granted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, student_id)
);

-- WhatsApp integration
CREATE TABLE whatsapp_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    last_message_sent TIMESTAMP,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session reports (archived data)
CREATE TABLE session_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    class_name VARCHAR(100) NOT NULL,
    teacher_name VARCHAR(100) NOT NULL,
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    duration_minutes INTEGER,
    students_present INTEGER,
    students_absent INTEGER,
    total_students INTEGER,
    average_attendance_duration DECIMAL(5,2),
    recording_url VARCHAR(255),
    chat_messages_count INTEGER DEFAULT 0,
    report_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_code ON users(code);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_classes_teacher ON classes(teacher_id);
CREATE INDEX idx_classes_code ON classes(code);
CREATE INDEX idx_enrollments_class ON class_enrollments(class_id);
CREATE INDEX idx_enrollments_student ON class_enrollments(student_id);
CREATE INDEX idx_sessions_class ON class_sessions(class_id);
CREATE INDEX idx_sessions_date ON class_sessions(session_date);
CREATE INDEX idx_attendance_session ON attendance(session_id);
CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_chat_session ON chat_messages(session_id);
CREATE INDEX idx_chat_created ON chat_messages(created_at);
CREATE INDEX idx_grades_student ON student_grades(student_id);
CREATE INDEX idx_grades_class ON student_grades(class_id);

-- Insert default grade components
INSERT INTO grade_components (name, code, max_marks, weight_percentage, description) VALUES
('التفاعل في الصف', 'class_interaction', 7, 7, 'علامة التفاعل والمشاركة في الصف'),
('حل التمارين والواجبات', 'homework', 7, 7, 'علامة أداء الواجبات والتمارين'),
('الامتحان الشفهي', 'oral_exam', 60, 60, 'الامتحان الشفهي والأسئلة الشفهية'),
('الامتحان الخطي', 'written_exam', 7, 7, 'الامتحان الخطي والكتابي'),
('العلامة النهائية', 'final_grade', 100, 100, 'العلامة النهائية المحسوبة تلقائياً');

-- Create admin user (code: 0000)
INSERT INTO users (code, full_name, phone_number, email, password_hash, role) VALUES
('0000', 'مدير النظام', '0000000000', 'admin@almafd.edu', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');

-- Create triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function for automatic final grade calculation
CREATE OR REPLACE FUNCTION calculate_final_grade(student_id UUID, class_id UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    final_grade DECIMAL(5,2);
BEGIN
    SELECT 
        ROUND(
            SUM(sg.marks_obtained * gc.weight_percentage / 100), 2
        )
    INTO final_grade
    FROM student_grades sg
    JOIN grade_components gc ON sg.component_id = gc.id
    WHERE sg.student_id = $1 
        AND sg.class_id = $2
        AND gc.code != 'final_grade';
    
    RETURN final_grade;
END;
$$ LANGUAGE plpgsql;