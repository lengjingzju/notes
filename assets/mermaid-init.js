(() => {
    const darkThemes = ['ayu', 'navy', 'coal'];
    const lightThemes = ['light', 'rust'];

    const classList = document.getElementsByTagName('html')[0].classList;

    let lastThemeWasLight = true;
    for (const cssClass of classList) {
        if (darkThemes.includes(cssClass)) {
            lastThemeWasLight = false;
            break;
        }
    }

    const theme = lastThemeWasLight ? 'default' : 'dark';
    mermaid.initialize({
        startOnLoad: false,
        theme,
        securityLevel: 'loose',
        fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    });

    // 创建SVG图标（完全内联）
    const createSVGIcon = (pathData) => {
        const svgNS = "http://www.w3.org/2000/svg";
        const svg = document.createElementNS(svgNS, "svg");
        svg.setAttribute("viewBox", "0 0 24 24");
        svg.setAttribute("width", "16");
        svg.setAttribute("height", "16");
        svg.style.verticalAlign = "middle";
        svg.style.marginRight = "4px";

        const path = document.createElementNS(svgNS, "path");
        path.setAttribute("d", pathData);

        svg.appendChild(path);
        return svg;
    };

    // 下载SVG功能（完全自包含）
    const downloadSVG = (svgElement, fileName = 'diagram.svg') => {
        try {
            const serializer = new XMLSerializer();
            let source = serializer.serializeToString(svgElement);

            // 修复命名空间问题
            if (!source.includes('xmlns="http://www.w3.org/2000/svg"')) {
                source = source.replace(/<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
            }
            if (!source.includes('xmlns:xlink="http://www.w3.org/1999/xlink"')) {
                source = source.replace(/<svg/, '<svg xmlns:xlink="http://www.w3.org/1999/xlink"');
            }

            const blob = new Blob([source], { type: 'image/svg+xml;charset=utf-8' });
            const url = URL.createObjectURL(blob);

            const downloadLink = document.createElement("a");
            downloadLink.href = url;
            downloadLink.download = fileName;
            downloadLink.style.display = "none";
            document.body.appendChild(downloadLink);
            downloadLink.click();

            // 清理
            setTimeout(() => {
                document.body.removeChild(downloadLink);
                URL.revokeObjectURL(url);
            }, 100);
        } catch (e) {
            console.error('下载SVG失败:', e);
            alert('下载图表失败，请尝试刷新页面后重试');
        }
    };

    // 处理Mermaid图表
    const processMermaidDiagrams = () => {
        document.querySelectorAll('div.mermaid:not(.processed)').forEach(diagram => {
            // 标记为已处理
            diagram.classList.add('processed');

            // 获取原始代码
            const rawCode = diagram.getAttribute('data-code') || '';
            if (!rawCode) return;

            // 创建容器
            const container = document.createElement('div');
            container.className = 'mermaid-container';

            // 创建按钮容器
            const buttonGroup = document.createElement('div');
            buttonGroup.className = 'mermaid-button-group';

            // 创建切换按钮
            const toggleButton = document.createElement('button');
            toggleButton.className = 'mermaid-toggle';
            toggleButton.textContent = '显示代码';

            // 创建下载按钮
            const downloadButton = document.createElement('button');
            downloadButton.className = 'mermaid-download';
            downloadButton.appendChild(createSVGIcon("M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"));
            downloadButton.appendChild(document.createTextNode('下载'));

            // 创建复制按钮
            const copyButton = document.createElement('button');
            copyButton.className = 'mermaid-copy';
            copyButton.appendChild(createSVGIcon("M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"));
            copyButton.appendChild(document.createTextNode('复制'));
            copyButton.style.display = 'none'; // 默认隐藏

            // 设置切换按钮点击事件
            toggleButton.addEventListener('click', () => {
                const codePre = container.querySelector('.mermaid-code');
                if (toggleButton.textContent === '显示代码') {
                    diagram.style.display = 'none';
                    codePre.style.display = 'block';
                    copyButton.style.display = 'inline-flex';
                    downloadButton.style.display = 'none';
                    toggleButton.textContent = '显示图表';
                } else {
                    diagram.style.display = 'block';
                    codePre.style.display = 'none';
                    copyButton.style.display = 'none';
                    downloadButton.style.display = 'inline-flex';
                    toggleButton.textContent = '显示代码';
                }
            });

            // 设置下载按钮点击事件
            downloadButton.addEventListener('click', () => {
                const svgElement = diagram.querySelector('svg');
                if (svgElement) {
                    // 生成文件名
                    let fileName = 'diagram.svg';
                    const header = document.querySelector('h1');
                    if (header) {
                        fileName = header.textContent.trim().replace(/[^\w\s]/gi, '') + '.svg';
                    }
                    downloadSVG(svgElement, fileName);
                } else {
                    console.error('找不到SVG元素');
                    alert('无法下载图表，图表尚未加载完成');
                }
            });

            // 设置复制按钮点击事件
            copyButton.addEventListener('click', () => {
                navigator.clipboard.writeText(rawCode).then(() => {
                    const originalHTML = copyButton.innerHTML;
                    copyButton.innerHTML = '<span class="copied-text">已复制!</span>';

                    setTimeout(() => {
                        copyButton.innerHTML = originalHTML;
                    }, 2000);
                }).catch(err => {
                    console.error('复制失败:', err);
                    copyButton.innerHTML = '<span class="error-text">复制失败</span>';
                    setTimeout(() => {
                        copyButton.innerHTML = originalHTML;
                    }, 2000);
                });
            });

            // 创建代码显示区域
            const codePre = document.createElement('pre');
            codePre.className = 'mermaid-code';
            codePre.textContent = rawCode;
            codePre.style.display = 'none';

            // 组装按钮组
            buttonGroup.appendChild(toggleButton);
            buttonGroup.appendChild(downloadButton);
            buttonGroup.appendChild(copyButton);

            // 包装图表
            diagram.parentNode.insertBefore(container, diagram);
            container.appendChild(buttonGroup);
            container.appendChild(diagram);
            container.appendChild(codePre);
        });
    };

    // 保存原始代码并初始化Mermaid
    document.querySelectorAll('pre.mermaid').forEach(pre => {
        const rawCode = pre.textContent.trim();

        // 创建图表容器
        const diagram = document.createElement('div');
        diagram.className = 'mermaid';
        diagram.setAttribute('data-code', rawCode);
        diagram.textContent = rawCode;

        // 替换原始<pre>元素
        pre.parentNode.replaceChild(diagram, pre);
    });

    // 初始化Mermaid并添加按钮
    mermaid.init(undefined, '.mermaid').then(() => {
        processMermaidDiagrams();
    });

    // 监听主题切换事件
    for (const darkTheme of darkThemes) {
        const element = document.getElementById(darkTheme);
        if (element) {
            element.addEventListener('click', () => {
                if (lastThemeWasLight) {
                    window.location.reload();
                }
            });
        }
    }

    for (const lightTheme of lightThemes) {
        const element = document.getElementById(lightTheme);
        if (element) {
            element.addEventListener('click', () => {
                if (!lastThemeWasLight) {
                    window.location.reload();
                }
            });
        }
    }

    // 监听可能的动态内容变化
    const observer = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
            if (mutation.addedNodes.length) {
                setTimeout(processMermaidDiagrams, 300);
            }
        });
    });

    observer.observe(document.body, { childList: true, subtree: true });
})();
