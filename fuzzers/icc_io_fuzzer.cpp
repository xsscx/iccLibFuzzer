#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include <fcntl.h>
#include "IccProfile.h"
#include "IccUtil.h"
#include "IccIO.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128 || size > 2 * 1024 * 1024) return 0;
  
  char icc_file[] = "/tmp/fuzz_icc_XXXXXX";
  int fd = mkstemp(icc_file);
  if (fd == -1) return 0;
  
  write(fd, data, size);
  close(fd);
  
  // Test ICC profile I/O operations
  CIccFileIO io;
  if (io.Open(icc_file, "r")) {
    unsigned long length = io.GetLength();
    
    if (length > 0 && length < 10 * 1024 * 1024) {
      icUInt8Number *profile_data = (icUInt8Number *)malloc(length);
      if (profile_data) {
        io.Read8(profile_data, (icInt32Number)length);
        
        // Validate profile
        CIccProfile *pIcc = OpenIccProfile(profile_data, length);
        if (pIcc) {
          std::string report;
          pIcc->Validate(report);
          
          // Test write operations
          char out_file[] = "/tmp/fuzz_out_XXXXXX";
          int fd_out = mkstemp(out_file);
          if (fd_out != -1) {
            close(fd_out);
            CIccFileIO io_out;
            if (io_out.Open(out_file, "w")) {
              pIcc->Write(&io_out);
              io_out.Close();
            }
            unlink(out_file);
          }
          
          delete pIcc;
        }
        
        free(profile_data);
      }
    }
    io.Close();
  }
  
  unlink(icc_file);
  return 0;
}
