(() => {
  const year = new Date().getFullYear();
  document.querySelectorAll('[data-year]').forEach((node) => {
    node.textContent = year;
  });

  const params = new URLSearchParams(window.location.search);
  const paramLang = params.get('lang');
  const storedLang = window.localStorage.getItem('lang');
  const defaultLang = document.documentElement.getAttribute('lang') || 'en';
  const lang = paramLang || storedLang || defaultLang;

  if (paramLang) {
    window.localStorage.setItem('lang', paramLang);
  }

  const switcher = document.querySelector('[data-lang-switcher]');
  if (switcher) {
    switcher.value = lang;
    switcher.addEventListener('change', () => {
      const nextLang = switcher.value;
      const url = new URL(window.location.href);
      if (nextLang === 'en') {
        url.searchParams.delete('lang');
        window.localStorage.removeItem('lang');
      } else {
        url.searchParams.set('lang', nextLang);
        window.localStorage.setItem('lang', nextLang);
      }
      window.location.href = url.toString();
    });
  }

  if (!lang || lang === 'en') {
    return;
  }

  fetch(`/locales/${lang}.json`, { cache: 'no-store' })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`Missing locale: ${lang}`);
      }
      return response.json();
    })
    .then((dict) => {
      document.documentElement.setAttribute('lang', lang);

      const nodes = document.querySelectorAll('[data-i18n]');
      nodes.forEach((node) => {
        const key = node.getAttribute('data-i18n');
        const value = dict[key];
        if (typeof value === 'string') {
          if (node.hasAttribute('data-i18n-html')) {
            node.innerHTML = value;
          } else {
            node.textContent = value;
          }
        }

        const attrList = node.getAttribute('data-i18n-attr');
        if (attrList) {
          attrList.split(',').forEach((rawAttr) => {
            const attr = rawAttr.trim();
            if (!attr) {
              return;
            }
            const attrKey = `${key}.${attr}`;
            const attrValue = dict[attrKey];
            if (typeof attrValue === 'string') {
              node.setAttribute(attr, attrValue);
            }
          });
        }
      });
    })
    .catch((error) => {
      console.warn('[i18n] locale load failed', error);
    });
})();
