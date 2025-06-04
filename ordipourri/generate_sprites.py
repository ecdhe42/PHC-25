from PIL import Image

img = Image.open('ordipourri.png')

def encode_sprites(label, top_x, top_y, nb_lines, nb_cols=32):
    bytes = []
    for y in range(nb_lines):
        byte1 = 0
        for x in range(0, nb_cols, 8):
            byte1 = 0
            exp = 128
            for pixel in range(8):
                pixel_val = img.getpixel((x+top_x+pixel, y+top_y))
                if pixel_val:
                    byte1 += exp
                exp = int(exp/2)
            bytes.append("${:02X}".format(byte1))

    for i in range(0, len(bytes), 32):
        if i == 0:
            print(label + ":")
        row = bytes[i:i+32]
        print('    db ' + ','.join(row))

encode_sprites(label="label_cpu", top_x=0, top_y=1, nb_lines=15)
encode_sprites(label="label_ram", top_x=32, top_y=1, nb_lines=15)
encode_sprites(label="label_gpu", top_x=64, top_y=1, nb_lines=15)
encode_sprites(label="sprite_cpu", top_x=0, top_y=16, nb_lines=56)
encode_sprites(label="sprite_ram", top_x=32, top_y=16, nb_lines=56)
encode_sprites(label="sprite_gpu", top_x=64, top_y=16, nb_lines=56)
encode_sprites(label="sprite_olipix", top_x=0, top_y=72, nb_lines=31, nb_cols=24)
