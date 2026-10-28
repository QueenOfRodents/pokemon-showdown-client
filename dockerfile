# Build the Pokémon Showdown client
FROM node:22-bookworm AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Fix repository target clone name
RUN node -e "const fs = require('fs'); const p = 'build-tools/build-indexes'; const s = fs.readFileSync(p, 'utf8'); const old = 'git clone https://github.com/QueenOfRodents/pokemon-showdown-queen.git'; const replacement = old + ' pokemon-showdown'; if (!s.includes(old)) throw new Error('Expected clone command was not found'); fs.writeFileSync(p, s.replace(old, replacement));"

RUN mkdir -p caches \
    && npm run build-full


# Serve the static site
FROM nginx:1.27-alpine

# 1. Clean out the default Nginx welcome files
RUN rm -rf /usr/share/nginx/html/*

# 2. Copy the built Showdown client
COPY --from=builder /app/play.pokemonshowdown.com/ /usr/share/nginx/html/

# 3. Copy your clean Nginx configuration directly over the default config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 4. Test configuration syntax at build time to catch errors early
RUN nginx -t

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
