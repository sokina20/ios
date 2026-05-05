<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db.php';

try {
    $rawInput = file_get_contents("php://input");
    $data = json_decode($rawInput, true);

    if (!$data || !is_array($data)) {
        echo json_encode([
            "success" => false,
            "message" => "البيانات المرسلة غير صحيحة أو ليست JSON صالح"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $company_id = isset($data['company_id']) ? (int)$data['company_id'] : 0;
    $title = isset($data['title']) ? trim($data['title']) : '';
    $description = isset($data['description']) ? trim($data['description']) : '';
    $requirements = isset($data['requirements']) ? trim($data['requirements']) : null;
    $location = isset($data['location']) ? trim($data['location']) : null;
    $employment_type = isset($data['employment_type']) ? trim($data['employment_type']) : 'full_time';
    $salary_min = isset($data['salary_min']) && $data['salary_min'] !== ''
        ? (float)$data['salary_min']
        : null;
    $salary_max = isset($data['salary_max']) && $data['salary_max'] !== ''
        ? (float)$data['salary_max']
        : null;
    $target_disability_id = isset($data['target_disability_id']) && $data['target_disability_id'] !== ''
        ? (int)$data['target_disability_id']
        : null;
    $is_active = isset($data['is_active']) ? (int)$data['is_active'] : 1;
    $application_deadline = isset($data['application_deadline']) && trim($data['application_deadline']) !== ''
        ? trim($data['application_deadline'])
        : null;

    if ($company_id <= 0) {
        echo json_encode([
            "success" => false,
            "message" => "الشركة مطلوبة"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($title === '') {
        echo json_encode([
            "success" => false,
            "message" => "عنوان الوظيفة مطلوب"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($description === '') {
        echo json_encode([
            "success" => false,
            "message" => "وصف الوظيفة مطلوب"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $query = "INSERT INTO jobs (
                company_id,
                title,
                description,
                requirements,
                location,
                employment_type,
                salary_min,
                salary_max,
                target_disability_id,
                is_active,
                application_deadline
              ) VALUES (
                :company_id,
                :title,
                :description,
                :requirements,
                :location,
                :employment_type,
                :salary_min,
                :salary_max,
                :target_disability_id,
                :is_active,
                :application_deadline
              )";

    $stmt = $conn->prepare($query);

    $stmt->bindParam(':company_id', $company_id, PDO::PARAM_INT);
    $stmt->bindParam(':title', $title);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':requirements', $requirements);
    $stmt->bindParam(':location', $location);
    $stmt->bindParam(':employment_type', $employment_type);
    $stmt->bindParam(':salary_min', $salary_min);
    $stmt->bindParam(':salary_max', $salary_max);
    $stmt->bindParam(':target_disability_id', $target_disability_id, PDO::PARAM_INT);
    $stmt->bindParam(':is_active', $is_active, PDO::PARAM_INT);
    $stmt->bindParam(':application_deadline', $application_deadline);

    $stmt->execute();

    echo json_encode([
        "success" => true,
        "message" => "تم إضافة الوظيفة بنجاح"
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}