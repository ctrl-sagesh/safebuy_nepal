/**
 * SafeBuy Nepal — Premium Website Animations (14 Total)
 * BSc (Hons) Ethical Hacking & Cybersecurity Thesis
 * Author: Sagesh Adhikari — Softwarica College / Coventry University
 */

(function () {
  'use strict';

  // ═══════════════════════════════════════════════════════════════
  // Welcome Overlay
  // ═══════════════════════════════════════════════════════════════
  // Shown only on the first visit — returning visitors land straight
  // on the hero so the value proposition is readable immediately.
  const welcomeOverlay = document.getElementById('welcomeOverlay');
  const welcomeEnterBtn = document.getElementById('welcomeEnterBtn');
  let welcomed = false;
  try { welcomed = localStorage.getItem('sb_welcomed') === '1'; } catch (e) { /* private mode */ }
  if (welcomeOverlay && welcomed) {
    welcomeOverlay.classList.add('hidden');
  } else if (welcomeOverlay && welcomeEnterBtn) {
    document.body.style.overflow = 'hidden';
    welcomeEnterBtn.addEventListener('click', () => {
      welcomeOverlay.classList.add('hidden');
      document.body.style.overflow = '';
      try { localStorage.setItem('sb_welcomed', '1'); } catch (e) { /* ignore */ }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 1: Custom Cursor with Lerp
  // ═══════════════════════════════════════════════════════════════
  const cursorDot = document.getElementById('cursorDot');
  const cursorRing = document.getElementById('cursorRing');
  if (cursorDot && cursorRing && window.matchMedia('(pointer: fine)').matches) {
    let mouseX = 0, mouseY = 0;
    let ringX = 0, ringY = 0;

    document.addEventListener('mousemove', (e) => {
      mouseX = e.clientX;
      mouseY = e.clientY;
      cursorDot.style.left = mouseX + 'px';
      cursorDot.style.top = mouseY + 'px';
    });

    function animateRing() {
      ringX += (mouseX - ringX) * 0.12;
      ringY += (mouseY - ringY) * 0.12;
      cursorRing.style.left = ringX + 'px';
      cursorRing.style.top = ringY + 'px';
      requestAnimationFrame(animateRing);
    }
    animateRing();

    // Hover state on interactive elements
    const interactiveEls = 'a, button, .btn, .magnetic, .demo-tab, .lang-btn, .glow-card, .feature-card, .scam-card, .ab-card';
    document.querySelectorAll(interactiveEls).forEach(el => {
      el.addEventListener('mouseenter', () => {
        cursorDot.classList.add('hover');
        cursorRing.classList.add('hover');
      });
      el.addEventListener('mouseleave', () => {
        cursorDot.classList.remove('hover');
        cursorRing.classList.remove('hover');
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 2: Particle Network Canvas
  // ═══════════════════════════════════════════════════════════════
  const canvas = document.getElementById('particleCanvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    let particles = [];
    let animFrame;
    const MAX_PARTICLES = 60;
    const CONNECT_DIST = 140;

    function resizeCanvas() {
      const hero = canvas.parentElement;
      canvas.width = hero.offsetWidth;
      canvas.height = hero.offsetHeight;
    }
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    class Particle {
      constructor() {
        this.x = Math.random() * canvas.width;
        this.y = Math.random() * canvas.height;
        this.vx = (Math.random() - 0.5) * 0.5;
        this.vy = (Math.random() - 0.5) * 0.5;
        this.r = Math.random() * 2 + 0.5;
        this.alpha = Math.random() * 0.5 + 0.2;
      }
      update() {
        this.x += this.vx;
        this.y += this.vy;
        if (this.x < 0 || this.x > canvas.width) this.vx *= -1;
        if (this.y < 0 || this.y > canvas.height) this.vy *= -1;
      }
      draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 255, 255, ${this.alpha})`;
        ctx.fill();
      }
    }

    for (let i = 0; i < MAX_PARTICLES; i++) particles.push(new Particle());

    function animateParticles() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach(p => { p.update(); p.draw(); });
      // Draw connecting lines
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < CONNECT_DIST) {
            const opacity = (1 - dist / CONNECT_DIST) * 0.15;
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `rgba(255, 255, 255, ${opacity * 1.3})`;
            ctx.lineWidth = 0.5;
            ctx.stroke();
          }
        }
      }
      animFrame = requestAnimationFrame(animateParticles);
    }
    animateParticles();
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 4: Phone Mockup Slide Rotation
  // ═══════════════════════════════════════════════════════════════
  const slides = document.querySelectorAll('.slide');
  const searchTyping = document.getElementById('searchTyping');
  if (slides.length > 0) {
    let currentSlide = 0;
    const searchQueries = ['Search: 9841234567...', 'Search: @quickbuy_np...', 'Report submitted!'];

    function typeInSearch(text, el, cb) {
      if (!el) { if (cb) cb(); return; }
      el.textContent = '';
      let i = 0;
      const interval = setInterval(() => {
        if (i < text.length) {
          el.textContent += text[i];
          i++;
        } else {
          clearInterval(interval);
          if (cb) setTimeout(cb, 800);
        }
      }, 60);
    }

    function nextSlide() {
      slides.forEach(s => s.classList.remove('active'));
      currentSlide = (currentSlide + 1) % slides.length;
      slides[currentSlide].classList.add('active');

      if (currentSlide < 2 && searchTyping) {
        typeInSearch(searchQueries[currentSlide], searchTyping, null);
      }
      setTimeout(nextSlide, 4000);
    }

    // Start first search typing
    if (searchTyping) {
      typeInSearch(searchQueries[0], searchTyping, null);
    }
    setTimeout(nextSlide, 4000);
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 3: Floating Card 3D Tilt
  // ═══════════════════════════════════════════════════════════════
  document.querySelectorAll('.float-card').forEach(card => {
    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      const x = (e.clientX - rect.left) / rect.width - 0.5;
      const y = (e.clientY - rect.top) / rect.height - 0.5;
      card.style.transform = `perspective(600px) rotateY(${x * 10}deg) rotateX(${-y * 10}deg) scale(1.05)`;
    });
    card.addEventListener('mouseleave', () => {
      card.style.transform = '';
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Animation 5: Magnetic Buttons
  // ═══════════════════════════════════════════════════════════════
  document.querySelectorAll('.magnetic').forEach(btn => {
    btn.addEventListener('mousemove', (e) => {
      const rect = btn.getBoundingClientRect();
      const x = e.clientX - rect.left - rect.width / 2;
      const y = e.clientY - rect.top - rect.height / 2;
      btn.style.transform = `translate(${x * 0.2}px, ${y * 0.2}px)`;
    });
    btn.addEventListener('mouseleave', () => {
      btn.style.transform = '';
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Animation 6: Scroll Reveal via IntersectionObserver
  // ═══════════════════════════════════════════════════════════════
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        // Trigger counters
        if (entry.target.closest('.stats-section') || entry.target.classList.contains('stats-section')) {
          animateCounters();
        }
        // Trigger algo bars
        if (entry.target.classList.contains('algo-weights')) {
          animateAlgoBars();
        }
        // Trigger Nepal Police fraud-by-numbers counters
        if (entry.target.closest('.fraudnum-section') || entry.target.classList.contains('fraudnum-section')) {
          animateFraudCounters();
        }
      }
    });
  }, { threshold: 0.15, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

  // Staggered delays for grid children
  function addStagger(selector, delay) {
    document.querySelectorAll(selector).forEach((el, i) => {
      el.style.transitionDelay = (i * delay) + 'ms';
    });
  }
  addStagger('.features-grid .feature-card', 100);
  addStagger('.scam-grid .scam-card', 100);
  addStagger('.coldstart-grid .feature-card', 100);
  addStagger('.stats-grid .stat-card', 80);
  addStagger('.police-flow .pflow-step', 120);
  addStagger('.fraudnum-grid .fraudnum-card', 100);

  // Fraud-by-numbers counters (same easing as the main stats counters)
  let fraudCountersAnimated = false;
  function animateFraudCounters() {
    if (fraudCountersAnimated) return;
    fraudCountersAnimated = true;

    document.querySelectorAll('.fraud-counter').forEach(counter => {
      const target = parseInt(counter.getAttribute('data-target'));
      if (isNaN(target)) return;

      const duration = 2200;
      const start = performance.now();

      function tick(now) {
        const progress = Math.min((now - start) / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        counter.textContent = Math.floor(eased * target).toLocaleString();
        if (progress < 1) requestAnimationFrame(tick);
        else counter.textContent = target.toLocaleString();
      }
      requestAnimationFrame(tick);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 7: Counter Animation
  // ═══════════════════════════════════════════════════════════════
  let countersAnimated = false;
  function animateCounters() {
    if (countersAnimated) return;
    countersAnimated = true;

    document.querySelectorAll('.counter').forEach(counter => {
      const parent = counter.closest('.stat-card');
      if (!parent) return;
      const target = parseInt(parent.getAttribute('data-count'));
      if (isNaN(target)) return;

      const duration = 2200;
      const start = performance.now();

      function formatNum(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(1);
        if (n >= 1000) return n.toLocaleString();
        return n.toString();
      }

      function tick(now) {
        const elapsed = now - start;
        const progress = Math.min(elapsed / duration, 1);
        const eased = 1 - Math.pow(1 - progress, 3);
        counter.textContent = formatNum(Math.floor(eased * target));
        if (progress < 1) requestAnimationFrame(tick);
        else counter.textContent = formatNum(target);
      }
      requestAnimationFrame(tick);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 8: Glow Card Border (handled via CSS @property)
  // ═══════════════════════════════════════════════════════════════
  // CSS handles the rotating conic-gradient glow. No JS needed.

  // ═══════════════════════════════════════════════════════════════
  // Animation 9: Interactive Trust Score Demo
  // ═══════════════════════════════════════════════════════════════
  const demoTabs = document.querySelectorAll('.demo-tab');
  const scoreArc = document.querySelector('.score-arc');
  const demoScoreNum = document.getElementById('demoScoreNum');
  const demoSellerName = document.getElementById('demoSellerName');
  const demoVerdict = document.getElementById('demoVerdict');

  function updateDemo(score, color, name, verdictText) {
    if (!scoreArc) return;
    const circumference = 2 * Math.PI * 52; // r=52
    const offset = circumference - (score / 100) * circumference;
    scoreArc.style.transition = 'stroke-dashoffset 0.8s ease, stroke 0.4s';
    scoreArc.setAttribute('stroke', color);
    scoreArc.setAttribute('stroke-dashoffset', offset);

    // Animate number
    if (demoScoreNum) {
      const currentVal = parseInt(demoScoreNum.textContent) || 0;
      const diff = score - currentVal;
      const steps = 30;
      let step = 0;
      const interval = setInterval(() => {
        step++;
        const val = Math.round(currentVal + (diff * (step / steps)));
        demoScoreNum.textContent = val;
        if (step >= steps) {
          demoScoreNum.textContent = score;
          clearInterval(interval);
        }
      }, 25);
    }

    if (demoSellerName) demoSellerName.textContent = name;
    if (demoVerdict) {
      let label = 'HIGH RISK';
      let bg = 'rgba(226,59,59,0.14)';
      let fg = '#E23B3B';
      let icon = '✕';
      if (score >= 80) { label = 'TRUSTED'; bg = 'rgba(0,184,80,0.14)'; fg = '#00B850'; icon = '✓'; }
      else if (score >= 50) { label = 'UNVERIFIED'; bg = 'rgba(245,147,0,0.14)'; fg = '#F59300'; icon = '?'; }
      demoVerdict.style.background = bg;
      demoVerdict.style.color = fg;
      demoVerdict.textContent = icon + ' ' + label;
    }
  }

  demoTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      demoTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const score = parseInt(tab.dataset.score);
      const color = tab.dataset.color;
      const name = tab.dataset.name;
      updateDemo(score, color, name, tab.dataset.verdict);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Animation 10: Typing Animation
  // ═══════════════════════════════════════════════════════════════
  const typingEl = document.getElementById('typingText');
  if (typingEl) {
    const phrases = [
      'Is this seller safe to buy from?',
      'के यो विक्रेता विश्वसनीय छ?',
      'Check any seller before you pay.',
      'पैसा तिर्नु अघि जाँच गर्नुहोस्।',
      'Report fraud. Protect buyers.',
    ];
    let phraseIdx = 0;
    let charIdx = 0;
    let deleting = false;

    function typeLoop() {
      const current = phrases[phraseIdx];
      if (!deleting) {
        typingEl.textContent = current.substring(0, charIdx + 1);
        charIdx++;
        if (charIdx >= current.length) {
          deleting = true;
          setTimeout(typeLoop, 2000);
          return;
        }
        setTimeout(typeLoop, 55);
      } else {
        typingEl.textContent = current.substring(0, charIdx);
        charIdx--;
        if (charIdx < 0) {
          deleting = false;
          charIdx = 0;
          phraseIdx = (phraseIdx + 1) % phrases.length;
          setTimeout(typeLoop, 400);
          return;
        }
        setTimeout(typeLoop, 30);
      }
    }
    setTimeout(typeLoop, 1200);
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 11: Anti-Bot Sequential Activation
  // ═══════════════════════════════════════════════════════════════
  const antibotGrid = document.getElementById('antibotGrid');
  if (antibotGrid) {
    const abObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const cards = antibotGrid.querySelectorAll('.ab-card');
          cards.forEach((card, i) => {
            setTimeout(() => card.classList.add('activated'), i * 250);
          });
          abObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.2 });
    abObserver.observe(antibotGrid);
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 12: How-It-Works Connecting Lines
  // ═══════════════════════════════════════════════════════════════
  const drawLines = document.querySelectorAll('.draw-line');
  if (drawLines.length > 0) {
    const lineObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animated');
          lineObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.5 });
    drawLines.forEach(line => lineObserver.observe(line));
  }

  // ═══════════════════════════════════════════════════════════════
  // Animation 13: Noise Texture (handled via CSS ::after)
  // ═══════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════
  // Animation 14: Hero Parallax Glows
  // ═══════════════════════════════════════════════════════════════
  const heroGlow1 = document.querySelector('.hero-glow-1');
  const heroGlow2 = document.querySelector('.hero-glow-2');
  if (heroGlow1 && heroGlow2) {
    document.addEventListener('mousemove', (e) => {
      const x = (e.clientX / window.innerWidth - 0.5) * 2;
      const y = (e.clientY / window.innerHeight - 0.5) * 2;
      heroGlow1.style.transform = `translate(${x * 30}px, ${y * 20}px)`;
      heroGlow2.style.transform = `translate(${x * -25}px, ${y * -15}px)`;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Algo Bars Animation
  // ═══════════════════════════════════════════════════════════════
  let barsAnimated = false;
  function animateAlgoBars() {
    if (barsAnimated) return;
    barsAnimated = true;
    document.querySelectorAll('.algo-bar').forEach((bar, i) => {
      const w = bar.dataset.width;
      if (w) {
        bar.style.setProperty('--bar-width', w + '%');
        setTimeout(() => bar.classList.add('animated'), i * 150);
      }
    });
  }

  // Also observe algo-weights for bar animation
  const algoWeights = document.querySelector('.algo-weights');
  if (algoWeights) revealObserver.observe(algoWeights);

  // ═══════════════════════════════════════════════════════════════
  // Language Toggle (shared across navbar + welcome screen)
  // ═══════════════════════════════════════════════════════════════
  let currentLang = 'en';
  const langBtns = document.querySelectorAll('.lang-btn');
  const welcomeLangBtns = document.querySelectorAll('.welcome-lang-btn');

  function applyLang(lang) {
    currentLang = lang;

    // Sync navbar toggle state
    langBtns.forEach(b => b.classList.toggle('active', b.dataset.lang === lang));
    // Sync welcome button state
    welcomeLangBtns.forEach(b =>
      b.classList.toggle('active', b.dataset.setlang === lang));

    // Swap all translatable elements
    document.querySelectorAll('[data-en][data-ne]').forEach(el => {
      const text = el.getAttribute('data-' + lang);
      if (text) el.innerHTML = text;
    });

    // Swap anti-bot card titles and descriptions
    document.querySelectorAll('.ab-card').forEach(card => {
      const title = card.getAttribute('data-' + lang + '-title');
      const desc = card.getAttribute('data-' + lang + '-desc');
      if (title) card.querySelector('h4').textContent = title;
      if (desc) card.querySelector('p').textContent = desc;
    });

    // Reflect on <html lang>
    document.documentElement.setAttribute('lang', lang);
  }

  langBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      if (btn.dataset.lang !== currentLang) applyLang(btn.dataset.lang);
    });
  });
  welcomeLangBtns.forEach(btn => {
    btn.addEventListener('click', () => applyLang(btn.dataset.setlang));
  });

  // ═══════════════════════════════════════════════════════════════
  // Navbar Scroll Effect
  // ═══════════════════════════════════════════════════════════════
  const navbar = document.getElementById('navbar');
  if (navbar) {
    window.addEventListener('scroll', () => {
      navbar.classList.toggle('scrolled', window.scrollY > 60);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Mobile Nav Toggle
  // ═══════════════════════════════════════════════════════════════
  const navToggle = document.getElementById('navToggle');
  const mobileMenu = document.getElementById('mobileMenu');
  if (navToggle && mobileMenu) {
    navToggle.addEventListener('click', () => {
      mobileMenu.classList.toggle('active');
    });
    mobileMenu.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => mobileMenu.classList.remove('active'));
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Smooth Scroll for Anchor Links
  // ═══════════════════════════════════════════════════════════════
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        const offset = 80; // navbar height
        const top = target.getBoundingClientRect().top + window.pageYOffset - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Scroll Progress Bar + Back To Top
  // ═══════════════════════════════════════════════════════════════
  const scrollProgress = document.getElementById('scrollProgress');
  const backToTop = document.getElementById('backToTop');
  function onScrollUI() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const docH = document.documentElement.scrollHeight - window.innerHeight;
    const pct = docH > 0 ? (scrollTop / docH) * 100 : 0;
    if (scrollProgress) scrollProgress.style.width = pct + '%';
    if (backToTop) backToTop.classList.toggle('show', scrollTop > 600);
  }
  window.addEventListener('scroll', onScrollUI, { passive: true });
  onScrollUI();
  if (backToTop) {
    backToTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
  }

})();
