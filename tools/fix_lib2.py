content = open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'r', encoding='utf-8').read()

# Fix NOT (A) -> (!A)
old_not = 'function : "(A)" ;'
new_not = 'function : "(!A)" ;'
# Only fix inside the NOT cell
not_start = content.find('cell (_dollar__NOT_)')
not_end = content.find('\n  }', not_start) + 4
not_cell = content[not_start:not_end]
if '(A)' in not_cell:
    not_cell = not_cell.replace('function : "(A)" ;', 'function : "(!A)" ;')
    content = content[:not_start] + not_cell + content[not_end:]

# Remove BUF cell if present
if 'cell (_dollar__BUF_)' in content:
    buf_start = content.find('cell (_dollar__BUF_)')
    buf_end = content.find('\n  }', buf_start) + 4
    # Also remove trailing whitespace/blank lines
    while buf_end < len(content) and content[buf_end] in '\n\r ':
        buf_end += 1
    content = content[:buf_start] + content[buf_end:]

open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'w', encoding='utf-8').write(content)
print('Done. NOT=inverter, BUF=removed')
