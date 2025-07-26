# Technology Stack & Build System

## Core Technologies
- **Apache Spark 3.4**: Distributed computing framework (Bitnami images)
- **Apache Flink 1.x**: Stream processing framework
- **Docker & Docker Compose**: Containerization and orchestration
- **Jupyter Notebook**: Interactive development environment with PySpark
- **Python**: Primary programming language with PySpark API
- **Scala**: Secondary language support for Spark development

## Optional Components
- **Apache Kafka 7.4.0**: Message streaming (Confluent images)
- **Apache Zookeeper**: Kafka coordination
- **Elasticsearch 8.8.0**: Search and analytics engine
- **Kibana 8.8.0**: Data visualization dashboard

## Environment Management

### Common Commands

#### Environment Startup
```powershell
# Start core environment (Spark + Jupyter)
.\scripts\start_environment.ps1

# Start with streaming components (includes Kafka)
.\scripts\start_environment.ps1 -Streaming

# Start with analytics components (includes Elasticsearch/Kibana)
.\scripts\start_environment.ps1 -Analytics

# Start all components
.\scripts\start_environment.ps1 -All

# Force restart environment
.\scripts\start_environment.ps1 -Force
```

#### Environment Management
```powershell
# Stop environment
.\scripts\stop_environment.ps1

# Health check
.\scripts\health_check.ps1

# Detailed health check with streaming components
.\scripts\health_check.ps1 -Detailed -Streaming

# Environment verification
.\scripts\verify_environment.ps1

# Troubleshooting
.\scripts\troubleshoot.ps1
```

#### Docker Commands
```powershell
# View container status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all containers
docker-compose down

# Rebuild containers
docker-compose build --no-cache
```

## Development Environment

### Jupyter Configuration
- **Port**: 8888
- **Token-based authentication**: Auto-generated tokens
- **Pre-installed libraries**: PySpark, Pandas, Matplotlib, NumPy
- **Spark UI ports**: 4040-4050 range
- **Auto-save extension**: Enabled for notebooks

### Spark Cluster Configuration
- **Master**: spark://spark-master:7077 (UI: port 8080)
- **Workers**: 2 workers with 2GB memory, 2 cores each
- **Worker UIs**: ports 8081, 8082
- **Driver memory**: 1GB
- **Executor memory**: 1GB

## File Structure Conventions
- **Scripts**: PowerShell (.ps1) for Windows environment
- **Notebooks**: Jupyter (.ipynb) and Markdown (.md) documentation
- **Data**: Organized by size (sample/, medium/, large/)
- **Configuration**: Docker Compose and Spark configuration files
- **Documentation**: Chinese primary, English secondary