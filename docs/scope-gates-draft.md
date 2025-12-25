# DRAFT - Issue Scope Gates

Wed Dec 24 06:53:16 PM UTC 2025

## Purpose

This draft document outlines the concept of **AST gates** to classify fuzzing reports, bugs & security issues as **IN-SCOPE** or **OUT-OF-SCOPE** for `iccDEV`.

---

## Canonical Scope Definition (Authoritative)

A report is **IN-SCOPE** *only if* execution follows the canonical **Profile Attachment / Parse map**:

```
main / tool / fuzzer
 └─ OpenIccProfile / Attach / Read
     └─ CIccProfile::LoadTag
         └─ Tag::Read (virtual dispatch)
             └─ Tag-specific logic
```

If this path is not proven in the AST → **OUT-OF-SCOPE**.

### IccToXml

```
Build/clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   -I../IccXML/IccLibXML   $(pkg-config --cflags libxml-2.0)   ../IccXML/CmdLine/IccToXml/IccToXml.cpp  | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x5cbfba122950 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5cbfba124258 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
```

### iccDumpProfile

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccDumpProfile/iccDumpProfile.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x5794e3d7e5c0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5794e3d7fec8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5794e42ca938 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5794e42caa08 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5794e42cfec8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5794e42cff98 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5794e43355c0 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5794e43c45d8 <line:307:3, col:77> col:17 used GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5794e43c51a8 <line:315:3, col:67> col:17 used GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5794e43c7318 <line:339:3, col:52> col:17 used GetProfileID 'const icChar *(icProfileID *)'
```

### iccFromXML

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   -I../IccXML/IccLibXML   $(pkg-config --cflags libxml-2.0)   ../IccXML/CmdLine/IccFromXml/IccFromXml.cpp  |
 egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x57c6c1a80830 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x57c6c1a82138 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x57c6c1fa1028 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x57c6c1fa1bf8 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x57c6c1fa3d68 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
```

### iccRoundTrip

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccRoundTrip/iccRoundTrip.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Att
ach|Profile" | grep Get
| |-CXXMethodDecl 0x5a4708fbcf48 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5a4708fbdce8 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5a4708fbff18 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x5a47082f95d0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5a47082faed8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5a47095a2718 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5a47095a27e8 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5a47095b16a8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5a47095b1778 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5a470960ece0 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5a470964b288 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5a470964c1d8 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5a470964c2d0 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5a470964cbf0 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5a4709693b38 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
```

### iccApplyNamedCmm

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccApplyNamedCmm/iccApplyNamedCmm.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|
Read|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x64a55934b170 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x64a55934ca78 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x64a55989bec8 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x64a55989bf98 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x64a5598a1458 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x64a5598a1528 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x64a559904e90 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x64a559995b08 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x64a5599966d8 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x64a559998848 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x64a5599c95c8 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x64a5599ca518 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x64a5599ca610 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x64a5599caf30 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x64a559a1b348 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
```

### iccApplySearch

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccApplySearch/iccApplySearch.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read
|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x565ff6288830 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x565ff628a138 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x565ff67d9218 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x565ff67d92e8 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x565ff67de7a8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x565ff67de878 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x565ff68422a0 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x565ff68d2bb8 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x565ff68d3788 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x565ff68d58f8 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x565ff6906698 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x565ff69075e8 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x565ff69076e0 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x565ff6908000 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x565ff6958368 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
```

### iccApplytoLink

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccApplyToLink/iccApplyToLink.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read
|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x5d89084fd0e0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5d89084fe9e8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5d8908a40c28 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5d8908a40cf8 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5d8908a461b8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5d8908a46288 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5d8908aa9d70 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5d8908b3a448 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5d8908b3b018 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5d8908b3d188 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x5d8908b6dfb8 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5d8908b6ef08 <line:425:2, col:61> col:21 used GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5d8908b6f000 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5d8908b6f920 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5d8908bbfae8 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
```

### iccFromCube

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccFromCube/iccFromCube.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attac
h|Profile" | grep Get
| |-CXXMethodDecl 0x6374bfe10b90 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x6374bfe12498 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x6374c027dd08 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x6374c027ddd8 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x6374c0331790 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x6374c03be4e8 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x6374c03be5b8 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x6374c047e288 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x6374c047ee58 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x6374c0480fc8 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
```

### iccSpecSepToTiff

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccSpecSepToTiff/iccSpecSepToTiff.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attach|Profile" | grep Get
../Tools/CmdLine/IccSpecSepToTiff/iccSpecSepToTiff.cpp:81:10: fatal error: 'TiffImg.h' file not found
   81 | #include "TiffImg.h"
      |          ^~~~~~~~~~~
| |-CXXMethodDecl 0x587cfb5d1590 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x587cfb5d2e98 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x587cfba6c558 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x587cfba6c628 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x587cfba7b3c8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x587cfba7b498 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x587cfbadff30 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x587cfbb6db68 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x587cfbb72538 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x587cfbb746a8 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x587cfbba4768 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x587cfbba56b8 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x587cfbba57b0 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x587cfbba60d0 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x587cfbbf17c8 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
1 error generated.
```

### iccTiffDump

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccTiffDump/iccTiffDump.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attac
h|Profile" | grep Get
../Tools/CmdLine/IccTiffDump/iccTiffDump.cpp:78:10: fatal error: 'TiffImg.h' file not found
   78 | #include "TiffImg.h"
      |          ^~~~~~~~~~~
