(function () {
    const root = document.querySelector('.doomscroll-landing');
    if (!root) return;

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReducedMotion) return;

    root.classList.add('has-motion');

    const revealItems = Array.from(document.querySelectorAll('.reveal'));
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                observer.unobserve(entry.target);
            }
        });
    }, {
        rootMargin: '0px 0px -10% 0px',
        threshold: 0.15
    });

    revealItems.forEach((item) => observer.observe(item));

    const parallaxItems = Array.from(document.querySelectorAll('[data-parallax]'));
    if (!parallaxItems.length) return;

    let ticking = false;
    const onScroll = () => {
        if (ticking) return;
        ticking = true;

        window.requestAnimationFrame(() => {
            const scrollY = window.scrollY;
            parallaxItems.forEach((item) => {
                const speed = Number(item.getAttribute('data-parallax')) || 0;
                item.style.transform = `translate3d(0, ${scrollY * speed * -0.15}px, 0)`;
            });
            ticking = false;
        });
    };

    window.addEventListener('scroll', onScroll, { passive: true });
})();
