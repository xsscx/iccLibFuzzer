#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include <fcntl.h>
#include "IccCmm.h"
#include "IccUtil.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 258 || size > 2 * 1024 * 1024) return 0;
  
  // Extract rendering intent and interpolation from first 2 bytes
  icRenderingIntent intent = (icRenderingIntent)(data[0] % 4);
  icXformInterp interp = (data[1] & 1) ? icInterpLinear : icInterpTetrahedral;
  
  // Use 3rd byte for PCS override flag (removed lutType - not used)
  bool useAbsPCS = (data[2] & 0x01);
  
  // Split remaining input into two profiles
  size_t mid = (size - 3) / 2 + 3;
  
  char tmp1[] = "/tmp/fuzz_link1_XXXXXX";
  char tmp2[] = "/tmp/fuzz_link2_XXXXXX";
  
  int fd1 = mkstemp(tmp1);
  int fd2 = mkstemp(tmp2);
  
  if (fd1 == -1 || fd2 == -1) {
    if (fd1 != -1) { close(fd1); unlink(tmp1); }
    if (fd2 != -1) { close(fd2); unlink(tmp2); }
    return 0;
  }
  
  write(fd1, data + 3, mid - 3);
  write(fd2, data + mid, size - mid);
  close(fd1);
  close(fd2);
  
  // Test profile linking with varied parameters
  CIccCmm cmm(icSigUnknownData, icSigUnknownData, useAbsPCS);
  if (cmm.AddXform(tmp1, intent, interp) == icCmmStatOk) {
    if (cmm.AddXform(tmp2, intent, interp) == icCmmStatOk) {
      if (cmm.Begin() == icCmmStatOk) {
        // Test varied color values through chain
        icFloatNumber in[16] = {0.0, 0.25, 0.5, 0.75, 1.0, 0.0, 0.5, 1.0, 
                                 0.5, 0.5, 0.5, 0.1, 0.9, 0.3, 0.7, 0.6};
        icFloatNumber out[16];
        for (int i = 0; i < 5; i++) {
          cmm.Apply(out + i * 3, in + i * 3);
        }
        
        // Test boundary values
        icFloatNumber bounds[] = {-0.1f, 0.0f, 1.0f, 1.1f, 0.5f, 0.5f};
        icFloatNumber bounds_out[6];
        cmm.Apply(bounds_out, bounds);
        cmm.Apply(bounds_out + 3, bounds + 3);
        
        // Exercise CMM chain info
        cmm.GetNumXforms();
        cmm.GetSourceSpace();
        cmm.GetDestSpace();
        cmm.Valid();
      }
    }
  }
  
  unlink(tmp1);
  unlink(tmp2);
  return 0;
}
