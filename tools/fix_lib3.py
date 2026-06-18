content = open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'r', encoding='utf-8').read()

# Ensure NOT is inverter
not_start = content.find('cell (_dollar__NOT_)')
not_end = content.find('\n  }', not_start) + 4
not_cell = content[not_start:not_end]
not_cell = not_cell.replace('function : "(A)" ;', 'function : "(!A)" ;')
content = content[:not_start] + not_cell + content[not_end:]

# Add BUF cell if not present (after NOT)
if 'cell (_dollar__BUF_)' not in content:
    buf = (
        '\n  cell (_dollar__BUF_) {\n'
        '    area : 1.0 ;\n'
        '\n'
        '    pin (A) {\n'
        '      direction : "input" ;\n'
        '      capacitance : 0.5 ;\n'
        '    }\n'
        '\n'
        '    pin (Y) {\n'
        '      direction : "output" ;\n'
        '      capacitance : 0.5 ;\n'
        '      function : "(A)" ;\n'
        '      max_capacitance : 2.0 ;\n'
        '\n'
        '      timing () {\n'
        '        related_pin : "A" ;\n'
        '        timing_sense : positive_unate ;\n'
        '        cell_rise (delay_template_2x2) {\n'
        '          values ("0.1, 0.2", "0.3, 0.4") ;\n'
        '        }\n'
        '        rise_transition (delay_template_2x2) {\n'
        '          values ("0.05, 0.1", "0.2, 0.3") ;\n'
        '        }\n'
        '        cell_fall (delay_template_2x2) {\n'
        '          values ("0.08, 0.18", "0.25, 0.35") ;\n'
        '        }\n'
        '        fall_transition (delay_template_2x2) {\n'
        '          values ("0.04, 0.09", "0.18, 0.28") ;\n'
        '        }\n'
        '      }\n'
        '    }\n'
        '\n'
        '    leakage_power () {\n'
        '      value : 0.001 ;\n'
        '    }\n'
        '  }\n'
    )
    # Insert after NOT cell closing brace
    insert_point = content.find('\n  }', content.find('cell (_dollar__NOT_)')) + 4
    content = content[:insert_point] + buf + content[insert_point:]

open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'w', encoding='utf-8').write(content)
print('NOT=inverter, BUF=added')
