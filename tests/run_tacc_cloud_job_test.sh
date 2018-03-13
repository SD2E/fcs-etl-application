 #!/bin/bash

jobs-submit -v -F deploy-${_AGAVE_USERNAME}-job.json && exit 0

exit 1

