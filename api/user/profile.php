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
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'user_id is required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $userQuery = "SELECT
                    u.id,
                    u.full_name,
                    u.username,
                    u.email,
                    u.phone,
                    u.role,
                    u.gender,
                    u.birth_date,
                    u.disability_type_id,
                    u.profile_image,
                    u.created_at,
                    d.name_ar AS disability_type_name,
                    up.address,
                    up.city,
                    up.country,
                    up.education_level,
                    up.bio,
                    up.emergency_contact_name,
                    up.emergency_contact_phone,
                    up.guardian_name,
                    up.guardian_phone,
                    up.needs_assistant,
                    up.preferred_language,
                    a.font_size,
                    a.high_contrast,
                    a.text_to_speech,
                    a.voice_commands,
                    a.sign_language_support,
                    a.captions_enabled,
                    a.simplified_mode,
                    a.color_blind_mode,
                    a.preferred_input
                  FROM users u
                  LEFT JOIN disability_types d ON d.id = u.disability_type_id
                  LEFT JOIN user_profiles up ON up.user_id = u.id
                  LEFT JOIN accessibility_settings a ON a.user_id = u.id
                  WHERE u.id = :user_id
                  LIMIT 1";

    $userStmt = $conn->prepare($userQuery);
    $userStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $userStmt->execute();
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $statsQuery = "SELECT
                    (SELECT COUNT(*) FROM lesson_progress WHERE user_id = :user_id AND is_completed = 1) AS completed_lessons,
                    (SELECT COUNT(*) FROM lesson_progress WHERE user_id = :user_id) AS started_lessons,
                    (SELECT COUNT(*) FROM favorite_lessons WHERE user_id = :user_id) AS favorite_lessons,
                    (SELECT COUNT(*) FROM job_applications WHERE user_id = :user_id) AS job_applications";

    $statsStmt = $conn->prepare($statsQuery);
    $statsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $statsStmt->execute();
    $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);

    $favoritesQuery = "SELECT
                        l.id,
                        l.title_ar,
                        l.short_description,
                        l.lesson_type,
                        l.difficulty_level,
                        l.duration_minutes,
                        l.thumbnail,
                        c.name_ar AS category_name
                      FROM favorite_lessons f
                      INNER JOIN lessons l ON l.id = f.lesson_id
                      INNER JOIN categories c ON c.id = l.category_id
                      WHERE f.user_id = :user_id
                      AND l.status = 'published'
                      ORDER BY f.created_at DESC
                      LIMIT 10";

    $favoritesStmt = $conn->prepare($favoritesQuery);
    $favoritesStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $favoritesStmt->execute();
    $favorites = $favoritesStmt->fetchAll(PDO::FETCH_ASSOC);

    $applicationsQuery = "SELECT
                            ja.id,
                            ja.job_id,
                            ja.status,
                            ja.applied_at,
                            ja.cover_letter,
                            ja.cv_file,
                            j.title,
                            j.location,
                            j.employment_type,
                            c.company_name
                          FROM job_applications ja
                          INNER JOIN jobs j ON j.id = ja.job_id
                          INNER JOIN companies c ON c.id = j.company_id
                          WHERE ja.user_id = :user_id
                          ORDER BY ja.applied_at DESC
                          LIMIT 10";

    $applicationsStmt = $conn->prepare($applicationsQuery);
    $applicationsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $applicationsStmt->execute();
    $applications = $applicationsStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Profile fetched successfully',
        'data' => [
            'user' => $user,
            'stats' => $stats,
            'favorite_lessons' => $favorites,
            'job_applications' => $applications
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