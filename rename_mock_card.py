import glob

files = glob.glob('lib/**/*.dart', recursive=True)
for file in files:
    with open(file, 'r') as f:
        content = f.read()
    
    new_content = content.replace('mock_add_card_sheet.dart', 'add_card_sheet.dart')
    new_content = new_content.replace('MockAddCardSheet', 'AddCardSheet')
    
    if new_content != content:
        with open(file, 'w') as f:
            f.write(new_content)
        print(f"Updated {file}")

