<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../config/db.php';

try {
    $database = new Database();
    $conn = $database->getConnection();

    function getCount($conn, $query) {
        $stmt = $conn->prepare($query);
        $stmt->execute();
        return (int)$stmt->fetchColumn();
    }

    $users_count = getCount($conn, "SELECT COUNT(*) FROM users WHERE role != 'admin'");
    $lessons_count = getCount($conn, "SELECT COUNT(*) FROM lessons");
    $categories_count = getCount($conn, "SELECT COUNT(*) FROM categories");
    $jobs_count = getCount($conn, "SELECT COUNT(*) FROM jobs");
    $companies_count = getCount($conn, "SELECT COUNT(*) FROM companies");
    $applications_count = getCount($conn, "SELECT COUNT(*) FROM job_applications");

    $activities = [];

    // آخر الدروس
    $stmt = $conn->prepare("
        SELECT id, title_ar AS title, created_at
        FROM lessons
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $lessons = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($lessons as $item) {
        $activities[] = [
            'type' => 'lesson',
            'text' => 'تمت إضافة درس: ' . ($item['title'] ?? ''),
            'created_at' => $item['created_at'] ?? null,
        ];
    }

    // آخر الأقسام
    $stmt = $conn->prepare("
        SELECT id, name_ar AS title, created_at
        FROM categories
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($categories as $item) {
        $activities[] = [
            'type' => 'category',
            'text' => 'تمت إضافة قسم: ' . ($item['title'] ?? ''),
            'created_at' => $item['created_at'] ?? null,
        ];
    }

    // آخر الوظائف
    $stmt = $conn->prepare("
        SELECT j.id, j.title, j.created_at, c.company_name
        FROM jobs j
        LEFT JOIN companies c ON c.id = j.company_id
        ORDER BY j.created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($jobs as $item) {
        $companyName = $item['company_name'] ?? 'شركة غير معروفة';
        $activities[] = [
            'type' => 'job',
            'text' => 'تمت إضافة وظيفة: ' . ($item['title'] ?? '') . ' - ' . $companyName,
            'created_at' => $item['created_at'] ?? null,
        ];
    }

    // آخر الشركات
    $stmt = $conn->prepare("
        SELECT id, company_name, created_at
        FROM companies
        ORDER BY created_at DESC
        LIMIT 5
    ");
    $stmt->execute();
    $companies = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($companies as $item) {
        $activities[] = [
            'type' => 'company',
            'text' => 'تمت إضافة شركة: ' . ($item['company_name'] ?? ''),
            'created_at' => $item['created_at'] ?? null,
        ];
    }

    // ترتيب زمني موحد
    usort($activities, function ($a, $b) {
        return strtotime($b['created_at'] ?? '1970-01-01 00:00:00') 
             <=> strtotime($a['created_at'] ?? '1970-01-01 00:00:00');
    });

    $recent_activities = array_slice($activities, 0, 8);

    echo json_encode([
        'success' => true,
        'data' => [
            'users_count' => $users_count,
            'lessons_count' => $lessons_count,
            'categories_count' => $categories_count,
            'jobs_count' => $jobs_count,
            'companies_count' => $companies_count,
            'applications_count' => $applications_count,
            'recent_activities' => $recent_activities,
        ],
        'message' => 'تم جلب إحصائيات لوحة التحكم بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب إحصائيات لوحة التحكم: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>