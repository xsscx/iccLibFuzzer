/*
 * LibFuzzer target for ICC calculator element processing
 * 
 * Targets:
 * - CIccMpeCalculator
 * - IccCalcImport macros
 * - Nested calculator expressions
 * - NaN propagation in calculations
 */

#include "IccProfile.h"
#include "IccTag.h"
#include "IccTagLut.h"
#include "IccUtil.h"
#include "IccMpeFactory.h"
#include "IccCmm.h"
#include <stdint.h>
#include <stddef.h>
#include <cmath>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128) return 0;
  if (size > 5 * 1024 * 1024) return 0;  // Max 5MB

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

    // Find and exercise calculator-containing tags
    // AToB tags often contain calculator elements
    for (icSignature sig : {
      icSigAToB0Tag, icSigAToB1Tag, icSigAToB2Tag, icSigAToB3Tag,
      icSigBToA0Tag, icSigBToA1Tag, icSigBToA2Tag, icSigBToA3Tag,
      icSigDToB0Tag, icSigDToB1Tag, icSigDToB2Tag, icSigDToB3Tag,
      icSigGamutTag, icSigPreview0Tag, icSigPreview1Tag, icSigPreview2Tag
    }) {
      CIccTag *pTag = pProfile->FindTag(sig);
      if (!pTag) continue;

      // Validate tag (triggers calculator validation)
      std::string sigPath = "";
      std::string report;
      pTag->Validate(sigPath, report, pProfile);

      // Exercise LUT/MPE type-specific paths
      icTagTypeSignature tagType = pTag->GetType();
      if (tagType == icSigLutAtoBType || tagType == icSigLutBtoAType) {
        // Exercise MPE chain traversal and calculator elements
        CIccTagLutAtoB *pLut = (CIccTagLutAtoB*)pTag;
        if (pLut) {
          // Trigger MPE chain validation and channel info
          icUInt16Number nInputChannels = pLut->InputChannels();
          icUInt16Number nOutputChannels = pLut->OutputChannels();
          
          // DEEP EXECUTION: Use CMM to apply calculator
          if (nInputChannels > 0 && nInputChannels <= 16 &&
              nOutputChannels > 0 && nOutputChannels <= 16) {
            CIccCmm *pCmm = new CIccCmm();
            if (pCmm && pCmm->AddXform(pProfile, icPerceptual)) {
              icFloatNumber test_values[][16] = {
                {0.0f}, {1.0f}, {0.5f}, {NAN}, {INFINITY}
              };
              
              for (size_t k = 0; k < 5; k++) {
                icFloatNumber out[16] = {0};
                pCmm->Apply(out, test_values[k]);
              }
            }
            if (pCmm) delete pCmm;
          }
        }
      }

      // Attempt to write (exercises serialization)
      CIccMemIO *pOutIO = new CIccMemIO;
      if (pOutIO) {
        pOutIO->Alloc(size + 4096);
        pTag->Write(pOutIO);
        delete pOutIO;
      }
    }

    // Overall profile validation
    std::string validationReport;
    pProfile->Validate(validationReport);

    delete pProfile;

  } catch (...) {
    if (pProfile) delete pProfile;
  }

  return 0;
}
