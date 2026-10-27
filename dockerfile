# Build the Pokémon Showdown client
FROM node:22-bookworm AS builder

WORKDIR /app

# `build-full` clones and builds the Showdown server data.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# The forked build script clones pokemon-showdown-queen, but later expects
# the checkout at caches/pokemon-showdown. Give git clone that explicit name.
RUN node -e "const fs = require('fs'); const p = 'build-tools/build-indexes'; const s = fs.readFileSync(p, 'utf8'); const old = 'git clone https://github.com/QueenOfRodents/pokemon-showdown-queen.git'; const replacement = old + ' pokemon-showdown'; if (!s.includes(old)) throw new Error('Expected clone command was not found'); fs.writeFileSync(p, s.replace(old, replacement));"

RUN mkdir -p caches \
    && npm run build-full


# Serve the generated static site
FROM nginx:1.27-alpine

COPY --from=builder /app/play.pokemonshowdown.com/ /usr/share/nginx/html/

RUN printf '%s\n' \
    'server {' \
    '    listen 80;' \
    '    server_name _;' \
    '    root /usr/share/nginx/html;' \
    '    index index.html;' \
    '' \
    '    location / {' \
    '        try_files $uri $uri/ /index.html;' \
    '    }' \
    '' \
    '    location ~* \.(?:css|js|mjs|json|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf)$ {' \
    '        try_files $uri =404;' \
    '        expires 7d;' \
    '        add_header Cache-Control "public";' \
    '    }' \
    '}' \
    > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
