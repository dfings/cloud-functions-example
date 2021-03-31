.PHONY: build clean release_run release_function run run_docker run_docker_image test venv

.DEFAULT_GOAL = run
.SHELLFLAGS = -ec

# Constants
APP_NAME = cloud-functions-example
FUNCTION_TARGET = handle_request
FUNCTION_TARGET_ENV = GOOGLE_FUNCTION_TARGET=$(FUNCTION_TARGET)
GCP_BUCKET = cloud-functions-example-bucket-12345
PROJECT = cloud-functions-example-project-12345
RELEASE_IMAGE = gcr.io/$(PROJECT)/$(APP_NAME)
RELEASE_LABEL := $(shell date +"%Y%m%d.%H%M%S")

# Deletes the __pycache__ directories.
clean:
	find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete

# Builds a local Docker image with pack.
build:
	pack build $(APP_NAME) \
		--path src \
		--env $(FUNCTION_TARGET_ENV) \
		--builder gcr.io/buildpacks/builder:v1

# Creates a timestamped released in GCR.
release_run: test clean
	gcloud config set project $(PROJECT)
	gcloud builds submit src --pack image=$(RELEASE_IMAGE),env=$(FUNCTION_TARGET_ENV)
	gcloud container images add-tag -q $(RELEASE_IMAGE):latest $(RELEASE_IMAGE):$(RELEASE_LABEL)

# Creates a zip file in the build/ directory, then copies it
# to a Google Cloud Storage bucket.
release_function: test clean
	mkdir -p build
	cd src; \
	zip -vr ../build/src-$(RELEASE_LABEL).zip . -x@.gcloudignore
	echo gsutil cp -n ../build/src-$(RELEASE_LABEL).zip gs://$(GCP_BUCKET)

# Runs a local debug server.
run:
	. .venv/bin/activate; \
	functions-framework --source src/main.py --target $(FUNCTION_TARGET) --debug

# Builds and runs a local Docker image.
run_docker: build run_docker_image

# Runs a local Docker image.
run_docker_image:
	docker run --rm -it -p 8080:8080 $(APP_NAME)

test:
	. ./.venv/bin/activate; \
	pytest; \
	pytype src; \
	mypy --strict --ignore-missing-imports src; \
	prospector

# Sets up the virtual environment.
venv:
	python -m venv .venv; \
	. .venv/bin/activate; \
	python -m pip install --upgrade pip wheel; \
	python -m pip install --upgrade functions-framework; \
	python -m pip install -r src/requirements.txt; \
	python -m pip install -r src/requirements-test.txt
