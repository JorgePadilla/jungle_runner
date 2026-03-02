#!/usr/bin/env python3
"""
Jungle Runner — Pixel Art Asset Generator
Generates all game sprites, backgrounds, and UI elements.
Style: 16-bit inspired pixel art with a lush jungle palette.
"""

from PIL import Image, ImageDraw
import os
import math
import random

random.seed(42)  # Reproducible art

# Output directories
BASE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "images")
os.makedirs(os.path.join(BASE, "player"), exist_ok=True)
os.makedirs(os.path.join(BASE, "background"), exist_ok=True)
os.makedirs(os.path.join(BASE, "ground"), exist_ok=True)
os.makedirs(os.path.join(BASE, "obstacles"), exist_ok=True)
os.makedirs(os.path.join(BASE, "collectibles"), exist_ok=True)
os.makedirs(os.path.join(BASE, "powerups"), exist_ok=True)
os.makedirs(os.path.join(BASE, "ui"), exist_ok=True)

# ─── Color Palette ───────────────────────────────────────────────
# Jungle palette
SKY_TOP = (135, 206, 235)
SKY_MID = (176, 224, 230)
SKY_BOT = (200, 235, 245)
CLOUD_WHITE = (255, 255, 255, 200)

MOUNTAIN_DARK = (80, 100, 120)
MOUNTAIN_MID = (100, 130, 150)
MOUNTAIN_LIGHT = (120, 150, 170)

TREE_DARK = (20, 80, 20)
TREE_MID = (34, 139, 34)
TREE_LIGHT = (50, 180, 50)
TREE_HIGHLIGHT = (100, 200, 80)

GROUND_TOP = (34, 139, 34)
GROUND_MID = (25, 100, 25)
GROUND_DIRT = (139, 90, 43)
GROUND_DIRT_DARK = (100, 65, 30)

# Monkey colors
MONKEY_BODY = (160, 100, 50)
MONKEY_BODY_DARK = (120, 75, 35)
MONKEY_BODY_LIGHT = (190, 130, 70)
MONKEY_BELLY = (220, 180, 140)
MONKEY_FACE = (210, 170, 120)
MONKEY_EYE = (30, 30, 30)
MONKEY_EYE_WHITE = (255, 255, 255)
MONKEY_NOSE = (80, 50, 30)
MONKEY_TAIL = (140, 85, 40)

# Obstacle colors
LOG_DARK = (100, 60, 25)
LOG_MID = (130, 80, 35)
LOG_LIGHT = (160, 110, 55)
LOG_RING = (90, 55, 20)

ROCK_DARK = (100, 100, 100)
ROCK_MID = (140, 140, 140)
ROCK_LIGHT = (170, 170, 170)

VINE_GREEN = (30, 120, 30)
VINE_DARK = (20, 80, 20)

# Coin colors
COIN_GOLD = (255, 215, 0)
COIN_DARK = (200, 170, 0)
COIN_LIGHT = (255, 240, 100)
COIN_SHINE = (255, 255, 200)

# Power-up colors
SHIELD_BLUE = (50, 150, 255)
SHIELD_LIGHT = (100, 200, 255)
MAGNET_RED = (200, 50, 50)
MAGNET_BLUE = (50, 50, 200)

TRANSPARENT = (0, 0, 0, 0)


