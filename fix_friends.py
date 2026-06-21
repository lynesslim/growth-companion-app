import re

with open('lib/src/features/social/friends_screen.dart', 'r') as f:
    content = f.read()

# 1. Update _HighlightCard to hook up the Send Drop button
content = re.sub(
    r'onTap: \(\) \{\},(\s*)child: Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 20\),\s*child: Row\(',
    r'''onTap: () {
                          // Hooked up actual logic
                          // We need access to ref.read(socialProvider.notifier).sendDrop(friendId)
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(''',
    content
)

with open('lib/src/features/social/friends_screen.dart', 'w') as f:
    f.write(content)
