variable "alerting_enabled" {
  type    = bool
  default = true
}

variable "enabled" {
  type    = bool
  default = true
}

variable "notification_channel" {
  type    = string
  default = ""
}

variable "name" {
  type = string
}

variable "service" {
  type = string
}

variable "alert_message" {
  type = string
}

variable "recovery_message" {
  type    = string
  default = ""
}

variable "note" {
  type    = string
  default = ""
}

variable "docs" {
  type    = string
  default = ""
}

variable "env" {
  type = string
}

variable "additional_tags" {
  type    = list(string)
  default = []
}

variable "name_prefix" {
  type    = string
  default = ""
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "priority" {
  description = "Number from 1 (high) to 5 (low)."

  type    = number
  default = null
}

variable "custom_message" {
  description = "This field give the option to put in custom text. Both 'note' and 'docs' are prefixed in the template with 'note:' and 'docs:' respectively. 'custom_message' allows for free format"
  type        = string
  default     = ""
}

# HTTP Synthetic specific

variable "paused" {
  type    = bool
  default = false
}

variable "expected_status_code" {
  type    = number
  default = 200
}

variable "locations" {
  type    = list(string)
  default = []
}

variable "min_failure_duration" {
  type = number
}

variable "min_location_failed" {
  type    = number
  default = 1
}

variable "check_interval_secs" {
  type    = number
  default = 900
}

variable "retry_count" {
  type    = number
  default = 1
}

variable "retry_interval_secs" {
  type    = number
  default = 300
}

variable "request_method" {
  type    = string
  default = "GET"
}

variable "request_body" {
  type    = string
  default = null
}

variable "request_url" {
  type = string
}

variable "request_headers" {
  type    = map(string)
  default = {}
}

variable "expected_response_time" {
  type    = number
  default = null
}

variable "expected_string" {
  type    = string
  default = null
}

variable "expected_json" {
  default = null
}

variable "expected_json_path" {
  type    = string
  default = "."
}