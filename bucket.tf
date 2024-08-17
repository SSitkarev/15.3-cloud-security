// Create Service Account
resource "yandex_iam_service_account" "sa-bucket" {
    name      = "sa-for-bucket"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "bucket-editor" {
    folder_id = var.yandex_folder_id
    role      = "storage.editor"
    member    = "serviceAccount:${yandex_iam_service_account.sa-bucket.id}"
    depends_on = [yandex_iam_service_account.sa-bucket]
}

// Grant encrypt and decrypt access
resource "yandex_resourcemanager_folder_iam_member" "encrypt-decrypt" {
    folder_id = var.yandex_folder_id
    role      = "kms.keys.encrypterDecrypter"
    member    = "serviceAccount:${yandex_iam_service_account.sa-bucket.id}"
    depends_on = [yandex_iam_service_account.sa-bucket]
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
    service_account_id = yandex_iam_service_account.sa-bucket.id
    description        = "static access key for bucket"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "sitkarev-bucket" {
    access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
    bucket = "sitkarev-bucket"
    acl    = "public-read-write"
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = yandex_kms_symmetric_key.secret-key.id
                sse_algorithm     = "aws:kms"
      }
    }
  }
}

// Add picture to bucket
resource "yandex_storage_object" "bucket_image" {
    access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
    bucket = yandex_storage_bucket.sitkarev-bucket.bucket
    key = "bucket_image.jpg"
    source = "img/bucket_image.jpg"
    acl    = "public-read"
    depends_on = [yandex_storage_bucket.sitkarev-bucket]
}

resource "yandex_kms_symmetric_key" "secret-key" {
    name              = "key-1"
    description       = "bucket encrypt key"
    default_algorithm = "AES_128"
    rotation_period   = "24h"
}