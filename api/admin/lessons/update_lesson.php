<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

require_once __DIR__ . '/../../config/db.php';

$data = json_decode(file_get_contents("php://input"), true);

$id = intval($data['id']);

$category_id = intval($data['category_id']);
$title_ar = trim($data['title_ar']);

$title_en = trim($data['title_en'] ?? '');
$short_description = trim($data['short_description'] ?? '');
$content = trim($data['content'] ?? '');

$lesson_type = $data['lesson_type'];
$difficulty_level = $data['difficulty_level'];

$target_disability_id = $data['target_disability_id'] ?? null;

$thumbnail = trim($data['thumbnail'] ?? '');
$duration_minutes = intval($data['duration_minutes'] ?? 0);

$is_featured = intval($data['is_featured'] ?? 0);
$status = $data['status'];

try {

    $database = new Database();
    $conn = $database->getConnection();

    $query = "UPDATE lessons SET

        category_id = :category_id,
        title_ar = :title_ar,
        title_en = :title_en,
        short_description = :short_description,
        content = :content,
        lesson_type = :lesson_type,
        difficulty_level = :difficulty_level,
        target_disability_id = :target_disability_id,
        thumbnail = :thumbnail,
        duration_minutes = :duration_minutes,
        is_featured = :is_featured,
        status = :status

        WHERE id = :id";

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
    $stmt->bindParam(":id", $id);

    $stmt->execute();

    echo json_encode([
        "success" => true,
        "message" => "تم تحديث الدرس"
    ]);

} catch (Exception $e) {

    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}