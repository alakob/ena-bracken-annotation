FROM python:3.8

LABEL Author="Blaise Alako" Email="blaise@ebi.ac.uk"

LABEL Description="ENA Bracken metadata API service" Vendor="EMBL-EBI" Version="1.0"

WORKDIR /usr/src/app

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "./run.py" ]
