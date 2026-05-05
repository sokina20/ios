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
    if (!isset($_FILES['cv_file'])) {
        echo json_encode([
            'success' => false,
            'message' => 'لم يتم إرسال ملف CV'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $file = $_FILES['cv_file'];

    if ($file['error'] !== UPLOAD_ERR_OK) {
        echo json_encode([
            'success' => false,
            'message' => 'حدث خطأ أثناء رفع الملف'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $allowedExtensions = ['pdf', 'doc', 'docx'];
    $maxFileSize = 5 * 1024 * 1024;

    $originalName = $file['name'];
    $fileSize = $file['size'];
    $tmpName = $file['tmp_name'];

    $extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));

    if (!in_array($extension, $allowedExtensions)) {
        echo json_encode([
            'success' => false,
            'message' => 'صيغة الملف غير مدعومة. المسموح: pdf, doc, docx'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($fileSize > $maxFileSize) {
        echo json_encode([
            'success' => false,
            'message' => 'حجم الملف كبير جدًا. الحد الأقصى 5MB'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $uploadDir = '../../uploads/cvs/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $newFileName = 'cv_' . uniqid() . '_' . time() . '.' . $extension;
    $destination = $uploadDir . $newFileName;

    if (!move_uploaded_file($tmpName, $destination)) {
        echo json_encode([
            'success' => false,
            'message' => 'تعذر حفظ الملف'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    echo json_encode([
        'success' => true,
        'message' => 'تم رفع ملف CV بنجاح',
        'file_path' => 'uploads/cvs/' . $newFileName
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}