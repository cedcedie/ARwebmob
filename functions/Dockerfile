# functions/Dockerfile
FROM node:20-slim

# libreoffice-impress: headless PPTX -> PDF conversion (soffice --headless --convert-to pdf).
# poppler-utils: provides pdftoppm, used to rasterize the intermediate PDF into per-slide
# PNGs. The task brief's own sample only installs libreoffice-impress, but pdftoppm is
# NOT bundled with LibreOffice — it ships in poppler-utils. Without this package the
# `pdftoppm` execFile call in src/index.js would fail with ENOENT on every conversion, so
# it's included here even though it isn't listed in the brief's literal Dockerfile sample.
RUN apt-get update && apt-get install -y \
    libreoffice-impress \
    poppler-utils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY package.json ./
RUN npm install --omit=dev
COPY . .

CMD ["node", "src/index.js"]
