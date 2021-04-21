{
	"name": "${report_name}",
	"type": "TEST",
	"exportConfig": {
		"exportConfigType": "S3",
		"s3Destination": {
			"bucket": "${bucket_name}",
			"path": "${folder}",
			"packaging": "NONE"
		}
	}
}