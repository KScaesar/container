# https://snyk.io/blog/best-practices-containerizing-python-docker/

FROM python:3.11-slim AS builder

WORKDIR /build

COPY ./requirements.txt .

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gcc && \
    pip install --no-cache-dir --prefix=/build -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
ENV TZ=Asia/Taipei
ENV PREFECT_API_URL=http://prefect.vHost:4200/api

COPY --from=builder /build /usr/local
COPY ./ ./

CMD ["python", "example.py" ]