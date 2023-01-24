#!/bin/bash

TIMESTAMP="$(date +%Y%M%d_%H%M%S)"

# if [[ ${1} == "" ]]; then
# 	echo "Usage: ${0} qemu|vbox"
# 	exit 1
# else
# 	BUILDER=${1}
# fi

PROFILE="default"
BUILDER="vbox"
# print command for configuring the aws profile 
#echo "aws configure --profile ${PROFILE}"

BUCKET="thn-infra-tools-prd"
IMAGE="pfSense-CE-2.6.0-one-nic"

echo "Copy image to S3 Bucket ..."
aws s3 cp --profile ${PROFILE} ../output-${BUILDER}/${IMAGE} s3://${BUCKET}/${IMAGE}

IMAGEFORMAT="$(echo ${IMAGE} | rev | cut -d "." -f1 | rev)"
IMPORTSNAPSHOT="import-snapshot_${TIMESTAMP}.json"

cp import-snapshot.json ${IMPORTSNAPSHOT}
sed -i s/FORMAT_PLACEHODLER/${IMAGEFORMAT}/g ${IMPORTSNAPSHOT}
sed -i s/BUCKET_PLACEHODLER/${BUCKET}/g ${IMPORTSNAPSHOT}
sed -i s/IMAGE_PLACEHODLER/${IMAGE}/g ${IMPORTSNAPSHOT}

echo "Import image as EC2 snapshot ..."
# print output to stdout, capture ImporTaskId
IMPORTTASKID=$(aws ec2 --profile ${PROFILE} import-snapshot --disk-container file://${IMPORTSNAPSHOT} | tee /dev/tty | grep ImportTaskId | cut -d \" -f 4)

# print command for following snapshot import status
echo aws ec2 --profile ${PROFILE} describe-import-snapshot-tasks --import-task-id ${IMPORTTASKID}

rm ${IMPORTSNAPSHOT}

#examples:

aws ec2 import-snapshot --description "pfSense CE 2.6.0 one nic" --disk-container file://import-snapshot.json 
aws ec2 describe-import-snapshot-tasks --import-task-id import-snap-02a30d470d2048d9e


aws ec2 import-image --description "pfSense CE 2.6.0 one nic" --disk-containers file://import-snapshot.json 

aws ec2 describe-import-image-tasks --import-task-ids import-ami-00bf191d208967d23