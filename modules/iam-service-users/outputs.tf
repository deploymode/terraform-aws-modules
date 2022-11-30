output "users" {
  description = "IAM user name"
  value = { for u, user_data in module.user : u => {
    name                       = user_data.user_name
    arn                        = user_data.user_arn
    unique_id                  = user_data.user_unique_id
    access_key_id              = user_data.access_key_id
    access_key_id_ssm_path     = user_data.access_key_id_ssm_path
    secret_access_key_ssm_path = user_data.secret_access_key_ssm_path
    }
  }
}
