# Editing enemy1 animation frames (walk, idle, attack)

## How the editor works

- **You don’t open the .tres file by itself.** Double‑clicking `enemy1_sprite_frames.tres` usually just selects it or shows it in the Inspector; it doesn’t open a dedicated “Sprite Frames” window.
- **The Sprite Frames panel appears when you edit a scene that uses that resource.** So you open the **Enemy scene**, select the node that has the sprite, and the bottom panel shows the animations and the grid icon. That’s the right place to edit.

## Where to edit the tiles/frames

1. **Open the Enemy scene**
   - In the **FileSystem** dock, open **`scenes/enemies/Enemy.tscn`**.

2. **Select the sprite node**
   - In the **Scene** tree, select the **AnimatedSprite2D** node (under Enemy).
   - The bottom panel should show **Sprite Frames** (or **Animation**) with **Animations** on the left (attack, idle, walk) and **Animation Frames** on the right. That’s the right panel.

3. **Edit a frame’s region (without the grid tool)**
   - In the left list, click **walk** (or idle/attack).
   - On the right, click one of the frames (0, 1, 2).
   - In the **Inspector**, find that frame’s texture (e.g. **AtlasTexture**).
   - Set **Region** to the part of `enemy1.png` you want, e.g. **Rect2(x, y, 16, 16)** in pixels.

4. **Using the grid icon (“Create Frames from Sprite Sheet”)**
   - The grid tool always needs an **image file** (e.g. `enemy1.png`), not a .tres file. If you pick a .tres file, you get “Unable to load images.”
   - With the Sprite Frames panel open (from step 1–2), click the **grid** icon in the **Animation Frames** toolbar.
   - A **file picker** opens. It may default to showing .tres or “Resource” files:
	 - Use the **file type filter** at the bottom (e.g. “All Files” or a dropdown) and switch it to **“Image files”** or **“PNG”** so that `enemy1.png` is visible and selectable.
	 - Or use the folder breadcrumb/path to go to **`res://assets/characters/`** (where `enemy1.png` lives), then select **`enemy1.png`**.
   - After you select **`enemy1.png`**, the sprite-sheet dialog should open; set the cell **Size** to **16×16** and confirm. That creates one frame per 16×16 cell from the image.

## Current mapping (16×16 grid, column then row)

- **idle**: (0,0) and (0,1) → Rect2(0,0,16,16) and Rect2(0,16,16,16)
- **walk**: (0,2), (0,3), (0,4) → Rect2(0,32,16,16), Rect2(0,48,16,16), Rect2(0,64,16,16)
- **attack**: (1,1) → Rect2(16,16,16,16)

If your sheet uses **row then column**, swap: e.g. (0,2) = row 0, col 2 → Rect2(32, 0, 16, 16).
