/* NotchDown — one small piece of behaviour.
   ---------------------------------------------------------------------------
   NotchDown only runs on macOS, so tell visitors on other platforms before they
   download a disk image they cannot open. Everything else on this page is
   static HTML and CSS by design.
   --------------------------------------------------------------------------- */

(function () {
  'use strict';

  var isMac = /Mac|iPhone|iPad|iPod/.test(navigator.platform || '') ||
              /Mac OS X/.test(navigator.userAgent || '');

  if (isMac) return;

  var note = document.createElement('p');
  note.className = 'platform-note';
  note.textContent =
    'NotchDown is a macOS app. This download will not run on your current device.';

  var hero = document.querySelector('.hero__copy .download');
  if (hero && hero.parentNode) {
    hero.parentNode.insertBefore(note, hero.nextSibling);
  }
})();
