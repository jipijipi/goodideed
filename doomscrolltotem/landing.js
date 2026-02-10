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

        const kickerNode = activeChapter.querySelector('[data-meta="kicker"]');
        const titleNode = activeChapter.querySelector('[data-meta="title"]');
        const detailNode = activeChapter.querySelector('[data-meta="detail"]');

        if (storyKicker) storyKicker.textContent = (kickerNode && kickerNode.textContent) || activeChapter.dataset.kicker || '';
        if (storyTitle) storyTitle.textContent = (titleNode && titleNode.textContent) || activeChapter.dataset.title || '';
        if (storyDetail) storyDetail.textContent = (detailNode && detailNode.textContent) || activeChapter.dataset.detail || '';
    };

    if (chapterNodes.length > 0) {
        setActiveStep(chapterNodes[0].dataset.step || '1');
    }

    let lastY = window.scrollY;
    let tickingTopbar = false;
    const onTopbarScroll = () => {
        if (tickingTopbar) return;
        tickingTopbar = true;

        window.requestAnimationFrame(() => {
            const currentY = window.scrollY;
            const delta = currentY - lastY;

            root.classList.toggle('is-scrolled', currentY > 32);

            if (currentY > 120 && delta > 2) {
                root.classList.add('is-nav-compact');
            } else if (delta < -2 || currentY <= 80) {
                root.classList.remove('is-nav-compact');
            }

            lastY = currentY;
            tickingTopbar = false;
        });
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
