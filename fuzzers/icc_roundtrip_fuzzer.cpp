#include <stdint.h>
#include <stddef.h>
#include <string>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include "IccEval.h"
#include "IccPrmg.h"

class CIccMinMaxEval : public CIccEvalCompare {
public:
  virtual void Compare(icFloatNumber *, icFloatNumber *, icFloatNumber *, icFloatNumber *) override {}
};

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128 || size > 1024 * 1024) return 0;
  
  char tmp_file[] = "/tmp/fuzz_profile_XXXXXX";
  int fd = mkstemp(tmp_file);
  if (fd == -1) return 0;
  
  write(fd, data, size);
  close(fd);
  
  CIccMinMaxEval eval;
  
  // Test all rendering intents for comprehensive coverage
  icRenderingIntent intents[] = {
    icPerceptual,
    icRelativeColorimetric,
    icSaturation,
    icAbsoluteColorimetric
  };
  
  // Test both interpolation methods
  icXformInterp interps[] = {
    icInterpLinear,
    icInterpTetrahedral
  };
  
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 2; j++) {
      icStatusCMM stat = eval.EvaluateProfile(tmp_file, 0, intents[i], interps[j], false);
      
      if (stat == icCmmStatOk && i == 0 && j == 0) {
        // Only run PRMG on first successful evaluation to save time
        CIccPRMG prmg;
        prmg.EvaluateProfile(tmp_file, intents[i], interps[j], false);
      }
    }
  }
  
  unlink(tmp_file);
  return 0;
}
