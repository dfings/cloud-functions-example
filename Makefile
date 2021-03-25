.PHONY: build clean run run_docker run_docker_image test venv

.DEFAULT_GOAL = run
.SHELLFLAGS = -ec

# Constants
APP_NAME = cloud-functions-example
FUNCTION_TARGET = handle_request
GCP_BUCKET=cloud-functions-example-bucket-12345
RELEASE_LABEL := $(shell date +"%Y%m%d.%H%M%S")

# Deletes the __pycache__ directories.
clean:
	find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete

# Builds a local Docker image with pack.
build:
	pack build $(APP_NAME) \
		--path src \
		--env GOOGLE_FUNCTION_TARGET=$(FUNCTION_TARGET) \
		--builder gcr.io/buildpacks/builder:v1

# Creates a zip file in the build/ directory, then copies it
# to a Google Cloud Storage bucket.
release: test clean
	mkdir -p build
	cd src; \
	zip -vr ../build/src-$(RELEASE_LABEL).zip . -x@.gcloudignore
	echo gsutil cp -n ../build/src-$(RELEASE_LABEL).zip gs://$(GCP_BUCKET)

# Runs a local debug server.
run:
	. .venv/bin/activate; \
	cd src; \
	functions-framework --target $(FUNCTION_TARGET) --debug

# Builds and runs a local Docker image.
run_docker: build run_docker_image

# Runs a local Docker image.
run_docker_image:
	docker run --rm -it -p 8080:8080 $(APP_NAME)

test:
	. ./.venv/bin/activate; \
	pytest; \
	pytype src

# Sets up the virtual environment.
venv:
	python -m venv .venv; \
	. .venv/bin/activate; \
	python -m pip install --upgrade pip wheel; \
	python -m pip install --upgrade functions-framework; \
	python -m pip install -r src/requirements.txt; \
	python -m pip install -r src/requirements-test.txt
