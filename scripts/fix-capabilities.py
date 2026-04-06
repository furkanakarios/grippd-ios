#!/usr/bin/env python3
"""
Fixes SystemCapabilities format in Xcode project after xcodegen generation.
xcodegen writes SystemCapabilities as a quoted string; Xcode needs a proper dict.
"""
import re, sys

path = 'Grippd.xcodeproj/project.pbxproj'

with open(path, 'r') as f:
    content = f.read()

# Replace the broken string form xcodegen outputs with proper Xcode dict format
fixed = re.sub(
    r'SystemCapabilities = "\[.*?\]";',
    'SystemCapabilities = {\n\t\t\t\t\t\t"com.apple.SignInWithApple" = {\n\t\t\t\t\t\t\tenabled = 1;\n\t\t\t\t\t\t};\n\t\t\t\t\t};',
    content,
    flags=re.DOTALL
)

if fixed == content:
    print('ℹ️  SystemCapabilities already in correct format or not found, skipping.')
    sys.exit(0)

with open(path, 'w') as f:
    f.write(fixed)

print('✅ SystemCapabilities patched for Sign in with Apple')
