/**
 * SafeBuy Nepal — Interactive Web App (browser demo of the mobile app)
 * Search sellers · view trust scores · file reports · write reviews · live scoring
 * Data persists in localStorage. Mirrors the Flutter app's flows & 5-factor algorithm.
 * Author: Sagesh Adhikari — Softwarica College / Coventry University
 */
(function () {
  'use strict';

  var LS_SELLERS = 'sb_sellers_v2';
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
          { id: 'r1', rating: 5, comment: 'Genuine seller, delivered my kurtha on time with original packaging.', evidence: true, reporter: 'Anita', date: daysAgo(20),
            proof: [ { kind: 'chat', app: 'Instagram', scenario: 'received', seller: 'Priya Fashions', item: 'the kurtha' } ] },
          { id: 'r2', rating: 4, comment: 'Good quality clothes, slightly slow reply but trustworthy overall.', evidence: true, reporter: 'Bishal', date: daysAgo(8),
            proof: [ { kind: 'payment', method: 'eSewa', amount: 1800, to: 'Priya Fashions', id: '9841234567', ref: 'ESW1180042', when: '8 days ago' } ] }
        ]
      },
      {
        id: 'quickbuy', name: 'QuickBuy Electronics', handle: '@quickbuy_np',
        phone: '9801112233', platform: 'TikTok', category: 'Electronics & Gadgets',
        verified: false, accountAgeDays: 35,
        reports: [
          { id: 'p1', type: 'no_delivery', amount: 8500, platform: 'TikTok', desc: 'Saw a "smart watch" on TikTok, moved to WhatsApp, paid Rs 8,500 advance via QR. Never delivered, then blocked me.', evidence: true, reporter: 'Verified buyer #4821', date: daysAgo(15),
            proof: [
              { kind: 'chat', app: 'WhatsApp', scenario: 'blocked', seller: 'QuickBuy Electronics', item: 'the smart watch', amount: 8500 },
              { kind: 'payment', method: 'eSewa', amount: 8500, to: 'QuickBuy Electronics', id: '9801112233', ref: 'ESW8842190', when: '15 days ago' }
            ] },
          { id: 'p2', type: 'no_delivery', amount: 12000, platform: 'WhatsApp', desc: 'Advance payment of Rs 12,000 taken for earbuds, account disappeared right after.', evidence: true, reporter: 'Verified buyer #7732', date: daysAgo(9),
            proof: [
              { kind: 'payment', method: 'Khalti', amount: 12000, to: 'QuickBuy Electronics', id: '9801112233', ref: 'KHL771203', when: '9 days ago' },
              { kind: 'chat', app: 'WhatsApp', scenario: 'blocked', seller: 'QuickBuy Electronics', item: 'the earbuds', amount: 12000 }
            ] },
          { id: 'p3', type: 'payment_issue', amount: 5000, platform: 'TikTok', desc: 'Sent eSewa payment of Rs 5,000, no response for weeks.', evidence: true, reporter: 'Verified buyer #1290', date: daysAgo(4),
            proof: [
              { kind: 'payment', method: 'eSewa', amount: 5000, to: 'QuickBuy Electronics', id: '9801112233', ref: 'ESW1290055', when: '3 weeks ago' }
            ] },
          { id: 'p4', type: 'fake_product', amount: 6500, platform: 'Instagram', desc: 'Received a fake charger instead of the branded one shown in the video.', evidence: true, reporter: 'Verified buyer #5567', date: daysAgo(2),
            proof: [
              { kind: 'chat', app: 'Instagram', scenario: 'wrongitem', seller: 'QuickBuy Electronics', item: 'the original charger', amount: 6500 }
            ] }
        ],
        reviews: []
      },
      {
        id: 'sunset', name: 'Sunset Cosmetics', handle: '@sunset_cosmetics',
        phone: '9812345678', platform: 'Facebook', category: 'Cosmetics & Beauty',
        verified: false, accountAgeDays: 120,
        reports: [
          { id: 's1', type: 'wrong_item', amount: 2200, platform: 'Facebook', desc: 'Ordered a branded serum, received a different cheaper product.', evidence: true, reporter: 'Verified buyer #3344', date: daysAgo(12),
            proof: [
              { kind: 'payment', method: 'eSewa', amount: 2200, to: 'Sunset Cosmetics', id: '9812345678', ref: 'ESW3344021', when: '12 days ago' },
              { kind: 'chat', app: 'Facebook', scenario: 'wrongitem', seller: 'Sunset Cosmetics', item: 'the branded serum', amount: 2200 }
            ] }
        ],
        reviews: [
          { id: 'rv1', rating: 4, comment: 'Products are okay, packaging could be better but a legit seller overall.', evidence: true, reporter: 'Sita', date: daysAgo(6),
            proof: [ { kind: 'chat', app: 'Facebook', scenario: 'received', seller: 'Sunset Cosmetics', item: 'the lip set' } ] }
        ]
      },
      {
        id: 'himalayan', name: 'Himalayan Handicrafts', handle: '@himalayan_crafts',
        phone: '9856701234', platform: 'Instagram', category: 'Handmade & Crafts',
        verified: true, accountAgeDays: 800,
        reports: [],
        reviews: [
          { id: 'h1', rating: 5, comment: 'Beautiful handmade pashmina, exactly as pictured. Highly recommend!', evidence: true, reporter: 'Kiran', date: daysAgo(30),
            proof: [ { kind: 'chat', app: 'Instagram', scenario: 'received', seller: 'Himalayan Handicrafts', item: 'the pashmina' } ] },
          { id: 'h2', rating: 5, comment: 'Authentic crafts and fast shipping inside Kathmandu valley.', evidence: true, reporter: 'Maya', date: daysAgo(11),
            proof: [ { kind: 'payment', method: 'Khalti', amount: 3200, to: 'Himalayan Handicrafts', id: '9856701234', ref: 'KHL320119', when: '11 days ago' } ] }
        ]
      },
      {
        id: 'gadgetzone', name: 'GadgetZone Nepal', handle: '@gadgetzone',
        phone: '9803456789', platform: 'TikTok', category: 'Electronics & Gadgets',
        verified: false, accountAgeDays: 75,
        reports: [
          { id: 'g1', type: 'fake_product', amount: 15000, platform: 'TikTok', desc: 'Sold a refurbished phone as brand new. Paid Rs 15,000, seller ignored complaints then blocked me.', evidence: true, reporter: 'Verified buyer #9981', date: daysAgo(7),
            proof: [
              { kind: 'payment', method: 'eSewa', amount: 15000, to: 'GadgetZone Nepal', id: '9803456789', ref: 'ESW9981700', when: '7 days ago' },
              { kind: 'chat', app: 'TikTok', scenario: 'blocked', seller: 'GadgetZone Nepal', item: 'the new phone', amount: 15000 }
            ] }
        ],
        reviews: [
          { id: 'gv1', rating: 2, comment: 'Item not as described, had a lot of trouble getting any refund.', evidence: true, reporter: 'Ramesh', date: daysAgo(5),
            proof: [ { kind: 'chat', app: 'TikTok', scenario: 'wrongitem', seller: 'GadgetZone Nepal', item: 'the advertised phone', amount: 15000 } ] }
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
  var wipeTimer = null;
  function openModal(html, onMount) {
    ensureRoot();
    // Cancel a pending close-wipe so a modal opened right after closeModal()
    // (e.g. sign-in leading straight into report/escalation) is not erased.
    if (wipeTimer) { clearTimeout(wipeTimer); wipeTimer = null; }
    root.innerHTML = '<div class="sb-modal-backdrop" id="sbBackdrop"><div class="sb-modal" role="dialog" aria-modal="true">' +
      '<button class="sb-modal-close" id="sbClose" aria-label="Close">×</button>' + html + '</div></div>';
    document.body.style.overflow = 'hidden';
    var card = root.querySelector('.sb-modal');
    setTimeout(function () { var bd = root.querySelector('.sb-modal-backdrop'); if (bd) bd.classList.add('open'); }, 20);
    root.querySelector('#sbClose').onclick = closeModal;
    root.querySelector('#sbBackdrop').onclick = function (e) { if (e.target.id === 'sbBackdrop') closeModal(); };
    if (onMount) onMount(card);
  }
  function closeModal() {
    if (!root) return;
    var b = root.querySelector('.sb-modal-backdrop');
    if (b) b.classList.remove('open');
    document.body.style.overflow = '';
    wipeTimer = setTimeout(function () {
      if (root) root.innerHTML = '';
      wipeTimer = null;
    }, 250);
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
      setTimeout(function () { a.style.strokeDashoffset = a.getAttribute('data-off'); }, 80);
    });
  }
  function stars(n) {
    var out = '';
    for (var i = 1; i <= 5; i++) out += '<span class="sb-star ' + (i <= n ? 'on' : '') + '">★</span>';
    return out;
  }

  // ── Evidence: synthetic chat + payment screenshots (crisp SVG) ──────────
  var EVGROUPS = {}; // reset each profile open; maps report/review id -> [evidence]

  function wrap(text, max) {
    var words = String(text).split(' '), lines = [], cur = '';
    words.forEach(function (w) {
      if ((cur + ' ' + w).trim().length > max) { if (cur) lines.push(cur); cur = w; }
      else cur = (cur + ' ' + w).trim();
    });
    if (cur) lines.push(cur);
    return lines;
  }
  function appTheme(app) {
    switch (app) {
      case 'WhatsApp': return { bar: '#075E54', accent: '#DCF8C6', name: app };
      case 'Viber': return { bar: '#7360F2', accent: '#E7E3FF', name: app };
      case 'Facebook': return { bar: '#0866FF', accent: '#E7F0FF', name: 'Messenger' };
      case 'Instagram': return { bar: '#C13584', accent: '#FCE7F3', name: 'Instagram DM' };
      case 'TikTok': return { bar: '#111', accent: '#EAEAEA', name: 'TikTok DM' };
      default: return { bar: '#1565C0', accent: '#E7F0FF', name: 'Chat' };
    }
  }
  function buildConversation(ev) {
    var amt = 'Rs ' + Number(ev.amount || 0).toLocaleString('en-IN');
    var item = ev.item || 'the item';
    var t = [];
    if (ev.scenario === 'received') {
      t.push({ w: 'them', x: 'Your order has been shipped 🚚' });
      t.push({ w: 'me', x: 'Received the parcel, thank you! ❤️', k: 2 });
      t.push({ w: 'me', x: 'Quality is exactly as shown 👌', k: 2 });
      t.push({ w: 'them', x: 'Thank you for shopping with us 🙏' });
    } else if (ev.scenario === 'wrongitem') {
      t.push({ w: 'me', x: 'Sent ' + amt + ' for ' + item + ' 🙏', k: 2 });
      t.push({ w: 'them', x: 'Received 👍 shipping today' });
      t.push({ w: 'me', x: 'This is NOT what I ordered 😡', k: 2 });
      t.push({ w: 'me', x: 'I wanted ' + item + ', got something cheap', k: 1 });
      t.push({ w: 'me', x: 'Please refund or resend', k: 1 });
      t.push({ b: 'Seller stopped replying · last seen 6 days ago' });
    } else { // 'blocked' (default scam pattern)
      t.push({ w: 'them', x: 'Yes ' + item + ' available 🙏 Send advance to confirm' });
      t.push({ w: 'me', x: 'Okay sending now', k: 2 });
      t.push({ p: true }); // payment chip
      t.push({ w: 'me', x: 'Sent ' + amt + ', please confirm 🙏', k: 2 });
      t.push({ w: 'them', x: 'Received 👍 Will ship today' });
      t.push({ w: 'me', x: 'Any update on delivery?', k: 1 });
      t.push({ w: 'me', x: "Hello? It's been 5 days 😟", k: 1 });
      t.push({ w: 'me', x: 'Please reply 🙏', k: 1 });
      t.push({ b: '🚫 You can no longer message this contact' });
    }
    return t;
  }
  function chatSVG(ev) {
    var th = appTheme(ev.app);
    var W = 340, y = 78, body = '';
    buildConversation(ev).forEach(function (m) {
      if (m.p) {
        body += '<g transform="translate(' + (W - 232) + ',' + y + ')">' +
          '<rect width="220" height="46" rx="12" fill="#fff" stroke="#E2E8F0"/>' +
          '<circle cx="26" cy="23" r="13" fill="#60BB46"/><text x="26" y="28" font-size="13" fill="#fff" text-anchor="middle">₨</text>' +
          '<text x="46" y="20" font-size="12" font-weight="700" fill="#0A1628">Payment sent</text>' +
          '<text x="46" y="36" font-size="11" fill="#5B6B82">eSewa · Rs ' + Number(ev.amount || 0).toLocaleString('en-IN') + '</text></g>';
        y += 58; return;
      }
      if (m.b) {
        body += '<g transform="translate(20,' + y + ')"><rect width="' + (W - 40) + '" height="34" rx="9" fill="#FDE7E7"/>' +
          '<text x="' + ((W - 40) / 2) + '" y="22" font-size="11.5" font-weight="600" fill="#C0392B" text-anchor="middle">' + m.b + '</text></g>';
        y += 46; return;
      }
      var me = m.w === 'me';
      var lines = wrap(m.x, 30);
      var longest = lines.reduce(function (a, l) { return Math.max(a, l.length); }, 0);
      var bw = Math.min(238, longest * 6.6 + 26);
      var bh = lines.length * 17 + 20;
      var x = me ? (W - 20 - bw) : 20;
      var fill = me ? th.accent : '#FFFFFF';
      var txt = lines.map(function (l, i) {
        return '<text x="' + (x + 13) + '" y="' + (y + 19 + i * 17) + '" font-size="12.5" fill="#0A1628">' + esc(l) + '</text>';
      }).join('');
      var tick = me ? '<text x="' + (x + bw - 8) + '" y="' + (y + bh - 6) + '" font-size="10" text-anchor="end" fill="' + (m.k === 2 ? '#34B7F1' : '#9AA7B8') + '">' + (m.k === 2 ? '✓✓' : '✓') + '</text>' : '';
      body += '<g><rect x="' + x + '" y="' + y + '" width="' + bw + '" height="' + bh + '" rx="12" fill="' + fill + '" stroke="#EAEFF5"/>' + txt + tick + '</g>';
      y += bh + 10;
    });
    var H = y + 16;
    return '<svg viewBox="0 0 ' + W + ' ' + H + '" xmlns="http://www.w3.org/2000/svg" font-family="Inter, sans-serif">' +
      '<rect width="' + W + '" height="' + H + '" fill="#ECE5DD"/>' +
      '<rect width="' + W + '" height="60" fill="' + th.bar + '"/>' +
      '<circle cx="34" cy="30" r="16" fill="rgba(255,255,255,0.25)"/>' +
      '<text x="34" y="35" font-size="15" fill="#fff" text-anchor="middle" font-weight="700">' + esc((ev.seller || 'S')[0]) + '</text>' +
      '<text x="60" y="26" font-size="14" font-weight="700" fill="#fff">' + esc(ev.seller || 'Seller') + '</text>' +
      '<text x="60" y="43" font-size="11" fill="rgba(255,255,255,0.8)">' + esc(th.name) + (ev.scenario === 'blocked' ? ' · blocked you' : ' · last seen long ago') + '</text>' +
      body + '</svg>';
  }
  function paymentSVG(ev) {
    var isKhalti = ev.method === 'Khalti';
    var brand = isKhalti ? '#5C2D91' : '#60BB46';
    var name = isKhalti ? 'Khalti' : 'eSewa';
    var amt = Number(ev.amount || 0).toLocaleString('en-IN');
    var rows = [
      ['Paid to', ev.to || 'Seller'],
      ['Mobile / ID', ev.id || '98XXXXXXXX'],
      ['Reference', ev.ref || ('TXN' + (100000 + Math.floor(Math.random() * 899999)))],
      ['Channel', name + ' Mobile'],
      ['Date', ev.when || 'Recently']
    ];
    var W = 320, H = 470;
    var rowsSVG = rows.map(function (r, i) {
      var yy = 250 + i * 40;
      return '<text x="26" y="' + yy + '" font-size="12.5" fill="#8A98AC">' + esc(r[0]) + '</text>' +
        '<text x="' + (W - 26) + '" y="' + yy + '" font-size="12.5" font-weight="600" fill="#0A1628" text-anchor="end">' + esc(r[1]) + '</text>' +
        '<line x1="26" y1="' + (yy + 14) + '" x2="' + (W - 26) + '" y2="' + (yy + 14) + '" stroke="#EEF2F6"/>';
    }).join('');
    return '<svg viewBox="0 0 ' + W + ' ' + H + '" xmlns="http://www.w3.org/2000/svg" font-family="Inter, sans-serif">' +
      '<rect width="' + W + '" height="' + H + '" fill="#F6F8FB"/>' +
      '<rect width="' + W + '" height="150" fill="' + brand + '"/>' +
      '<text x="' + (W / 2) + '" y="46" font-size="20" font-weight="800" fill="#fff" text-anchor="middle">' + name + '</text>' +
      '<circle cx="' + (W / 2) + '" cy="96" r="26" fill="rgba(255,255,255,0.2)"/>' +
      '<path d="M' + (W / 2 - 12) + ' 96 l8 8 l16 -17" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' +
      '<text x="' + (W / 2) + '" y="185" font-size="14" fill="#5B6B82" text-anchor="middle">Payment Successful</text>' +
      '<text x="' + (W / 2) + '" y="222" font-size="30" font-weight="800" fill="#0A1628" text-anchor="middle">Rs ' + amt + '</text>' +
      rowsSVG + '</svg>';
  }
  function renderEvidenceFull(ev) {
    if (ev.kind === 'image') return '<img src="' + ev.src + '" alt="evidence" style="width:100%;border-radius:12px"/>';
    if (ev.kind === 'payment') return paymentSVG(ev);
    return chatSVG(ev);
  }
  function evLabel(ev) {
    if (ev.kind === 'image') return '📷 Screenshot';
    if (ev.kind === 'payment') return (ev.method || 'eSewa') + ' receipt';
    return (ev.app || 'Chat') + ' chat';
  }
  function evidenceThumbs(key, list) {
    if (!list || !list.length) return '';
    EVGROUPS[key] = list;
    return '<div class="sb-ev-row">' + list.map(function (ev, i) {
      return '<button class="sb-ev-thumb" data-evkey="' + key + '" data-evidx="' + i + '" title="View evidence">' +
        '<div class="sb-ev-preview">' + renderEvidenceFull(ev) + '</div>' +
        '<span>' + esc(evLabel(ev)) + '</span></button>';
    }).join('') + '</div>';
  }
  function wireEvidence(scope) {
    scope.querySelectorAll('.sb-ev-thumb').forEach(function (b) {
      b.onclick = function (e) {
        e.stopPropagation();
        var list = EVGROUPS[b.getAttribute('data-evkey')];
        openLightbox(list, parseInt(b.getAttribute('data-evidx'), 10));
      };
    });
  }
  function openLightbox(list, idx) {
    if (!list || !list.length) return;
    var lb = document.getElementById('sbLightbox');
    if (!lb) { lb = document.createElement('div'); lb.id = 'sbLightbox'; lb.className = 'sb-lightbox'; document.body.appendChild(lb); }
    function render(i) {
      var ev = list[i];
      lb.innerHTML = '<div class="sb-lb-inner">' +
        '<button class="sb-lb-close" aria-label="Close">×</button>' +
        (list.length > 1 ? '<button class="sb-lb-nav prev" aria-label="Previous">‹</button><button class="sb-lb-nav next" aria-label="Next">›</button>' : '') +
        '<div class="sb-lb-stage">' + renderEvidenceFull(ev) + '</div>' +
        '<div class="sb-lb-cap">' + esc(evLabel(ev)) + (ev.caption ? ' · ' + esc(ev.caption) : '') + ' · ' + (i + 1) + '/' + list.length + '</div></div>';
      lb.querySelector('.sb-lb-close').onclick = close;
      var p = lb.querySelector('.prev'), n = lb.querySelector('.next');
      if (p) p.onclick = function () { i = (i - 1 + list.length) % list.length; render(i); };
      if (n) n.onclick = function () { i = (i + 1) % list.length; render(i); };
      lb.onclick = function (e) { if (e.target === lb) close(); };
    }
    function close() { lb.classList.remove('open'); setTimeout(function () { lb.innerHTML = ''; }, 250); }
    render(idx || 0);
    setTimeout(function () { lb.classList.add('open'); }, 20);
  }

  // ── v1.1 feature parity: loyalty badges, checklist, WhatsApp, police ────
  function loyaltyTier(s) {
    if ((s.reports || []).length) return null;
    var d = s.accountAgeDays || 0;
    if (d >= 730) return { label: '2 Year Elite Seller', color: '#D4AF37' };
    if (d >= 365) return { label: '1 Year Trusted', color: '#97A3B4' };
    if (d >= 182) return { label: '6 Month Clean Record', color: '#CD7F32' };
    return null;
  }
  function loyaltyPill(s, compact) {
    var t = loyaltyTier(s);
    if (!t) return '';
    return '<span class="sb-loyalty' + (compact ? ' sm' : '') + '" style="border-color:' + t.color + '99;color:' + t.color + '">🎖 ' + t.label + '</span>';
  }

  function warningText(s, r, lost) {
    return 'FRAUD WARNING (SafeBuy Nepal)\n' +
      'Seller: ' + s.name + ' (' + s.phone + ')\n' +
      'Platform: ' + s.platform + '\n' +
      'Trust Rating: HIGH RISK, ' + r.score + '/100\n' +
      'Fraud Reports: ' + s.reports.length + '\n' +
      'Amount Reported Lost: NPR ' + Number(lost).toLocaleString('en-IN') + '\n\n' +
      'Check any seller before paying:\nsafebuy-nepal.vercel.app\n\n' +
      'Shared via SafeBuy Nepal';
  }
  function copyText(text, done) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, done);
    } else {
      var ta = document.createElement('textarea');
      ta.value = text; document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); } catch (e) { /* ignore */ }
      document.body.removeChild(ta); done();
    }
  }

  var CHECK_STEPS = [
    'Ask for a video call showing the actual product',
    'Check their Instagram/TikTok comments for complaints',
    'Start with a small test order under NPR 500',
    'Screenshot their profile and QR before paying',
    'Never pay the full amount before dispatch'
  ];
  function chkState(id) {
    try { return JSON.parse(sessionStorage.getItem('sb_chk_' + id)) || { done: [], hidden: false }; }
    catch (e) { return { done: [], hidden: false }; }
  }
  function chkSave(id, st) {
    try { sessionStorage.setItem('sb_chk_' + id, JSON.stringify(st)); } catch (e) { /* ignore */ }
  }
  function checklistHTML(s) {
    var st = chkState(s.id);
    if (st.hidden) return '';
    var all = st.done.length === CHECK_STEPS.length;
    return '<div class="sb-checklist' + (all ? ' done' : '') + '" id="sbChecklist">' +
      '<div class="sb-chk-head"><b>' + (all ? '✅ You have completed all safety steps' : '🧾 Unverified Seller: Check These Before Paying') + '</b>' +
      '<span>' + st.done.length + ' of ' + CHECK_STEPS.length + '</span></div>' +
      '<div class="sb-chk-bar"><i style="width:' + (st.done.length / CHECK_STEPS.length * 100) + '%"></i></div>' +
      (all ? '<p class="sb-chk-note">You are better protected now.</p>' :
        CHECK_STEPS.map(function (step, i) {
          var on = st.done.indexOf(i) !== -1;
          return '<button class="sb-chk-item' + (on ? ' on' : '') + '" data-chk="' + i + '">' +
            '<span>' + (on ? '✓' : '○') + '</span> ' + step + '</button>';
        }).join('')) +
      '<button class="sb-chk-dismiss" id="sbChkDismiss">I understand the risks</button></div>';
  }

  function openEscalation(id) {
    requireSignIn(function (user) {
      var s = getSeller(id); if (!s) return;
      var r = computeScore(s);
      var lost = totalLost(s);
      var newest = s.reports[s.reports.length - 1];
      var today = new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'long', year: 'numeric' });
      var body =
        'CYBERCRIME COMPLAINT\n' +
        'Date: ' + today + '\n\n' +
        'To: Nepal Police Cybercrime Investigation Bureau\nNaxal, Kathmandu\n\n' +
        'COMPLAINANT: ' + user.tag + ' (details filled in the app)\n\n' +
        'INCIDENT DETAILS\n' +
        'Seller: ' + s.name + ' | ' + s.handle + ' | ' + s.phone + '\n' +
        'Platform: ' + s.platform + '\n' +
        'Fraud reports on record: ' + s.reports.length + '\n' +
        'Amount reported lost: NPR ' + Number(lost).toLocaleString('en-IN') + '\n\n' +
        'DESCRIPTION\n' + (newest ? newest.desc : 'See attached SafeBuy Nepal report records.') + '\n\n' +
        'APPLICABLE LAW\nElectronic Transactions Act 2063, Section 48 (Electronic Fraud: advance payment taken, goods never sent)\n\n' +
        'All evidence is preserved on the SafeBuy Nepal platform and available on request.\n\n' +
        'Filed via SafeBuy Nepal (safebuy-nepal.vercel.app)';
      openModal(
        '<h3 class="sb-form-title">🏛️ Escalate to Nepal Police</h3>' +
        '<div class="sb-bureau"><b>Nepal Police Cybercrime Investigation Bureau</b>' +
        '<p>📍 Naxal, Kathmandu · 📞 <a href="tel:014412323">01-4412323</a> · 🕙 Sun to Fri, 10am to 5pm</p>' +
        '<p>✉️ <a href="mailto:cybercrime@nepalpolice.gov.np">cybercrime@nepalpolice.gov.np</a></p></div>' +
        '<label class="sb-esc-label">Complaint preview (auto-filled from the fraud record):</label>' +
        '<pre class="sb-esc-preview">' + esc(body) + '</pre>' +
        '<label class="sb-declare"><input type="checkbox" id="sbDeclare"> I declare this information is true. Filing a false complaint is an offence under the laws of Nepal.</label>' +
        '<button class="btn btn-primary sb-submit" id="sbEmailPolice">✉️ Email Complaint to Nepal Police</button>' +
        '<p class="sb-esc-note">The mobile app can also save this complaint as an official PDF to carry to the Naxal office in person.</p>',
        function (card) {
          card.querySelector('#sbEmailPolice').onclick = function () {
            if (!card.querySelector('#sbDeclare').checked) { toast('⚠️ Please confirm the declaration first.'); return; }
            var subject = 'Cybercrime Complaint - Social Commerce Fraud - SafeBuy Nepal (' + s.name + ')';
            location.href = 'mailto:cybercrime@nepalpolice.gov.np?subject=' + encodeURIComponent(subject) + '&body=' + encodeURIComponent(body);
            toast('✓ Complaint draft opened in your email app.');
          };
        }
      );
    });
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
      '<small>' + esc(s.handle) + ' · ' + esc(s.platform) + '</small>' +
      loyaltyPill(s, true) + '</div>' +
      '<div class="sb-result-score"><span class="sb-badge" style="background:' + r.color + '22;color:' + r.color + '">' + r.score + '</span>' +
      '<em style="color:' + r.color + '">' + r.label + '</em></div></button>';
  }
  function renderResults(list) {
    var box = document.getElementById('demoResults');
    if (!box) return;
    if (!list.length) {
      box.innerHTML = '<div class="sb-empty">🔍 No seller found. This does not mean they are fraudulent. They may simply not be registered yet. Check the spelling, or <b>add this seller</b> so the community can start building their trust record.</div>';
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
    EVGROUPS = {};
    var r = computeScore(s);
    var lost = totalLost(s);
    var reportsHTML = s.reports.length ? s.reports.slice().reverse().map(function (rp) {
      return '<div class="sb-item"><div class="sb-item-top"><span class="sb-tag-red">' + esc(TYPE_LABEL[rp.type] || rp.type) + '</span>' +
        '<b>' + npr(rp.amount || 0) + '</b></div><p>' + esc(rp.desc) + '</p>' +
        evidenceThumbs(rp.id, rp.proof) +
        '<div class="sb-item-meta">🛡️ ' + esc(rp.reporter) + ' · ' + esc(rp.platform) + ' · ' + timeAgo(rp.date) + '</div></div>';
    }).join('') : '<div class="sb-empty sm">No fraud reports yet.</div>';

    var reviewsHTML = s.reviews.length ? s.reviews.slice().reverse().map(function (rv) {
      return '<div class="sb-item"><div class="sb-item-top"><span class="sb-stars">' + stars(rv.rating) + '</span></div>' +
        '<p>' + esc(rv.comment) + '</p>' +
        evidenceThumbs(rv.id, rv.proof) +
        '<div class="sb-item-meta">🛡️ ' + esc(rv.reporter) + ' · ' + timeAgo(rv.date) + '</div></div>';
    }).join('') : '<div class="sb-empty sm">No reviews yet.</div>';

    var escalation = s.reports.length >= 4 || lost >= 25000;

    // 48h response window on the newest complaint (mirrors the app rule).
    var cdBlock = '';
    if (s.reports.length) {
      var newestAt = Math.max.apply(null, s.reports.map(function (x) { return x.date; }));
      var hrsLeft = 48 - (Date.now() - newestAt) / 3600000;
      cdBlock = hrsLeft > 0
        ? '<div class="sb-countdown amber">⏳ Seller has <b>' + Math.floor(hrsLeft) + 'h ' +
          Math.floor((hrsLeft % 1) * 60) + 'm</b> to respond to the newest complaint.' +
          '<div class="sb-cd-bar"><i style="width:' + ((48 - hrsLeft) / 48 * 100) + '%"></i></div></div>'
        : '<div class="sb-countdown red">⏱ Seller did not respond within 48 hours. This negatively affects their trust rating.</div>';
    }

    var waBlock = r.verdict === 'high_risk'
      ? '<div class="sb-wa-row"><button class="btn sb-wa" id="sbWaShare">Share on WhatsApp</button>' +
        '<button class="btn btn-outline sb-copywarn" id="sbWaCopy">Copy Warning Text</button></div>'
      : '';
    var checklistBlock = r.verdict === 'unverified' ? checklistHTML(s) : '';
    var policeBtn = r.verdict === 'high_risk'
      ? '<button class="btn sb-police" id="sbEscalate">🏛️ Escalate to Nepal Police</button>'
      : '';

    openModal(
      '<div class="sb-profile-head">' + ring(r.score, r.color) +
      '<div class="sb-profile-id"><h3>' + esc(s.name) + '</h3>' +
      '<p>' + esc(s.handle) + ' · ' + esc(s.phone) + '</p>' +
      '<span class="sb-verdict" style="background:' + r.color + '22;color:' + r.color + '">' + (r.verdict === 'trusted' ? '✓ ' : r.verdict === 'high_risk' ? '✕ ' : '? ') + r.label + '</span>' +
      (s.verified ? '<span class="sb-verified">✓ Verified business</span>' : '') +
      loyaltyPill(s, false) +
      '</div></div>' +
      '<div class="sb-stats"><div><b>' + s.reports.length + '</b><span>Reports</span></div>' +
      '<div><b>' + s.reviews.length + '</b><span>Reviews</span></div>' +
      '<div><b>' + npr(lost) + '</b><span>Reported loss</span></div>' +
      '<div><b>' + esc(s.platform) + '</b><span>Platform</span></div></div>' +
      waBlock +
      checklistBlock +
      cdBlock +
      (escalation ? '<div class="sb-escalate">⚖️ This seller has crossed the fraud threshold. In the app, an official <b>Cyber Bureau निवेदन</b> letter is auto-drafted for admin approval.</div>' : '') +
      policeBtn +
      '<div class="sb-actions"><button class="btn btn-primary" id="sbReportBtn">🚩 Report Fraud</button>' +
      '<button class="btn btn-outline" id="sbReviewBtn">⭐ Write Review</button></div>' +
      '<div class="sb-tabs"><button class="sb-tab active" data-tab="reports">Reports (' + s.reports.length + ')</button>' +
      '<button class="sb-tab" data-tab="reviews">Reviews (' + s.reviews.length + ')</button></div>' +
      '<div class="sb-tabpane" id="paneReports">' + reportsHTML + '</div>' +
      '<div class="sb-tabpane" id="paneReviews" style="display:none">' + reviewsHTML + '</div>',
      function (card) {
        animateRings(card);
        wireEvidence(card);
        card.querySelector('#sbReportBtn').onclick = function () { openReportForm(s.id); };
        card.querySelector('#sbReviewBtn').onclick = function () { openReviewForm(s.id); };

        // v1.1 parity wiring
        var wa = card.querySelector('#sbWaShare');
        if (wa) wa.onclick = function () {
          window.open('https://wa.me/?text=' + encodeURIComponent(warningText(s, r, lost)), '_blank');
        };
        var cp = card.querySelector('#sbWaCopy');
        if (cp) cp.onclick = function () {
          copyText(warningText(s, r, lost), function () {
            toast('✓ Warning text copied to clipboard');
          });
        };
        var escBtn = card.querySelector('#sbEscalate');
        if (escBtn) escBtn.onclick = function () { openEscalation(s.id); };
        var chk = card.querySelector('#sbChecklist');
        if (chk) {
          chk.querySelectorAll('.sb-chk-item').forEach(function (b) {
            b.onclick = function () {
              var st = chkState(s.id);
              var i = parseInt(b.getAttribute('data-chk'), 10);
              var at = st.done.indexOf(i);
              if (at === -1) st.done.push(i); else st.done.splice(at, 1);
              chkSave(s.id, st);
              openSeller(s.id);
            };
          });
          var dis = chk.querySelector('#sbChkDismiss');
          if (dis) dis.onclick = function () {
            var st = chkState(s.id); st.hidden = true; chkSave(s.id, st);
            openSeller(s.id);
          };
        }
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
        '<h3 class="sb-form-title">🚩 Report Fraud</h3><p class="sb-form-sub">Reporting <b>' + esc(s.name) + '</b>. You stay anonymous, only "' + esc(user.tag) + '" is shown.</p>' +
        '<form id="sbReportForm" class="sb-form">' +
        '<label>What happened?</label><select id="rpType" required>' +
        Object.keys(TYPE_LABEL).map(function (k) { return '<option value="' + k + '">' + TYPE_LABEL[k] + '</option>'; }).join('') + '</select>' +
        '<label>Where did you find this seller?</label><select id="rpPlatform" required>' +
        PLATFORMS.map(function (p) { return '<option' + (p === s.platform ? ' selected' : '') + '>' + p + '</option>'; }).join('') + '</select>' +
        '<label>How much money was scammed? <b id="rpAmtLabel" class="sb-amt">NPR 5,000</b></label>' +
        '<input type="range" id="rpAmount" class="sb-slider" min="0" max="100000" step="500" value="5000"/>' +
        '<label>Describe what happened</label><textarea id="rpDesc" rows="3" minlength="20" placeholder="Explain the incident in at least 20 characters..." required></textarea>' +
        '<label class="sb-file-label">📎 Evidence (required): screenshot of chat / payment' +
        '<input type="file" id="rpEvidence" accept="image/*" required></label>' +
        '<div class="sb-anon">🔒 Your name & phone stay private. False reports hurt the community, so only report real incidents. <button type="button" class="sb-inline-link" data-guide="report">Read the reporting rules ›</button></div>' +
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
            var file = card.querySelector('#rpEvidence').files[0];
            if (!file) { toast('⚠️ Evidence is required for every report.'); return; }
            readImage(file, function (proof) {
              s.reports.push({
                id: rid('RPT'), type: card.querySelector('#rpType').value,
                amount: parseInt(slider.value, 10), platform: card.querySelector('#rpPlatform').value,
                desc: desc, evidence: true, reporter: user.tag, date: Date.now(), proof: proof
              });
              updateSeller(s);
              closeModal();
              var nr = computeScore(s);
              toast('✓ Report filed · New trust score: <b>' + nr.score + ' (' + nr.label + ')</b>');
              setTimeout(function () { openSeller(s.id); doSearch(document.getElementById('demoSearch').value.trim()); }, 350);
            });
          };
        }
      );
    });
  }

  function paintSlider(el) {
    var pct = (el.value - el.min) / (el.max - el.min) * 100;
    el.style.background = 'linear-gradient(90deg,#E23B3B ' + pct + '%, #E6EDF5 ' + pct + '%)';
  }

  // Read an uploaded screenshot into a data URL so it displays as real evidence.
  function readImage(file, cb) {
    try {
      var fr = new FileReader();
      fr.onload = function () { cb([{ kind: 'image', src: fr.result, caption: 'Uploaded screenshot' }]); };
      fr.onerror = function () { cb([]); };
      fr.readAsDataURL(file);
    } catch (e) { cb([]); }
  }

  // ── Review form (star rating + evidence required) ───────────────────────
  function openReviewForm(id) {
    requireSignIn(function (user) {
      var s = getSeller(id); if (!s) return;
      openModal(
        '<h3 class="sb-form-title">⭐ Write a Review</h3><p class="sb-form-sub">Reviewing <b>' + esc(s.name) + '</b>. Evidence is required for positive <i>and</i> negative reviews to keep ratings fair. <button type="button" class="sb-inline-link" data-guide="review">Review rules ›</button></p>' +
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
            var file = card.querySelector('#rvEvidence').files[0];
            if (!file) { toast('⚠️ Evidence is required for every review.'); return; }
            readImage(file, function (proof) {
              s.reviews.push({ id: rid('REV'), rating: chosen, comment: c, evidence: true, reporter: user.name, date: Date.now(), proof: proof });
              updateSeller(s);
              closeModal();
              var nr = computeScore(s);
              toast('✓ Review posted · New trust score: <b>' + nr.score + ' (' + nr.label + ')</b>');
              setTimeout(function () { openSeller(s.id); doSearch(document.getElementById('demoSearch').value.trim()); }, 350);
            });
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
      '<p class="sb-form-sub">In the app, reporting requires a verified account (phone + email + national ID, approved by an admin). Here, just enter a display name and you will stay anonymous to others.</p>' +
      '<form id="siForm" class="sb-form">' +
      '<label>Display name</label><input id="siName" required placeholder="Your name"/>' +
      '<label>Email (optional)</label><input id="siEmail" type="email" placeholder="you@example.com"/>' +
      '<button type="submit" class="btn btn-primary sb-submit">Continue</button></form>';
  }

  // ── Navigation helpers ──────────────────────────────────────────────────
  function scrollToId(id) {
    var el = document.getElementById(id);
    if (!el) return;
    var top = el.getBoundingClientRect().top + window.pageYOffset - 80;
    window.scrollTo({ top: top, behavior: 'smooth' });
  }
  function gotoDemo(focus) {
    scrollToId('trydemo');
    if (focus) setTimeout(function () {
      var s = document.getElementById('demoSearch');
      if (s) { s.focus(); s.select(); }
    }, 600);
  }

  // ── Make marketing sections actionable ──────────────────────────────────
  function runAction(action) {
    switch (action) {
      case 'verify': gotoDemo(true); toast('🔍 Search any seller here to see their trust score.'); break;
      case 'report': openPicker('report'); break;
      case 'review': openPicker('review'); break;
      case 'chatbot': openChatbot(); break;
      case 'trust': scrollToId('trust-algorithm'); break;
      case 'alerts': openScamAlerts(); break;
      case 'lang': {
        var inactive = document.querySelector('.lang-toggle .lang-btn:not(.active)');
        if (inactive) inactive.click();
        toast('🌐 Language switched.');
        break;
      }
    }
  }

  // Seller picker → for "Report Fraud" / "Write Review" launched from anywhere
  function openPicker(mode) {
    var list = load();
    var verb = mode === 'review' ? 'review' : 'report';
    openModal(
      '<h3 class="sb-form-title">' + (mode === 'review' ? '⭐ Write a Review' : '🚩 Report Fraud') + '</h3>' +
      '<p class="sb-form-sub">Choose the seller you want to ' + verb + '. Can\'t find them? Close this and use “Add a seller”.</p>' +
      '<div class="sb-picker">' + list.map(resultCard).join('') + '</div>',
      function (card) {
        card.querySelectorAll('.sb-result').forEach(function (b) {
          b.onclick = function () {
            var id = b.getAttribute('data-id');
            if (mode === 'review') openReviewForm(id); else openReportForm(id);
          };
        });
      }
    );
  }

  // Safety assistant (rule-based, runs fully in the browser)
  function botReply(q) {
    q = ' ' + q.toLowerCase() + ' ';
    function has() { for (var i = 0; i < arguments.length; i++) if (q.indexOf(arguments[i]) > -1) return true; return false; }
    if (has('hello', 'hi ', 'hey', 'namaste')) return "Namaste! 🙏 I'm the <b>SafeBuy Safety Assistant</b>. Ask me about advance payments, spotting fake sellers, or what to do if you were scammed.";
    if (has('esewa', 'khalti', ' qr', 'advance', 'deposit', 'pay first', 'pay now')) return "⚠️ <b>Never pay the full amount in advance</b> to an unknown seller. Scammers ask for eSewa/Khalti/QR advance, then block you.<br>• Prefer Cash on Delivery.<br>• If advance is needed, pay only a small token.<br>• Check the seller's SafeBuy trust score first.<br>• Keep the payment screenshot as evidence.";
    if (has('fake', 'spot', 'genuine', ' real ', 'verify', 'legit', 'trustworthy')) return "🔍 <b>To spot a fake seller:</b><br>• Search them on SafeBuy — a score below 50 is High Risk.<br>• Brand-new account with only 5-star reviews = suspicious.<br>• They rush you to move to WhatsApp/Viber.<br>• No address and no COD option.<br>• Reverse-search their product photos.";
    if (has('scam', 'cheat', 'lost money', 'fraud', 'ripped', 'duped', 'got robbed')) return "😔 Sorry that happened. Do this now:<br>1. Stop any further payment.<br>2. Screenshot all chats + the payment receipt.<br>3. File a report on SafeBuy (with evidence) so others are warned.<br>4. For large amounts, the app escalates to the <b>Cyber Bureau (निवेदन)</b>.<br>5. Inform your payment provider (eSewa/Khalti/bank).";
    if (has('block', 'no reply', 'ignoring', 'ghosted')) return "🚫 Being blocked after payment is the #1 scam pattern. Your chat + receipt are strong evidence — file a report so the seller's score drops and others avoid them.";
    if (has('score', 'algorithm', 'calculat', 'rating work')) return "📊 The trust score (0–100) is a 5-factor weighted model:<br>• Report severity 40%<br>• Verification 25%<br>• Reviews 20%<br>• Dispute resolution 10%<br>• Account age 5%<br><b>80+</b> = Trusted, <b>50–79</b> = Unverified, <b>below 50</b> = High Risk.";
    if (has('report', 'complain')) return "🚩 To report: open the <b>live verification tool</b>, search the seller, open their profile, then tap <b>Report Fraud</b>. Add the incident type, amount, and a screenshot (evidence is required).";
    if (has('review', 'feedback', 'rate ')) return "⭐ You can leave positive or negative reviews — both need evidence (a screenshot) so ratings stay fair. Search a seller and tap <b>Write Review</b>.";
    if (has('tiktok', 'instagram', 'facebook', 'whatsapp', 'viber')) return "📱 Most scams start on TikTok/Instagram ads, then move to WhatsApp/Viber for payment. Red flags: “DM to order”, “limited stock, pay now”, advance-only via QR. Always verify before paying.";
    if (has('cyber bureau', 'police', 'nivedan', 'निवेदन', ' law ')) return "⚖️ When a seller crosses the fraud threshold, SafeBuy auto-drafts an official Nepali <b>निवेदन</b> to the Cyber Bureau (Nepal Police) — an admin approves it before it's shared.";
    if (has('thank', 'dhanyabad')) return "You're welcome! Stay safe and always verify before you pay. 🙏";
    return "I can help with: advance-payment safety, spotting fake sellers, what to do after a scam, how the trust score works, and reporting. Tap a quick question below 👇";
  }
  function openChatbot() {
    openModal(
      '<div class="sb-chat"><div class="sb-chat-head"><span class="cb-ava">🛡️</span><div><b>Safety Assistant</b><small>Shopping-safety answers · EN/नेपाली</small></div></div>' +
      '<div class="sb-chat-msgs" id="cbMsgs"></div>' +
      '<div class="sb-chat-chips" id="cbChips"></div>' +
      '<form class="sb-chat-input" id="cbForm"><input id="cbInput" autocomplete="off" placeholder="Ask about scams, payments, safety…"/><button class="btn btn-primary" type="submit" aria-label="Send">➤</button></form></div>',
      function (card) {
        var msgs = card.querySelector('#cbMsgs');
        function add(who, html) { var d = document.createElement('div'); d.className = 'cb-msg ' + who; d.innerHTML = html; msgs.appendChild(d); msgs.scrollTop = msgs.scrollHeight; }
        function botSay(t) { var typ = document.createElement('div'); typ.className = 'cb-msg bot cb-typing'; typ.innerHTML = '<span></span><span></span><span></span>'; msgs.appendChild(typ); msgs.scrollTop = msgs.scrollHeight; setTimeout(function () { typ.remove(); add('bot', t); }, 550); }
        add('bot', "Namaste! 🙏 I'm the <b>SafeBuy Safety Assistant</b>. Ask me anything about safe online shopping in Nepal — or tap a question below.");
        var qs = ['Is eSewa advance safe?', 'How to spot a fake seller?', 'I got scammed — what now?', 'How does the trust score work?'];
        var chipBox = card.querySelector('#cbChips');
        chipBox.innerHTML = qs.map(function (c) { return '<button type="button" class="cb-chip">' + esc(c) + '</button>'; }).join('');
        function send(text) { add('me', esc(text)); botSay(botReply(text)); }
        chipBox.querySelectorAll('.cb-chip').forEach(function (b) { b.onclick = function () { send(b.textContent); }; });
        card.querySelector('#cbForm').onsubmit = function (e) { e.preventDefault(); var inp = card.querySelector('#cbInput'); var v = inp.value.trim(); if (!v) return; inp.value = ''; send(v); };
      }
    );
  }

  // Live Scam Alerts
  function openScamAlerts() {
    var alerts = [
      { sev: 'high', area: 'Kathmandu', when: '2h ago', text: 'New TikTok “smart watch” scam — sellers move to WhatsApp and demand advance via QR, then vanish.' },
      { sev: 'high', area: 'Community', when: '3h ago', text: 'QuickBuy Electronics crossed the fraud threshold — a Cyber Bureau निवेदन has been prepared for admin approval.' },
      { sev: 'med', area: 'Lalitpur', when: '1d ago', text: 'Fake cosmetics pages cloning “Sunset Cosmetics” branding to take eSewa payments.' },
      { sev: 'med', area: 'Pokhara', when: '2d ago', text: 'Refurbished phones being sold as brand-new on TikTok Live. Always ask for COD.' },
      { sev: 'low', area: 'Nationwide', when: '3d ago', text: 'Reminder: legitimate sellers rarely need 100% advance. Verify the trust score before paying.' }
    ];
    var dot = { high: '#E23B3B', med: '#F59300', low: '#1565C0' };
    openModal(
      '<h3 class="sb-form-title">🔔 Live Scam Alerts</h3><p class="sb-form-sub">Recent community warnings across Nepal. In the app these arrive as push notifications.</p>' +
      '<div class="sb-alerts">' + alerts.map(function (a) {
        return '<div class="sb-alert"><span class="sb-alert-dot" style="background:' + dot[a.sev] + '"></span>' +
          '<div><p>' + esc(a.text) + '</p><small>📍 ' + esc(a.area) + ' · ' + esc(a.when) + '</small></div></div>';
      }).join('') + '</div>' +
      '<button class="btn btn-outline sb-submit" id="alGo">Search a seller now</button>',
      function (card) { card.querySelector('#alGo').onclick = function () { closeModal(); gotoDemo(true); }; }
    );
  }

  // Scam-type detail with prevention tips
  function openScamDetail(key) {
    var data = {
      non_delivery: { icon: '📦', title: 'Non-Delivery', pct: '35%', desc: 'Seller takes advance payment (often via WhatsApp/Viber QR) then never ships and blocks you.', tips: ['Prefer Cash on Delivery', 'Never pay 100% advance to a new seller', 'Check the trust score before paying', 'Save the chat + receipt as evidence'] },
      fake_product: { icon: '🏷️', title: 'Fake Products', pct: '28%', desc: 'Counterfeit items sold as branded originals — common in cosmetics and electronics.', tips: ['Compare price with official stores (too cheap = fake)', 'Ask for real unboxing photos/videos', 'Reverse-search product images', 'Read verified reviews with evidence'] },
      payment_issue: { icon: '💳', title: 'Payment Fraud', pct: '20%', desc: 'eSewa/Khalti reversals, swapped QR codes, and fake payment confirmations.', tips: ['Verify the recipient name before sending', 'Never scan a QR sent by the seller blindly', 'Keep transaction reference IDs', 'Confirm receipt independently'] },
      impersonation: { icon: '🎭', title: 'Account Cloning', pct: '12%', desc: 'Fake pages impersonate real businesses to steal customer payments.', tips: ['Check the account age and follower history', 'Verify via the business’s official channel', 'Beware slightly-misspelled handles', 'Report clones so others are warned'] }
    };
    var d = data[key]; if (!d) return;
    openModal(
      '<h3 class="sb-form-title">' + d.icon + ' ' + d.title + ' <span style="color:var(--high-risk)">' + d.pct + '</span></h3>' +
      '<p class="sb-form-sub">' + esc(d.desc) + '</p>' +
      '<div class="sb-tips"><h4>🛡️ How to protect yourself</h4><ul>' + d.tips.map(function (t) { return '<li>' + esc(t) + '</li>'; }).join('') + '</ul></div>' +
      '<div class="sb-actions"><button class="btn btn-primary" id="sdChat">Ask the Safety Assistant</button><button class="btn btn-outline" id="sdVerify">Verify a seller</button></div>',
      function (card) {
        card.querySelector('#sdChat').onclick = function () { closeModal(); setTimeout(openChatbot, 260); };
        card.querySelector('#sdVerify').onclick = function () { closeModal(); gotoDemo(true); };
      }
    );
  }

  // Install / download instructions
  function openInstall() {
    openModal(
      '<h3 class="sb-form-title">📲 Install SafeBuy Nepal</h3>' +
      '<p class="sb-form-sub">This works as a real app on your phone — installable and auto-updating.</p>' +
      '<div class="sb-tips"><h4>On Android (Chrome)</h4><ul><li>Tap the ⋮ menu → <b>Install app</b> / <b>Add to Home screen</b></li><li>Open it from your home-screen icon — it runs fullscreen like a native app</li></ul>' +
      '<h4>On iPhone (Safari)</h4><ul><li>Tap the Share icon → <b>Add to Home Screen</b></li></ul></div>' +
      '<button class="btn btn-primary sb-submit" id="inTry">Try it live first</button>',
      function (card) { card.querySelector('#inTry').onclick = function () { closeModal(); gotoDemo(true); }; }
    );
  }

  // Guidelines & Policies — what to know before searching / reporting / verifying
  var GUIDE = {
    search: {
      label: '🔍 Before you search', title: 'Before you search & verify',
      items: [
        'Search by <b>phone number, eSewa / Khalti ID, or social @handle / username</b>.',
        'A <b>low score is a community warning</b>, not legal proof of guilt.',
        'No record yet does <b>not</b> guarantee safety — new scam pages have no history.',
        'Always prefer <b>Cash on Delivery</b> and confirm the person before paying any advance.'
      ]
    },
    report: {
      label: '🚩 Before you report', title: 'Reporting rules',
      items: [
        '<b>Evidence is mandatory</b> — attach chat and/or payment screenshots.',
        'Only report <b>real incidents</b> you personally experienced or witnessed.',
        'False or malicious reports are <b>removed</b> and hurt the whole community.',
        'You stay <b>anonymous</b>: your name may show, your phone & personal details never do.',
        'Serious or repeated cases are <b>escalated to the Cyber Bureau</b> after admin review (official निवेदन).',
        'A report here is not a legal complaint by itself — for crimes, also file with the police / Cyber Bureau.'
      ]
    },
    review: {
      label: '⭐ Before you review', title: 'Review rules',
      items: [
        '<b>Evidence is required for positive AND negative</b> reviews — this keeps ratings fair.',
        'Be <b>honest and specific</b> about your real experience.',
        'One review per seller · minimum 20 characters · no spam or copy-paste.',
        'Reviews are <b>weighted by credibility</b>; fake and copy-pasted reviews are filtered out.'
      ]
    },
    verify: {
      label: '🪪 Getting verified', title: 'How sellers get verified',
      items: [
        'Register with a <b>real phone + email</b>.',
        'Upload a valid <b>National ID</b>; PAN / business registration is optional but recommended.',
        'An <b>admin manually reviews and approves</b> — this can take some time.',
        'Verification can be <b>revoked</b> if fraud is later confirmed.',
        'A <b>Verified badge</b> + good reviews build customer trust and more sales.'
      ]
    },
    privacy: {
      label: '⚖️ Privacy & law', title: 'Privacy & legal',
      items: [
        'Reporter identity is <b>protected</b>: name shown, contact details hidden.',
        'Evidence is used only for verification and, if escalated, for the Cyber Bureau.',
        'Aligned with the <b>Electronic Transactions Act 2063</b> and <b>Consumer Protection Act 2075</b>.',
        'Your data is <b>never sold</b>. You may request removal of your data.'
      ]
    }
  };
  function openGuidelines(tab) {
    var order = ['search', 'report', 'review', 'verify', 'privacy'];
    if (!GUIDE[tab]) tab = 'search';
    function paneHTML(key) {
      var g = GUIDE[key];
      return '<h3 class="pol-title">' + g.label.replace(/^\S+\s/, '') + '</h3><ul class="pol-list">' +
        g.items.map(function (t) { return '<li>' + t + '</li>'; }).join('') + '</ul>';
    }
    openModal(
      '<h3 class="sb-form-title">📖 Guidelines &amp; Policies</h3>' +
      '<p class="sb-form-sub">Know how SafeBuy works and the rules before you search, report, or verify.</p>' +
      '<div class="pol-tabs">' + order.map(function (k) {
        return '<button class="pol-tab" data-pol="' + k + '">' + GUIDE[k].label + '</button>';
      }).join('') + '</div><div class="pol-pane" id="polPane"></div>',
      function (card) {
        var tabs = card.querySelectorAll('.pol-tab');
        var pane = card.querySelector('#polPane');
        function select(key) {
          tabs.forEach(function (t) { t.classList.toggle('active', t.getAttribute('data-pol') === key); });
          pane.innerHTML = paneHTML(key);
        }
        tabs.forEach(function (t) { t.onclick = function () { select(t.getAttribute('data-pol')); }; });
        select(tab);
      }
    );
  }

  function wireActionableSections() {
    var featureActions = ['verify', 'report', 'chatbot', 'trust', 'alerts', 'lang'];
    document.querySelectorAll('#features .feature-card').forEach(function (card, i) {
      if (!featureActions[i]) return;
      card.classList.add('clickable'); card.setAttribute('role', 'button'); card.setAttribute('tabindex', '0');
      card.onclick = function () { runAction(featureActions[i]); };
      card.onkeydown = function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); runAction(featureActions[i]); } };
    });
    var scamKeys = ['non_delivery', 'fake_product', 'payment_issue', 'impersonation'];
    document.querySelectorAll('#safety .scam-card').forEach(function (card, i) {
      if (!scamKeys[i]) return;
      card.classList.add('clickable'); card.onclick = function () { openScamDetail(scamKeys[i]); };
    });
    document.querySelectorAll('#how-it-works .step').forEach(function (s) {
      s.classList.add('clickable'); s.onclick = function () { gotoDemo(true); };
    });
    document.querySelectorAll('.coldstart-section .feature-card').forEach(function (c) {
      c.classList.add('clickable'); c.onclick = function () { gotoDemo(true); };
    });
    var dl = document.querySelector('#download .btn');
    if (dl) dl.onclick = function (e) { e.preventDefault(); openInstall(); };
  }

  // Stakeholder (Buyer / Seller / Government) tab switching
  function wireStakeholderTabs() {
    var tabs = document.querySelectorAll('.stk-tab');
    if (!tabs.length) return;
    tabs.forEach(function (t) {
      t.onclick = function () {
        tabs.forEach(function (x) { x.classList.remove('active'); });
        t.classList.add('active');
        var key = t.getAttribute('data-stk');
        document.querySelectorAll('.stk-pane').forEach(function (p) {
          p.classList.toggle('active', p.id === 'stk-' + key);
        });
      };
    });
  }

  // Floating speed-dial gadget
  function wireSpeedDial() {
    var dial = document.getElementById('sbSpeedDial');
    if (!dial) return;
    var main = document.getElementById('sdMain');
    main.onclick = function (e) { e.stopPropagation(); dial.classList.toggle('open'); };
    document.addEventListener('click', function () { dial.classList.remove('open'); });
    dial.querySelectorAll('.sd-item').forEach(function (b) {
      b.onclick = function (e) { e.stopPropagation(); dial.classList.remove('open'); runAction(b.getAttribute('data-sd')); };
    });
  }

  // Expose for inline handlers if ever needed
  window.SafeBuy = { action: runAction, chatbot: openChatbot, alerts: openScamAlerts };

  // ── Boot ────────────────────────────────────────────────────────────────
  function init() {
    var search = document.getElementById('demoSearch');
    var searchBtn = document.getElementById('demoSearchBtn');
    var chips = document.getElementById('demoChips');
    wireActionableSections();
    wireStakeholderTabs();
    wireSpeedDial();
    // Any element with data-guide opens the guidelines/policy modal
    document.addEventListener('click', function (e) {
      var g = e.target.closest && e.target.closest('[data-guide]');
      if (g) { e.preventDefault(); openGuidelines(g.getAttribute('data-guide')); }
    });
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
      save(seed()); doSearch(''); toast('↺ Data reset.');
    };
    var add = document.getElementById('demoAddSeller');
    if (add) add.onclick = function (e) { e.preventDefault(); openAddSeller(); };

    doSearch(''); // show all sellers initially
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
