# Create file processing dead letter queue
resource "aws_sqs_queue" "file-processing-queue-dlq-RoK" {
  name                      = "${var.name}-dlq"
  delay_seconds             = "${var.delay_seconds}"
  max_message_size          = "${var.max_message_size}"
  message_retention_seconds = "${var.message_retention_seconds}"
  receive_wait_time_seconds = "${var.receive_wait_time_seconds}"
}

# Create file processing message queue
resource "aws_sqs_queue" "file-processing-queue-RoK" {
  name                      = "${var.name}"
  delay_seconds             = "${var.delay_seconds}"
  max_message_size          = "${var.max_message_size}"
  message_retention_seconds = "${var.message_retention_seconds}"
  receive_wait_time_seconds = "${var.receive_wait_time_seconds}"
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.file-processing-queue-dlq-RoK.arn}\",\"maxReceiveCount\":4}"
}