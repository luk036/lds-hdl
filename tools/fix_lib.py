# Fix _dollar__NOT_ function and add _dollar__BUF_ cell
content = open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'r', encoding='utf-8').read()

# Step 1: Fix NOT function (A) -> (!A)
old_not = 'cell (_dollar__NOT_) {\n    area : 1.0 ;\n\n    pin (A) {\n      direction : "input" ;\n      capacitance : 0.5 ;\n    }\n\n    pin (Y) {\n      direction : "output" ;\n      capacitance : 0.5 ;\n      function : "(A)" ;'
new_not = old_not.replace('function : "(A)" ;', 'function : "(!A)" ;')
content = content.replace(old_not, new_not)

# Step 2: Add BUF cell after NOT cell
buf_cell = '''
  cell (_dollar__BUF_) {
    area : 1.0 ;

    pin (A) {
      direction : "input" ;
      capacitance : 0.5 ;
    }

    pin (Y) {
      direction : "output" ;
      capacitance : 0.5 ;
      function : "(A)" ;
      max_capacitance : 2.0 ;

      timing () {
        related_pin : "A" ;
        timing_sense : positive_unate ;
        cell_rise (delay_template_2x2) {
          values ("0.1, 0.2", "0.3, 0.4") ;
        }
        rise_transition (delay_template_2x2) {
          values ("0.05, 0.1", "0.2, 0.3") ;
        }
        cell_fall (delay_template_2x2) {
          values ("0.08, 0.18", "0.25, 0.35") ;
        }
        fall_transition (delay_template_2x2) {
          values ("0.04, 0.09", "0.18, 0.28") ;
        }
      }
    }

    leakage_power () {
      value : 0.001 ;
    }
  }
'''

# Find end of NOT cell definition
not_cell_end = content.find('leakage_power', content.find('_dollar__NOT_'))
brace = content.find('}', not_cell_end) + 1
content = content[:brace] + buf_cell + content[brace:]

open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'w', encoding='utf-8').write(content)
print('Fixed NOT and added BUF cell')
