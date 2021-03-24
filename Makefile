.PHONY: release run run_docker test venv

.DEFAULT_GOAL = run
.SHELLFLAGS = -ec

# Constants
APP_NAME = cloud-functions-example
FUNCTION_TARGET = handle_request
GCP_BUCKET=cloud-functions-example-bucket-12345
RELEASE_LABEL := $(shell date +"%Y%m%d.%H%M%S")

release:
	mkdir -p build
	cd src; \
	zip -vr ../build/src-$(RELEASE_LABEL).zip . -x@.gcloudignore
	echo gsutil cp -n ../build/src-$(RELEASE_LABEL).zip gs://$(GCP_BUCKET)

run:
	# Runs a local debug server.
	. .venv/bin/activate; \
	cd src; \
	functions-framework --target $(FUNCTION_TARGET) --debug

run_docker:
	# Runs a local Docker server.
	pack build $(APP_NAME) \
		--path src \
		--env GOOGLE_FUNCTION_TARGET=$(FUNCTION_TARGET) \
		--builder gcr.io/buildpacks/builder:v1
	docker run --rm -it -p 8080:8080 $(APP_NAME)

test:
	# Runs the type checker.
	. ./.venv/bin/activate; \
	pytest; \
	pytype src

venv:
	# Sets up the virtual environment.
	python -m venv .venv; \
	. .venv/bin/activate; \
	python -m pip install --upgrade pip wheel; \
	python -m pip install --upgrade functions-framework; \
	python -m pip install -r src/requirements.txt; \
	python -m pip install -r test/requirements.txt
