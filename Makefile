.PHONY: tests container tests-local tests-reactor tests-deployed data-representation
.SILENT: tests container tests-local tests-reactor tests-deployed data-representation

PYTESTDIR := src
INIFILE := app.ini
export AGAVE_JOB_DIR := $(PWD)

# all: clean app deploy postdeploy
# 	true

clean-tests:
	rm -rf .hypothesis .pytest_cache __pycache__ */__pycache__ tmp.*

# allow the base containers to be rebuilt
clean-base-containers:
	rm -rf .octave-base
	docker rmi -f sd2e/octave-base:dev
	rm -rf .tasbe-base
	docker rmi -f sd2e/tasbe-base:dev

# remove the agave app container
clean-app-container:
	bash tests/remove_images.sh $(INIFILE)

# meta - allow all containers to be rebuilt
clean-containers: clean-base-containers clean-app-container
	true

# meta - clean everything up
clean: clean-tests clean-containers
	true

.octave-base:
	docker build --no-cache -t sd2e/octave-base:dev -f Dockerfile.octave .
	touch .octave-base

.tasbe-base: .octave-base
	docker build --no-cache -t sd2e/tasbe-base:dev -f Dockerfile.tasbe .
	touch .tasbe-base

container: .tasbe-base
	apps-build-container -V -x "--no-cache"

# # app:
# # 	apps-deploy -R

# shell into the target container (assuming it's been built)
shell:
	bash tests/run_container_tests.sh bash

tests-pytest:
	bash tests/run_container_tests.sh pytest $(PYTESTDIR) -s -vvv $(PYTESTOPTS)

# tests-app:
#  	bash tests/run_local_message.sh

# tests-deployed:
#  	bash tests/run_deployed_message.sh

# tests: tests-pytest tests-app
#  	true

# deploy:
# 	apps-deploy --backup

# # postdeploy:
# # 	bash tests/run_after_deploy.sh
