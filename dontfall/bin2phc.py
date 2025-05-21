with open('loader.phc', 'rb') as f:
    loader = f.read()

header = loader[0:16]
basic = loader[16:32]
footer = loader[32:64]

with open('test.bin', 'rb') as f:
    asm = f.read()

output = header + basic + asm + footer

with open('test.phc', 'wb') as f:
    f.write(output)
