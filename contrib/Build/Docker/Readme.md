## Dockerfiles

iccDEV now maintains a Docker Image. The current version in Packages is Built with `debug-asan --platform linux/amd64,linux/arm64`

To Install: `docker pull ghcr.io/internationalcolorconsortium/iccdev:latest`

To Run: `docker run -it ghcr.io/internationalcolorconsortium/iccdev:latest bash -l`

## Docker Login

- At login, you will see:

```
========= International Color Consortium ============
https://color.org              iccDEV v2.3.1.1 Docker
=====================================================

The Libraries & Tools are on PATH located in:

/opt/iccdev/Build/IccProfLib/libIccProfLib2.so.2.3.1.1
/opt/iccdev/Build/IccProfLib/libIccProfLib2-static.a
/opt/iccdev/Build/IccXML/libIccXML2.so.2.3.1.1
/opt/iccdev/Build/IccXML/libIccXML2-static.a
/opt/iccdev/Build/Tools/IccFromCube/iccFromCube
/opt/iccdev/Build/Tools/IccPngDump/iccPngDump
/opt/iccdev/Build/Tools/IccFromXml/iccFromXml
/opt/iccdev/Build/Tools/IccToXml/iccToXml
/opt/iccdev/Build/Tools/IccRoundTrip/iccRoundTrip
/opt/iccdev/Build/Tools/IccApplySearch/iccApplySearch
/opt/iccdev/Build/Tools/IccV5DspObsToV4Dsp/iccV5DspObsToV4Dsp
/opt/iccdev/Build/Tools/IccApplyProfiles/iccApplyProfiles
/opt/iccdev/Build/Tools/IccApplyToLink/iccApplyToLink
/opt/iccdev/Build/Tools/IccDumpProfile/iccDumpProfile
/opt/iccdev/Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm
/opt/iccdev/Build/Tools/IccSpecSepToTiff/iccSpecSepToTiff
/opt/iccdev/Build/Tools/IccTiffDump/iccTiffDump

The Testing directory contains pre-built ICC profiles

Open an Issue with Comments or Feedback at URL:
https://github.com/InternationalColorConsortium/iccDEV/issues

=== Thank you for using iccDEV Libraries & Tools ======

iccdev@061742a2614f:~$ iccToXml
IccToXml built with IccProfLib Version 2.3.1.1, IccLibXML Version 2.3.1.1

Usage: IccToXml src_icc_profile dest_xml_file
```

## Example Usage

`iccDumpProfile`

```
Usage: iccDumpProfile {-v} {int} profile {tagId to dump/"ALL"}
Built with IccProfLib version 2.3.1.1

The -v option causes profile validation to be performed.
The optional integer parameter specifies verboseness of output (1-100, default=100).
```

`iccFromXml`

```
IccFromXml built with IccProfLib Version 2.3.1.1, IccLibXML Version 2.3.1.1

Usage: IccFromXml xml_file saved_profile_file {-noid -v{=[relax_ng_schema_file - optional]}}
```

`iccToXml`

```
IccToXml built with IccProfLib Version 2.3.1.1, IccLibXML Version 2.3.1.1

Usage: IccToXml src_icc_profile dest_xml_file
```

`iccRoundTrip`

```
Usage: iccRoundTrip profile {rendering_intent=1 {use_mpe=0}}
Built with IccProfLib version 2.3.1.1
  where rendering_intent is (0=perceptual, 1=relative, 2=saturation, 3=absolute)
```




Please do post any comments or suggestions.

Thank You

---
