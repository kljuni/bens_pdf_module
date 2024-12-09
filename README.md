# BensPdfModule

## Overview
BensPdfModule is a Ruby on Rails application designed for processing PDF documents. This README provides instructions on how to set up and run the application using docker compose.

## Prerequisites
- docker
- docker compose

## Getting Started

### 1. Clone the Repository
First, clone the repository to your local machine:
```
git clone https://github.com/kljuni/bens_pdf_module.git
cd bens_pdf_module
```

### 2. Add an .env file in root of project containing these fields:
```
DATABASE_USER=
DATABASE_PASSWORD=
POSTGRES_DB=
REDIS_URL=
```

### 3. Build and Start the Application
Use docker compose to build and start the application. This will set up the web server, database, and any other services defined in the `docker-compose.yml` file.

```
docker compose up --build
```

### 5. Database Setup
To set up the database, run the following command in a new terminal window (make sure the Docker containers are still running):
```
docker compose run web ./bin/rails db:create db:migrate
docker compose run web ./bin/rails db:seed
```