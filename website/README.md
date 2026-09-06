# NotchDown website

Static site. No build step, no dependencies, no external requests — every asset
is local, and the type uses the system font stack.

## Uploading to Hostinger

1. Open **hPanel → Files → File Manager** (or connect over FTP).
2. Go to `public_html/`.
3. Upload the **contents** of this folder, not the folder itself, so the layout
   on the server is:

   ```
   public_html/
     index.html
     styles.css
     script.js
     assets/
       NotchDown_v1.0_Installer.dmg
       shots/*.png
   ```

4. Visit the domain. `index.html` is served automatically.

That is the whole deployment. Nothing needs configuring.

## Releasing a new version

The download button points to the GitHub release installer at:
`https://github.com/festomanolo/notch-down/releases/download/v1.0/NotchDown_v1.0_Installer.dmg`.
When you ship a new build:

1. Run `./create_dmg.sh` from the project root. It builds a universal Release
   binary and packages `NotchDown_v<version>_Installer.dmg`.
2. Create the GitHub release and upload the `.dmg`.
3. Update the download URLs in `index.html`, and the version/size in the facts list and footer.

## Screenshots

Everything under `assets/shots/` is a real capture of the app, taken at 2×.
They are transparent PNGs cropped to the island with the shadow feathered out
at the edges, which is why they sit on the page without a visible box.

If you retake them, keep them transparent and trimmed the same way — the layout
aligns the island's own left edge to the text, so a wide transparent margin in
the file will read as a random indent.

## Things worth keeping honest

The install section tells visitors two true things that are easy to leave out:

- The app is signed with an Apple Development certificate and is **not
  notarised**, so Gatekeeper blocks the first launch and they need to
  right-click → Open. If you later notarise the build, delete that step.
- It needs Automation permission to drive System Events for shutdown, restart
  and log out. Sleep works without it.

Both save you support questions. Don't remove them unless they stop being true.
