version = 1.0
account = $(shell aws sts get-caller-identity --query "Account" --output text)
image = jenkins-master-centos22b
region = us-east-1


testing:
	@echo current image version is $(version)

build: testing
	docker build -t $(image):$(version) docker/.

login: build
	aws ecr get-login-password --region $(region) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com

push: login
	docker tag $(image):$(version) $(account).dkr.ecr.$(region).amazonaws.com/$(image):$(version)
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(image):$(version)

deploy: push
	cat jenkins.yaml | sed "s/ACCT_NUMBER/$(account)/g;s/IMAGE/$(image)/g;s/VERSION/$(version)/g;s/REGION/$(region)/g" | kubectl apply -f -

delete:
	cat jenkins.yaml | sed "s/ACCT_NUMBER/$(account)/g;s/IMAGE/$(image)/g;s/VERSION/$(version)/g;s/REGION/$(region)/g" | kubectl delete -f -
