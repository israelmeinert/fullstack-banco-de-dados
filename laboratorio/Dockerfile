FROM python:3.12.12-slim-bookworm
WORKDIR /lab
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
ENTRYPOINT ["python", "/lab/testes.py"]
