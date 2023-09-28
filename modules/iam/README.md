IAM Module
=====================

This is a simplified IAM module for small orgs. It is intended to be run in the master (root) 
account.

The access approach is as follows:

- the module creates the specified users and adds them to the specified groups
- membership in each group permits the user to AssumeRole to a role in the relevant account
- the roles in each account have the actual permissions to interact which the account
- therefore users cannot perform any action directly except for AssumeRole

The purpose of this is to isolate the permissions into roles so they can be assigned as required to
users or services.

Groups specified in the `groups` variable are intended to be used to control access to sub-accounts.

## Known issues

* Module must currently be run twice in order to assign new users to groups

## User passwords

To view encrypted passwords, run the following command:

### Using keybase

```bash
brew install keybase
keybase login
terragrunt output -json user_login_profile_encrypted_password
echo "encrypted_password" | base64 --decode | keybase pgp decrypt
```

### Using gpg

```bash 
terragrunt output -json user_login_profile_encrypted_password
export GPG_TTY=$(tty)
echo "encrypted_password" | base64 --decode | gpg --decrypt
```