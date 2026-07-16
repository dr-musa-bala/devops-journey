# Step 1: Grab a pre-made kitchen from the internet
FROM nginx:alpine
# Step 2: Put our webpage (the sandwich) into the kitchen's serving tray
COPY index.html /usr/share/nginx/html/index.html
# Step 3: Tell the kichen to open its doors to the public
EXPOSE 80