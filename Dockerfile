FROM oxsecurity/megalinter-terraform:v8

# Install git-crypt
RUN apk add --no-cache git-crypt
