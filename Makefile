include settings.mk

packer-image:
	docker build -t rastervision/packer -f Dockerfile.packer .

validate-packer-template:
	docker run --rm -it \
		-v ${PWD}/:/usr/local/src \
		-v ${HOME}/.aws:/root/.aws:ro \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_BATCH_BASE_AMI=${AWS_BATCH_BASE_AMI} \
		-e AWS_ROOT_BLOCK_DEVICE_SIZE=${AWS_ROOT_BLOCK_DEVICE_SIZE} \
		-w /usr/local/src \
		rastervision/packer \
		validate packer/template-gpu.json

create-image: validate-packer-template
	docker run --rm -it \
		-v ${PWD}/:/usr/local/src \
		-v ${HOME}/.aws:/root/.aws:ro \
		-e AWS_PROFILE=${AWS_PROFILE} \
		-e AWS_BATCH_BASE_AMI=${AWS_BATCH_BASE_AMI} \
		-e AWS_ROOT_BLOCK_DEVICE_SIZE=${AWS_ROOT_BLOCK_DEVICE_SIZE} \
		-w /usr/local/src \
		rastervision/packer \
		build packer/template-gpu.json


publish-container:
	$(eval ACCOUNT_ID=$(shell aws sts get-caller-identity --output text --query 'Account'))
	aws ecr get-login --no-include-email --region ${AWS_REGION} | bash;
	docker tag ${RASTER_VISION_IMAGE} \
		${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_IMAGE}:${ECR_IMAGE_TAG}
	docker push \
		${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_IMAGE}:${ECR_IMAGE_TAG}
