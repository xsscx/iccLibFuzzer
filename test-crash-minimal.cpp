#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "IccProfile.h"
#include "IccIO.h"

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Usage: %s <icc-file>\n", argv[0]);
    return 1;
  }

  FILE *fp = fopen(argv[1], "rb");
  if (!fp) {
    printf("Failed to open %s\n", argv[1]);
    return 1;
  }

  fseek(fp, 0, SEEK_END);
  size_t size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  uint8_t *data = (uint8_t*)malloc(size);
  fread(data, 1, size, fp);
  fclose(fp);

  printf("Testing file size %zu\n", size);

  CIccProfile *pIcc = OpenIccProfile(data, size);
  if (pIcc) {
    printf("Profile loaded\n");
    
    // Test Write() - this is where crash may occur
    CIccMemIO io;
    io.Alloc(size * 2, true);  // Allocate buffer
    printf("Calling Write()...\n");
    bool writeResult = pIcc->Write(&io);
    icUInt32Number ioLen = io.GetLength();
    printf("Write returned %d, io.GetLength() = %u\n", writeResult, ioLen);
    
    if (writeResult && ioLen > 0) {
      printf("Write succeeded\n");
      // Try reading back
      io.Seek(0, icSeekSet);
      icUInt8Number *buf = new icUInt8Number[ioLen];
      io.Read8(buf, ioLen);
      printf("Read back %u bytes\n", ioLen);
      delete[] buf;
    }
    
    printf("Deleting profile...\n");
    delete pIcc;
    printf("Deleted\n");
  } else {
    printf("Failed to load profile\n");
  }

  free(data);
  return 0;
}
