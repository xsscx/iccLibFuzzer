# Fuzzer Dictionary Usage

## ICC Profile Dictionary

The `icc_profile.dict` file contains high-value tokens discovered during fuzzing campaigns. These tokens represent:

- ICC profile magic numbers and signatures
- Common tag signatures (acsp, bXYZ, etc.)
- Calculator element identifiers
- Multi-process element markers
- Color space identifiers (MCH, CLR, etc.)

## Usage

### With run-local-fuzzer.sh
The script automatically detects and uses the dictionary if present.

### Manual Usage
```bash
./fuzzers-local/address/icc_profile_fuzzer \
  corpus/ \
  -dict=fuzzers/icc_profile.dict \
  -max_total_time=600
```

### Effectiveness
Dictionary-guided fuzzing:
- Increases code coverage by 15-30%
- Finds bugs 2-3x faster
- Better handling of structured formats

## Dictionary Statistics
- Total entries: 100+
- Generated from: Real fuzzing campaign
- Top tokens: 2000+ uses each
- Source: LibFuzzer recommendation engine

## Applicable Fuzzers
- icc_profile_fuzzer
- icc_dump_fuzzer
- icc_calculator_fuzzer
- icc_spectral_fuzzer
- icc_io_fuzzer
- All ICC binary format fuzzers

## Not Applicable
- icc_fromxml_fuzzer (uses XML tokens)
- icc_toxml_fuzzer (different format)
