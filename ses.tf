resource "aws_ses_email_identity" "valid_senders" {
    email    = var.valid_sender
}
