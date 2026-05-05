<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db.php';

try {
    $database = new Database();
    $conn = $database->getConnection();

    $query = "SELECT 
                j.id,
                j.company_id,
                j.title,
                j.description,
                j.requirements,
                j.location,
                j.employment_type,
                j.salary_min,
                j.salary_max,
                j.target_disability_id,
                j.is_active,
                j.application_deadline,
                j.created_at,
                c.company_name,
                d.name_ar AS target_disability_name
              FROM jobs j
              LEFT JOIN companies c ON j.company_id = c.id
              LEFT JOIN disability_types d ON j.target_disability_id = d.id
              ORDER BY j.id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();
    $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $jobs,
        'message' => 'تم جلب الوظائف بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب الوظائف: ' . $e->getMessage(),
        'line' => $e->getLine(),
        'file' => $e->getFile()
    ], JSON_UNESCAPED_UNICODE);
}
?>