def px(img, x, y, color):
    """Set a pixel with bounds checking."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def fill_rect(img, x1, y1, x2, y2, color):
    """Fill a rectangle."""
    draw = ImageDraw.Draw(img)
    draw.rectangle([x1, y1, x2, y2], fill=color)


# ─── MONKEY CHARACTER ────────────────────────────────────────────
def draw_monkey_frame(frame_type, frame_num=0, skin="default"):
    """Draw a single monkey frame at 40x60 pixels."""
    img = Image.new("RGBA", (40, 60), TRANSPARENT)
    
    # Skin color overrides
    body = MONKEY_BODY
    body_dark = MONKEY_BODY_DARK
    body_light = MONKEY_BODY_LIGHT
    
    if skin == "golden":
        body = (220, 180, 50)
        body_dark = (180, 140, 30)
        body_light = (240, 210, 80)
    elif skin == "dark":
        body = (50, 50, 55)
        body_dark = (30, 30, 35)
        body_light = (70, 70, 80)
    elif skin == "ninja":
        body = (30, 30, 35)
        body_dark = (15, 15, 20)
        body_light = (50, 50, 55)
    
    if frame_type == "run":
        _draw_monkey_run(img, frame_num, body, body_dark, body_light)
    elif frame_type == "jump":
        _draw_monkey_jump(img, body, body_dark, body_light)
    elif frame_type == "slide":
        _draw_monkey_slide(img, body, body_dark, body_light)
    elif frame_type == "idle":
        _draw_monkey_idle(img, body, body_dark, body_light)
    
    return img


def _draw_monkey_body_base(img, y_offset, body, body_dark, body_light):
    """Draw base monkey body."""
    d = ImageDraw.Draw(img)
    
    # Head (12x12, centered at top)
    head_x, head_y = 14, 2 + y_offset
    d.rounded_rectangle([head_x, head_y, head_x+12, head_y+12], radius=3, fill=body)
    # Head highlight
    fill_rect(img, head_x+1, head_y+1, head_x+4, head_y+3, body_light)
    
    # Ears
    d.ellipse([head_x-3, head_y+2, head_x+1, head_y+8], fill=body)
    d.ellipse([head_x-2, head_y+3, head_x, head_y+7], fill=MONKEY_FACE)
    d.ellipse([head_x+11, head_y+2, head_x+15, head_y+8], fill=body)
    d.ellipse([head_x+12, head_y+3, head_x+14, head_y+7], fill=MONKEY_FACE)
    
    # Face area
    d.ellipse([head_x+2, head_y+4, head_x+10, head_y+11], fill=MONKEY_FACE)
    
    # Eyes
    px(img, head_x+4, head_y+5, MONKEY_EYE_WHITE)
    px(img, head_x+5, head_y+5, MONKEY_EYE_WHITE)
    px(img, head_x+5, head_y+6, MONKEY_EYE)
    
    px(img, head_x+7, head_y+5, MONKEY_EYE_WHITE)
    px(img, head_x+8, head_y+5, MONKEY_EYE_WHITE)
    px(img, head_x+8, head_y+6, MONKEY_EYE)
    
    # Nose
    px(img, head_x+6, head_y+7, MONKEY_NOSE)
    
    # Mouth
    px(img, head_x+5, head_y+9, MONKEY_NOSE)
    px(img, head_x+6, head_y+9, MONKEY_NOSE)
    px(img, head_x+7, head_y+9, MONKEY_NOSE)
    
    # Body (torso)
    torso_y = head_y + 13
    d.rounded_rectangle([12, torso_y, 28, torso_y+18], radius=2, fill=body)
    # Belly
    d.ellipse([15, torso_y+3, 25, torso_y+14], fill=MONKEY_BELLY)
    # Body shading
    fill_rect(img, 12, torso_y, 14, torso_y+18, body_dark)
    
    return torso_y


def _draw_monkey_run(img, frame_num, body, body_dark, body_light):
    """Running animation (4 frames)."""
    d = ImageDraw.Draw(img)
    bounce = [0, -1, 0, 1][frame_num % 4]
    
    torso_y = _draw_monkey_body_base(img, bounce, body, body_dark, body_light)
    
    # Arms (animated)
    arm_phase = frame_num % 4
    if arm_phase == 0:
        d.line([(12, torso_y+4), (6, torso_y+12)], fill=body, width=3)
        d.line([(28, torso_y+4), (34, torso_y+8)], fill=body, width=3)
    elif arm_phase == 1:
        d.line([(12, torso_y+4), (8, torso_y+10)], fill=body, width=3)
        d.line([(28, torso_y+4), (32, torso_y+12)], fill=body, width=3)
    elif arm_phase == 2:
        d.line([(12, torso_y+4), (6, torso_y+8)], fill=body, width=3)
        d.line([(28, torso_y+4), (34, torso_y+12)], fill=body, width=3)
    else:
        d.line([(12, torso_y+4), (8, torso_y+14)], fill=body, width=3)
        d.line([(28, torso_y+4), (32, torso_y+8)], fill=body, width=3)
    
    # Legs (animated)
    leg_y = torso_y + 18
    if arm_phase == 0:
        d.line([(16, leg_y), (10, leg_y+12)], fill=body_dark, width=3)
        d.line([(24, leg_y), (30, leg_y+8)], fill=body_dark, width=3)
    elif arm_phase == 1:
        d.line([(16, leg_y), (14, leg_y+12)], fill=body_dark, width=3)
        d.line([(24, leg_y), (26, leg_y+12)], fill=body_dark, width=3)
    elif arm_phase == 2:
        d.line([(16, leg_y), (22, leg_y+8)], fill=body_dark, width=3)
        d.line([(24, leg_y), (18, leg_y+12)], fill=body_dark, width=3)
    else:
        d.line([(16, leg_y), (12, leg_y+8)], fill=body_dark, width=3)
        d.line([(24, leg_y), (28, leg_y+12)], fill=body_dark, width=3)
    
    # Tail (curled)
    tail_y = torso_y + 8
    d.arc([28, tail_y, 38, tail_y+16], start=270, end=180, fill=MONKEY_TAIL, width=2)


def _draw_monkey_jump(img, body, body_dark, body_light):
    """Jump pose."""
    d = ImageDraw.Draw(img)
    torso_y = _draw_monkey_body_base(img, -3, body, body_dark, body_light)
    
    # Arms up
    d.line([(12, torso_y+3), (4, torso_y-4)], fill=body, width=3)
    d.line([(28, torso_y+3), (36, torso_y-4)], fill=body, width=3)
    
    # Legs tucked
    leg_y = torso_y + 18
    d.line([(16, leg_y), (12, leg_y+6)], fill=body_dark, width=3)
    d.line([(12, leg_y+6), (16, leg_y+10)], fill=body_dark, width=3)
    d.line([(24, leg_y), (28, leg_y+6)], fill=body_dark, width=3)
    d.line([(28, leg_y+6), (24, leg_y+10)], fill=body_dark, width=3)
    
    # Tail stretched
    tail_y = torso_y + 10
    d.arc([28, tail_y, 40, tail_y+12], start=300, end=180, fill=MONKEY_TAIL, width=2)


def _draw_monkey_slide(img, body, body_dark, body_light):
    """Slide pose (shorter height)."""
    d = ImageDraw.Draw(img)
    
    # Rotated/crouched position - lower in the frame
    y_off = 28
    
    # Head (tilted)
    head_x, head_y = 8, y_off
    d.rounded_rectangle([head_x, head_y, head_x+12, head_y+10], radius=2, fill=body)
    d.ellipse([head_x+2, head_y+2, head_x+10, head_y+9], fill=MONKEY_FACE)
    px(img, head_x+4, head_y+4, MONKEY_EYE)
    px(img, head_x+8, head_y+4, MONKEY_EYE)
    
    # Body (horizontal)
    d.rounded_rectangle([head_x+10, head_y+2, head_x+30, head_y+14], radius=2, fill=body)
    d.ellipse([head_x+14, head_y+4, head_x+26, head_y+12], fill=MONKEY_BELLY)
    
    # Legs stretched back
    d.line([(head_x+26, head_y+10), (head_x+32, head_y+16)], fill=body_dark, width=3)
    
    # Tail
    d.arc([head_x+26, head_y, head_x+38, head_y+10], start=300, end=180, fill=MONKEY_TAIL, width=2)


def _draw_monkey_idle(img, body, body_dark, body_light):
    """Idle standing pose."""
    d = ImageDraw.Draw(img)
    torso_y = _draw_monkey_body_base(img, 0, body, body_dark, body_light)
    
    # Arms at sides
    d.line([(12, torso_y+4), (8, torso_y+16)], fill=body, width=3)
    d.line([(28, torso_y+4), (32, torso_y+16)], fill=body, width=3)
    
    # Legs straight
    leg_y = torso_y + 18
    d.line([(16, leg_y), (14, leg_y+12)], fill=body_dark, width=3)
    d.line([(24, leg_y), (26, leg_y+12)], fill=body_dark, width=3)
    
    # Tail relaxed
    tail_y = torso_y + 10
    d.arc([28, tail_y, 38, tail_y+14], start=280, end=180, fill=MONKEY_TAIL, width=2)


def generate_player_sprites():
    """Generate all player sprite sheets."""
    print("Generating player sprites...")
    
    for skin in ["default", "golden", "dark", "ninja"]:
        # Running (4 frames)
        sheet = Image.new("RGBA", (160, 60), TRANSPARENT)
        for i in range(4):
            frame = draw_monkey_frame("run", i, skin)
            sheet.paste(frame, (i * 40, 0))
        sheet.save(os.path.join(BASE, "player", f"run_{skin}.png"))
        
        # Jump (1 frame)
        frame = draw_monkey_frame("jump", 0, skin)
        frame.save(os.path.join(BASE, "player", f"jump_{skin}.png"))
        
        # Slide (1 frame)
        frame = draw_monkey_frame("slide", 0, skin)
        frame.save(os.path.join(BASE, "player", f"slide_{skin}.png"))
        
        # Idle (1 frame)
        frame = draw_monkey_frame("idle", 0, skin)
        frame.save(os.path.join(BASE, "player", f"idle_{skin}.png"))
    
    # Rainbow skin (special: hue-shifted)
    for anim in ["run", "jump", "slide", "idle"]:
        if anim == "run":
            sheet = Image.new("RGBA", (160, 60), TRANSPARENT)
            for i in range(4):
                frame = draw_monkey_frame("run", i, "default")
                # Apply rainbow tint
                _apply_rainbow_tint(frame)
                sheet.paste(frame, (i * 40, 0))
            sheet.save(os.path.join(BASE, "player", f"run_rainbow.png"))
        else:
            frame = draw_monkey_frame(anim, 0, "default")
            _apply_rainbow_tint(frame)
            frame.save(os.path.join(BASE, "player", f"{anim}_rainbow.png"))


def _apply_rainbow_tint(img):
    """Apply a rainbow color shift to an image."""
    pixels = img.load()
    for y in range(img.height):
        hue_shift = (y / img.height) * 360
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a > 0 and not (r > 200 and g > 200 and b > 200):  # Skip whites
                # Simple hue rotation
                t = (y * 6) / img.height
                if t < 1: nr, ng, nb = 255, int(t*255), 0
                elif t < 2: nr, ng, nb = int((2-t)*255), 255, 0
                elif t < 3: nr, ng, nb = 0, 255, int((t-2)*255)
                elif t < 4: nr, ng, nb = 0, int((4-t)*255), 255
                elif t < 5: nr, ng, nb = int((t-4)*255), 0, 255
                else: nr, ng, nb = 255, 0, int((6-t)*255)
                
                # Blend with original brightness
                bright = (r + g + b) / (3 * 255)
                pixels[x, y] = (
                    int(nr * bright),
                    int(ng * bright),
                    int(nb * bright),
                    a
                )


# ─── PARALLAX BACKGROUND ────────────────────────────────────────
def generate_backgrounds():
    """Generate 5-layer parallax background."""
    print("Generating parallax backgrounds...")
    W, H = 800, 600
    
    # Layer 0: Sky
    sky = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(sky)
    for y in range(H):
        t = y / H
        r = int(SKY_TOP[0] * (1-t) + SKY_BOT[0] * t)
        g = int(SKY_TOP[1] * (1-t) + SKY_BOT[1] * t)
        b = int(SKY_TOP[2] * (1-t) + SKY_BOT[2] * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    
    # Add clouds
    for cx, cy, cw in [(150, 60, 80), (400, 90, 100), (650, 50, 70), (250, 130, 60)]:
        d.ellipse([cx, cy, cx+cw, cy+cw//3], fill=(255,255,255,180))
        d.ellipse([cx+cw//4, cy-cw//8, cx+cw*3//4, cy+cw//4], fill=(255,255,255,160))
        d.ellipse([cx-cw//6, cy+cw//12, cx+cw//3, cy+cw//3], fill=(255,255,255,140))
    
    # Sun
    d.ellipse([620, 20, 680, 80], fill=(255, 250, 200, 200))
    d.ellipse([628, 28, 672, 72], fill=(255, 255, 220, 230))
    
    sky.save(os.path.join(BASE, "background", "sky.png"))
    
    # Layer 1: Far mountains
    mountains = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(mountains)
    
    points = [(0, H)]
    x = 0
    while x < W + 50:
        peak_h = random.randint(200, 350)
        points.append((x, H - peak_h))
        x += random.randint(80, 150)
        valley_h = random.randint(120, 200)
        points.append((x, H - valley_h))
        x += random.randint(40, 80)
    points.append((W, H))
    
    d.polygon(points, fill=MOUNTAIN_DARK + (180,))
    
    # Second mountain range (lighter, closer)
    points2 = [(0, H)]
    x = 30
    while x < W + 50:
        peak_h = random.randint(150, 280)
        points2.append((x, H - peak_h))
        x += random.randint(60, 120)
        valley_h = random.randint(100, 180)
        points2.append((x, H - valley_h))
        x += random.randint(30, 70)
    points2.append((W, H))
    d.polygon(points2, fill=MOUNTAIN_MID + (160,))
    
    mountains.save(os.path.join(BASE, "background", "mountains.png"))
    
    # Layer 2: Mid trees (forest silhouette)
    mid_trees = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(mid_trees)
    
    for tx in range(0, W, 35):
        tree_h = random.randint(150, 250)
        tree_w = random.randint(40, 60)
        tree_top = H - tree_h
        
        # Trunk
        trunk_w = tree_w // 5
        d.rectangle([tx + tree_w//2 - trunk_w//2, H-80, tx + tree_w//2 + trunk_w//2, H], 
                    fill=LOG_DARK + (150,))
        
        # Foliage (multiple overlapping circles)
        foliage_color = TREE_DARK + (160,)
        d.ellipse([tx, tree_top, tx+tree_w, tree_top+tree_h//2], fill=foliage_color)
        d.ellipse([tx-10, tree_top+tree_h//4, tx+tree_w+10, tree_top+tree_h*3//4], fill=foliage_color)
    
    mid_trees.save(os.path.join(BASE, "background", "mid_trees.png"))
    
    # Layer 3: Near trees
    near_trees = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(near_trees)
    
    for tx in range(0, W, 70):
        tree_h = random.randint(200, 350)
        tree_w = random.randint(50, 80)
        tree_top = H - tree_h
        
        # Thick trunk
        trunk_w = tree_w // 3
        trunk_x = tx + tree_w//2 - trunk_w//2
        d.rectangle([trunk_x, H-120, trunk_x+trunk_w, H], fill=LOG_MID + (200,))
        # Trunk detail
        for ty in range(H-120, H, 15):
            d.line([(trunk_x, ty), (trunk_x+trunk_w, ty)], fill=LOG_DARK + (100,), width=1)
        
        # Big foliage
        d.ellipse([tx-15, tree_top, tx+tree_w+15, tree_top+tree_h*2//3], fill=TREE_MID + (180,))
        d.ellipse([tx-5, tree_top+20, tx+tree_w+5, tree_top+tree_h//2], fill=TREE_LIGHT + (140,))
        
        # Vines hanging
        for vx in range(tx, tx+tree_w, 15):
            vine_len = random.randint(30, 80)
            vine_start = tree_top + tree_h//3
            for vy in range(vine_start, vine_start + vine_len, 2):
                px(near_trees, vx + int(math.sin(vy*0.1)*3), vy, VINE_GREEN + (180,))
    
    near_trees.save(os.path.join(BASE, "background", "near_trees.png"))
    
    # Layer 4: Close vegetation (bushes, ferns)
    vegetation = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(vegetation)
    
    ground_y = H - 100
    
    for bx in range(0, W, 25):
        bush_h = random.randint(30, 60)
        bush_w = random.randint(25, 45)
        
        # Bush
        d.ellipse([bx, ground_y - bush_h, bx + bush_w, ground_y + 5], 
                  fill=TREE_DARK + (220,))
        d.ellipse([bx+5, ground_y - bush_h + 5, bx + bush_w - 5, ground_y], 
                  fill=TREE_MID + (200,))
        
        # Fern/grass blades
        for gx in range(bx, bx+bush_w, 4):
            grass_h = random.randint(10, 25)
            for gy in range(ground_y - grass_h, ground_y):
                offset = int(math.sin(gy * 0.2) * 2)
                px(vegetation, gx + offset, gy, TREE_LIGHT + (200,))
    
    vegetation.save(os.path.join(BASE, "background", "vegetation.png"))


# ─── GROUND TILE ─────────────────────────────────────────────────
def generate_ground():
    """Generate tileable ground."""
    print("Generating ground tiles...")
    W, H = 256, 100
    
    ground = Image.new("RGBA", (W, H), TRANSPARENT)
    d = ImageDraw.Draw(ground)
    
    # Grass top layer
    for y in range(0, 15):
        t = y / 15
        r = int(GROUND_TOP[0] * (1-t) + GROUND_MID[0] * t)
        g = int(GROUND_TOP[1] * (1-t) + GROUND_MID[1] * t)
        b = int(GROUND_TOP[2] * (1-t) + GROUND_MID[2] * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    
    # Dirt layer
    for y in range(15, H):
        t = (y - 15) / (H - 15)
        r = int(GROUND_DIRT[0] * (1-t) + GROUND_DIRT_DARK[0] * t)
        g = int(GROUND_DIRT[1] * (1-t) + GROUND_DIRT_DARK[1] * t)
        b = int(GROUND_DIRT[2] * (1-t) + GROUND_DIRT_DARK[2] * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    
    # Grass blades on top
    for gx in range(0, W, 3):
        gh = random.randint(4, 10)
        grass_c = random.choice([TREE_LIGHT, TREE_MID, GROUND_TOP])
        for gy in range(-gh, 0):
            px(ground, gx, gy + 5, grass_c + (255,) if len(grass_c) == 3 else grass_c)
    
    # Dirt texture (small rocks, roots)
    for _ in range(30):
        rx = random.randint(0, W-6)
        ry = random.randint(20, H-10)
        rs = random.randint(2, 5)
        d.ellipse([rx, ry, rx+rs, ry+rs], fill=ROCK_MID + (100,))
    
    # Roots
    for _ in range(5):
        rx = random.randint(0, W)
        ry = random.randint(12, 20)
        d.line([(rx, ry), (rx + random.randint(-20, 20), ry + random.randint(5, 15))],
               fill=LOG_DARK + (150,), width=2)
    
    ground.save(os.path.join(BASE, "ground", "ground_tile.png"))


# ─── OBSTACLES ───────────────────────────────────────────────────
def generate_obstacles():
    """Generate obstacle sprites."""
    print("Generating obstacles...")
    
    # Log obstacle (50x50)
    log = Image.new("RGBA", (50, 50), TRANSPARENT)
    d = ImageDraw.Draw(log)
    
    # Main log body
    d.rounded_rectangle([2, 5, 48, 45], radius=5, fill=LOG_MID)
    d.rounded_rectangle([4, 7, 46, 43], radius=4, fill=LOG_LIGHT)
    
    # Wood grain lines
    for ly in range(10, 42, 6):
        d.line([(6, ly), (44, ly)], fill=LOG_DARK + (100,), width=1)
    
    # End rings
    d.ellipse([2, 10, 14, 40], fill=LOG_MID)
    d.ellipse([4, 12, 12, 38], fill=LOG_LIGHT)
    d.ellipse([6, 18, 10, 32], fill=LOG_RING)
    d.ellipse([7, 22, 9, 28], fill=LOG_DARK)
    
    # Bark texture on top/bottom
    d.line([(2, 5), (48, 5)], fill=LOG_DARK, width=2)
    d.line([(2, 45), (48, 45)], fill=LOG_DARK, width=2)
    
    log.save(os.path.join(BASE, "obstacles", "log.png"))
    
    # Rock obstacle (50x50)
    rock = Image.new("RGBA", (50, 50), TRANSPARENT)
    d = ImageDraw.Draw(rock)
    
    # Rock shape (irregular polygon)
    rock_points = [(10, 45), (3, 30), (8, 12), (20, 3), (35, 5), (45, 15), (47, 35), (40, 45)]
    d.polygon(rock_points, fill=ROCK_MID)
    
    # Highlights
    d.polygon([(12, 40), (6, 28), (12, 14), (22, 8), (30, 10)], fill=ROCK_LIGHT + (100,))
    
    # Shadow/cracks
    d.line([(15, 15), (25, 25)], fill=ROCK_DARK, width=1)
    d.line([(30, 12), (35, 28)], fill=ROCK_DARK, width=1)
    d.line([(20, 30), (32, 38)], fill=ROCK_DARK, width=1)
    
    # Moss
    for mx in range(8, 30, 3):
        d.ellipse([mx, 8, mx+4, 13], fill=TREE_DARK + (150,))
    
    rock.save(os.path.join(BASE, "obstacles", "rock.png"))
    
    # Vine obstacle (50x80, hangs from top)
    vine = Image.new("RGBA", (50, 80), TRANSPARENT)
    d = ImageDraw.Draw(vine)
    
    # Main vine
    for vy in range(0, 80, 2):
        vx = 25 + int(math.sin(vy * 0.08) * 8)
        d.ellipse([vx-3, vy, vx+3, vy+4], fill=VINE_GREEN)
        d.ellipse([vx-2, vy+1, vx+2, vy+3], fill=VINE_DARK)
    
    # Leaves along vine
    for vy in range(10, 75, 12):
        vx = 25 + int(math.sin(vy * 0.08) * 8)
        side = 1 if vy % 24 < 12 else -1
        leaf_points = [(vx, vy), (vx + side*12, vy-4), (vx + side*8, vy+2)]
        d.polygon(leaf_points, fill=TREE_LIGHT)
        leaf_points2 = [(vx, vy+6), (vx + side*10, vy+2), (vx + side*6, vy+8)]
        d.polygon(leaf_points2, fill=TREE_MID)
    
    vine.save(os.path.join(BASE, "obstacles", "vine.png"))


# ─── COLLECTIBLES ────────────────────────────────────────────────
def generate_coins():
    """Generate coin animation frames."""
    print("Generating coins...")
    
    frames = 6
    sheet = Image.new("RGBA", (frames * 20, 20), TRANSPARENT)
    
    for i in range(frames):
        frame = Image.new("RGBA", (20, 20), TRANSPARENT)
        d = ImageDraw.Draw(frame)
        
        # Coin width varies for rotation effect
        squeeze = abs(math.sin(i * math.pi / frames))
        w = max(3, int(18 * squeeze))
        cx = 10
        
        # Outer ring
        d.ellipse([cx-w//2, 1, cx+w//2, 19], fill=COIN_GOLD)
        
        # Inner detail
        if w > 6:
            d.ellipse([cx-w//2+2, 3, cx+w//2-2, 17], fill=COIN_LIGHT)
            # Diamond symbol in center
            if w > 10:
                diamond = [(cx, 6), (cx+3, 10), (cx, 14), (cx-3, 10)]
                d.polygon(diamond, fill=COIN_DARK)
        
        # Shine
        if w > 4:
            px(frame, cx-w//4, 4, COIN_SHINE)
            px(frame, cx-w//4+1, 4, COIN_SHINE)
        
        sheet.paste(frame, (i * 20, 0))
    
    sheet.save(os.path.join(BASE, "collectibles", "coin_sheet.png"))
    
    # Also save individual coin for static use
    coin_static = Image.new("RGBA", (20, 20), TRANSPARENT)
    d = ImageDraw.Draw(coin_static)
    d.ellipse([1, 1, 19, 19], fill=COIN_GOLD)
    d.ellipse([3, 3, 17, 17], fill=COIN_LIGHT)
    d.ellipse([6, 6, 14, 14], fill=COIN_GOLD)
    px(coin_static, 8, 5, COIN_SHINE)
    px(coin_static, 9, 5, COIN_SHINE)
    coin_static.save(os.path.join(BASE, "collectibles", "coin.png"))


# ─── POWER-UPS ───────────────────────────────────────────────────
def generate_powerups():
    """Generate power-up sprites."""
    print("Generating power-ups...")
    
    # Shield (30x30)
    shield = Image.new("RGBA", (30, 30), TRANSPARENT)
    d = ImageDraw.Draw(shield)
    
    # Shield shape
    points = [(15, 2), (27, 8), (25, 22), (15, 28), (5, 22), (3, 8)]
    d.polygon(points, fill=SHIELD_BLUE + (200,))
    
    inner = [(15, 5), (24, 10), (22, 21), (15, 25), (8, 21), (6, 10)]
    d.polygon(inner, fill=SHIELD_LIGHT + (180,))
    
    # Star in center
    d.ellipse([11, 11, 19, 19], fill=(255, 255, 255, 200))
    d.ellipse([13, 13, 17, 17], fill=SHIELD_BLUE + (220,))
    
    # Glow effect
    d.ellipse([0, 0, 30, 30], outline=SHIELD_LIGHT + (80,), width=2)
    
    shield.save(os.path.join(BASE, "powerups", "shield.png"))
    
    # Magnet (30x30)
    magnet = Image.new("RGBA", (30, 30), TRANSPARENT)
    d = ImageDraw.Draw(magnet)
    
    # U-shaped magnet
    d.arc([5, 2, 25, 22], start=0, end=180, fill=MAGNET_RED, width=5)
    d.rectangle([5, 10, 10, 25], fill=MAGNET_RED)
    d.rectangle([20, 10, 25, 25], fill=MAGNET_BLUE)
    
    # Pole tips
    d.rectangle([4, 22, 11, 28], fill=ROCK_LIGHT)
    d.rectangle([19, 22, 26, 28], fill=ROCK_LIGHT)
    
    # Magnetic field lines
    d.arc([0, 0, 30, 30], start=0, end=180, fill=(200, 200, 255, 80), width=1)
    
    magnet.save(os.path.join(BASE, "powerups", "magnet.png"))


# ─── UI ELEMENTS ─────────────────────────────────────────────────
def generate_ui():
    """Generate UI elements."""
    print("Generating UI elements...")
    
    # Pause button (48x48)
    pause = Image.new("RGBA", (48, 48), TRANSPARENT)
    d = ImageDraw.Draw(pause)
    d.rounded_rectangle([0, 0, 47, 47], radius=10, fill=(0, 0, 0, 150))
    d.rounded_rectangle([2, 2, 45, 45], radius=8, fill=(50, 50, 50, 200))
    d.rectangle([14, 12, 20, 36], fill=(255, 255, 255, 230))
    d.rectangle([28, 12, 34, 36], fill=(255, 255, 255, 230))
    pause.save(os.path.join(BASE, "ui", "pause_btn.png"))
    
    # Play button (48x48)
    play = Image.new("RGBA", (48, 48), TRANSPARENT)
    d = ImageDraw.Draw(play)
    d.rounded_rectangle([0, 0, 47, 47], radius=10, fill=(0, 0, 0, 150))
    d.rounded_rectangle([2, 2, 45, 45], radius=8, fill=(50, 50, 50, 200))
    d.polygon([(16, 10), (38, 24), (16, 38)], fill=(255, 255, 255, 230))
    play.save(os.path.join(BASE, "ui", "play_btn.png"))
    
    # Heart icon (20x20)
    heart = Image.new("RGBA", (20, 20), TRANSPARENT)
    d = ImageDraw.Draw(heart)
    d.ellipse([1, 2, 10, 10], fill=(220, 50, 50))
    d.ellipse([10, 2, 19, 10], fill=(220, 50, 50))
    d.polygon([(2, 8), (10, 18), (18, 8)], fill=(220, 50, 50))
    d.ellipse([3, 3, 8, 7], fill=(255, 100, 100, 150))
    heart.save(os.path.join(BASE, "ui", "heart.png"))
    
    # Coin icon for HUD (16x16)
    coin_hud = Image.new("RGBA", (16, 16), TRANSPARENT)
    d = ImageDraw.Draw(coin_hud)
    d.ellipse([1, 1, 15, 15], fill=COIN_GOLD)
    d.ellipse([3, 3, 13, 13], fill=COIN_LIGHT)
    d.ellipse([5, 5, 11, 11], fill=COIN_GOLD)
    coin_hud.save(os.path.join(BASE, "ui", "coin_icon.png"))


# ─── APP ICON ────────────────────────────────────────────────────
def generate_app_icon():
    """Generate app icon (512x512)."""
    print("Generating app icon...")
    size = 512
    icon = Image.new("RGBA", (size, size), TRANSPARENT)
    d = ImageDraw.Draw(icon)
    
    # Background gradient (green jungle)
    for y in range(size):
        t = y / size
        r = int(34 * (1-t) + 0 * t)
        g = int(180 * (1-t) + 100 * t)
        b = int(34 * (1-t) + 0 * t)
        d.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Round corners
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size-1, size-1], radius=100, fill=255)
    icon.putalpha(mask)
    
    # Jungle vines in background
    for vx in range(50, size, 80):
        for vy in range(0, size, 3):
            offset = int(math.sin(vy * 0.02 + vx * 0.01) * 15)
            d.ellipse([vx+offset-2, vy, vx+offset+2, vy+3], fill=(20, 100, 20, 60))
    
    # Big monkey face
    cx, cy = size//2, size//2 - 20
    face_r = 150
    
    # Head
    d.ellipse([cx-face_r, cy-face_r, cx+face_r, cy+face_r], fill=MONKEY_BODY)
    
    # Ears
    ear_r = 50
    d.ellipse([cx-face_r-20, cy-30, cx-face_r+ear_r, cy+30+ear_r], fill=MONKEY_BODY)
    d.ellipse([cx-face_r-10, cy-20, cx-face_r+ear_r-10, cy+20+ear_r], fill=MONKEY_FACE)
    d.ellipse([cx+face_r-ear_r+20, cy-30, cx+face_r+20, cy+30+ear_r], fill=MONKEY_BODY)
    d.ellipse([cx+face_r-ear_r+30, cy-20, cx+face_r+10, cy+20+ear_r], fill=MONKEY_FACE)
    
    # Face area
    d.ellipse([cx-100, cy-60, cx+100, cy+100], fill=MONKEY_FACE)
    
    # Eyes
    eye_y = cy - 10
    for ex in [cx-45, cx+25]:
        d.ellipse([ex, eye_y, ex+40, eye_y+45], fill=MONKEY_EYE_WHITE)
        d.ellipse([ex+12, eye_y+8, ex+32, eye_y+38], fill=MONKEY_EYE)
        d.ellipse([ex+18, eye_y+14, ex+26, eye_y+22], fill=MONKEY_EYE_WHITE)
    
    # Nose
    d.ellipse([cx-15, cy+40, cx+15, cy+65], fill=MONKEY_NOSE)
    d.ellipse([cx-8, cy+45, cx-2, cy+55], fill=(50, 30, 15))
    d.ellipse([cx+2, cy+45, cx+8, cy+55], fill=(50, 30, 15))
    
    # Smile
    d.arc([cx-40, cy+55, cx+40, cy+100], start=10, end=170, fill=MONKEY_NOSE, width=4)
    
    # Title text area
    text_y = size - 130
    d.rounded_rectangle([40, text_y, size-40, text_y+80], radius=15, fill=(0, 0, 0, 150))
    
    # "JUNGLE RUNNER" text (pixel-style)
    text = "JUNGLE"
    text2 = "RUNNER"
    # Simple block letters
    for i, ch in enumerate(text):
        bx = 80 + i * 60
        d.rounded_rectangle([bx, text_y+8, bx+50, text_y+38], radius=5, fill=COIN_GOLD)
        d.text((bx+12, text_y+10), ch, fill=(80, 50, 0))
    
    for i, ch in enumerate(text2):
        bx = 80 + i * 60
        d.rounded_rectangle([bx, text_y+42, bx+50, text_y+72], radius=5, fill=(255, 255, 255, 200))
        d.text((bx+12, text_y+44), ch, fill=(30, 30, 30))
    
    icon.save(os.path.join(BASE, "ui", "app_icon.png"))


# ─── MAIN ────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("🎨 Jungle Runner Asset Generator")
    print("=" * 40)
    
    generate_player_sprites()
    generate_backgrounds()
    generate_ground()
    generate_obstacles()
    generate_coins()
    generate_powerups()
    generate_ui()
    generate_app_icon()
    
    print("=" * 40)
    print("✅ All assets generated!")
    print(f"📁 Output: {BASE}")
    
    # List generated files
    for root, dirs, files in os.walk(BASE):
        for f in sorted(files):
            rel = os.path.relpath(os.path.join(root, f), BASE)
            print(f"   {rel}")
