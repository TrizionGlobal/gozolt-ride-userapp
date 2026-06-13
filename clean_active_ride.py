import re

with open('lib/features/ride/presentation/providers/active_ride_provider.dart', 'r') as f:
    content = f.read()

# 1. initializeRide
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{.*?\/\/ Real implementation: fetch ride \+ driver info from API', '', content, flags=re.DOTALL)

# 2. shareRide
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{.*?\}', '', content, count=1, flags=re.DOTALL)

# 3. triggerSos
content = re.sub(r'if \(!AppConstants\.kDevBypass\) \{([\s\S]*?)\}', r'\1', content, count=1)

# 4. rateRide
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{[\s\S]*?\} else \{([\s\S]*?)\}', r'\1', content, count=1)

# 5. addExtraFare
content = re.sub(r'if \(!AppConstants\.kDevBypass\) \{([\s\S]*?)\}', r'\1', content, count=1)

# 6. sendTip
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{[\s\S]*?\} else \{([\s\S]*?)\}', r'\1', content, count=1)

# 7. requestDestinationChange
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{[\s\S]*?return;\n    \}', '', content, count=1)

# 8. cancelDestinationChange
content = re.sub(r'if \(!AppConstants\.kDevBypass\) \{([\s\S]*?)\}', r'\1', content, count=1)

# 9. checkoutRide
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{[\s\S]*?\} else \{([\s\S]*?)\}', r'\1', content, count=1)

# 10. reconnectAndFetchState
content = re.sub(r'if \(AppConstants\.kDevBypass\) \{[\s\S]*?return;\n    \}', '', content, count=1)

with open('lib/features/ride/presentation/providers/active_ride_provider.dart', 'w') as f:
    f.write(content)

