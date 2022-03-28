resource "aws_iam_instance_profile" "phoenix_db_instance_profile" {
  name = "${aws_security_group.phoenix_db.id}-ec2-profile-${var.envir}"
  role = aws_iam_role.phoenix_db_instance_role.name

        depends_on = [aws_iam_role.phoenix_db_instance_role]
}

resource "aws_iam_role" "phoenix_db_instance_role" {
  name = "${aws_security_group.phoenix_db.id}-ec2-role-${var.envir}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "phoenix_db_instance_attach" {
  name       = "${aws_security_group.phoenix_db.id}-profile-attach-${var.envir}"
  roles      = [aws_iam_role.phoenix_db_instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.phoenix_db_instance_role]
}

resource "aws_iam_role_policy" "db_dump_bucket_write" {
  name = "phoenix-db-dump-bucket-write-${var.envir}"
  role = aws_iam_role.phoenix_db_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject*",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.db_dump_bucket.arn}/*"
      },
    ]
  })

  depends_on = [aws_iam_role.phoenix_db_instance_role, aws_s3_bucket.db_dump_bucket]
}