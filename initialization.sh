#!/usr/bin/env bash

# Creating new Org under global scope

boundary scopes create -name DevopsInc -scope-id global -recovery-config $PWD/recover-config.yaml -skip-admin-role-creation -skip-default-role-creation > /dev/null
OrgId=`boundary scopes list -scope-id 'global' -recovery-config $PWD/recover-config.yaml -format=json | jq -r '.items[] |  select( .name == "DevopsInc") | .id'`

echo $OrgId

# Creating new Projec under Org which is created in the previous step

boundary scopes create -name Engineering -scope-id $OrgId -recovery-config $PWD/recover-config.yaml -skip-admin-role-creation -skip-default-role-creation > /dev/null
ProjId=`boundary scopes list -scope-id $OrgId -recovery-config $PWD/recover-config.yaml -format=json | jq -r '.items[] |  select( .name == "Engineering") | .id'`

echo $ProjId

# Creating new Auth method under Org scope

boundary auth-methods create password -recovery-config $PWD/recover-config.yaml -scope-id $OrgId -name 'test_auth_method' -description 'test auth method' > /dev/null
AuthId=`boundary auth-methods list -scope-id $OrgId -recovery-config $PWD/recover-config.yaml -format=json | jq -r '.items[] |  select( .name == "test_auth_method") | .id'`

echo $AuthId

# Creating new login account under the previously created auth method id

boundary accounts create password -recovery-config $PWD/recover-config.yaml -login-name "reddy" -password "happylearning" -auth-method-id $AuthId > /dev/null
AcctId=`boundary accounts list -auth-method-id=$AuthId -recovery-config $PWD/recover-config.yaml -format=json | jq -r '.items[] |  select( .attributes.login_name == "reddy") | .id'`

echo $AcctId

# Create new user 

boundary users create -scope-id $OrgId -recovery-config $PWD/recover-config.yaml -name "reddy" -description "reddy" > /dev/null
UserId=`boundary users list -scope-id $OrgId -recovery-config $PWD/recover-config.yaml -format=json | jq -r '.items[] |  select( .name == "reddy") | .id'`

# Mapping the user created to the login account

boundary users add-accounts -recovery-config $PWD/recover-config.yaml -id $UserId -account $AcctId > /dev/null

# Creating Global Anonymous listing role

boundary roles create -name 'global_anon_listing' -recovery-config $PWD/recover-config.yaml -scope-id 'global' > /dev/null
glob_anonlist=`boundary roles list -scope-id=global -recovery-config $PWD/recover-config.yaml -format json | jq -r '.items[] |  select( .name == "global_anon_listing") | .id'`

echo $glob_anonlist

# adding grants to global anonymous list role

boundary roles add-grants -id $glob_anonlist -recovery-config $PWD/recover-config.yaml -grant 'id=*;type=auth-method;actions=list,authenticate' -grant 'id=*;type=scope;actions=list,no-op' -grant 'id={{account.id}};actions=read,change-password' > /dev/null

# Adding principals to the global anonymous list role

boundary roles add-principals -id $glob_anonlist \
  -recovery-config $PWD/recover-config.yaml \
  -principal 'u_anon' > /dev/null

# Creating organization anonymous listing role

boundary roles create -name 'org_anon_listing' -recovery-config $PWD/recover-config.yaml -scope-id $OrgId > /dev/null
org_anonlist=`boundary roles list -scope-id=$OrgId -recovery-config $PWD/recover-config.yaml -format json | jq -r '.items[] |  select( .name == "org_anon_listing") | .id'`

# adding grants to organization anonymous list role

boundary roles add-grants -id $org_anonlist \
  -recovery-config $PWD/recover-config.yaml \
  -grant 'id=*;type=auth-method;actions=list,authenticate' \
  -grant 'type=scope;actions=list' \
  -grant 'id={{account.id}};actions=read,change-password' > /dev/null

# adding principals to the org anonymous list role

boundary roles add-principals -id $org_anonlist \
  -recovery-config $PWD/recover-config.yaml \
  -principal 'u_anon' > /dev/null

# Creating org admin role for myuser

boundary roles create -name 'org_admin' \
  -recovery-config $PWD/recover-config.yaml \
  -scope-id 'global' \
  -grant-scope-id $OrgId > /dev/null

OrgAdmRoId=`boundary roles list -scope-id=global -recovery-config $PWD/recover-config.yaml -format json | jq -r '.items[] |  select( .name == "org_admin") | .id'` 

# Adding grants to org admin role

boundary roles add-grants -id $OrgAdmRoId \
  -recovery-config $PWD/recover-config.yaml \
  -grant 'id=*;type=*;actions=*' > /dev/null

# adding principals to org admin role

boundary roles add-principals -id $OrgAdmRoId \
  -recovery-config $PWD/recover-config.yaml \
  -principal $UserId > /dev/null

# Creating proj admin role for myuser

boundary roles create -name 'project_admin' \
  -recovery-config $PWD/recover-config.yaml \
  -scope-id $OrgId \
  -grant-scope-id $ProjId > /dev/null 

ProjAdmRoId=`boundary roles list -scope-id=$OrgId -recovery-config $PWD/recover-config.yaml -format json | jq -r '.items[] |  select( .name == "project_admin") | .id'`

# adding grants to proj admin role

boundary roles add-grants -id $ProjAdmRoId \
  -recovery-config $PWD/recover-config.yaml \
  -grant 'id=*;type=*;actions=*' > /dev/null

# adding principals to proj admin role

boundary roles add-principals -id $ProjAdmRoId \
  -recovery-config $PWD/recover-config.yaml \
  -principal $UserId > /dev/null
