# FROM python:3.8-slim
# COPY consumer.py .
# RUN pip install kafka-python
# CMD ["python", "consumer.py"]
# ENV PYTHONUNBUFFERED=1

FROM python:3.8-slim
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY consumer.py .
RUN pip install --no-cache-dir kafka-python==2.0.2
CMD ["python", "consumer.py"]
