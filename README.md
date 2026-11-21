# Fight For Baddies

Rojo project for the Roblox Studio place `Fight For Baddies`.

## Export from Studio

1. Run `rojo serve` in this directory.
2. In Roblox Studio, open the **Plugins** tab and click **Rojo**, then **Connect**.
3. Use **File → Save to File…** to save a snapshot as `place.rbxl` in this directory.
   (`*.rbxl` is gitignored.)
4. Preview what syncback will write:

   ```bash
   rojo syncback . --input place.rbxl --dry-run --list
   ```

5. Apply it:

   ```bash
   rojo syncback . --input place.rbxl -y
   ```

6. Review and commit:

   ```bash
   git status
   git add -A
   git commit -m "Export place from Studio"
   ```

## Build a place file

```bash
rojo build -o build/fight-for-baddies.rbxlx
```
