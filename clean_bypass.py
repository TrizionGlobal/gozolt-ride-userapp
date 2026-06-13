import os
import glob

def remove_bypass_blocks(content):
    while True:
        idx = content.find('if (AppConstants.kDevBypass)')
        if idx == -1:
            break
        
        # Find start of the block
        start_brace = content.find('{', idx)
        if start_brace == -1:
            # Maybe it's a single line if statement?
            # like `if (AppConstants.kDevBypass) return;`
            semicolon = content.find(';', idx)
            content = content[:idx] + content[semicolon+1:]
            continue
            
        # Check if there is a single line without braces before {
        # Actually in dart, `if (AppConstants.kDevBypass) return;` is common
        
        # If the `{` is far away, it might be a single line statement
        newline = content.find('\n', idx)
        if newline != -1 and newline < start_brace:
            # It's likely a single line statement without braces
            content = content[:idx] + content[newline+1:]
            continue

        # Count braces to find the end
        brace_count = 1
        end_idx = start_brace + 1
        while end_idx < len(content) and brace_count > 0:
            if content[end_idx] == '{':
                brace_count += 1
            elif content[end_idx] == '}':
                brace_count -= 1
            end_idx += 1
            
        # check if it's an if-else block
        # skip whitespaces after end_idx
        ws_idx = end_idx
        while ws_idx < len(content) and content[ws_idx] in ' \t\n':
            ws_idx += 1
            
        if content[ws_idx:ws_idx+4] == 'else':
            # It's an if-else block, we need to remove the `if` block and keep the `else` block content
            # Wait, `else { ... }`
            else_start_brace = content.find('{', ws_idx)
            if else_start_brace != -1:
                else_brace_count = 1
                else_end_idx = else_start_brace + 1
                while else_end_idx < len(content) and else_brace_count > 0:
                    if content[else_end_idx] == '{':
                        else_brace_count += 1
                    elif content[else_end_idx] == '}':
                        else_brace_count -= 1
                    else_end_idx += 1
                    
                # Replace the whole if-else with just the content inside the else
                else_content = content[else_start_brace+1:else_end_idx-1]
                content = content[:idx] + else_content + content[else_end_idx:]
            continue
            
        # Normal if block
        content = content[:idx] + content[end_idx:]
        
    return content

files = glob.glob('lib/**/*.dart', recursive=True)
for file in files:
    with open(file, 'r') as f:
        original = f.read()
    
    cleaned = remove_bypass_blocks(original)
    
    if cleaned != original:
        with open(file, 'w') as f:
            f.write(cleaned)
        print(f"Cleaned {file}")

