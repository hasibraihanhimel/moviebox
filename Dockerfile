FROM node:22-alpine AS frontend
WORKDIR /build
RUN apk add --no-cache unzip
COPY moviebox-source.zip /tmp/moviebox-source.zip
RUN unzip -q /tmp/moviebox-source.zip -d /build/src
WORKDIR /build/src
RUN npm install
RUN npm run build

FROM python:3.12-slim
WORKDIR /app
COPY moviebox-source.zip /tmp/moviebox-source.zip
RUN python - <<'PY'
import zipfile
with zipfile.ZipFile('/tmp/moviebox-source.zip') as z:
    z.extractall('/tmp/src')
PY
COPY --from=frontend /build/src/dist ./dist
COPY --from=frontend /build/src/api.py ./api.py
COPY --from=frontend /build/src/main.py ./main.py
COPY --from=frontend /build/src/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
