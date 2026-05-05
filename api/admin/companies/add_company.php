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
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مسموحة');
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $company_name = trim($data['company_name'] ?? '');
    $email = trim($data['email'] ?? '');
    $phone = trim($data['phone'] ?? '');
    $website = trim($data['website'] ?? '');
    $city = trim($data['city'] ?? '');
    $address = trim($data['address'] ?? '');
    $description = trim($data['description'] ?? '');
    $logo = trim($data['logo'] ?? '');
    $status = trim($data['status'] ?? 'approved');
    $created_by = intval($data['created_by'] ?? 0);

    if ($company_name === '') {
        throw new Exception('اسم الشركة مطلوب');
    }

    $database = new Database();
    $conn = $database->getConnection();

    $query = "INSERT INTO companies (
                company_name,
                email,
                phone,
                website,
                city,
                address,
                description,
                logo,
                status,
                created_by
              ) VALUES (
                :company_name,
                :email,
                :phone,
                :website,
                :city,
                :address,
                :description,
                :logo,
                :status,
                :created_by
              )";

    $stmt = $conn->prepare($query);
    $stmt->bindValue(':company_name', $company_name);
    $stmt->bindValue(':email', $email !== '' ? $email : null);
    $stmt->bindValue(':phone', $phone !== '' ? $phone : null);
    $stmt->bindValue(':website', $website !== '' ? $website : null);
    $stmt->bindValue(':city', $city !== '' ? $city : null);
    $stmt->bindValue(':address', $address !== '' ? $address : null);
    $stmt->bindValue(':description', $description !== '' ? $description : null);
    $stmt->bindValue(':logo', $logo !== '' ? $logo : null);
    $stmt->bindValue(':status', $status);
    $stmt->bindValue(':created_by', $created_by > 0 ? $created_by : null);

    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم إضافة الشركة بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>