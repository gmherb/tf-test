locals {
  user_roles = merge(flatten([
    for group in var.user_groups : [
      for user in group.users : {
        for role in group.roles :
        "${user}-${trimprefix(role, "roles/")}" => {
          user = user
          role = trimprefix(role, "roles/")
        }
      }
    ]
  ])...)

  user_compute_filters = merge(flatten([
    for group in var.user_groups : {
      for user in group.users : "${user}-${join(":", group.compute_filters)}" => {
        user            = user
        compute_filters = join(":", group.compute_filters)
      }
    } if group.compute_filters != null && length(group.compute_filters) > 0
  ])...)

  sa_users = flatten([
    for group in var.user_groups : [
      for user in group.users : [
        user
      ] if group.grant_sa_access != null && group.grant_sa_access == true
    ]
  ])

  user_groups_from_paths = flatten([
    for path in var.user_groups_paths : [
      for file in fileset(path, "*.{yaml,yml}") :
      yamldecode(file("${path}/${file}"))
    ]
  ])

  user_groups = concat(var.user_groups, local.user_groups_from_paths)

  user_groups_keys_required = ["name", "users", "roles"]
  user_groups_keys_optional = ["compute_filters", "grant_sa_access"]
  user_groups_keys          = concat(local.user_groups_keys_required, local.user_groups_keys_optional)
}
