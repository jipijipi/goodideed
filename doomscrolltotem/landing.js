(function () {
    const root = document.querySelector('.doomscroll-landing');
    if (!root) return;

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    const storyKicker = document.querySelector('[data-story-kicker]');
    const storyTitle = document.querySelector('[data-story-title]');
    const storyDetail = document.querySelector('[data-story-detail]');
    const chapterNodes = Array.from(document.querySelectorAll('.chapter[data-step]'));
    const stepIndicators = Array.from(document.querySelectorAll('[data-step-indicator]'));

    const setActiveStep = (step) => {
        chapterNodes.forEach((chapter) => {
            chapter.classList.toggle('is-active', chapter.dataset.step === step);
        });

        stepIndicators.forEach((item) => {
            item.classList.toggle('is-active', item.dataset.stepIndicator === step);
        });

        const activeChapter = chapterNodes.find((chapter) => chapter.dataset.step === step);
        if (!activeChapter) return;

        if (storyKicker) storyKicker.textContent = activeChapter.dataset.kicker || '';
        if (storyTitle) storyTitle.textContent = activeChapter.dataset.title || '';
        if (storyDetail) storyDetail.textContent = activeChapter.dataset.detail || '';
    };

    if (chapterNodes.length > 0) {
        setActiveStep(chapterNodes[0].dataset.step || '1');
    }

    const onTopbarScroll = () => {
        root.classList.toggle('is-scrolled', window.scrollY > 32);
    };

    onTopbarScroll();
    window.addEventListener('scroll', onTopbarScroll, { passive: true });

    if (prefersReducedMotion) return;

    root.classList.add('has-motion');

    const revealItems = Array.from(document.querySelectorAll('.reveal'));
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                revealObserver.unobserve(entry.target);
            }
        });
    }, {
        rootMargin: '0px 0px -8% 0px',
        threshold: 0.2
    });

    revealItems.forEach((item) => revealObserver.observe(item));

    const storyObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                const step = entry.target.getAttribute('data-step');
                if (step) setActiveStep(step);
            }
        });
    }, {
        rootMargin: '-35% 0px -45% 0px',
        threshold: 0.1
    });

    chapterNodes.forEach((chapter) => storyObserver.observe(chapter));
})();
