<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مسموحة');
    }

    if (!isset($_FILES['logo'])) {
        throw new Exception('لم يتم إرسال ملف الشعار');
    }

    $file = $_FILES['logo'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('حدث خطأ أثناء رفع الملف');
    }

    $allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    $maxSize = 5 * 1024 * 1024; // 5MB

    $originalName = $file['name'];
    $tmpName = $file['tmp_name'];
    $fileSize = $file['size'];

    $extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));

    if (!in_array($extension, $allowedExtensions)) {
        throw new Exception('نوع الملف غير مدعوم. المسموح: jpg, jpeg, png, webp');
    }

    if ($fileSize > $maxSize) {
        throw new Exception('حجم الملف كبير جدًا. الحد الأقصى 5MB');
    }

    $uploadDir = __DIR__ . '/../../uploads/companies/';

    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $fileName = 'company_' . uniqid() . '_' . time() . '.' . $extension;
    $fullPath = $uploadDir . $fileName;

    if (!move_uploaded_file($tmpName, $fullPath)) {
        throw new Exception('فشل حفظ الملف على السيرفر');
    }

    $relativePath = 'uploads/companies/' . $fileName;

    echo json_encode([
        'success' => true,
        'message' => 'تم رفع الشعار بنجاح',
        'file_path' => $relativePath
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>