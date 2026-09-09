module.exports = (req, res) => {
  const file = req.query.file || '';
  if (!file) {
    return res.redirect('/');
  }

  // Sanitize filename to prevent directory traversal
  const safeFile = encodeURIComponent(file.replace(/[^a-zA-Z0-9_.-]/g, ''));
  const supabaseUrl = `https://tbsmesdqigeajrwswlkj.supabase.co/storage/v1/object/public/gallery/${safeFile}`;
  
  // WhatsApp crawler requires preview images to be strictly < 300KB
  const previewThumbnail = `https://images.weserv.nl/?url=${encodeURIComponent(supabaseUrl)}&w=600&q=80&output=jpg`;
  
  // Fast loading web-optimized display image
  const displayImage = `https://images.weserv.nl/?url=${encodeURIComponent(supabaseUrl)}&w=1200&q=85&output=webp`;

  // Parse category or fallback title from filename if possible
  let title = 'Campus Memories';
  const catMatch = safeFile.match(/cat_([^_/]+(?:_[^_/]+)*)_/);
  if (catMatch) {
    title = decodeURIComponent(catMatch[1]);
  }

  // Check if raw image download requested
  if (req.query.raw === '1' || req.query.download === '1') {
    return res.redirect(supabaseUrl);
  }

  // Remove any x-robots-tag or strict headers that block WhatsApp
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=86400');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
  <title>${title} | Strawberry Preschool & Daycare</title>
  
  <!-- Open Graph / WhatsApp / Facebook / Twitter Card Meta Tags -->
  <meta property="og:type" content="article">
  <meta property="og:site_name" content="Strawberry Preschool & Daycare">
  <meta property="og:title" content="${title} 🍓 Strawberry Preschool">
  <meta property="og:description" content="View photo from Strawberry Preschool & Daycare, Sector 85, Faridabad. Safe, loving preschool & daycare.">
  <meta property="og:image" content="${previewThumbnail}">
  <meta property="og:image:secure_url" content="${previewThumbnail}">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="600">
  <meta property="og:image:height" content="600">
  <meta property="og:image:alt" content="${title}">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title} 🍓 Strawberry Preschool">
  <meta name="twitter:description" content="View photo from Strawberry Preschool & Daycare, Sector 85, Faridabad.">
  <meta name="twitter:image" content="${previewThumbnail}">

  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&display=swap" rel="stylesheet">

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0F172A;
      color: #F8FAFC;
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      -webkit-font-smoothing: antialiased;
    }
    header {
      padding: 12px 16px;
      background: rgba(15, 23, 42, 0.9);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      display: flex;
      align-items: center;
      justify-content: space-between;
      position: sticky;
      top: 0;
      z-index: 10;
      gap: 8px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: white;
      min-width: 0;
      flex: 1;
    }
    .brand img {
      width: 34px;
      height: 34px;
      border-radius: 50%;
      flex-shrink: 0;
    }
    .brand-info {
      min-width: 0;
      overflow: hidden;
    }
    .brand-text {
      font-size: 14px;
      font-weight: 800;
      letter-spacing: -0.2px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .brand-sub {
      font-size: 10.5px;
      color: #94A3B8;
      font-weight: 500;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .btn-visit {
      background: #E94464;
      color: white;
      text-decoration: none;
      font-size: 12px;
      font-weight: 700;
      padding: 8px 14px;
      border-radius: 20px;
      transition: all 0.2s;
      flex-shrink: 0;
      white-space: nowrap;
    }
    .btn-visit:hover {
      background: #d63353;
      transform: translateY(-1px);
    }
    main {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 12px 10px 24px;
      max-width: 860px;
      margin: 0 auto;
      width: 100%;
    }
    .photo-card {
      background: #1E293B;
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 16px 36px rgba(0, 0, 0, 0.5);
      border: 1px solid rgba(255, 255, 255, 0.08);
      width: 100%;
      display: flex;
      flex-direction: column;
    }
    .img-wrap {
      max-height: 74vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #000;
      overflow: hidden;
    }
    .img-wrap img {
      width: 100%;
      height: auto;
      max-height: 74vh;
      object-fit: contain;
      display: block;
    }
    .photo-info {
      padding: 14px 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      background: #1E293B;
    }
    .photo-title {
      font-size: 15px;
      font-weight: 700;
      color: #F8FAFC;
      display: flex;
      align-items: center;
      gap: 6px;
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .photo-actions {
      display: flex;
      gap: 8px;
      flex-shrink: 0;
    }
    .btn-action {
      background: rgba(255, 255, 255, 0.1);
      color: #F8FAFC;
      text-decoration: none;
      font-size: 12px;
      font-weight: 600;
      padding: 8px 14px;
      border-radius: 12px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      transition: background 0.2s;
      white-space: nowrap;
    }
    .btn-action:hover {
      background: rgba(255, 255, 255, 0.18);
    }
    .btn-action.primary {
      background: #E94464;
      color: white;
    }
    .btn-action.primary:hover {
      background: #d63353;
    }
    footer {
      text-align: center;
      padding: 14px;
      font-size: 11px;
      color: #64748B;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
    }

    /* Mobile Responsive Optimizations */
    @media (max-width: 560px) {
      header {
        padding: 10px 12px;
      }
      .brand img {
        width: 30px;
        height: 30px;
      }
      .brand-text {
        font-size: 13px;
      }
      .brand-sub {
        font-size: 10px;
      }
      .btn-visit {
        font-size: 11px;
        padding: 6px 12px;
      }
      main {
        padding: 8px 6px 16px;
      }
      .photo-card {
        border-radius: 14px;
      }
      .img-wrap {
        max-height: 68vh;
      }
      .img-wrap img {
        max-height: 68vh;
      }
      .photo-info {
        padding: 12px 14px;
      }
      .photo-title {
        font-size: 13.5px;
      }
      .btn-action {
        padding: 8px 14px;
        font-size: 11.5px;
      }
    }
  </style>
</head>
<body>
  <header>
    <a href="/" class="brand">
      <img src="/icons/Icon-192.png" alt="Strawberry Preschool">
      <div class="brand-info">
        <div class="brand-text">Strawberry Preschool</div>
        <div class="brand-sub">Sector 85, Faridabad</div>
      </div>
    </a>
    <a href="/" class="btn-visit">Visit Website →</a>
  </header>

  <main>
    <div class="photo-card">
      <div class="img-wrap">
        <img src="${displayImage}" onerror="this.src='${supabaseUrl}'" alt="${title}" loading="lazy">
      </div>
      <div class="photo-info">
        <div class="photo-title">📸 ${title}</div>
        <div class="photo-actions">
          <a href="/" class="btn-action primary">
            🍓 Visit Website
          </a>
        </div>
      </div>
    </div>
  </main>

  <footer>
    Strawberry Preschool & Daycare • Sector 85, Faridabad • +91 99992 49495
  </footer>
</body>
</html>`;

  return res.status(200).send(html);
};
