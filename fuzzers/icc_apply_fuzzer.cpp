#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include <fcntl.h>
#include "IccCmm.h"
#include "IccUtil.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 130 || size > 1024 * 1024) return 0;
  
  // Extract rendering intent and interpolation from first 2 bytes
  icRenderingIntent intent = (icRenderingIntent)(data[0] % 4);
  icXformInterp interp = (data[1] & 1) ? icInterpLinear : icInterpTetrahedral;
  
  char tmp_file[] = "/tmp/fuzz_apply_XXXXXX";
  int fd = mkstemp(tmp_file);
  if (fd == -1) return 0;
  write(fd, data + 2, size - 2);
  close(fd);
  
  CIccCmm cmm;
  if (cmm.AddXform(tmp_file, intent, interp) == icCmmStatOk) {
    if (cmm.Begin() == icCmmStatOk) {
      // Test multiple color value ranges
      icFloatNumber in[24] = {0.0, 0.25, 0.5, 0.75, 1.0, 0.0, 0.5, 1.0,
                               0.5, 0.5, 0.5, 0.1, 0.9, 0.3, 0.7, 0.6,
                               0.2, 0.4, 0.6, 0.8, 0.15, 0.35, 0.65, 0.95};
      icFloatNumber out[24];
      for (int i = 0; i < 8; i++) {
        cmm.Apply(out + i * 3, in + i * 3);
      }
      
      // Test edge cases including negative and >1.0
      icFloatNumber edge_in[] = {0.0, 0.0, 0.0, 1.0, 1.0, 1.0, -0.1, -0.1, -0.1, 1.1, 1.1, 1.1};
      icFloatNumber edge_out[12];
      for (int i = 0; i < 4; i++) {
        cmm.Apply(edge_out + i * 3, edge_in + i * 3);
      }
      
      // Exercise CMM info methods
      cmm.GetNumXforms();
      cmm.GetSourceSpace();
      cmm.GetDestSpace();
      cmm.Valid();
    }
  }
  
  unlink(tmp_file);
  return 0;
}
