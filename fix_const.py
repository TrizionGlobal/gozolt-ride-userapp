import os
import re

lib_dir = '/Users/Trizion/Desktop/Gozolt_App/Flutter_Apps/gozolt-ride-userapp/lib'

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Regex to find const Text( ... AppTextStyles ... ) or similar
    # It's easier to just do a regex replace of "const Text(" with "Text(" everywhere in the file if the file has "AppTextStyles".
    # Same for const Center, const Padding.
    # Actually, the error says:
    # "The invocation of 'headlineMedium' is not allowed in a constant expression."
    
    # Let's just remove "const " if it's right before "Text(", "Center(", "Padding(" and the block contains AppTextStyles.
    # Or just replace all `const Text(` with `Text(` in files that failed, or globally.
    
    # We can just replace `const Text(` with `Text(` globally, the linter will suggest adding it back where possible, but it will compile.
    # To be safer, let's only replace `const Text` with `Text` in files that import AppTextStyles.
    
    new_content = content
    if 'AppTextStyles' in content:
        new_content = new_content.replace('const Text(', 'Text(')
        new_content = new_content.replace('const Center(\n', 'Center(\n')
        new_content = new_content.replace('const Center(child: Text', 'Center(child: Text')
        new_content = new_content.replace('const Padding(', 'Padding(')
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

