## Setup Bucket Access for backup
```json
s3:*
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BucketAccessForUser",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::tobi-backup",
                "arn:aws:s3:::tobi-backup/*"
            ]
        }
    ]
}
```
