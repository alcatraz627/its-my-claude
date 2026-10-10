// Behaviour every page shares: the theme switch, tables that scroll inside
// their own box, table headers that follow the reader, and plain tabs.
// Inlined into a page by pagekit.py. Guide: conventions/pages.md
(function () {
  const root = document.documentElement;

  // Theme. Dark is the default; the choice is remembered when the browser allows it.
  function readTheme() { try { return localStorage.getItem('kit-theme'); } catch (e) { return null; } }
  function applyTheme(t) {
    root.dataset.theme = t;
    document.body.classList.toggle('light', t === 'light');
    document.querySelectorAll('[data-kit-theme]').forEach(b => { b.textContent = t === 'light' ? 'Dark' : 'Light'; b.setAttribute('aria-label', 'Switch to ' + (t === 'light' ? 'dark' : 'light') + ' theme'); });
  }
  applyTheme(readTheme() || root.dataset.theme || 'dark');
  document.addEventListener('click', e => {
    const b = e.target.closest('[data-kit-theme]'); if (!b) return;
    const next = root.dataset.theme === 'light' ? 'dark' : 'light';
    applyTheme(next);
    try { localStorage.setItem('kit-theme', next); } catch (err) {}
  });

  // Every table scrolls sideways inside its own box, never the whole page.
  document.querySelectorAll('.kit-page table').forEach(t => {
    if (t.parentElement.classList.contains('kit-table-wrap')) return;
    const w = document.createElement('div'); w.className = 'kit-table-wrap';
    t.parentNode.insertBefore(w, t); w.appendChild(t);
  });

  // Table headers follow the reader. CSS sticky cannot do this, because a
  // header cannot stick past the scroll box its table sits in.
  const bar = document.querySelector('.kit-bar');
  let queued = false;
  function stick() {
    queued = false;
    const top = bar ? bar.getBoundingClientRect().bottom : 0;
    document.querySelectorAll('.kit-page table').forEach(t => {
      const h = t.tHead; if (!h || t.offsetParent === null) return;
      const box = t.getBoundingClientRect();
      const dy = (box.top < top && box.bottom - h.offsetHeight - 40 > top) ? Math.round(top - box.top) : 0;
      h.style.transform = dy ? 'translateY(' + dy + 'px)' : '';
      h.classList.toggle('kit-stuck', dy > 0);
    });
  }
  function queue() { if (!queued) { queued = true; requestAnimationFrame(stick); } }
  window.addEventListener('scroll', queue, { passive: true });
  window.addEventListener('resize', queue);

  // Tabs. A button with data-kit-tab="x" shows the element with data-kit-panel="x".
  const tabs = Array.from(document.querySelectorAll('[data-kit-tab]'));
  function show(name) {
    tabs.forEach(t => t.setAttribute('aria-selected', String(t.dataset.kitTab === name)));
    document.querySelectorAll('[data-kit-panel]').forEach(p => { p.hidden = p.dataset.kitPanel !== name; });
    window.scrollTo(0, 0); queue();
  }
  tabs.forEach(t => t.addEventListener('click', () => { show(t.dataset.kitTab); try { history.replaceState(null, '', '#' + t.dataset.kitTab); } catch (e) {} }));
  if (tabs.length) {
    const wanted = (location.hash || '').slice(1);
    show(tabs.some(t => t.dataset.kitTab === wanted) ? wanted : tabs[0].dataset.kitTab);
  }
})();
