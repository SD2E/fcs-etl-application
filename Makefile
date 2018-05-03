.PHONY: tests container tests-local tests-reactor tests-deployed data-representation
.SILENT: tests container tests-local tests-reactor tests-deployed data-representation

PYTESTDIR := /src
URILIST := tests/jobs.txt
export INIFILE := app.ini
export TEMP_JOB_DIR := test-data

# all: clean app deploy postdeploy
# 	true

clean-tests:
	rm -rf .hypothesis .pytest_cache __pycache__ */__pycache__ tmp.*

# meta - remove the cached and test job data
clean-data: clean-cache clean-test-data
	true

# meta - allow all containers to be rebuilt
clean-containers: clean-base-containers clean-app-container
	true

# allow the base containers to be rebuilt
clean-base-containers:
	rm -rf .octave-base ; \
	docker rmi -f sd2e/octave-base:dev
	rm -rf .tasbe-base ; \
	docker rmi -f sd2e/tasbe-base:dev

# remove the agave app container
clean-app-container:
	bash scripts/remove_images.sh $(INIFILE)

# delete the cached job directories
clean-cache:
	rm -rf .jobcache/* ; \
	echo "Job template data has been removed. Re-download with 'make job-data'"

# delete the temporary test data directory
clean-test-data:
	rm -rf $(TEMP_JOB_DIR)/* ; \
	echo "Job data was deleted from $(TEMP_JOB_DIR)"

# meta - clean everything up
clean: clean-tests clean-containers
	true

# CONTAINERS
# build an image with octave and lots of base deps in it. uses .octave-base
# as a donefile.
.octave-base:
	docker build --no-cache -t sd2e/octave-base:dev -f Dockerfile.octave . ; \
	touch .octave-base

# layer in tasbe atop octave-base. uses .tasbe-base as a donefile.
.tasbe-base: .octave-base
	docker build --no-cache -t sd2e/tasbe-base:dev -f Dockerfile.tasbe . ; \
	touch .tasbe-base

# layer in requirements.txt, source, config, tests into final container
container: .tasbe-base
	apps-build-container -V -x "--no-cache" ; \
	echo "The app container is done building."
	echo "  make shell - explore the container interactively"
	echo "  make tests-pytest - run Python tests in the container"
	echo "  make tests-local - execute container (and wrapper) under emulation"

# JOB DATA
# Fetch and cache simulated job directories, namespaced by appId
job-cache:
	bash scripts/fetch-test-job-dirs.sh ; \
	echo "The job data cache has been refreshed."

# Copy a ready-to-use job directory from the cache
job-data: job-cache
	bash scripts/prep-test-job-dir.sh $(TEMP_JOB_DIR) ; \
	bash scripts/prep-test-job-ipcexe.sh $(TEMP_JOB_DIR) ; \
	echo "Temporary job directory is ready for use."
	echo "  'make tests-local' to execute the container (via its shell wrapper) under emulation"

# shell into the target container (assuming it's been built)
shell:
	bash scripts/run_container_tests.sh bash

# TESTING
# ((((Pytest-ception)))) run pytest inside your container on the /src
# directory. Configuration comes from setup.cfg which is copied into src
# in the Dockerfile
tests-pytest:
	echo "Running Pytests inside container. See STDOUT for results." ; \
	bash scripts/run_container_tests.sh pytest $(PYTESTDIR) -s -vvv $(PYTESTOPTS)

# Leverage test-data, the container, and generated ipcexe file to emulate
# running an Agave job in a local directory. This sidesteps the pain of
# waiting on deployment, job scheduling, and data marshaling, as well as the
# of remote debugging on the execution system (which is not always available
# to app developers and maintainers)
tests-local: job-data

	echo "Executing application under local emulation in $(TEMP_JOB_DIR)"
	echo "  $(TEMP_JOB_DIR)/local.ipcexe - emulated version of Agave's shell wrapper"
	echo "  $(TEMP_JOB_DIR)/.agave.log - emulated local Agave log file"
	echo "  $(TEMP_JOB_DIR)/.agave.archive - emulated no-archive manifest for the job"
	echo "  $(TEMP_JOB_DIR)/local.err - STDERR from your container process"
	echo "  $(TEMP_JOB_DIR)/local.out - STDOUT from your container process"
	echo "Run 'make clean-test-data && make job-data' to reset $(TEMP_JOB_DIR) to a pristine state."
	cd $(TEMP_JOB_DIR) ; \
	bash local.ipcexe

# tests-deployed:
#  	bash scripts/run_deployed_message.sh

# meta - run
# tests: tests-pytest tests-app
#  	true


deploy:
	apps-deploy --backup

# # postdeploy:
# # 	bash scripts/run_after_deploy.sh
