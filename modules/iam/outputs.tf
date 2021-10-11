output "users" {
  description = "IAM user name"
  value = { for u, user_data in aws_iam_user.user : u => {
    arn       = user_data.arn
    unique_id = user_data.unique_id
    }
  }
}

output "user_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value = { for u, user_data in aws_iam_user_login_profile.user_login : u => {
    encrypted_password = user_data.encrypted_password
    key_fingerprint    = user_data.key_fingerprint
    }
  }
  sensitive = true
}

output "user_groups" {
  description = "Group membership of users"
  value       = aws_iam_group_membership.group_membership.*
}
