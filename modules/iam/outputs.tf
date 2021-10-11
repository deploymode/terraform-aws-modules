output "users" {
  description = "IAM user name"
  value = { for u in aws_iam_user.user : u.value.name => {
    arn       = u.value.arn
    unique_id = u.value.unique_id
    }
  }
}

output "user_login_profile_encrypted_password" {
  description = "The encrypted password, base64 encoded"
  value = { for u in aws_iam_user_login_profile.user : u.value.name => {
    encrypted_password = u.value.encrypted_password
    key_fingerprint    = u.value.key_fingerprint
    }
  }
  sensitive = true
}

output "user_groups" {
  description = "Group membership of users"
  value       = aws_iam_user_group_membership.group_membership.*
}
