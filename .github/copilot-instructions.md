# Copilot Instructions for iccpatch

## Project Overview
iccpatch is an open source set of libraries and tools for interaction, manipulation, and application of ICC-based color management profiles. The project is maintained by the International Color Consortium (ICC) and uses the BSD 3-Clause License.

## Code Style Guidelines

### Indentation and Formatting
- Use **2 space indentation**, no tabs
- Use **K&R brace style**
- Aim for zero compiler warnings and static analysis warnings across all platforms

### Naming Conventions
- Prefix class/struct members with `m_` (e.g., `m_variableName`)
- No uniform convention for general variables - match nearby code
- Use descriptive names

### Code Organization
- Multiple classes per file, grouped by functionality
- Use header guards in all header files
- Minimize pollution of the `std` namespace
- Const correctness: make inputs const when possible, class functions const when appropriate

### Language Features
- **Error handling**: Use manual return values, NOT exceptions (this is the existing pattern)
- **Containers**: Prefer STL containers, but the codebase historically uses raw pointers
- **Templates**: Currently minimal use. Ensure new templates are readable
- **Namespaces**: Not currently using namespaces (work in progress)
- **C++ Standard**: Requires C++17 or higher

### Comments
- No consistent style exists - match nearby code
- Don't over-comment obvious code

## Build System

### Primary Build Tool
- CMake-based build system located in `Build/Cmake/`
- Supports multiple platforms: Linux, macOS, Windows

### Dependencies
Required libraries:
- libpng
- libjpeg-turbo
- libtiff
- wxwidgets
- nlohmann-json
- libxml2

### Build Commands

**Ubuntu/Linux:**
```bash
cd Build
cmake Cmake
make -j$(nproc)
```

**macOS:**
```bash
cmake -G "Xcode" Build/Cmake
xcodebuild -project RefIccMAX.xcodeproj
```

**Windows:**
```bash
vcpkg integrate install
vcpkg install
cmake --preset vs2022-x64 -B . -S Build/Cmake
cmake --build . -- /m /maxcpucount
```

## Testing
- Test scripts located in `Testing/` directory
- Run tests using `Testing/RunTests.sh` (Unix) or `Testing/RunTests.bat` (Windows)
- Profile creation: `Testing/CreateAllProfiles.sh`
- Test various ICC profile operations and transformations

### Available Tools
The project includes several tools for profile manipulation:

Command-line tools in `Tools/CmdLine/`:
- **IccApplyNamedCmm** - Apply color transformations using profiles
- **IccApplyProfiles** - Apply profiles to TIFF images
- **IccDumpProfile** - Display profile contents and validation info
- **IccRoundTrip** - Test colorimetric round-trip accuracy
- **IccTiffDump** - Display TIFF image and profile information
- **IccPngDump** - Display PNG image and profile information
- **IccJpegDump** - Display JPEG image and profile information
- **IccSpecSepToTiff** - Combine spectral images into multi-sample TIFF

XML tools in `IccXML/CmdLine/`:
- **IccFromXml** - Create ICC profiles from XML representation
- **IccToXml** - Convert ICC profiles to XML format

GUI tools in `Tools/wxWidget/`:
- **wxProfileDump** - GUI-based profile inspector

## Security Practices
- Report security issues via GitHub Security Advisory
- All new source files must begin with ICC Copyright notice and BSD 3-Clause License
- Follow secure coding practices
- Validate all inputs, especially when processing ICC profiles
- Be mindful of buffer overflows, integer overflows, and NaN/infinity handling
- Profile data is untrusted input - always validate sizes and ranges

## Legal and Licensing

### Copyright Notice
All new source files must begin with the ICC Copyright notice and include or reference the BSD 3-Clause "New" or "Revised" License.

### Contributor License Agreement
Contributors must sign the ICC Contributor License Agreement (CLA) before code can be merged.

## Pull Request Process
1. Create a topic branch: `feature/<your-feature>` or `bugfix/<your-fix>`
2. Make focused changes related to the topic
3. Ensure code compiles and tests pass
4. Follow existing code style and conventions
5. Create pull request with clear description
6. Address review feedback
7. Requires Committer approval before merge

## Project Structure
- `IccProfLib/` - Core ICC profile library
  - Contains fundamental classes for ICC profile manipulation
  - Key files: `IccProfile.h/cpp`, `IccTag*.h/cpp`, `IccUtil.h/cpp`
- `IccXML/` - XML handling for ICC profiles
  - Provides XML serialization/deserialization for profiles
  - Allows profiles to be represented and edited as XML
- `Tools/` - Command-line tools for profile manipulation
  - `CmdLine/` - Command-line utilities (IccApplyNamedCmm, IccDumpProfile, etc.)
  - `wxWidget/` - GUI-based profile inspector (wxProfileDump)
  - `Winnt/` - Windows-specific tools
- `Build/` - Build system files (CMake, XCode)
  - `Cmake/` - CMake configuration and build scripts
  - `Modules/` - CMake module files
- `Testing/` - Test files and scripts
  - Contains test profiles, test scripts, and reference data
  - Subdirectories for different profile types (Calc, Display, Named, PCC, etc.)
- `docs/` - Documentation
  - Build instructions, API documentation, and guides

## Key Considerations
- This is an older codebase - consistency is valued over perfection
- Match existing patterns when adding new code
- Focus on cross-platform compatibility (Linux, macOS, Windows)
- Performance matters for profile processing
- Maintain compatibility with ICC specifications

## Common Workflows

### Adding a New Source File
Every new source file must start with the ICC copyright header. This is a simplified example - refer to existing files like `IccProfLib/IccProfile.h` for the complete BSD 3-Clause license text (~50 lines):
```cpp
/** @file
    File:       YourFile.cpp
    Contains:   Brief description
    Version:    V1
    Copyright:  (c) see Software License
*/

/*
 * Copyright (c) International Color Consortium.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. In the absence of prior written permission, the names "ICC" and "The
 *    International Color Consortium" must not be used to imply that the
 *    ICC organization endorses or promotes products derived from this
 *    software.
 *
 * [... complete BSD 3-Clause license text continues for ~30 more lines ...]
 * See existing source files for full license text.
 */
```

### Building and Testing Workflow
1. Make code changes
2. Build: `cd Build && cmake Cmake && make -j$(nproc)` (Linux/macOS)
3. Run tests: `cd Testing && ./RunTests.sh`
4. Create test profiles: `./CreateAllProfiles.sh`
5. Verify no new compiler warnings

### Common Patterns
- Use `icFloatNumber` for floating-point values in ICC context
- Check for NaN and infinity using utilities from `IccUtil.h`
- Memory management: prefer smart pointers when adding new code, but maintain consistency with existing raw pointer usage
- Error checking: return `false` or appropriate error codes rather than throwing exceptions

## Troubleshooting

### Build Issues
- Missing dependencies: Install via package manager (see Dependencies section)
- CMake errors: Try cleaning build directory and regenerating
- Linker errors: Ensure all dependencies are found by CMake
- On Windows: Make sure vcpkg is properly integrated

### Common Pitfalls
- Don't add tabs - use 2 spaces only
- Don't throw exceptions in new code - use return values
- Don't forget the `m_` prefix for class/struct members
- Don't modify working code unnecessarily - surgical changes only
- Don't break cross-platform compatibility
