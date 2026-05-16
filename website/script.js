/* ============================================================
   Stro Speak — landing page interactions
   ============================================================ */

// --- Year ------------------------------------------------------
document.getElementById('year').textContent = new Date().getFullYear();

// --- Nav scroll state -----------------------------------------
const nav = document.getElementById('nav');
const onScroll = () => {
  if (window.scrollY > 16) nav.classList.add('scrolled');
  else nav.classList.remove('scrolled');
};
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

// --- Smooth-scroll anchors ------------------------------------
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const id = a.getAttribute('href');
    if (id.length <= 1) return;
    const el = document.querySelector(id);
    if (!el) return;
    e.preventDefault();
    const top = el.getBoundingClientRect().top + window.scrollY - 60;
    window.scrollTo({ top, behavior: 'smooth' });
  });
});

// --- Reveal on scroll -----------------------------------------
const io = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('in');
      io.unobserve(entry.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });

document.querySelectorAll('.reveal').forEach(el => io.observe(el));

// --- Card spotlight (mouse-follow gradient) -------------------
document.querySelectorAll('.card').forEach(card => {
  card.addEventListener('pointermove', e => {
    const rect = card.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    card.style.setProperty('--mx', x + '%');
    card.style.setProperty('--my', y + '%');
  });
});

// --- Animated waveform + caption typing -----------------------
(() => {
  const wave = document.getElementById('wave');
  const caption = document.getElementById('caption');
  if (!wave || !caption) return;

  // Build 28 bars
  const N = 28;
  for (let i = 0; i < N; i++) {
    const span = document.createElement('span');
    span.style.height = '4px';
    wave.appendChild(span);
  }
  const bars = Array.from(wave.children);

  // Loop pseudo-waveform animation using sine waves of varying phase
  let t = 0;
  function animate() {
    t += 0.08;
    bars.forEach((b, i) => {
      const phase = i / N * Math.PI * 2;
      const v =
        Math.abs(Math.sin(t + phase * 1.3)) * 0.6 +
        Math.abs(Math.sin(t * 1.7 + phase * 0.5)) * 0.3 +
        Math.random() * 0.1;
      const h = 4 + v * 48;
      b.style.height = h + 'px';
    });
    rAF = requestAnimationFrame(animate);
  }
  let rAF = requestAnimationFrame(animate);

  // Pause animation when hero is out of view
  const heroIO = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        if (!rAF) rAF = requestAnimationFrame(animate);
      } else {
        cancelAnimationFrame(rAF);
        rAF = 0;
      }
    });
  });
  heroIO.observe(wave);

  // Typing caption — cycles through example phrases
  const phrases = [
    "Reply to Sarah and tell her I'll be 10 minutes late.",
    "Refactor this function to use a single loop.",
    "Summarize the doc above in three bullets.",
    "Schedule a coffee with Marcus next Tuesday afternoon.",
    "Draft a polite no to the meeting invite from Linear."
  ];

  let phraseIdx = 0;
  let charIdx = 0;
  let mode = 'typing'; // typing | holding | erasing
  let holdUntil = 0;
  const caret = caption.querySelector('.caret');

  function tick() {
    const now = performance.now();
    const phrase = phrases[phraseIdx];

    if (mode === 'typing') {
      charIdx++;
      if (charIdx >= phrase.length) {
        mode = 'holding';
        holdUntil = now + 1800;
      }
    } else if (mode === 'holding') {
      if (now >= holdUntil) mode = 'erasing';
    } else if (mode === 'erasing') {
      charIdx -= 2;
      if (charIdx <= 0) {
        charIdx = 0;
        mode = 'typing';
        phraseIdx = (phraseIdx + 1) % phrases.length;
      }
    }

    // Render
    caption.textContent = phrase.slice(0, Math.max(0, charIdx));
    caption.appendChild(caret);

    const delay = mode === 'typing' ? 45 + Math.random() * 35
                : mode === 'erasing' ? 22
                : 80;
    setTimeout(tick, delay);
  }
  setTimeout(tick, 600);
})();

// --- Animate count-up stats -----------------------------------
const animateCount = (el) => {
  const target = parseFloat(el.dataset.target);
  const prefix = el.dataset.prefix || '';
  const suffix = el.dataset.suffix || '';
  const duration = 1400;
  const start = performance.now();

  function step(now) {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3);
    const v = Math.round(target * eased);
    el.textContent = `${prefix}${v.toLocaleString()}${suffix}`;
    if (t < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
};

const statIO = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      animateCount(entry.target);
      statIO.unobserve(entry.target);
    }
  });
}, { threshold: 0.5 });

document.querySelectorAll('.stat__num').forEach(el => statIO.observe(el));

// --- Parallax on background orbs ------------------------------
const orbs = document.querySelectorAll('.bg-orb');
let pTick = false;
window.addEventListener('scroll', () => {
  if (pTick) return;
  pTick = true;
  requestAnimationFrame(() => {
    const y = window.scrollY;
    orbs.forEach((orb, i) => {
      const speed = (i + 1) * 0.04;
      orb.style.transform = `translateY(${y * speed}px)`;
    });
    pTick = false;
  });
}, { passive: true });

// --- Download button: tiny celebration ------------------------
const dl = document.getElementById('downloadBtn');
if (dl) {
  dl.addEventListener('click', e => {
    // Until a build URL is wired in, prevent the empty hash from jumping
    // and give a subtle confirmation tap.
    if (dl.getAttribute('href') === '#') {
      e.preventDefault();
      const original = dl.innerHTML;
      dl.innerHTML = '<span style="display:inline-flex;align-items:center;gap:8px;">Coming soon — thanks for the interest</span>';
      dl.style.pointerEvents = 'none';
      setTimeout(() => {
        dl.innerHTML = original;
        dl.style.pointerEvents = '';
      }, 2200);
    }
  });
}
