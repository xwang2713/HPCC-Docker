SCRIPT_DIR=$(dirname $0)

#URL_BASE=http://10.176.32.10/builds
URL_BASE=http://cdn.hpccsystems.com/releases

${SCRIPT_DIR}/build.sh -b "${URL_BASE}/CE-Candidate-5.4.8/bin/platform" \
-i /Users/ming/work/lexisnexis/Docker/HPCC-Docker/hpcc/trusty/Dockerfile.template \
-f hpccsystems-platform-community_5.4.8-1trusty_amd64.deb -t 5.4.8-1trusty
