IAM Module
=====================

The access approach is as follows:

- the module creates the specified users and adds them to the specified groups
- membership in each group permits the user to AssumeRole to a role in the relevant account
- the roles in each account have the actual permissions to interact which the account
- therefore users cannot perform any action directly except for AssumeRole

The purpose of this is to isolate the permissions into roles so they can be assigned as required to
users or services.