locals {
  notification_channel = var.alerting_enabled ? var.notification_channel : ""
  tag_specials_regex   = "/[^a-z0-9\\-_:.\\/]/"

  tags = concat(
    [
      "terraform:true",
      "env:${var.env}",
      "service:${var.service}",
    ],
    var.additional_tags
  )

  # Normalize all the tags according to best practices defined by Datadog. The
  # following changes are made:
  #
  # * Make all characters lowercase.
  # * Replace special characters with an underscore.
  # * Remove duplicate underscores.
  # * Remove any non-letter leading characters.
  # * Remove any trailing underscores.
  #
  # See: https://docs.datadoghq.com/developers/guide/what-best-practices-are-recommended-for-naming-metrics-and-tags
  normalized_tags = [
    for tag
    in local.tags :
    replace(
      replace(
        replace(
          replace(lower(tag), local.tag_specials_regex, "_")
          ,
          "/_+/",
          "_"
        ),
        "/^[^a-z]+/",
        ""
      ),
      "/_+$/",
      ""
    )
  ]

  # build assertions list
  assertions = concat(
    var.expected_status_code != null ? [{
      operator       = "is"
      target         = tostring(var.expected_status_code)
      type           = "statusCode"
      targetjsonpath = []
    }] : [],
    var.expected_response_time != null ? [{
      operator       = "lessThan"
      target         = tostring(var.expected_response_time)
      type           = "responseTime"
      targetjsonpath = []
    }] : [],
    var.expected_string != null ? [{
      operator       = "contains"
      target         = var.expected_string
      type           = "body"
      targetjsonpath = []
    }] : [],
    var.expected_json != null ? [{
      operator = "validatesJSONPath"
      type     = "body"
      targetjsonpath = [
        {
          jsonpath    = var.expected_json_path
          operator    = "contains"
          targetvalue = var.expected_json
        }
      ]
      target = null
    }] : [],
    # if var.check_actuator_status is null it has no effect.
    # but when it is not null it overrules
    ((length(var.actuator_components) > 0 || var.check_actuator_status == true) && var.check_actuator_status != false) ? [{
      operator = "validatesJSONPath"
      type     = "body"
      targetjsonpath = [
        {
          jsonpath    = "$.status"
          operator    = "contains"
          targetvalue = "UP"
        }
      ]
      target = null
    }] : [],
    [for component in var.actuator_components : {
      operator = "validatesJSONPath"
      type     = "body"
      targetjsonpath = [
        {
          # if sub_actuator_keyword == "" we don't place a dot
          jsonpath    = "$.${var.sub_actuator_keyword != "" ? join("", [var.sub_actuator_keyword, "."]) : ""}${component}.status"
          operator    = "contains"
          targetvalue = "UP"
        }
      ]
      target = null
    }],
    var.additional_assertions
  )
}


resource "datadog_synthetics_test" "generic_http_synthetic" {
  count = var.enabled ? 1 : 0
  name = join(" - ", compact([
    var.name_prefix,
    var.service,
    "HTTP Synthetics", # indicates where the data is coming from
    var.name,
    var.name_suffix
  ]))
  type = "api"

  message = templatefile("${path.module}/alert.tpl", {
    alert_message    = var.alert_message
    recovery_message = var.recovery_message

    note           = var.note
    docs           = var.docs
    custom_message = var.custom_message

    notification_channel = local.notification_channel
  })

  locations = var.locations
  status    = var.paused ? "paused" : "live"

  tags = local.normalized_tags

  dynamic "assertion" {
    for_each = local.assertions
    content {
      operator = assertion.value["operator"]
      target   = assertion.value["target"]
      dynamic "targetjsonpath" {
        for_each = assertion.value["targetjsonpath"]
        content {
          jsonpath    = targetjsonpath.value["jsonpath"]
          operator    = targetjsonpath.value["operator"]
          targetvalue = targetjsonpath.value["targetvalue"]
        }
      }
      type = assertion.value["type"]
    }
  }

  options_list {
    min_failure_duration = var.min_failure_duration
    min_location_failed  = var.min_location_failed
    tick_every           = var.check_interval_secs
    # Not compatible with current version
    # monitor_priority = var.priority

    # we don't use this (atm?)
    monitor_options {
      renotify_interval = 0
    }

    retry {
      count    = var.retry_count
      interval = var.retry_interval_secs
    }
  }

  request_definition {
    method = var.request_method
    url    = var.request_url
    body   = var.request_body
  }

  request_headers = var.request_headers
}
