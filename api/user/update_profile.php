<?php
require_once __DIR__ . '/../config/db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);

    $userId = isset($data['user_id']) ? (int)$data['user_id'] : 0;
    $fullName = isset($data['full_name']) ? trim($data['full_name']) : '';
    $phone = isset($data['phone']) ? trim($data['phone']) : null;
    $gender = isset($data['gender']) ? trim($data['gender']) : null;
    $birthDate = isset($data['birth_date']) ? trim($data['birth_date']) : null;
    $disabilityTypeId = isset($data['disability_type_id']) && $data['disability_type_id'] !== null
        ? (int)$data['disability_type_id'] : null;

    $address = isset($data['address']) ? trim($data['address']) : null;
    $city = isset($data['city']) ? trim($data['city']) : null;
    $country = isset($data['country']) ? trim($data['country']) : null;
    $educationLevel = isset($data['education_level']) ? trim($data['education_level']) : null;
    $bio = isset($data['bio']) ? trim($data['bio']) : null;
    $emergencyContactName = isset($data['emergency_contact_name']) ? trim($data['emergency_contact_name']) : null;
    $emergencyContactPhone = isset($data['emergency_contact_phone']) ? trim($data['emergency_contact_phone']) : null;
    $guardianName = isset($data['guardian_name']) ? trim($data['guardian_name']) : null;
    $guardianPhone = isset($data['guardian_phone']) ? trim($data['guardian_phone']) : null;
    $needsAssistant = isset($data['needs_assistant']) ? (int)$data['needs_assistant'] : 0;
    $preferredLanguage = isset($data['preferred_language']) ? trim($data['preferred_language']) : 'ar';

    if ($userId <= 0 || empty($fullName)) {
        echo json_encode([
            'success' => false,
            'message' => 'بيانات غير صحيحة'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();
    $conn->beginTransaction();

    $updateUserQuery = "UPDATE users
                        SET full_name = :full_name,
                            phone = :phone,
                            gender = :gender,
                            birth_date = :birth_date,
                            disability_type_id = :disability_type_id,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = :user_id";

    $updateUserStmt = $conn->prepare($updateUserQuery);
    $updateUserStmt->bindParam(':full_name', $fullName);
    $updateUserStmt->bindParam(':phone', $phone);
    $updateUserStmt->bindParam(':gender', $gender);
    $updateUserStmt->bindParam(':birth_date', $birthDate);
    $updateUserStmt->bindParam(':disability_type_id', $disabilityTypeId, PDO::PARAM_INT);
    $updateUserStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $updateUserStmt->execute();

    $checkProfileQuery = "SELECT id FROM user_profiles WHERE user_id = :user_id LIMIT 1";
    $checkProfileStmt = $conn->prepare($checkProfileQuery);
    $checkProfileStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkProfileStmt->execute();
    $profileExists = $checkProfileStmt->fetch(PDO::FETCH_ASSOC);

    if ($profileExists) {
        $profileQuery = "UPDATE user_profiles
                         SET address = :address,
                             city = :city,
                             country = :country,
                             education_level = :education_level,
                             bio = :bio,
                             emergency_contact_name = :emergency_contact_name,
                             emergency_contact_phone = :emergency_contact_phone,
                             guardian_name = :guardian_name,
                             guardian_phone = :guardian_phone,
                             needs_assistant = :needs_assistant,
                             preferred_language = :preferred_language,
                             updated_at = CURRENT_TIMESTAMP
                         WHERE user_id = :user_id";
    } else {
        $profileQuery = "INSERT INTO user_profiles
                        (user_id, address, city, country, education_level, bio,
                         emergency_contact_name, emergency_contact_phone,
                         guardian_name, guardian_phone, needs_assistant, preferred_language)
                         VALUES
                        (:user_id, :address, :city, :country, :education_level, :bio,
                         :emergency_contact_name, :emergency_contact_phone,
                         :guardian_name, :guardian_phone, :needs_assistant, :preferred_language)";
    }

    $profileStmt = $conn->prepare($profileQuery);
    $profileStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $profileStmt->bindParam(':address', $address);
    $profileStmt->bindParam(':city', $city);
    $profileStmt->bindParam(':country', $country);
    $profileStmt->bindParam(':education_level', $educationLevel);
    $profileStmt->bindParam(':bio', $bio);
    $profileStmt->bindParam(':emergency_contact_name', $emergencyContactName);
    $profileStmt->bindParam(':emergency_contact_phone', $emergencyContactPhone);
    $profileStmt->bindParam(':guardian_name', $guardianName);
    $profileStmt->bindParam(':guardian_phone', $guardianPhone);
    $profileStmt->bindParam(':needs_assistant', $needsAssistant, PDO::PARAM_INT);
    $profileStmt->bindParam(':preferred_language', $preferredLanguage);
    $profileStmt->execute();

    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'تم تحديث الملف الشخصي بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    if (isset($conn) && $conn->inTransaction()) {
        $conn->rollBack();
    }

    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}