(() => {
  const button = document.querySelector('#install-button');
  const status = document.querySelector('#offline-status');
  const help = document.querySelector('#install-help');
  const notice = document.querySelector('#update-notice');
  const updateButton = document.querySelector('#update-button');
  const displayMode = window.matchMedia('(display-mode: standalone)');
  const isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent || '') ||
    (/Mac/i.test(navigator.platform || navigator.userAgent || '') && navigator.maxTouchPoints > 1);
  const isAndroid = /Android/i.test(navigator.userAgent || '');
  let helpPlatform = isIOS ? 'ios' : isAndroid ? 'android' : 'desktop';
  let installPrompt = null;
  let registration = null;
  let offlineReady = false;
  let updating = false;
  let installedByEvent = false;

  function setHelpPlatform(platform) {
    helpPlatform = platform;
    document.querySelector('#install-device-ios').setAttribute('aria-pressed', String(platform === 'ios'));
    document.querySelector('#install-device-android').setAttribute('aria-pressed', String(platform === 'android'));
    const intro = document.querySelector('#install-help-intro');
    const steps = document.querySelector('#install-help-steps');
    document.querySelector('#install-help-feedback').textContent = '';
    if (platform === 'ios') {
      intro.innerHTML = 'على آيفون وآيباد، أضف اللعبة من قائمة <b>Safari</b>.';
      steps.innerHTML = '<li>افتح رابط اللعبة مباشرة في <b>Safari</b>. إذا فتحته داخل واتساب أو ChatGPT، انسخه والصقه في Safari.</li><li>أغلق هذه النافذة، ثم اضغط <b>مشاركة</b> في شريط Safari <span class="install-share" aria-label="مربع وسهم للأعلى"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M8 9H4v12h16V9h-4M12 15V2m-4 4 4-4 4 4"/></svg></span>. قد تجدها داخل <b>قائمة الصفحة</b>.</li><li>اختَر <b>إضافة إلى الشاشة الرئيسية</b>. إذا لم تظهر، افتح <b>تعديل الإجراءات</b> وأضفها.</li><li>فعّل <b>فتح كتطبيق ويب</b> إذا ظهر، ثم اضغط <b>إضافة</b>.</li>';
    } else if (platform === 'android') {
      intro.innerHTML = 'على أندرويد، افتح رابط اللعبة مباشرة في <b>Chrome</b>. إذا كان داخل تطبيق آخر، انسخه والصقه في Chrome.';
      steps.innerHTML = '<li>اضغط قائمة <b>⋮</b> بجانب شريط العنوان.</li><li>اختَر <b>التثبيت وإنشاء اختصار</b> أو <b>الإضافة إلى الشاشة الرئيسية</b>.</li><li>اضغط <b>تثبيت</b>، ثم افتح اللعبة من أيقونتها.</li>';
    } else {
      intro.textContent = 'إذا ظهر خيار تثبيت اللعبة في شريط المتصفح أو قائمته، اضغطه. وللتثبيت على هاتفك، اختَر آيفون أو أندرويد أعلاه.';
      steps.innerHTML = '';
    }
  }
  setHelpPlatform(helpPlatform);
  document.querySelector('#install-device-ios').addEventListener('click', () => setHelpPlatform('ios'));
  document.querySelector('#install-device-android').addEventListener('click', () => setHelpPlatform('android'));
  if (isIOS) {
    button.textContent = 'إضافة للشاشة الرئيسية +';
    document.querySelector('#install-description').textContent = 'أضفها من Safari إلى الشاشة الرئيسية وافتحها كتطبيق.';
  }

  function refreshStatus() {
    const installed = installedByEvent || displayMode.matches || navigator.standalone === true;
    document.documentElement.classList.toggle('pwa-installed', installed);
    button.hidden = installed;
    if (installed) document.querySelector('#install-title').textContent = 'اللعبة على جهازك.';
    if (offlineReady) status.textContent = navigator.onLine ? '✓ جاهزة بدون إنترنت — كل الصور وملفات اللعبة محفوظة على الجهاز.' : '✓ أنت بدون إنترنت. اللعبة جاهزة، يلا نلعب!';
  }
  function closeHelp() { help.close(); }
  function showHelp() {
    document.dispatchEvent(new Event('kalma:before-update'));
    help.showModal();
  }
  function showUpdate() { if (registration?.waiting) notice.hidden = false; }
  refreshStatus();
  displayMode.addEventListener?.('change', refreshStatus);
  window.addEventListener('online', refreshStatus);
  window.addEventListener('offline', refreshStatus);
  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    installPrompt = event;
    button.textContent = 'تثبيت التطبيق ↓';
  });
  window.addEventListener('appinstalled', () => {
    installedByEvent = true;
    installPrompt = null;
    button.hidden = true;
    document.querySelector('#install-title').textContent = 'تم التثبيت… يلا حماس!';
    if (help.open) help.close();
  });
  button.addEventListener('click', async () => {
    if (!installPrompt) { showHelp(); return; }
    const prompt = installPrompt;
    installPrompt = null;
    try {
      await prompt.prompt();
      const choice = await prompt.userChoice;
      if (choice.outcome === 'accepted') button.textContent = 'جاري التثبيت…';
    } catch { showHelp(); }
  });
  document.querySelector('#close-install-help').addEventListener('click', closeHelp);
  document.querySelector('#done-install-help').addEventListener('click', closeHelp);
  help.addEventListener('click', event => { if (event.target === help) closeHelp(); });
  document.querySelector('#copy-install-link').addEventListener('click', async () => {
    const url = 'https://kalma-w-bas.laith-ziod.chatgpt.site';
    const feedback = document.querySelector('#install-help-feedback');
    try {
      await navigator.clipboard.writeText(url);
      feedback.dir = 'rtl';
      feedback.textContent = helpPlatform === 'ios' ? 'تم نسخ الرابط. الصقه في Safari على الآيفون أو الآيباد.' : helpPlatform === 'android' ? 'تم نسخ الرابط. افتحه في Chrome على جهازك.' : 'تم نسخ رابط اللعبة.';
    } catch {
      feedback.textContent = url;
      feedback.dir = 'ltr';
      feedback.style.userSelect = 'all';
    }
  });
  updateButton.addEventListener('click', () => {
    if (!registration?.waiting) return;
    document.dispatchEvent(new Event('kalma:before-update'));
    updating = true;
    updateButton.disabled = true;
    updateButton.textContent = 'جاري التحديث…';
    registration.waiting.postMessage({type:'ACTIVATE_UPDATE'});
  });
  if (!('serviceWorker' in navigator) || !window.isSecureContext) {
    status.textContent = `افتح اللعبة مباشرة في ${isIOS ? 'Safari' : 'متصفح جهازك'} لتجهيز اللعب دون اتصال.`;
    return;
  }
  navigator.serviceWorker.addEventListener('controllerchange', () => { if (updating) location.reload(); });
  navigator.serviceWorker.register('/sw.js', {scope:'/',updateViaCache:'none'}).then(reg => {
    registration = reg;
    showUpdate();
    function watchInstalling(worker) {
      worker?.addEventListener('statechange', () => {
        if (worker.state === 'installed') showUpdate();
        if (worker.state === 'redundant' && !reg.active) status.textContent = 'لم يكتمل التحميل دون اتصال. أعد فتح الصفحة وأنت متصل بالإنترنت.';
      });
    }
    watchInstalling(reg.installing);
    reg.addEventListener('updatefound', () => watchInstalling(reg.installing));
    return navigator.serviceWorker.ready;
  }).then(() => {
    offlineReady = true;
    refreshStatus();
  }).catch(() => {
    status.textContent = `اللعب متاح الآن. لتجهيز النسخة دون اتصال، افتح الرابط مباشرة في ${isIOS ? 'Safari' : 'متصفح جهازك'}.`;
  });
})();
