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

try {
    $jobId = isset($_GET['job_id']) ? (int)$_GET['job_id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($jobId <= 0 || $userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'job_id and user_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

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
                j.application_deadline,
                j.created_at,
                c.company_name,
                c.email AS company_email,
                c.phone AS company_phone,
                c.website AS company_website,
                c.city AS company_city,
                c.address AS company_address,
                c.description AS company_description,
                c.logo AS company_logo,
                d.name_ar AS disability_name,
                CASE WHEN ja.id IS NULL THEN 0 ELSE 1 END AS has_applied,
                ja.status AS application_status,
                ja.cover_letter,
                ja.cv_file,
                ja.notes
              FROM jobs j
              INNER JOIN companies c ON c.id = j.company_id
              LEFT JOIN disability_types d ON d.id = j.target_disability_id
              LEFT JOIN job_applications ja
                ON ja.job_id = j.id AND ja.user_id = :user_id
              WHERE j.id = :job_id
              AND j.is_active = 1
              AND c.status = 'approved'
              LIMIT 1";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':job_id', $jobId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();

    $job = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$job) {
        echo json_encode([
            'success' => false,
            'message' => 'Job not found'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    echo json_encode([
        'success' => true,
        'message' => 'Job details fetched successfully',
        'data' => $job
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}