variable "user_groups" {
  description = "Groups and their respective settings."
  type = list(object({
    name            = string
    users           = list(string)
    roles           = list(string)
    compute_filters = optional(list(string))
    grant_sa_access = optional(bool)
  }))
  default = [
    {
      name = "admins"
      users = [
        "gmherb@example.com",
      ]
      roles = [
        "roles/admin",
        "networkAdmin"
      ]
      compute_filters = [
        "startswith,net",
        "endswith,work"
      ]
      grant_sa_access = true
    },
    {
      name = "tester"
      users = [
        "tester@example.com"
      ]
      roles           = ["tester"]
      compute_filters = ["contains,test"]
      grant_sa_access = false
    },
    {
      name  = "bot"
      users = ["bot@bot.com"]
      roles = ["viewer"]
    }

  ]

  validation {
    condition = alltrue(flatten([
      for user_group in var.user_groups : [
        for user in user_group.users :
        strcontains(user, "@")
      ]
    ]))
    error_message = "Users must be email address"
  }

  validation {
    condition = alltrue(flatten([
      for user_group in var.user_groups :
      length(user_group.users) > 0
    ]))
    error_message = "Users must not be empty"
  }

}

variable "user_groups_paths" {
  description = "The paths to directories which contain YAML files with user_groups definitions."
  type        = list(string)
  default     = ["user_groups"]

  validation {
    condition = alltrue([
      for path in var.user_groups_paths : [
        !endswith(path, "/")
      ]
    ]...)
    error_message = "omit forward slash (/) at end of paths"
  }

  validation {
    condition = alltrue(flatten([
      for path in var.user_groups_paths : [
        for file in fileset(path, "*.{yaml,yml}") :
           yamldecode(file("${path}/${file}")) != null
      ]
    ]...))
    error_message = "YAML file must not be null"
  }

  validation {
    condition = alltrue(flatten([
      for path in var.user_groups_paths : [
        for file in fileset(path, "*.{yaml,yml}") : [
          for entry in yamldecode(file("${path}/${file}")) : [
            for key in keys(entry) : contains(local.user_groups_keys, key)
          ]
        ]
      ]
    ]))
    error_message = "YAML file must have keys [${join(", ", local.user_groups_keys_required)}] and optionally [${join(", ", local.user_groups_keys_optional)}]"
  }

  validation {
    condition = alltrue(flatten([
      for path in var.user_groups_paths : [
        for file in fileset(path, "*.{yaml,yml}") : [
          for entry in yamldecode(file("${path}/${file}")) : [
            for key in local.user_groups_keys_required : contains(keys(entry), key)
          ]
        ]
      ]
    ]))
    error_message = "YAML file must have keys [${join(", ", local.user_groups_keys_required)}] and optionally [${join(", ", local.user_groups_keys_optional)}]"
  }

  validation {
    condition = alltrue(flatten([
      for path in var.user_groups_paths : [
        for file in fileset(path, "*.{yaml,yml}") : [
          for user_group in yamldecode(file("${path}/${file}")) :
          user_group.roles != null && length(user_group.roles) > 0
        ]
      ]
    ]))
    error_message = "user_groups must have roles defined."
  }

  validation {
    condition = alltrue(flatten([
      for path in var.user_groups_paths : [
        for file in fileset(path, "*.{yaml,yml}") : [
          for user_group in yamldecode(file("${path}/${file}")) :
          user_group.users != null && length(user_group.users) > 0
        ]
      ]
    ]))
    error_message = "user_groups must have users defined."
  }

}
