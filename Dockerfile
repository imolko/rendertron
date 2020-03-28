FROM node:10-slim

# Add Respository chrome
RUN echo "Add Respository chrome." \
    && apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get --purge remove -y gnupg \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*


# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN  echo "Install latest chrome dev package." \
    && apt-get update \
    && apt-cache depends google-chrome-unstable \
    && apt-get install -y \
        google-chrome-unstable \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*


# Copy App.
COPY . /app/

# Add botrender as a user
RUN echo "Add botrender as a user." \ 
    && groupadd -r botrender && useradd -r -g botrender -G audio,video botrender \
    && mkdir -p /home/botrender/.config/fontconfig \
    && chown -R botrender:botrender /home/botrender \
    && chown -R botrender:botrender /app

# Instalamos las fuentes.
RUN echo "Add Fonts." \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        unzip \
        fonts-ipafont-gothic \
        fonts-wqy-zenhei \
        fonts-thai-tlwg \
        fonts-kacst \
        fonts-freefont-ttf \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-ipafont-mincho \
        fonts-unfonts-core \
    && TEMPFOLDER="$(mktemp -d)" \
    && cd "$TEMPFOLDER" \
    && wget https://noto-website.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip \
    && unzip NotoColorEmoji-unhinted.zip \
    && apt-get --purge remove -y unzip \
    && chmod 644 *.ttf \
    && mkdir -p /usr/local/share/fonts \
    && mv *.ttf /usr/local/share/fonts \
    && mkdir -p /home/botrender/.config/fontconfig \
    && cp /app/fonts.conf /home/botrender/.fonts.conf \
    && chown -R botrender:botrender /home/botrender \
    && cd \
    && rm -rf "$TEMPFOLDER" \
    && rm -rf /var/lib/apt/lists/*

# Run botrender non-privileged
USER botrender

# Build font cache.
RUN echo "Build font cache." \
    && fc-cache -f -v

# Workirn dir.
WORKDIR /app/

# expose port 3000
EXPOSE 3000

# Compile and install the application. TODO: Verificar que no sea necesrio elimnar la cahce de npm
RUN echo "Compile and install the application." \
    && npm install \
    && npm run build \
    && rm -rf node_modules \
    && npm install --production \
    && npm cache clean --force

# ejecutamos la aplicacion npm.
ENTRYPOINT [ "npm" ]

# Lanzamos la aplicacion.
CMD ["run", "start"]

