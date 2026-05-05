<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit();
}

require_once __DIR__ . '/../../config/db.php';

$data = json_decode(file_get_contents("php://input"), true);

$category_id = intval($data['category_id'] ?? 0);
$title_ar = trim($data['title_ar'] ?? '');
$title_en = trim($data['title_en'] ?? '');
$short_description = trim($data['short_description'] ?? '');
$content = trim($data['content'] ?? '');

$lesson_type = $data['lesson_type'] ?? 'text';
$difficulty_level = $data['difficulty_level'] ?? 'easy';

$target_disability_id = $data['target_disability_id'] ?? null;

$thumbnail = trim($data['thumbnail'] ?? '');
$duration_minutes = intval($data['duration_minutes'] ?? 0);

$is_featured = intval($data['is_featured'] ?? 0);
$status = $data['status'] ?? 'published';

$created_by = intval($data['created_by'] ?? 0);

if ($category_id <= 0 || $title_ar == '') {
    echo json_encode([
        "success" => false,
        "message" => "بيانات غير مكتملة"
    ]);
    exit();
}

try {

    $database = new Database();
    $conn = $database->getConnection();

    $query = "INSERT INTO lessons
    (
        category_id,
        title_ar,
        title_en,
        short_description,
        content,
        lesson_type,
        difficulty_level,
        target_disability_id,
        thumbnail,
        duration_minutes,
        is_featured,
        status,
        created_by
    )
    VALUES
    (
        :category_id,
        :title_ar,
        :title_en,
        :short_description,
        :content,
        :lesson_type,
        :difficulty_level,
        :target_disability_id,
        :thumbnail,
        :duration_minutes,
        :is_featured,
        :status,
        :created_by
    )";

    $stmt = $conn->prepare($query);

    $stmt->bindParam(":category_id", $category_id);
    $stmt->bindParam(":title_ar", $title_ar);
    $stmt->bindParam(":title_en", $title_en);
    $stmt->bindParam(":short_description", $short_description);
    $stmt->bindParam(":content", $content);
    $stmt->bindParam(":lesson_type", $lesson_type);
    $stmt->bindParam(":difficulty_level", $difficulty_level);
    $stmt->bindParam(":target_disability_id", $target_disability_id);
    $stmt->bindParam(":thumbnail", $thumbnail);
    $stmt->bindParam(":duration_minutes", $duration_minutes);
    $stmt->bindParam(":is_featured", $is_featured);
    $stmt->bindParam(":status", $status);
    $stmt->bindParam(":created_by", $created_by);

    $stmt->execute();

    echo json_encode([
        "success" => true,
        "message" => "تم إضافة الدرس بنجاح"
    ]);

} catch (Exception $e) {

    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}