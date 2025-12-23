 cd /home/xss/copilot/ipatch && LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML:$LD_LIBRARY_PATH ./icc_applyprofiles_fuzzer -runs=100 corpus/icc_applyprofiles_standalone/ 2>&1 | tail -20
