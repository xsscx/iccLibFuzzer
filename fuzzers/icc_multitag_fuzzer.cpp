/*
 * LibFuzzer target for multi-tag consistency validation
 * 
 * Targets:
 * - CIccProfile::Validate()
 * - Tag interdependencies
 * - Required tag combinations
 * - Cross-tag consistency checks
 */

#include "IccProfile.h"
#include "IccTag.h"
#include "IccUtil.h"
#include <stdint.h>
#include <stddef.h>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128) return 0;
  if (size > 10 * 1024 * 1024) return 0;

  CIccProfile *pProfile = nullptr;
  CIccMemIO *pIO = nullptr;

  try {
    pIO = new CIccMemIO;
    if (!pIO) return 0;

    if (!pIO->Attach((icUInt8Number*)data, size)) {
      delete pIO;
      return 0;
    }

    pProfile = new CIccProfile;
    if (!pProfile) {
      delete pIO;
      return 0;
    }

    if (!pProfile->Attach(pIO)) {
      delete pProfile;
      delete pIO;
      return 0;
    }

    // Deep validation (exercises tag consistency checks)
    std::string validationReport;
    icValidateStatus status = pProfile->Validate(validationReport);

    // Exercise tag lookup by signature (exercises tag retrieval and validation)
    for (icSignature sig : {
      icSigProfileDescriptionTag,
      icSigCopyrightTag,
      icSigMediaWhitePointTag,
      icSigChromaticAdaptationTag,
      icSigRedColorantTag,
      icSigGreenColorantTag,
      icSigBlueColorantTag,
      icSigRedTRCTag,
      icSigGreenTRCTag,
      icSigBlueTRCTag,
      icSigAToB0Tag,
      icSigBToA0Tag,
      icSigPreview0Tag,
      icSigGamutTag,
      icSigColorantTableTag
    }) {
      CIccTag *pTag = pProfile->FindTag(sig);
      if (pTag) {
        icTagTypeSignature type = pTag->GetType();
        
        // Validate individual tag
        std::string sigPath = "";
        std::string tagReport;
        pTag->Validate(sigPath, tagReport, pProfile);
      }
    }

    delete pProfile;

  } catch (...) {
    if (pProfile) delete pProfile;
  }

  return 0;
}
