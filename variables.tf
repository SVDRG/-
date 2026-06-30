variable "subid" {
  type      = string
  sensitive = true
}

variable "db_pswd" {
  type      = string
  sensitive = true
}

variable "shared_key" {
  type      = string
  sensitive = true
}

variable "rgname" {
  type    = string
  default = "team603-snort-central"
}

variable "rgname2" {
  type    = string
  default = "team603-snort-jpwest"
}

variable "rgloca2" {
  type    = string
  default = "JapanWest"
}

variable "rgloca" {
  type    = string
  default = "KoreaCentral"
}
