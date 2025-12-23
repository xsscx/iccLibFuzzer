/*
 * LibFuzzer target for ICC profile dump/validation operations
 * 
 * Targets IccDumpProfile functionality:
 * - CIccInfo formatting methods
 * - Tag duplication detection
 * - Tag overlap/padding validation
 * - Verbosity level variations
 * - Header field formatting
 */

#include <stdint.h>
#include <stddef.h>
#include <map>
#include "IccProfile.h"
#include "IccTag.h"
#include "IccTagLut.h"
#include "IccUtil.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < 128 || size > 1024 * 1024) return 0;
  
  CIccProfile *pIcc = OpenIccProfile(data, size);
  if (pIcc) {
    std::string report;
    pIcc->Validate(report);
    
    // Exercise CIccInfo formatting methods (IccDumpProfile coverage)
    CIccInfo Fmt;
    icHeader *pHdr = &pIcc->m_Header;
    
    Fmt.GetDeviceAttrName(pHdr->attributes);
    Fmt.GetProfileFlagsName(pHdr->flags);
    Fmt.GetPlatformSigName(pHdr->platform);
    Fmt.GetCmmSigName((icCmmSignature)pHdr->cmmId);
    Fmt.GetRenderingIntentName((icRenderingIntent)pHdr->renderingIntent);
    Fmt.GetProfileClassSigName(pHdr->deviceClass);
    Fmt.GetColorSpaceSigName(pHdr->colorSpace);
    Fmt.GetColorSpaceSigName(pHdr->pcs);
    Fmt.GetVersionName(pHdr->version);
    Fmt.GetSpectralColorSigName(pHdr->spectralPCS);
    Fmt.IsProfileIDCalculated(&pHdr->profileID);
    Fmt.GetProfileID(&pHdr->profileID);
    
    if (pHdr->version >= icVersionNumberV5 && pHdr->deviceSubClass) {
      Fmt.GetSubClassVersionName(pHdr->version);
    }
    
    // Tag duplication detection (IccDumpProfile lines 303-308)
    std::map<icTagSignature, int> tagCounts;
    TagEntryList::iterator i, j;
    for (i = pIcc->m_Tags->begin(); i != pIcc->m_Tags->end(); i++) {
      tagCounts[i->TagInfo.sig]++;
    }
    
    // Tag overlap and padding validation (IccDumpProfile lines 337-380)
    size_t n = pIcc->m_Tags->size();
    icUInt32Number smallest_offset = pHdr->size;
    
    for (i = pIcc->m_Tags->begin(); i != pIcc->m_Tags->end(); i++) {
      // Track smallest offset for first tag validation
      if (i->TagInfo.offset < smallest_offset) {
        smallest_offset = i->TagInfo.offset;
      }
      
      // Check if offset+size exceeds file size (check for overflow first)
      icUInt32Number tag_end = i->TagInfo.offset + i->TagInfo.size;
      if ((tag_end > i->TagInfo.offset) && (tag_end > pHdr->size)) {
        // Non-compliant tag bounds
      }
      
      // Find closest following tag for overlap detection
      icUInt32Number closest = pHdr->size;
      for (j = pIcc->m_Tags->begin(); j != pIcc->m_Tags->end(); j++) {
        if ((i != j) && (j->TagInfo.offset > i->TagInfo.offset) && 
            (j->TagInfo.offset <= closest)) {
          closest = j->TagInfo.offset;
        }
      }
      
      // Check for tag overlap (tag_end already computed above)
      if ((tag_end > i->TagInfo.offset) &&  // Check for overflow
          (closest < tag_end) && 
          (closest < pHdr->size)) {
        // Overlapping tags detected
      }
      
      // Check for padding gaps (4-byte alignment)
      icUInt32Number rndup = 4 * ((i->TagInfo.size + 3) / 4);
      icUInt32Number aligned_end = i->TagInfo.offset + rndup;
      if ((aligned_end > i->TagInfo.offset) &&  // Check for overflow
          (closest > aligned_end)) {
        // Unnecessary gap between tags
      }
    }
    
    // First tag offset validation (IccDumpProfile lines 384-390)
    if (n > 0) {
      icUInt32Number expected_first_offset = 128 + 4 + (n * 12);
      if (smallest_offset > expected_first_offset) {
        // Non-compliant: gap after tag table
      }
    }
    
    // File size multiple-of-4 check (IccDumpProfile lines 331-335)
    if ((pHdr->version >= icVersionNumberV4_2) && (pHdr->size % 4 != 0)) {
      // Non-compliant file size
    }
    
    // Exercise all tags with multiple verbosity levels (DumpTag coverage)
    for (i = pIcc->m_Tags->begin(); i != pIcc->m_Tags->end(); i++) {
      if (i->pTag) {
        std::string desc;
        i->pTag->Describe(desc, 1);    // Minimal verbosity
        i->pTag->Describe(desc, 50);   // Medium verbosity
        i->pTag->Describe(desc, 100);  // Maximum verbosity
        i->pTag->GetType();
        
        // Array type detection
        if (i->pTag->IsArrayType()) {
          // Exercise array-specific paths
        }
        i->pTag->IsSupported();
        
        // Get tag signature name for formatting
        Fmt.GetTagSigName(i->TagInfo.sig);
        Fmt.GetTagTypeSigName(i->pTag->GetType());
      }
    }
    
    // Exercise comprehensive tag lookup (expanded coverage)
    icSignature tags[] = {icSigAToB0Tag, icSigAToB1Tag, icSigAToB2Tag,
                           icSigBToA0Tag, icSigBToA1Tag, icSigBToA2Tag,
                           icSigRedColorantTag, icSigGreenColorantTag, icSigBlueColorantTag,
                           icSigRedTRCTag, icSigGreenTRCTag, icSigBlueTRCTag,
                           icSigGrayTRCTag, icSigMediaWhitePointTag,
                           icSigLuminanceTag, icSigMeasurementTag,
                           icSigNamedColor2Tag, icSigColorantTableTag,
                           icSigChromaticAdaptationTag, icSigCopyrightTag,
                           icSigProfileDescriptionTag, icSigViewingCondDescTag,
                           icSigColorantOrderTag, icSigColorimetricIntentImageStateTag,
                           icSigPerceptualRenderingIntentGamutTag,
                           icSigSaturationRenderingIntentGamutTag,
                           icSigTechnologyTag, icSigDeviceMfgDescTag,
                           icSigDeviceModelDescTag, icSigProfileSequenceDescTag,
                           icSigCicpTag, icSigMetaDataTag};
    for (int j = 0; j < 32; j++) {
      CIccTag *tag = pIcc->FindTag(tags[j]);
      if (tag) {
        std::string desc;
        tag->Describe(desc, 50);
        std::string report;
        tag->Validate("", report);
      }
    }
    
    // Exercise profile methods
    pIcc->GetSpaceSamples();
    pIcc->AreTagsUnique();
    
    delete pIcc;
  }
  
  return 0;
}
