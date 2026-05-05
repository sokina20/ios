<?php
require_once __DIR__ . '/../config/db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

class UserHomeController {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->getConnection();
    }

    public function getHomeData($userId) {
        try {
            if (empty($userId) || !is_numeric($userId)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid user id'
                ]);
                return;
            }

            $user = $this->getUserInfo($userId);
            if (!$user) {
                echo json_encode([
                    'success' => false,
                    'message' => 'User not found'
                ]);
                return;
            }

            $stats = $this->getUserStats($userId);
            $categories = $this->getCategories();
            $featuredLessons = $this->getFeaturedLessons($user['disability_type_id']);
            $recommendedJobs = $this->getRecommendedJobs($user['disability_type_id']);

            echo json_encode([
                'success' => true,
                'message' => 'Home data fetched successfully',
                'data' => [
                    'user' => $user,
                    'stats' => $stats,
                    'categories' => $categories,
                    'featured_lessons' => $featuredLessons,
                    'recommended_jobs' => $recommendedJobs
                ]
            ], JSON_UNESCAPED_UNICODE);

        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Server error',
                'error' => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
    }

    private function getUserInfo($userId) {
        $query = "SELECT 
                    u.id,
                    u.full_name,
                    u.email,
                    u.phone,
                    u.disability_type_id,
                    d.name_ar AS disability_type_name
                  FROM users u
                  LEFT JOIN disability_types d ON d.id = u.disability_type_id
                  WHERE u.id = :user_id
                  AND u.status = 'active'
                  LIMIT 1";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    private function getUserStats($userId) {
        $completedLessonsQuery = "SELECT COUNT(*) as total
                                  FROM lesson_progress
                                  WHERE user_id = :user_id AND is_completed = 1";
        $stmt1 = $this->conn->prepare($completedLessonsQuery);
        $stmt1->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt1->execute();
        $completedLessons = (int)$stmt1->fetch(PDO::FETCH_ASSOC)['total'];

        $favoriteLessonsQuery = "SELECT COUNT(*) as total
                                 FROM favorite_lessons
                                 WHERE user_id = :user_id";
        $stmt2 = $this->conn->prepare($favoriteLessonsQuery);
        $stmt2->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt2->execute();
        $favoriteLessons = (int)$stmt2->fetch(PDO::FETCH_ASSOC)['total'];

        $jobApplicationsQuery = "SELECT COUNT(*) as total
                                 FROM job_applications
                                 WHERE user_id = :user_id";
        $stmt3 = $this->conn->prepare($jobApplicationsQuery);
        $stmt3->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt3->execute();
        $jobApplications = (int)$stmt3->fetch(PDO::FETCH_ASSOC)['total'];

        return [
            'completed_lessons' => $completedLessons,
            'favorite_lessons' => $favoriteLessons,
            'job_applications' => $jobApplications
        ];
    }

    private function getCategories() {
        $query = "SELECT id, name_ar, name_en, description, icon
                  FROM categories
                  WHERE status = 'active'
                  ORDER BY id DESC
                  LIMIT 8";

        $stmt = $this->conn->prepare($query);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    private function getFeaturedLessons($disabilityTypeId) {
        $query = "SELECT 
                    l.id,
                    l.title_ar,
                    l.title_en,
                    l.short_description,
                    l.lesson_type,
                    l.difficulty_level,
                    l.duration_minutes,
                    l.thumbnail,
                    l.is_featured,
                    c.name_ar AS category_name
                  FROM lessons l
                  INNER JOIN categories c ON c.id = l.category_id
                  WHERE l.status = 'published'
                  AND l.is_featured = 1
                  AND (l.target_disability_id IS NULL OR l.target_disability_id = :disability_type_id)
                  ORDER BY l.created_at DESC
                  LIMIT 6";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':disability_type_id', $disabilityTypeId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    private function getRecommendedJobs($disabilityTypeId) {
        $query = "SELECT
                    j.id,
                    j.title,
                    j.description,
                    j.location,
                    j.employment_type,
                    j.salary_min,
                    j.salary_max,
                    j.application_deadline,
                    c.company_name,
                    c.logo AS company_logo
                  FROM jobs j
                  INNER JOIN companies c ON c.id = j.company_id
                  WHERE j.is_active = 1
                  AND c.status = 'approved'
                  AND (j.target_disability_id IS NULL OR j.target_disability_id = :disability_type_id)
                  ORDER BY j.created_at DESC
                  LIMIT 6";

        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':disability_type_id', $disabilityTypeId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

$controller = new UserHomeController();
$controller->getHomeData($userId);