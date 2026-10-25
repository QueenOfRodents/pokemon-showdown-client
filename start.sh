#!/bin/sh
set -e

cd /app
npm run build-full || echo 'WARNING: build-full failed; serving pre-built assets from image'
echo 'exports.BattlePokemonSprites = {};' > play.pokemonshowdown.com/data/pokedex-mini.js
echo 'exports.BattlePokemonSpritesGens = {};' > play.pokemonshowdown.com/data/pokedex-mini-bw.js

# Create stub testclient-key.js in root config dir if not provided via a volume mount,
# then symlink it into play.pokemonshowdown.com/config/ (same pattern as the other config files).
if [ ! -f /app/config/testclient-key.js ]; then
    echo '// Set POKEMON_SHOWDOWN_TESTCLIENT_KEY to your PS sid cookie value to auto-login on the test client.' > /app/config/testclient-key.js
fi
ln -sf /app/config/testclient-key.js /app/play.pokemonshowdown.com/config/testclient-key.js

php-fpm &
exec nginx -g 'daemon off;'
