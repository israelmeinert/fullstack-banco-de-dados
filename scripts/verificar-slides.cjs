// Usa o navegador e o Puppeteer já presentes na imagem oficial do Marp.
const fs = require('node:fs');
const puppeteer = require('/home/marp/.cli/node_modules/puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  try {
    const page = await browser.newPage();
    await page.setViewport({width: 1280, height: 720});
    await page.emulateMediaType('print');
    await page.goto('file:///home/marp/app/index.html', {waitUntil: 'networkidle0'});
    await page.evaluate(() => document.fonts.ready);
    const slides = await page.evaluate(() => [...document.querySelectorAll('section')].map((section, index) => {
      const area = section.getBoundingClientRect();
      const problemas = [...section.children]
        .filter(el => !['HEADER', 'FOOTER'].includes(el.tagName))
        .filter(el => {
          const box = el.getBoundingClientRect();
          return box.bottom > area.bottom - 35 * (area.height / 720) ||
            box.right > area.right + 1 || box.left < area.left - 1;
        }).map(el => el.textContent.trim().slice(0, 120));
      return {slide: index + 1, titulo: section.querySelector('h1')?.textContent, problemas};
    }));
    fs.mkdirSync('/home/marp/app/resultados', {recursive: true});
    fs.writeFileSync('/home/marp/app/resultados/slides-layout.json', JSON.stringify(slides, null, 2));
    const problemas = slides.filter(slide => slide.problemas.length);
    for (const index of [0, 3, 24, 40, 51]) {
      const sections = await page.$$('section');
      await sections[index].screenshot({path: `/home/marp/app/resultados/slide-${index + 1}.png`});
    }
    console.log(JSON.stringify({slides: slides.length, problemas}, null, 2));
    if (slides.length !== 52 || problemas.length) process.exitCode = 1;
  } finally {
    await browser.close();
  }
})().catch(erro => {console.error(erro); process.exitCode = 1;});