| |-CXXMethodDecl 0x5bd6f38decd0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5bd6f38e05d8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5bd6f3e303a8 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5bd6f3e30478 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5bd6f3e35938 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5bd6f3e35a08 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5bd6f3e994f0 <line:96:3, col:64> col:24 used GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5bd6f3f29d08 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5bd6f3f2a8d8 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5bd6f3f2ca48 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x5bd6f3f5d858 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5bd6f3f5e7a8 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5bd6f3f5e8a0 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5bd6f3f5f1c0 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5bd6f3faee98 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
1 error generated.
```


### iccV5DspObsToV4Dsp

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/CmdLine/IccV5DspObsToV4Dsp/IccV5DspObsToV4Dsp.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "O
pen|Read|Attach|Profile" | grep Get
| |-CXXMethodDecl 0x6048293788b0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x60482937a1b8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x6048298c5788 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x6048298c5858 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x6048298cad18 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x6048298cade8 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x604829930030 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x604829a0cad8 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x604829a0d6a8 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x604829a0f818 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
```

### wxProfileDump

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/wxWidget/wxProfileDump/wxProfileDump.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|
Attach|Profile" | grep Get
../Tools/wxWidget/wxProfileDump/wxProfileDump.cpp:78:10: fatal error: 'wx/wxprec.h' file not found
   78 | #include "wx/wxprec.h"
      |          ^~~~~~~~~~~~~
| |-CXXMethodDecl 0x5ad3138783c0 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5ad313879cc8 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5ad313dca248 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5ad313dca318 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5ad313dcf7d8 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5ad313dcf8a8 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5ad313e333c0 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5ad313ec3ab8 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5ad313ec4688 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5ad313ec67f8 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x5ad313ef8938 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5ad313ef9888 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5ad313ef9980 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5ad313efa2a0 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5ad313f4a6a8 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
1 error generated.
```

### iccDEVCmm

```
xss@xss:~/copilot/iccLibFuzzer/Build$ clang++ -Xclang -ast-dump -fsyntax-only   -I../IccProfLib   ../Tools/Winnt/IccDEVCmm/IccDEVCmm.cpp | egrep "CXXMethodDecl|FunctionDecl" | egrep "Open|Read|Attach|Prof
ile" | grep Get
In file included from ../Tools/Winnt/IccDEVCmm/IccDEVCmm.cpp:72:
../Tools/Winnt/IccDEVCmm/stdafx.h:11:10: fatal error: 'windows.h' file not found
   11 | #include <windows.h>
      |          ^~~~~~~~~~~
| |-CXXMethodDecl 0x5e67c16be520 <../IccProfLib/IccProfile.h:183:3, col:36> col:18 GetSpaceSamples 'icUInt16Number () const'
| |-CXXMethodDecl 0x5e67c16bfe28 <line:217:3, col:68> col:16 GetTag 'IccTagEntry *(icSignature, const CIccProfile *) const'
| |-CXXMethodDecl 0x5e67c19f4f88 <line:398:3, col:76> col:36 GetProfilePCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5e67c19f5058 <line:399:3, col:76> col:36 GetAppliedPCC 'IIccProfileConnectionConditions *()' implicit-inline
| |-CXXMethodDecl 0x5e67c19f9b48 <line:134:3, col:31> col:22 GetFirst 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5e67c19f9c18 <line:135:3, col:30> col:22 GetLast 'CIccProfileIdDesc *()'
| |-CXXMethodDecl 0x5e67c1a16da0 <line:96:3, col:64> col:24 GetProfile 'CIccProfile *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5e67c1aa49c8 <line:307:3, col:77> col:17 GetProfileFlagsName 'const icChar *(icUInt32Number, bool)'
| |-CXXMethodDecl 0x5e67c1aa5598 <line:315:3, col:67> col:17 GetProfileClassSigName 'const icChar *(icProfileClassSignature)'
| |-CXXMethodDecl 0x5e67c1aa76c8 <line:339:3, col:52> col:17 GetProfileID 'const icChar *(icProfileID *)'
| |-CXXMethodDecl 0x5e67c1ad6598 <line:404:3, col:86> col:44 GetProfileCC 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5e67c1ae09b8 <line:425:2, col:61> col:21 GetProfile 'const CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5e67c1ae0ab0 <line:428:3, col:59> col:16 GetProfilePtr 'CIccProfile *() const' implicit-inline
| |-CXXMethodDecl 0x5e67c1ae13d0 <line:441:3, col:110> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual implicit-inline
| |-CXXMethodDecl 0x5e67c1b2b298 <line:1445:3, col:70> col:44 GetConnectionConditions 'IIccProfileConnectionConditions *() const' virtual
1 error generated.
|-FunctionDecl 0x5e67c1b4f8a8 <line:935:1, line:950:1> line:935:21 invalid GetProfileFromBuf 'CIccProfile *(int)' static
```

## XML-only Code (Explicitly OUT-OF-SCOPE)

The following remain **OUT-OF-SCOPE** unless policy changes:
- `CIccProfileXml::ToXml*`
- XML serialization paths

```bash
clang++ -Xclang -ast-dump -Xclang -ast-dump-filter=ToXmlWithBlanks   -fsyntax-only -I../IccProfLib -I../IccXML/IccLibXML   $(pkg-config --cflags libxml-2.0)   ../IccXML/IccLibXML/IccProfileXml.cpp | egrep -q "OpenIccProfile|Attach|LoadTag|Read\(" && echo IN-SCOPE || echo OUT-OF-SCOPE
```

---

## Reviewer Acceptance Sentence

> **IN-SCOPE:** AST proves canonical path `LoadTag → Read → <Sink>` is reachable in `IccProfLib`; execution operates on user controllable input.

