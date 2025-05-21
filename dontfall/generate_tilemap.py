import xml.etree.ElementTree as ET

def print_map(name):
    xml = ET.parse(name + ".tmx")

    mp = xml.getroot()[1][0].text.strip().split(',')

    data = [(int(e)-1) for e in mp]

    rows = []

    for row in range(int(len(data) / 16)):
        line = []
        tileset_idx = 0
        for d in data[row*16:row*16+16]:
            next_tileset_idx = d*2
    #        print(d, tile_nb, tileset_idx)
            jump = next_tileset_idx - tileset_idx
            if jump < 0:
                line.append('$'+ hex(256+jump)[2:])
            else:
                line.append('$0'+ hex(jump)[2:])
            tileset_idx = next_tileset_idx+2
#        line.append('$00')
        
        rows.append(','.join(line))

    rows.reverse()

    print(name + ":")
    for row in rows:
        print('    db ' + row)

print_map("tilemap")
print_map("levels")
