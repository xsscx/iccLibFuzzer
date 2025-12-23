#include <stdint.h>
#include <stddef.h>
#include <string>
#include <cstring>
#include <unistd.h>
#include <sys/stat.h>
#include <libxml/parser.h>
#include "IccTagXmlFactory.h"
#include "IccMpeXmlFactory.h"
#include "IccProfileXml.h"
#include "IccIO.h"
#include "IccUtil.h"
#include "IccTag.h"

// Suppress libxml2 error/warning output during fuzzing
static void suppressXmlErrors(void *ctx, const char *msg, ...) {
  // Silently ignore errors - fuzzer is testing malformed inputs
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 10 || size > 10 * 1024 * 1024) return 0;

  // Suppress XML parser errors (expected when fuzzing malformed inputs)
  xmlSetGenericErrorFunc(nullptr, suppressXmlErrors);

  CIccTagCreator::PushFactory(new CIccTagXmlFactory());
  CIccMpeCreator::PushFactory(new CIccMpeXmlFactory());

  char temp_filename[] = "/tmp/fuzz_icc_xml_XXXXXX";
  int fd = mkstemp(temp_filename);
  if (fd == -1) return 0;

  ssize_t written = write(fd, data, size);
  close(fd);
  
  if (written != static_cast<ssize_t>(size)) {
    unlink(temp_filename);
    return 0;
  }

  CIccProfileXml profile;
  std::string reason;
  
  bool loaded = profile.LoadXml(temp_filename, nullptr, &reason);
  
  if (loaded) {
    std::string valid_report;
    icValidateStatus status = profile.Validate(valid_report);
    
    volatile icUInt32Number tmp;
    tmp = profile.m_Header.size;
    tmp = profile.m_Header.version;
    tmp = profile.m_Header.deviceClass;
    tmp = profile.m_Header.colorSpace;
    tmp = profile.m_Header.pcs;
    tmp = profile.m_Header.renderingIntent;
    (void)tmp;
    
    TagEntryList::iterator i;
    for (i = profile.m_Tags.begin(); i != profile.m_Tags.end(); i++) {
      if (i->pTag) {
        std::string desc;
        i->pTag->Describe(desc, 100);
        i->pTag->GetType();
        i->pTag->IsArrayType();
      }
    }
    
    char temp_output[] = "/tmp/fuzz_icc_out_XXXXXX";
    int out_fd = mkstemp(temp_output);
    if (out_fd != -1) {
      close(out_fd);
      
      SaveIccProfile(temp_output, &profile, icVersionBasedID);
      
      unlink(temp_output);
    }
  }
  
  unlink(temp_filename);
  return 0;
}
