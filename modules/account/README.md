Account
=========

Assumption is that the master account is created manually.
Temporary credentials (IAM key) should be created and added to Leapp/aws-vault in order to run
this module.

At https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials

- activate MFA
- create IAM keys

Once the required IAM users and roles are created for assuming role into this and other accounts,
the temporary credentials should be deleted.