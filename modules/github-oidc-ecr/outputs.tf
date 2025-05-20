output "github_oidc_repo_role_arns" {
  description = "GitHub OIDC role ARNs"
  value       = [for repo_name, repo_data in var.github_repositories : module.repo_oidc[repo_name].role.arn]
}
