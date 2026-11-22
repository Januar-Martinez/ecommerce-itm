# Módulo: observability
# Las tres señales de la observabilidad, con CloudWatch:
#   - MÉTRICAS: CPU, almacenamiento, memoria (alarmas y dashboard)
#   - LOGS: salida del contenedor Docker (grupo de logs, creado en el módulo compute)
#   - ALERTAS: SNS envía un correo cuando una alarma se dispara

locals {
  dashboard_name = "${var.name_prefix}-observabilidad"
}

# --- Notificaciones -----------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alertas"
}

# AWS envía un correo de confirmación: hay que pulsar "Confirm subscription".
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- Métrica personalizada a partir de los logs ------------------------------
# Cuenta las líneas de log con nivel ERROR del contenedor.
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.name_prefix}-errores-app"
  log_group_name = var.log_group_name
  pattern        = "?ERROR ?Traceback"

  metric_transformation {
    name          = "ErroresApp"
    namespace     = "Tienda"
    value         = "1"
    default_value = "0"
  }
}

# --- Alarmas ------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.name_prefix}-errores-en-la-app"
  alarm_description   = "La aplicación registró errores en sus logs"
  namespace           = "Tienda"
  metric_name         = "ErroresApp"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.name_prefix}-ec2-cpu-alta"
  alarm_description   = "CPU del servidor web por encima del 60%"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = var.instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 60
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_status" {
  alarm_name          = "${var.name_prefix}-ec2-status-fallido"
  alarm_description   = "El servidor web falló una verificación de estado"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = var.instance_id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-alta"
  alarm_description   = "CPU de MySQL por encima del 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.name_prefix}-rds-poco-almacenamiento"
  alarm_description   = "Quedan menos de 2 GB libres en MySQL"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.db_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648 # 2 GB en bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "${var.name_prefix}-redis-cpu-alta"
  alarm_description   = "CPU de Redis por encima del 70%"
  namespace           = "AWS/ElastiCache"
  metric_name         = "CPUUtilization"
  dimensions          = { CacheClusterId = var.cache_cluster_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 70
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${var.name_prefix}-redis-memoria-alta"
  alarm_description   = "Redis usa más del 80% de su memoria"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  dimensions          = { CacheClusterId = var.cache_cluster_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# --- Dashboard ----------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "EC2: uso de CPU (%)"
          region  = var.aws_region
          view    = "timeSeries"
          stat    = "Average"
          period  = 300
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "RDS MySQL: CPU (%) y conexiones"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_identifier, { yAxis = "right" }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "ElastiCache Redis: CPU (%) y memoria usada (%)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.cache_cluster_id],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.cache_cluster_id]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "Errores registrados por la app (logs)"
          region  = var.aws_region
          view    = "timeSeries"
          stat    = "Sum"
          period  = 60
          metrics = [["Tienda", "ErroresApp"]]
        }
      },
      {
        type = "log", x = 0, y = 12, width = 24, height = 6
        properties = {
          title  = "Últimos logs del contenedor"
          region = var.aws_region
          view   = "table"
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
        }
      }
    ]
  })
}
