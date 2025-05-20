
variable "github_repositories" {
  description = "Map of GitHub repositories to create OIDC roles for keyed by repo name"
  type = map(object({
    ecr_repository_name = string

    # Restrict the Github Action to deploy to only these environments 
    github_environments = optional(list(string), ["*"])

    # The default branch of the repository
    default_branch = optional(string, "main")

    default_conditions = optional(list(string), ["allow_main"])
  }))
  default = {}
}
