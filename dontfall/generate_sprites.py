from PIL import Image

img = Image.open('sprites.png')

def encode_sprites(label, top_y):
    bytes = []
    for frame in range(4):
        for y in range(16):
            byte1 = 0
            byte2 = 0
            exp = 128
            for x in range(8):
                pixel1 = img.getpixel((x+frame*16, y+top_y))
                pixel2 = img.getpixel((x+8+frame*16, y+top_y))
                if pixel1:
                    byte1 += exp
                if pixel2:
                    byte2 += exp
                exp = int(exp/2)
            bytes.append("${:02X}".format(byte1))
            bytes.append("${:02X}".format(byte2))

    for i in range(0, len(bytes), 32):
        if i == 0:
            print(label + ":")
        elif i == 32:
            print(label + "0:")
        row = bytes[i:i+32]
        print('    db ' + ','.join(row))

encode_sprites("sprite_right", 0)
encode_sprites("sprite_left", 16)
