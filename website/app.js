/**
 * SafeBuy Nepal — Interactive Web App (browser demo of the mobile app)
 * Search sellers · view trust scores · file reports · write reviews · live scoring
 * Data persists in localStorage. Mirrors the Flutter app's flows & 5-factor algorithm.
 * Author: Sagesh Adhikari — Softwarica College / Coventry University
 */
(function () {
  'use strict';

  var LS_SELLERS = 'sb_sellers_v1';
  var LS_USER = 'sb_user_v1';

  // ── Severity weights for the report-severity factor (40%) ───────────────
  var SEVERITY = {
    no_delivery: 14, payment_issue: 14, impersonation: 12,
    fake_product: 10, wrong_item: 7, other: 5
  };
  var TYPE_LABEL = {
    no_delivery: 'Item Not Delivered', wrong_item: 'Wrong Item Sent',
    fake_product: 'Fake / Counterfeit Product', payment_issue: 'Paid, No Response',
    impersonation: 'Account Impersonation', other: 'Other'
  };
  var PLATFORMS = ['TikTok', 'Instagram', 'Facebook', 'WhatsApp', 'Viber', 'Other'];

  // ── Seed data (matches the app's seed sellers) ──────────────────────────
  function seed() {
    return [
      {
        id: 'priya', name: 'Priya Fashions', handle: '@priya_fashions',
        phone: '9841234567', platform: 'Instagram', category: 'Clothing & Fashion',
        verified: true, accountAgeDays: 540,
        reports: [],
        reviews: [
          { id: 'r1', rating: 5, comment: 'Genuine seller, delivered my kurtha on time with original packaging.', evidence: true, reporter: 'Anita', date: daysAgo(20) },
          { id: 'r2', rating: 4, comment: 'Good quality clothes, slightly slow reply but trustworthy overall.', evidence: true, reporter: 'Bishal', date: daysAgo(8) }
        ]
      },
      {
        id: 'quickbuy', name: 'QuickBuy Electronics', handle: '@quickbuy_np',
        phone: '9801112233', platform: 'TikTok', category: 'Electronics & Gadgets',
        verified: false, accountAgeDays: 35,
        reports: [
          { id: 'p1', type: 'no_delivery', amount: 8500, platform: 'TikTok', desc: 'Paid via QR on WhatsApp, never delivered, then blocked me.', evidence: true, reporter: 'Verified buyer #4821', date: daysAgo(15) },
          { id: 'p2', type: 'no_delivery', amount: 12000, platform: 'WhatsApp', desc: 'Advance payment taken, account disappeared.', evidence: true, reporter: 'Verified buyer #7732', date: daysAgo(9) },
          { id: 'p3', type: 'payment_issue', amount: 5000, platform: 'TikTok', desc: 'Sent eSewa payment, no response for weeks.', evidence: true, reporter: 'Verified buyer #1290', date: daysAgo(4) },
          { id: 'p4', type: 'fake_product', amount: 6500, platform: 'Instagram', desc: 'Received a fake charger instead of the branded one shown.', evidence: true, reporter: 'Verified buyer #5567', date: daysAgo(2) }
        ],
        reviews: []
      },
      {
        id: 'sunset', name: 'Sunset Cosmetics', handle: '@sunset_cosmetics',
        phone: '9812345678', platform: 'Facebook', category: 'Cosmetics & Beauty',
        verified: false, accountAgeDays: 120,
        reports: [
          { id: 's1', type: 'wrong_item', amount: 2200, platform: 'Facebook', desc: 'Ordered a serum, received a different cheaper product.', evidence: true, reporter: 'Verified buyer #3344', date: daysAgo(12) }
        ],
        reviews: [
          { id: 'rv1', rating: 4, comment: 'Products are okay, packaging could be better but legit seller.', evidence: true, reporter: 'Sita', date: daysAgo(6) }
        ]
      },
      {
        id: 'himalayan', name: 'Himalayan Handicrafts', handle: '@himalayan_crafts',
        phone: '9856701234', platform: 'Instagram', category: 'Handmade & Crafts',
        verified: true, accountAgeDays: 800,
        reports: [],
        reviews: [
          { id: 'h1', rating: 5, comment: 'Beautiful handmade pashmina, exactly as pictured. Highly recommend!', evidence: true, reporter: 'Kiran', date: daysAgo(30) },
          { id: 'h2', rating: 5, comment: 'Authentic crafts and fast shipping inside Kathmandu valley.', evidence: true, reporter: 'Maya', date: daysAgo(11) }
        ]
      },
      {
        id: 'gadgetzone', name: 'GadgetZone Nepal', handle: '@gadgetzone',
        phone: '9803456789', platform: 'TikTok', category: 'Electronics & Gadgets',
        verified: false, accountAgeDays: 75,
        reports: [
          { id: 'g1', type: 'fake_product', amount: 15000, platform: 'TikTok', desc: 'Sold a refurbished phone as brand new.', evidence: true, reporter: 'Verified buyer #9981', date: daysAgo(7) }
        ],
        reviews: [
          { id: 'gv1', rating: 2, comment: 'Item not as described, had trouble getting a refund.', evidence: true, reporter: 'Ramesh', date: daysAgo(5) }
        ]
      }
    ];
  }

  function daysAgo(n) { return Date.now() - n * 86400000; }

  // ── Storage ─────────────────────────────────────────────────────────────
  function load() {
    try {
      var raw = localStorage.getItem(LS_SELLERS);
      if (!raw) { var s = seed(); save(s); return s; }
      return JSON.parse(raw);
    } catch (e) { var s2 = seed(); save(s2); return s2; }
  }
  function save(list) { try { localStorage.setItem(LS_SELLERS, JSON.stringify(list)); } catch (e) {} }
  function getSeller(id) { return load().filter(function (s) { return s.id === id; })[0]; }
  function updateSeller(seller) {
    var list = load().map(function (s) { return s.id === seller.id ? seller : s; });
    save(list);
  }

  // ── 5-Factor Trust Algorithm (mirrors the app) ──────────────────────────
  function computeScore(seller) {
    // Factor 1 — Report severity (40 pts at stake)
    var sevSum = 0;
    seller.reports.forEach(function (r) { sevSum += (SEVERITY[r.type] || 5); });
    var reportPenalty = Math.min(40, sevSum);

    // Factor 2 — Verification (25 pts)
    var verifyScore = seller.verified ? 25 : 11;

    // Factor 3 — Reviews (20 pts)
    var reviewScore = 12; // neutral baseline when no reviews
    if (seller.reviews.length) {
      var avg = seller.reviews.reduce(function (a, r) { return a + r.rating; }, 0) / seller.reviews.length;
      reviewScore = (avg / 5) * 20;
    }

    // Factor 4 — Dispute resolution (10 pts) — neutral baseline
    var disputeScore = 7;

    // Factor 5 — Account age (5 pts)
    var ageScore = Math.min(5, (seller.accountAgeDays / 365) * 5);

    var raw = (40 - reportPenalty) + verifyScore + reviewScore + disputeScore + ageScore;
    var score = Math.max(2, Math.min(100, Math.round(raw)));

    var verdict, color, label;
    if (score >= 80) { verdict = 'trusted'; color = '#00B850'; label = 'TRUSTED'; }
    else if (score >= 50) { verdict = 'unverified'; color = '#F59300'; label = 'UNVERIFIED'; }
    else { verdict = 'high_risk'; color = '#E23B3B'; label = 'HIGH RISK'; }
    return { score: score, verdict: verdict, color: color, label: label };
  }

  function totalLost(seller) {
    return seller.reports.reduce(function (a, r) { return a + (r.amount || 0); }, 0);
  }
  function npr(n) {
    if (n >= 100000) return 'NPR ' + (n / 100000).toFixed(1).replace(/\.0$/, '') + 'L';
    if (n >= 1000) return 'NPR ' + (n / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
    return 'NPR ' + n;
  }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function timeAgo(ts) {
    var d = Math.floor((Date.now() - ts) / 86400000);
    if (d <= 0) return 'today'; if (d === 1) return 'yesterday'; if (d < 30) return d + ' days ago';
    return Math.floor(d / 30) + ' mo ago';
  }
  function rid(prefix) { return prefix + '-' + Math.random().toString(36).slice(2, 8).toUpperCase(); }

  // ── Sign-in gate (mirrors verified-reporter requirement) ────────────────
  function getUser() { try { return JSON.parse(localStorage.getItem(LS_USER)); } catch (e) { return null; } }
  function requireSignIn(onReady) {
    var u = getUser();
    if (u && u.name) { onReady(u); return; }
    openModal(signInHTML(), function (root) {
      root.querySelector('#siForm').addEventListener('submit', function (e) {
        e.preventDefault();
        var name = root.querySelector('#siName').value.trim();
        var email = root.querySelector('#siEmail').value.trim();
        if (name.length < 2) { root.querySelector('#siName').focus(); return; }
        var user = { name: name, email: email, tag: 'Verified buyer #' + (1000 + Math.floor(Math.random() * 8999)) };
        localStorage.setItem(LS_USER, JSON.stringify(user));
        closeModal();
        toast('✓ Signed in as ' + esc(name) + ' (verified)');
        onReady(user);
      });
    });
  }

  // ── Modal plumbing ──────────────────────────────────────────────────────
  var root = null;
  function ensureRoot() {
    root = document.getElementById('sbModalRoot');
    if (!root) { root = document.createElement('div'); root.id = 'sbModalRoot'; document.body.appendChild(root); }
  }
  function openModal(html, onMount) {
    ensureRoot();
    root.innerHTML = '<div class="sb-modal-backdrop" id="sbBackdrop"><div class="sb-modal" role="dialog" aria-modal="true">' +
      '<button class="sb-modal-close" id="sbClose" aria-label="Close">×</button>' + html + '</div></div>';
    document.body.style.overflow = 'hidden';
    var card = root.querySelector('.sb-modal');
    requestAnimationFrame(function () { root.querySelector('.sb-modal-backdrop').classList.add('open'); });
    root.querySelector('#sbClose').onclick = closeModal;
    root.querySelector('#sbBackdrop').onclick = function (e) { if (e.target.id === 'sbBackdrop') closeModal(); };
    if (onMount) onMount(card);
  }
  function closeModal() {
    if (!root) return;
    var b = root.querySelector('.sb-modal-backdrop');
    if (b) b.classList.remove('open');
    document.body.style.overflow = '';
    setTimeout(function () { if (root) root.innerHTML = ''; }, 250);
  }
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeModal(); });

  function toast(msg) {
    var t = document.getElementById('sbToast');
    if (!t) { t = document.createElement('div'); t.id = 'sbToast'; t.className = 'sb-toast'; document.body.appendChild(t); }
    t.innerHTML = msg;
    t.classList.add('show');
    clearTimeout(t._timer);
    t._timer = setTimeout(function () { t.classList.remove('show'); }, 3200);
  }

  // ── Trust ring SVG ──────────────────────────────────────────────────────
  function ring(score, color, size) {
    size = size || 130;
    var r = 52, c = 2 * Math.PI * r, off = c - (score / 100) * c;
    return '<div class="sb-ring" style="width:' + size + 'px;height:' + size + 'px">' +
      '<svg viewBox="0 0 120 120"><circle cx="60" cy="60" r="52" stroke="#E6EDF5" stroke-width="9" fill="none"/>' +
      '<circle cx="60" cy="60" r="52" stroke="' + color + '" stroke-width="9" fill="none" stroke-linecap="round" ' +
      'stroke-dasharray="' + c.toFixed(1) + '" stroke-dashoffset="' + c.toFixed(1) + '" transform="rotate(-90 60 60)" class="sb-ring-arc" data-off="' + off.toFixed(1) + '"/></svg>' +
      '<div class="sb-ring-num" style="color:' + color + '">' + score + '</div></div>';
  }
  function animateRings(scope) {
    (scope || document).querySelectorAll('.sb-ring-arc').forEach(function (a) {
      requestAnimationFrame(function () { setTimeout(function () { a.style.strokeDashoffset = a.getAttribute('data-off'); }, 60); });
    });
  }
  function stars(n) {
    var out = '';
    for (var i = 1; i <= 5; i++) out += '<span class="sb-star ' + (i <= n ? 'on' : '') + '">★</span>';
    return out;
  }

  // ── Search & results ────────────────────────────────────────────────────
  function matchSeller(s, q) {
    q = q.toLowerCase();
    return [s.name, s.handle, s.phone, s.category, s.platform].join(' ').toLowerCase().indexOf(q) !== -1;
  }
  function resultCard(s) {
    var r = computeScore(s);
    return '<button class="sb-result" data-id="' + s.id + '">' +
      '<div class="sb-result-avatar" style="background:' + r.color + '">' + esc(s.name[0]) + '</div>' +
      '<div class="sb-result-info"><strong>' + esc(s.name) + '</strong>' +
      '<small>' + esc(s.handle) + ' · ' + esc(s.platform) + '</small></div>' +
      '<div class="sb-result-score"><span class="sb-badge" style="background:' + r.color + '22;color:' + r.color + '">' + r.score + '</span>' +
      '<em style="color:' + r.color + '">' + r.label + '</em></div></button>';
  }
  function renderResults(list) {
    var box = document.getElementById('demoResults');
    if (!box) return;
    if (!list.length) {
      box.innerHTML = '<div class="sb-empty">🤖 No seller found. In the app, our AI suggests checking the spelling or <b>adding this seller</b> so the community can start building their trust record.</div>';
      return;
    }
    box.innerHTML = list.map(resultCard).join('');
    box.querySelectorAll('.sb-result').forEach(function (b) {
      b.onclick = function () { openSeller(b.getAttribute('data-id')); };
    });
  }
  function doSearch(q) {
    var list = load();
    renderResults(q ? list.filter(function (s) { return matchSeller(s, q); }) : list);
  }

  // ── Seller profile ──────────────────────────────────────────────────────
  function openSeller(id) {
    var s = getSeller(id); if (!s) return;
    var r = computeScore(s);
    var lost = totalLost(s);
    var reportsHTML = s.reports.length ? s.reports.slice().reverse().map(function (rp) {
      return '<div class="sb-item"><div class="sb-item-top"><span class="sb-tag-red">' + esc(TYPE_LABEL[rp.type] || rp.type) + '</span>' +
        '<b>' + npr(rp.amount || 0) + '</b></div><p>' + esc(rp.desc) + '</p>' +
        '<div class="sb-item-meta">🛡️ ' + esc(rp.reporter) + ' · ' + esc(rp.platform) + ' · ' + timeAgo(rp.date) +
        (rp.evidence ? ' · 📎 evidence attached' : '') + '</div></div>';
    }).join('') : '<div class="sb-empty sm">No fraud reports yet.</div>';

    var reviewsHTML = s.reviews.length ? s.reviews.slice().reverse().map(function (rv) {
      return '<div class="sb-item"><div class="sb-item-top"><span class="sb-stars">' + stars(rv.rating) + '</span></div>' +
        '<p>' + esc(rv.comment) + '</p><div class="sb-item-meta">🛡️ ' + esc(rv.reporter) + ' · ' + timeAgo(rv.date) +
        (rv.evidence ? ' · 📎 evidence attached' : '') + '</div></div>';
    }).join('') : '<div class="sb-empty sm">No reviews yet.</div>';

    var escalation = s.reports.length >= 4 || lost >= 25000;

    openModal(
      '<div class="sb-profile-head">' + ring(r.score, r.color) +
      '<div class="sb-profile-id"><h3>' + esc(s.name) + '</h3>' +
      '<p>' + esc(s.handle) + ' · ' + esc(s.phone) + '</p>' +
      '<span class="sb-verdict" style="background:' + r.color + '22;color:' + r.color + '">' + (r.verdict === 'trusted' ? '✓ ' : r.verdict === 'high_risk' ? '✕ ' : '? ') + r.label + '</span>' +
      (s.verified ? '<span class="sb-verified">✓ Verified business</span>' : '') +
      '</div></div>' +
      '<div class="sb-stats"><div><b>' + s.reports.length + '</b><span>Reports</span></div>' +
      '<div><b>' + s.reviews.length + '</b><span>Reviews</span></div>' +
      '<div><b>' + npr(lost) + '</b><span>Reported loss</span></div>' +
      '<div><b>' + esc(s.platform) + '</b><span>Platform</span></div></div>' +
      (escalation ? '<div class="sb-escalate">⚖️ This seller has crossed the fraud threshold. In the app, an official <b>Cyber Bureau निवेदन</b> letter is auto-drafted for admin approval.</div>' : '') +
      '<div class="sb-actions"><button class="btn btn-primary" id="sbReportBtn">🚩 Report Fraud</button>' +
      '<button class="btn btn-outline" id="sbReviewBtn">⭐ Write Review</button></div>' +
      '<div class="sb-tabs"><button class="sb-tab active" data-tab="reports">Reports (' + s.reports.length + ')</button>' +
      '<button class="sb-tab" data-tab="reviews">Reviews (' + s.reviews.length + ')</button></div>' +
      '<div class="sb-tabpane" id="paneReports">' + reportsHTML + '</div>' +
      '<div class="sb-tabpane" id="paneReviews" style="display:none">' + reviewsHTML + '</div>',
      function (card) {
        animateRings(card);
        card.querySelector('#sbReportBtn').onclick = function () { openReportForm(s.id); };
        card.querySelector('#sbReviewBtn').onclick = function () { openReviewForm(s.id); };
        card.querySelectorAll('.sb-tab').forEach(function (t) {
          t.onclick = function () {
            card.querySelectorAll('.sb-tab').forEach(function (x) { x.classList.remove('active'); });
            t.classList.add('active');
            var which = t.getAttribute('data-tab');
            card.querySelector('#paneReports').style.display = which === 'reports' ? '' : 'none';
            card.querySelector('#paneReviews').style.display = which === 'reviews' ? '' : 'none';
          };
        });
      }
    );
  }

  // ── Report form (mirrors app: platform, type, amount slider, evidence) ──
  function openReportForm(id) {
    requireSignIn(function (user) {
      var s = getSeller(id); if (!s) return;
      openModal(
        '<h3 class="sb-form-title">🚩 Report Fraud</h3><p class="sb-form-sub">Reporting <b>' + esc(s.name) + '</b>. You stay anonymous — only "' + esc(user.tag) + '" is shown.</p>' +
        '<form id="sbReportForm" class="sb-form">' +
        '<label>What happened?</label><select id="rpType" required>' +
        Object.keys(TYPE_LABEL).map(function (k) { return '<option value="' + k + '">' + TYPE_LABEL[k] + '</option>'; }).join('') + '</select>' +
        '<label>Where did you find this seller?</label><select id="rpPlatform" required>' +
        PLATFORMS.map(function (p) { return '<option' + (p === s.platform ? ' selected' : '') + '>' + p + '</option>'; }).join('') + '</select>' +
        '<label>How much money was scammed? <b id="rpAmtLabel" class="sb-amt">NPR 5,000</b></label>' +
        '<input type="range" id="rpAmount" class="sb-slider" min="0" max="100000" step="500" value="5000"/>' +
        '<label>Describe what happened</label><textarea id="rpDesc" rows="3" minlength="20" placeholder="Explain the incident in at least 20 characters..." required></textarea>' +
        '<label class="sb-file-label">📎 Evidence (required) — screenshot of chat / payment' +
        '<input type="file" id="rpEvidence" accept="image/*" required></label>' +
        '<div class="sb-anon">🔒 Your name & phone stay private. False reports hurt the community — only report real incidents.</div>' +
        '<button type="submit" class="btn btn-primary sb-submit">Submit Report</button></form>',
        function (card) {
          var slider = card.querySelector('#rpAmount'), lbl = card.querySelector('#rpAmtLabel');
          function fmt(v) { return 'NPR ' + Number(v).toLocaleString('en-IN'); }
          slider.oninput = function () { lbl.textContent = fmt(slider.value); paintSlider(slider); };
          paintSlider(slider);
          card.querySelector('#sbReportForm').onsubmit = function (e) {
            e.preventDefault();
            var desc = card.querySelector('#rpDesc').value.trim();
            if (desc.length < 20) { card.querySelector('#rpDesc').focus(); return; }
            if (!card.querySelector('#rpEvidence').files.length) { toast('⚠️ Evidence is required for every report.'); return; }
            s.reports.push({
              id: rid('RPT'), type: card.querySelector('#rpType').value,
              amount: parseInt(slider.value, 10), platform: card.querySelector('#rpPlatform').value,
              desc: desc, evidence: true, reporter: user.tag, date: Date.now()
            });
            updateSeller(s);
            closeModal();
            var nr = computeScore(s);
            toast('✓ Report filed · ' + 'New trust score: <b>' + nr.score + ' (' + nr.label + ')</b>');
            setTimeout(function () { openSeller(s.id); doSearch(document.getElementById('demoSearch').value.trim()); }, 350);
          };
        }
      );
    });
  }

  function paintSlider(el) {
    var pct = (el.value - el.min) / (el.max - el.min) * 100;
    el.style.background = 'linear-gradient(90deg,#E23B3B ' + pct + '%, #E6EDF5 ' + pct + '%)';
  }

  // ── Review form (star rating + evidence required) ───────────────────────
  function openReviewForm(id) {
    requireSignIn(function (user) {
      var s = getSeller(id); if (!s) return;
      openModal(
        '<h3 class="sb-form-title">⭐ Write a Review</h3><p class="sb-form-sub">Reviewing <b>' + esc(s.name) + '</b>. Evidence is required for positive <i>and</i> negative reviews to keep ratings fair.</p>' +
        '<form id="sbReviewForm" class="sb-form">' +
        '<label>Your rating</label><div class="sb-rate" id="rvRate">' +
        [1, 2, 3, 4, 5].map(function (i) { return '<span class="sb-rate-star" data-v="' + i + '">★</span>'; }).join('') + '</div>' +
        '<label>Your review</label><textarea id="rvComment" rows="3" minlength="20" placeholder="Share your genuine experience (min 20 characters)..." required></textarea>' +
        '<label class="sb-file-label">📎 Evidence (required) — order / delivery / chat proof' +
        '<input type="file" id="rvEvidence" accept="image/*" required></label>' +
        '<button type="submit" class="btn btn-primary sb-submit">Submit Review</button></form>',
        function (card) {
          var chosen = 0;
          var starsEls = card.querySelectorAll('.sb-rate-star');
          starsEls.forEach(function (st) {
            st.onmouseenter = function () { paint(parseInt(st.getAttribute('data-v'), 10)); };
            st.onclick = function () { chosen = parseInt(st.getAttribute('data-v'), 10); paint(chosen); };
          });
          card.querySelector('#rvRate').onmouseleave = function () { paint(chosen); };
          function paint(n) { starsEls.forEach(function (st) { st.classList.toggle('on', parseInt(st.getAttribute('data-v'), 10) <= n); }); }
          card.querySelector('#sbReviewForm').onsubmit = function (e) {
            e.preventDefault();
            if (!chosen) { toast('⚠️ Please pick a star rating.'); return; }
            var c = card.querySelector('#rvComment').value.trim();
            if (c.length < 20) { card.querySelector('#rvComment').focus(); return; }
            if (!card.querySelector('#rvEvidence').files.length) { toast('⚠️ Evidence is required for every review.'); return; }
            s.reviews.push({ id: rid('REV'), rating: chosen, comment: c, evidence: true, reporter: user.name, date: Date.now() });
            updateSeller(s);
            closeModal();
            var nr = computeScore(s);
            toast('✓ Review posted · New trust score: <b>' + nr.score + ' (' + nr.label + ')</b>');
            setTimeout(function () { openSeller(s.id); doSearch(document.getElementById('demoSearch').value.trim()); }, 350);
          };
        }
      );
    });
  }

  // ── Add seller ──────────────────────────────────────────────────────────
  function openAddSeller() {
    openModal(
      '<h3 class="sb-form-title">+ Add a Seller</h3><p class="sb-form-sub">Start a trust record so the community can verify this seller.</p>' +
      '<form id="sbAddForm" class="sb-form">' +
      '<label>Business / seller name</label><input id="asName" required placeholder="e.g. Kathmandu Kicks"/>' +
      '<label>Handle or username</label><input id="asHandle" placeholder="@username"/>' +
      '<label>Phone / eSewa ID</label><input id="asPhone" placeholder="98XXXXXXXX"/>' +
      '<label>Platform</label><select id="asPlatform">' + PLATFORMS.map(function (p) { return '<option>' + p + '</option>'; }).join('') + '</select>' +
      '<button type="submit" class="btn btn-primary sb-submit">Add Seller</button></form>',
      function (card) {
        card.querySelector('#sbAddForm').onsubmit = function (e) {
          e.preventDefault();
          var name = card.querySelector('#asName').value.trim();
          if (name.length < 2) return;
          var list = load();
          var s = {
            id: 'u' + Date.now(), name: name,
            handle: card.querySelector('#asHandle').value.trim() || '@' + name.toLowerCase().replace(/\s+/g, '_'),
            phone: card.querySelector('#asPhone').value.trim() || '—',
            platform: card.querySelector('#asPlatform').value, category: 'Other',
            verified: false, accountAgeDays: 1, reports: [], reviews: []
          };
          list.push(s); save(list);
          closeModal();
          toast('✓ Seller added — start its trust record by filing a report or review.');
          setTimeout(function () { openSeller(s.id); doSearch(''); }, 300);
        };
      }
    );
  }

  // ── Sign-in modal HTML ──────────────────────────────────────────────────
  function signInHTML() {
    return '<h3 class="sb-form-title">🔐 Sign in to continue</h3>' +
      '<p class="sb-form-sub">In the app, reporting requires a verified account (phone + email + national ID, approved by an admin). For this demo, just enter a display name — you\'ll stay anonymous to others.</p>' +
      '<form id="siForm" class="sb-form">' +
      '<label>Display name</label><input id="siName" required placeholder="Your name"/>' +
      '<label>Email (optional)</label><input id="siEmail" type="email" placeholder="you@example.com"/>' +
      '<button type="submit" class="btn btn-primary sb-submit">Continue</button></form>';
  }

  // ── Boot ────────────────────────────────────────────────────────────────
  function init() {
    var search = document.getElementById('demoSearch');
    var searchBtn = document.getElementById('demoSearchBtn');
    var chips = document.getElementById('demoChips');
    if (!search) return; // section not present

    // popular chips
    var popular = ['Priya Fashions', 'QuickBuy Electronics', 'Sunset Cosmetics', 'GadgetZone'];
    chips.innerHTML = '<span class="sb-chip-label">Try:</span>' + popular.map(function (p) {
      return '<button class="sb-chip" data-q="' + esc(p) + '">' + esc(p) + '</button>';
    }).join('');
    chips.querySelectorAll('.sb-chip').forEach(function (c) {
      c.onclick = function () { search.value = c.getAttribute('data-q'); doSearch(search.value); };
    });

    search.addEventListener('input', function () { doSearch(search.value.trim()); });
    if (searchBtn) searchBtn.onclick = function () { doSearch(search.value.trim()); };
    search.addEventListener('keydown', function (e) { if (e.key === 'Enter') doSearch(search.value.trim()); });

    var reset = document.getElementById('demoReset');
    if (reset) reset.onclick = function () {
      localStorage.removeItem(LS_SELLERS); localStorage.removeItem(LS_USER);
      save(seed()); doSearch(''); toast('↺ Demo data reset.');
    };
    var add = document.getElementById('demoAddSeller');
    if (add) add.onclick = function (e) { e.preventDefault(); openAddSeller(); };

    doSearch(''); // show all sellers initially
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
