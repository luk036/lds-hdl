content = open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'r', encoding='utf-8').read()
old = 'cell (_dollar__NOT_) {\n    area : 1.0 ;\n\n    pin (A) {\n      direction : "input" ;\n      capacitance : 0.5 ;\n    }\n\n    pin (Y) {\n      direction : "output" ;\n      capacitance : 0.5 ;\n      function : "(A)" ;'
new = old.replace('function : "(A)" ;', 'function : "(!A)" ;')
content = content.replace(old, new)
open('D:/github/cpp/lds-hdl/tutorial_tech.lib', 'w', encoding='utf-8').write(content)
print('Fixed: (A) -> (!A)')
