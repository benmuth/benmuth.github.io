# Render site
default:
    bag index.janet

# Deploy site
deploy:
    git push origin main

# Install dependencies for live reload
install:
    pnpm install -g http-server livereload

set working-directory := 'site'
# Serve HTTP with live reloading
# (make sure "http://localhost:35729/livereload.js\" is in the HTML file)
serve:
    bash -c 'cleanup() { kill $(jobs -p); }; \
             trap cleanup EXIT; \
             http-server -o -c-1 & \
             livereload & \
             wait'
