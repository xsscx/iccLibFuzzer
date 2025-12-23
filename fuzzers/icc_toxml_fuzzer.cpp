/*
 * LibFuzzer target for ICC-to-XML serialization
 * 
 * Targets:
 * - CIccProfileXml::ToXml
 * - Tag XML factories
 * - Round-trip serialization
 * 
 * Complements icc_fromxml_fuzzer by testing reverse direction
 */

#include "IccProfile.h"
#include "IccTag.h"
#include "IccUtil.h"
#include <stdint.h>
#include <stddef.h>

#ifdef HAVE_ICCXML
#include "IccProfileXml.h"
#include "IccUtilXml.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128) return 0;
  if (size > 5 * 1024 * 1024) return 0;

  CIccMemIO *pIO = nullptr;

  try {
    pIO = new CIccMemIO;
    if (!pIO) return 0;

    if (!pIO->Attach((icUInt8Number*)data, size)) {
      delete pIO;
      return 0;
    }

    // Convert to XML
    CIccProfileXml xmlProfile;
    if (xmlProfile.Attach(pIO)) {
      // Convert to XML string
      std::string xmlString;
      if (xmlProfile.ToXml(xmlString)) {
        // Successfully serialized to XML
        // This exercises XML generation and tag serialization
      }
    }
    // xmlProfile owns pIO now, it will be freed when xmlProfile goes out of scope

  } catch (...) {
    // If exception before Attach, we need to clean up
    // Otherwise xmlProfile destructor handles it
  }

  return 0;
}

#else
// Stub when IccXML not available
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  return 0;
}
#endif
