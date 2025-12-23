/*
 * LibFuzzer target for ICC spectral data processing
 * 
 * Targets:
 * - CIccTagSpectralViewingConditions
 * - CIccTagSpectralDataInfo
 * - Spectral illuminant calculations
 * 
 * Recent vulnerability: CVE-2025-SPECTRAL-NULL-DEREF (c572512)
 */

#include "IccProfile.h"
#include "IccTag.h"
#include "IccUtil.h"
#include "IccCmm.h"
#include <stdint.h>
#include <stddef.h>
#include <cstring>
#include <cmath>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128) return 0;  // Minimum ICC header
  if (size > 10 * 1024 * 1024) return 0;  // Max 10MB

  CIccProfile *pProfile = nullptr;
  CIccMemIO *pIO = nullptr;

  try {
    // Create memory I/O wrapper
    pIO = new CIccMemIO;
    if (!pIO) return 0;

    if (!pIO->Attach((icUInt8Number*)data, size)) {
      delete pIO;
      return 0;
    }

    // Parse ICC profile
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

    // Exercise spectral viewing conditions tag
    CIccTag *pTag = pProfile->FindTag(icSigSpectralViewingConditionsTag);
    if (pTag) {
      // Trigger spectral processing paths
      icTagTypeSignature tagType = pTag->GetType();
      
      // Attempt to write (triggers NULL deref if not fixed)
      CIccMemIO *pOutIO = new CIccMemIO;
      if (pOutIO) {
        pOutIO->Alloc(size + 1024);
        pTag->Write(pOutIO);
        delete pOutIO;
      }
    }

    // Exercise spectral white point
    pTag = pProfile->FindTag(icSigSpectralWhitePointTag);
    if (pTag) {
      icTagTypeSignature tagType = pTag->GetType();
    }

    // Exercise spectral data info
    pTag = pProfile->FindTag(icSigSpectralDataInfoTag);
    if (pTag) {
      icTagTypeSignature tagType = pTag->GetType();
    }

    // DEEP EXECUTION: Apply transformations if spectral profile
    if (pProfile->m_Header.colorSpace == icSigReflectanceSpectralData ||
        pProfile->m_Header.colorSpace == icSigTransmisionSpectralData ||
        pProfile->m_Header.pcs == icSigReflectanceSpectralPcsData) {
      CIccCmm *pCmm = new CIccCmm();
      if (pCmm && pCmm->AddXform(pProfile, icPerceptual)) {
        icFloatNumber spectral_in[16] = {0.5f};
        icFloatNumber spectral_out[16];
        pCmm->Apply(spectral_out, spectral_in);
      }
      if (pCmm) delete pCmm;
    }

    // Validate profile (triggers spectral validation paths)
    std::string validationReport;
    pProfile->Validate(validationReport);

    // Profile owns pIO after successful Attach()
    // Deleting profile will delete attached IO via Detach()
    delete pProfile;

  } catch (...) {
    // Profile destructor handles pIO cleanup if attached
    if (pProfile) delete pProfile;
  }

  return 0;
}
